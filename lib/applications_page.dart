// --- applications_page.dart ---
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart'
    as tzdata; // Make sure this is initialized if needed here

class ApplicationsPage extends StatefulWidget {
  final Function(String) onDownload;
  final String currentLanguage;
  final Map<String, Map<String, String>> localizedStrings;
  final String companyId;
  final String Function(int?) getPlanName;

  const ApplicationsPage({
    Key? key,
    required this.onDownload,
    required this.currentLanguage,
    required this.localizedStrings,
    required this.companyId,
    required this.getPlanName,
  }) : super(key: key);

  @override
  _ApplicationsPageState createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  final _logger = Logger();
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String? _fetchError;

  // State to track which application is being deleted
  String? _deletingApplicationId;

  @override
  void initState() {
    super.initState();
    // Initialize timezone data if you handle timezones directly here
    tzdata.initializeTimeZones();
    _fetchApplications();
  }

  // --- Translate using PASSED language/strings ---
  String _translate(String key, [Map<String, dynamic>? params]) {
    final langKey = ['en', 'uz', 'ru'].contains(widget.currentLanguage)
        ? widget.currentLanguage
        : 'uz';
    String? translatedValue = widget.localizedStrings[langKey]?[key] ??
        widget.localizedStrings['uz']?[key];
    translatedValue ??= key;
    if (params != null) {
      params.forEach((pKey, value) {
        translatedValue =
            translatedValue!.replaceAll('{$pKey}', value.toString());
      });
    }
    return translatedValue!;
  }

  // --- Helper: Get Status Text ---
  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return _translate('pending');
      case 'active':
        return _translate('active');
      case 'stopped':
        return _translate('stopped');
      case 'rejected':
        return _translate('rejected');
      case 'superseded':
        return _translate('superseded');
      case 'expired':
        return _translate('expired');
      default:
        _logger.w('Unknown application status: $status');
        return _translate('unknown_status');
    }
  }

  // --- Helper: Get Plan Name ---
  String _getPlanName(int? planType) {
    return widget
        .getPlanName(planType); // Use the function passed from AdminPage
  }

  // --- Fetch Applications Logic ---
  Future<void> _fetchApplications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _fetchError = null;
      _applications = [];
    });

    try {
      final companyId = widget.companyId;
      if (companyId.isEmpty || companyId == 'N/A') {
        _logger.w(
            "Cannot fetch applications: Invalid Company ID passed to ApplicationsPage.");
        if (mounted) {
          setState(() {
            _applications = [];
            _isLoading = false;
            _fetchError = _translate('company_id_not_found');
          });
        }
        return;
      }

      _logger.i("Fetching applications for company ID: $companyId");

      final response = await Supabase.instance.client
          .from('applications')
          .select(
              'id, submitted_at, subscription_months, status, receipt_url, plan_type, total_amount, approved_at') // Added approved_at
          .eq('company_id', companyId)
          .order('submitted_at', ascending: false);

      if (response != null && response is List) {
        final fetchedApplications = List<Map<String, dynamic>>.from(response);
        if (mounted) {
          setState(() {
            _applications = fetchedApplications;
            _isLoading = false;
          });
          _logger.i(
              "Fetched ${_applications.length} applications for company ID $companyId.");
        }
      } else {
        _logger
            .w("Fetch applications response was null or not a list: $response");
        if (mounted) {
          setState(() {
            _applications = [];
            _isLoading = false;
            _fetchError = _translate('error_fetching_applications',
                {'error': 'Invalid response format.'});
          });
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error fetching applications',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        String errorMessage;
        if (e is PostgrestException) {
          errorMessage = _translate('error_fetching_applications',
              {'error': 'DB Error: ${e.message}'});
        } else if (e is SocketException) {
          errorMessage = _translate('no_internet');
        } else if (e.toString().contains("User not logged in")) {
          errorMessage =
              "User session expired. Please log in again."; // Hardcoded
        } else {
          errorMessage = _translate(
              'error_fetching_applications', {'error': e.toString()});
        }

        setState(() {
          _isLoading = false;
          _applications = [];
          _fetchError = errorMessage;
        });
      }
    }
  }

  // --- Delete Application Logic ---
  Future<void> _deleteApplication(String applicationId) async {
    if (!mounted) return;

    // Optional: Show a confirmation dialog
    final bool confirmed = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'), // Hardcoded
              content: const Text(
                  'Are you sure you want to delete this pending application?'), // Hardcoded
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'), // Hardcoded
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red)), // Hardcoded
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed

    if (!confirmed) {
      return; // User canceled deletion
    }

    // Set state to indicate deletion is in progress for this item
    setState(() {
      _deletingApplicationId = applicationId;
    });

    try {
      _logger.i("Attempting to delete application ID: $applicationId");
      final response = await Supabase.instance.client
          .from('applications')
          .delete()
          .eq('id', applicationId)
          .eq('company_id',
              widget.companyId); // Ensure only deleting for the current company

      // Supabase delete returns an empty list on success, or throws on failure.
      // We check if the response was successful implicitly by not catching an error.

      _logger.i("Application $applicationId deleted successfully.");

      if (mounted) {
        // Remove the application from the local list immediately
        setState(() {
          _applications.removeWhere((app) => app['id'] == applicationId);
          _deletingApplicationId = null; // Clear deleting state
        });
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Application deleted successfully.'),
            backgroundColor: Colors.green)); // Hardcoded
      }
    } catch (e, stackTrace) {
      _logger.e('Error deleting application $applicationId',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _deletingApplicationId = null; // Clear deleting state on error
        });
        String errorMessage;
        if (e is PostgrestException) {
          errorMessage = 'Delete failed: ${e.message}'; // Hardcoded
          // Note: Supabase RLS should prevent deleting non-pending or other company's apps.
          // If RLS is set up correctly, this error might indicate insufficient permissions.
          if (e.message.contains('permission denied')) {
            errorMessage =
                'Permission denied to delete this application.'; // Hardcoded
          }
        } else {
          errorMessage = 'Delete failed: ${e.toString()}'; // Hardcoded
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      }
    }
  }

  // --- Helper Widget: Build Status Chip (Remains the same) ---
  Widget _buildStatusChip(String? status) {
    Color chipColor;
    Color textColor = Colors.white;
    IconData? iconData;
    switch (status?.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange.shade700;
        iconData = Icons.hourglass_top_rounded;
        break;
      case 'active':
        chipColor = Colors.green.shade700;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case 'stopped':
        chipColor = Colors.grey.shade600;
        iconData = Icons.pause_circle_outline_rounded;
        break;
      case 'rejected':
        chipColor = Colors.red.shade700;
        iconData = Icons.cancel_outlined;
        break;
      case 'superseded':
        chipColor = Colors.blueGrey.shade400;
        iconData = Icons.history_toggle_off_rounded;
        break;
      case 'expired':
        chipColor = Colors.deepOrange.shade700;
        iconData = Icons.error_outline_rounded;
        break;
      default:
        chipColor = Colors.blueGrey;
        iconData = Icons.help_outline_rounded;
    }
    return Chip(
      avatar: Icon(iconData, color: textColor, size: 16),
      label: Text(_getStatusText(status)),
      backgroundColor: chipColor,
      labelStyle: TextStyle(
          color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  // Helper to safely format date
  String _safeFormatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      // Parse as UTC and convert to local TZDateTime
      final utcDate = DateTime.parse(dateString).toUtc();
      final localTZDate = tz.TZDateTime.from(utcDate, tz.local);
      return DateFormat('yyyy-MM-dd HH:mm', widget.currentLanguage)
          .format(localTZDate);
    } catch (e) {
      _logger.w("Failed to parse/format date string: $dateString", error: e);
      return 'Invalid Date'; // Hardcoded error message
    }
  }

  // --- Build Method for ApplicationsPage ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if companyId is available before building the list
    if (widget.companyId.isEmpty || widget.companyId == 'N/A') {
      return Scaffold(
        // Return a simple scaffold with an error message
        appBar: AppBar(
          title: Text(_translate('my_applications_title')),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 1.0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_translate('company_id_not_found'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.red.shade700)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('my_applications_title')),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _deletingApplicationId != null
                ? null
                : _fetchApplications, // Disable while loading or deleting
            tooltip: _translate('refresh'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchApplications,
              color: theme.primaryColor,
              child: _applications.isEmpty && _fetchError == null
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                              child: Text(_translate('no_applications'),
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(color: Colors.grey[600]))),
                        ),
                      ),
                    )
                  : _fetchError != null
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: Center(
                                  child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(_fetchError!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.red.shade700)),
                              )),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _applications.length,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 8.0),
                          itemBuilder: (context, index) {
                            final app = _applications[index];
                            final receiptUrl = app['receipt_url'] as String?;
                            final String? appId = app['id'] as String?;
                            final int? planType =
                                (app['plan_type'] as num?)?.toInt();
                            final int months =
                                (app['subscription_months'] as num?)?.toInt() ??
                                    0;
                            final String status =
                                app['status'] as String? ?? 'unknown';

                            // Determine if the delete button should be shown (only for 'pending' status)
                            final bool showDeleteButton =
                                status.toLowerCase() == 'pending';
                            // Check if this specific application is currently being deleted
                            final bool isDeletingThisApp =
                                _deletingApplicationId == appId;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              elevation: 1.5,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _getPlanName(planType),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme
                                                          .primaryColorDark),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          _buildStatusChip(status),
                                        ]),
                                    const SizedBox(height: 8),
                                    const Divider(height: 1, thickness: 0.5),
                                    const SizedBox(height: 8),

                                    // Application ID row
                                    Row(children: [
                                      Icon(Icons.tag_rounded,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: SelectableText(
                                        _translate('application_id',
                                            {'id': appId ?? 'N/A'}),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.grey[700]),
                                      ))
                                    ]),
                                    const SizedBox(height: 4),

                                    // Submitted At row
                                    Row(children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(
                                          _translate('submitted_at', {
                                            'datetime': _safeFormatDate(
                                                app['submitted_at'])
                                          }),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: Colors.grey[700]))
                                    ]),
                                    const SizedBox(height: 4),

                                    // Approved At row (Show only if approved_at exists)
                                    if (app['approved_at'] != null) ...[
                                      Row(children: [
                                        Icon(Icons.event_available_outlined,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                            _translate('last_activated', {
                                              'datetime': _safeFormatDate(
                                                  app['approved_at'])
                                            }),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: Colors.grey[700]))
                                      ]),
                                      const SizedBox(height: 4),
                                    ],

                                    // Term (Months) row
                                    Row(children: [
                                      Icon(Icons.timelapse_rounded,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(
                                          _translate('subscription_months',
                                              {'months': months}),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: Colors.grey[700]))
                                    ]),
                                    const SizedBox(height: 4),

                                    // Total Amount row
                                    if (app['total_amount'] != null) ...[
                                      Row(children: [
                                        Icon(Icons.attach_money_rounded,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                            '${app['total_amount'].toStringAsFixed(0)} UZS', // Format total amount
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: Colors.grey[700])),
                                      ]),
                                      const SizedBox(height: 4),
                                    ],

                                    // Row for action buttons (Receipt and Delete)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .end, // Align buttons to the end
                                      children: [
                                        // Receipt Download button
                                        if (receiptUrl != null &&
                                            receiptUrl.isNotEmpty)
                                          IconButton(
                                            icon: Icon(
                                                Icons
                                                    .download_for_offline_outlined,
                                                color: theme.primaryColor),
                                            tooltip:
                                                _translate('download_receipt'),
                                            onPressed: () =>
                                                widget.onDownload(receiptUrl),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        // Delete Button (Conditional)
                                        if (showDeleteButton &&
                                            appId !=
                                                null) // Only show if pending and has an ID
                                          isDeletingThisApp // Show loading indicator if deleting this specific app
                                              ? const SizedBox(
                                                  width:
                                                      24, // Match IconButton size approximately
                                                  height: 24,
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2)))
                                              : IconButton(
                                                  icon: Icon(
                                                      Icons.delete_outline,
                                                      color:
                                                          Colors.red.shade700),
                                                  tooltip:
                                                      'Delete Application', // Hardcoded
                                                  onPressed: _isLoading
                                                      ? null
                                                      : () => _deleteApplication(
                                                          appId), // Disable during main fetch
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}
