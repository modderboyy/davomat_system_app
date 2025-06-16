// --- web_apps_page.dart ---
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:async'; // Required for Completer
import 'package:url_launcher/url_launcher.dart'; // For external launch if needed
import 'package:flutter/services.dart'; // For Clipboard

// Helper class to manage state of individual open web views
class _OpenWebApp {
  final String id;
  final String name;
  final String url;
  final UniqueKey key = UniqueKey(); // Unique key for the WebView
  bool isMinimized;
  WebViewController? controller; // Store the controller
  final Completer<WebViewController> _controllerCompleter =
      Completer<WebViewController>(); // Completer for controller

  _OpenWebApp({
    required this.id,
    required this.name,
    required this.url,
    this.isMinimized = false,
  });

  // Method to create or get controller
  Future<WebViewController> getOrCreateController(Logger logger) async {
    if (controller != null) {
      if (!_controllerCompleter.isCompleted) {
        _controllerCompleter.complete(controller);
      }
      return controller!;
    }

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // Use WebKitWebViewControllerCreationParams for iOS specific settings
      final webKitParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
      // allowsBackForwardNavigationGestures is a property on WKWebViewConfiguration,
      // which is configured via WebKitWebViewControllerCreationParams.
      // The specific property name might depend on the webview_flutter version.
      // The original error "The setter 'allowsBackForwardNavigationGestures' isn't defined for the type 'WebKitWebViewController'"
      // suggests it was incorrectly accessed *after* creation on the platform instance.
      // We should set it during params creation if available in the specific webview_flutter version being used.
      // As of webview_flutter 4.x, this property is NOT directly in WebKitWebViewControllerCreationParams.
      // It seems you might need to cast the platform controller *after* creation if you need to set it dynamically,
      // but this can be fragile. Setting it during creation via params is safer if the API supports it.
      // Let's remove the problematic line entirely to fix the error, as gesture control isn't essential for basic function.
      // If needed, consult webview_flutter docs for the correct way in your version.
      params = webKitParams;
    } else {
      // Use default creation parameters for other platforms (like Android)
      params = const PlatformWebViewControllerCreationParams();
    }

    final newController = WebViewController.fromPlatformCreationParams(params);

    newController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar. Can be added to _OpenWebApp state
            // and passed to the WebView widget.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            // Handle errors
            logger.e("WebView Error for $name ($url): ${error.description}",
                error: error);
          },
          onNavigationRequest: (NavigationRequest request) {
            // You can intercept navigation requests here if needed
            // For example, open external links in the browser
            logger.i("WebView navigating to: ${request.url}");
            // Example: Open non-http/https URLs externally (e.g., mailto:, tel:)
            if (!request.url.startsWith('http://') &&
                !request.url.startsWith('https://')) {
              launchUrl(Uri.parse(request.url),
                      mode: LaunchMode.externalApplication)
                  .catchError((e) {
                logger.e("Failed to launch external URL: ${request.url}",
                    error: e);
              });
              return NavigationDecision
                  .prevent; // Prevent webview from loading it
            }
            // Example: Open specific external domains in browser if needed
            // if (request.url.startsWith('your.external.domain')) {
            //   launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication).catchError((e) { logger.e("Failed to launch external URL: ${request.url}", error: e); });
            //   return NavigationDecision.prevent;
            // }
            return NavigationDecision.navigate;
          },
        ),
      );

    // #docregion platform_features
    if (newController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (newController.platform as AndroidWebViewController)
          .setTextZoom(100); // Optional: set zoom
    }
    // Removed the problematic WebKit gesture setting here as it caused the error.
    // If needed, investigate the correct way for your webview_flutter version.
    // #enddocregion platform_features

    // Initial load
    final uri = Uri.parse(url);
    await newController.loadRequest(uri);

    controller = newController;
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }
    return newController;
  }

  // Expose the completer future
  Future<WebViewController> get controllerFuture => _controllerCompleter.future;

  // Dispose controller (when closing the web view)
  void disposeController() {
    // While WebViewWidget disposes its internal controller, clearing our reference is good practice.
    // If explicit disposal logic is needed, it depends on the exact webview_flutter version
    // and how it manages platform resources. The simplest is to nullify the reference.
    controller = null;
    // Reset completer if needed, but usually disposing means it's done.
    // If you were to re-open, you'd create a new _OpenWebApp instance.
  }
}

class WebAppsPage extends StatefulWidget {
  final String? companyId;
  final int? currentPlanType;
  final bool isSubscriptionEffectivelyActive;
  final String Function(String key, [Map<String, dynamic>? params]) translate;
  final Map<String, Map<String, String>> localizedStrings;
  final List<Map<String, dynamic>> subscriptionPlans;
  final Function(String message, {bool isWarning}) showErrorSnackbar;
  final Logger logger;
  final VoidCallback fetchAdminData; // Callback to trigger refresh on AdminPage

  const WebAppsPage({
    Key? key,
    required this.companyId, // FIX: Made required parameter
    required this.currentPlanType,
    required this.isSubscriptionEffectivelyActive,
    required this.translate,
    required this.localizedStrings,
    required this.subscriptionPlans,
    required this.showErrorSnackbar,
    required this.logger, // FIX: Made required parameter
    required this.fetchAdminData, // Require the callback
  }) : super(key: key);

  @override
  _WebAppsPageState createState() => _WebAppsPageState();
}

class _WebAppsPageState extends State<WebAppsPage> {
  List<Map<String, dynamic>> _webApps = [];
  bool _isLoading = true;

  // List to manage opened/minimized web views
  final List<_OpenWebApp> _openWebApps = [];
  // OverlayEntry to display the minimized apps bar
  OverlayEntry? _minimizedAppsOverlayEntry;

  // Controllers for adding/editing dialog
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Only fetch if companyId is available on initialization
    if (widget.companyId != null) {
      _fetchWebApps();
    } else {
      // FIX: Update local loading state
      if (mounted) setState(() => _isLoading = false);
    }

    // Potential improvement: Add listeners for changes in companyId or subscription state
    // if they can change while this page is active. For now, rely on the parent's fetchAdminData
    // and re-fetching web apps when the tab is revisited or refresh is pulled.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _urlController.dispose();
    _hideMinimizedAppsOverlay(); // Ensure overlay is removed
    // Dispose controllers of any remaining open web views if necessary
    for (var app in _openWebApps) {
      app.disposeController(); // Clean up controller reference
    }
    super.dispose();
  }

  String _translate(String key, [Map<String, dynamic>? params]) {
    return widget.translate(key, params);
  }

  Future<void> _fetchWebApps() async {
    if (widget.companyId == null) {
      widget.logger.w("Cannot fetch web apps: companyId is null.");
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('company_web_apps')
          .select('*')
          .eq('company_id', widget.companyId!)
          .order('created_at', ascending: true);

      // Check for PostgrestException indicating no rows, not a true error
      // Supabase client might return null or an empty list directly on no rows now.
      // Handle both possibilities.
      if (response == null || (response is List && response.isEmpty)) {
        widget.logger.i('No web apps found for company ${widget.companyId}');
        if (mounted) {
          setState(() {
            _webApps = [];
          });
        }
      } else if (response is List) {
        // Ensure response is a list
        if (mounted) {
          setState(() {
            _webApps = List<Map<String, dynamic>>.from(response);
          });
        }
      } else {
        // Handle other unexpected response types
        widget.logger
            .w('Unexpected response format fetching web apps: $response');
        if (mounted) {
          setState(() {
            _webApps = [];
          });
        }
      }
    } catch (e, stackTrace) {
      // FIX: Use stackTrace parameter name
      widget.logger
          .e('Error fetching web apps', error: e, stackTrace: stackTrace);
      if (mounted) {
        widget.showErrorSnackbar(
            _translate('error_fetching_web_apps', {'error': e.toString()}));
        setState(() {
          _webApps = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _hasBigPlan() {
    // Check if the current plan type is Big Plan (type 3) AND subscription is effectively active
    try {
      // Find the Big Plan type value from the list
      final bigPlan = widget.subscriptionPlans.firstWhere(
          (p) => p['name_en'] == 'Big Plan',
          orElse: () =>
              {'plan_type': null} // Handle case where Big Plan isn't found
          );
      final bigPlanType = bigPlan['plan_type'];

      if (bigPlanType == null) {
        widget.logger.w("Big Plan definition not found in subscriptionPlans.");
        return false; // Cannot determine Big Plan type, so assume no Big Plan access
      }

      return widget.isSubscriptionEffectivelyActive &&
          widget.currentPlanType == bigPlanType;
    } catch (e, stackTrace) {
      // FIX: Use stackTrace parameter name
      widget.logger
          .e("Error finding Big Plan type", error: e, stackTrace: stackTrace);
      return false; // Assume no Big Plan if lookup fails
    }
  }

  void _showAddWebAppDialog() {
    if (widget.companyId == null) {
      widget.showErrorSnackbar(
          "Cannot add web app: company ID is not available. Please refresh the Admin tab.",
          isWarning: true); // Localize this
      return;
    }

    _nameController.clear();
    _usernameController.clear();
    _urlController.clear();
    _formKey.currentState?.reset(); // Reset form state

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(_translate('add_web_app'),
              style: theme.textTheme.titleLarge),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              // Allow content to scroll if keyboard is tall
              child: ListBody(
                // Use ListBody or Column inside SingleChildScrollView
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _translate('web_app_name'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _translate('name_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: _translate('web_app_username'),
                      hintText: _translate(
                          'web_app_username'), // Use hint text for optional field
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: _translate('web_app_url'),
                      hintText: 'https://example.com',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _translate('url_required');
                      }
                      // FIX: Simpler and more robust URL validation
                      final uri = Uri.tryParse(value);
                      if (uri == null ||
                          !(uri.hasScheme &&
                              (uri.scheme == 'http' ||
                                  uri.scheme == 'https'))) {
                        return _translate('invalid_url');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(_translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(_translate('save')),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _addWebApp();
                  Navigator.of(context).pop(); // Close dialog
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addWebApp() async {
    if (widget.companyId == null) {
      widget.showErrorSnackbar("Cannot add web app: company ID not available.");
      return;
    }
    if (!mounted) return;
    // No need for setState((){ _isLoading = true; }) here as it's handled in a modal
    try {
      final data = {
        'company_id': widget.companyId!,
        'app_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(), // Optional field
        'app_url': _urlController.text.trim(),
      };
      widget.logger.i("Adding web app: $data");
      await Supabase.instance.client.from('company_web_apps').insert(data);

      if (mounted) {
        widget.showErrorSnackbar(_translate('web_app_added_success'),
            isWarning: false); // Use green for success
        _fetchWebApps(); // Refresh the list
        widget.fetchAdminData(); // Trigger refresh on AdminPage as well
      }
    } catch (e, stackTrace) {
      // FIX: Use stackTrace parameter name
      widget.logger.e('Error adding web app', error: e, stackTrace: stackTrace);
      if (mounted) {
        widget.showErrorSnackbar(
            _translate('error_adding_web_app', {'error': e.toString()}));
      }
    } finally {
      // No modal loading state to turn off here
    }
  }

  // Method to remove a web app (optional, but good practice)
  // Might require a confirmation dialog
  Future<void> _deleteWebApp(String appId) async {
    // Implement confirmation dialog first
    final bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Confirm Delete'), // Localize this
                  content: Text(
                      'Are you sure you want to delete this web app?'), // Localize this
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(_translate('cancel'))),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Delete',
                            style: TextStyle(
                                color: Colors
                                    .red))), // Localize "Delete", style red
                  ],
                )) ??
        false;

    if (!confirm) return;

    if (!mounted) return;
    // Optionally show a loading indicator
    widget.logger.i("Deleting web app: $appId");
    try {
      await Supabase.instance.client
          .from('company_web_apps')
          .delete()
          .eq('id', appId);
      widget.logger.i("Web app deleted: $appId");
      if (mounted) {
        widget.showErrorSnackbar("Web App deleted successfully.",
            isWarning: false); // Localize this
        _fetchWebApps(); // Refresh list
        // Also, check if the deleted app is currently open/minimized and close it
        _closeWebApp(
            appId); // Use the close logic (closes modal if open, removes from list)
      }
    } catch (e, stackTrace) {
      // FIX: Use stackTrace parameter name
      widget.logger
          .e('Error deleting web app $appId', error: e, stackTrace: stackTrace);
      if (mounted) {
        widget.showErrorSnackbar(
            "Error deleting Web App: ${e.toString()}"); // Localize this
      }
    }
  }

  // --- Web View Management ---

  void _openWebApp(String appId, String appName, String appUrl) async {
    if (!mounted) return;

    // Check if the app is already open/minimized
    final existingApp = _openWebApps.firstWhereOrNull((app) => app.id == appId);

    if (existingApp != null) {
      // If already open, just bring it to front if minimized
      if (existingApp.isMinimized) {
        widget.logger.i("Restoring minimized web app: $appName");
        setState(() {
          existingApp.isMinimized = false;
        });
        // Ensure overlay is visible
        _showMinimizedAppsOverlay();
        // Re-show the modal for this app
        _showWebAppModal(existingApp);
      } else {
        widget.logger.i("Web app is already open: $appName");
        // Optional: Show a message or just do nothing if already full screen
        // widget.showErrorSnackbar("App is already open.", isWarning: true);
        // If the modal is already open but somehow not full screen (unlikely with current logic),
        // you might need more complex state management to bring it to front or ensure it's fullscreen.
      }
      return; // Don't open a new instance
    }

    // Create a new _OpenWebApp instance
    final newOpenApp = _OpenWebApp(id: appId, name: appName, url: appUrl);

    // Add the new app to the list of open apps
    setState(() {
      _openWebApps.add(newOpenApp);
    });

    // Show the modal for the new app
    _showWebAppModal(newOpenApp);

    // Ensure minimized apps overlay is shown if needed
    if (_openWebApps.isNotEmpty) {
      _showMinimizedAppsOverlay();
    }
  }

  void _showWebAppModal(_OpenWebApp openApp) {
    // Using the UniqueKey as a flag to prevent showing the same modal instance multiple times
    // if called rapidly. This is a simple workaround. A more robust solution would
    // involve tracking which app ID currently has a modal open.
    bool isModalAlreadyOpenForThisApp = false;
    // You'd need to store the currently shown modal's app ID/key somewhere to check this accurately.
    // For now, let's skip this check and rely on the framework's handling and the PopScope/dismissal logic.
    // If showModalBottomSheet is called twice for the same app, it will stack, which is usually undesirable.
    // A proper solution might involve a dedicated state variable like `String? _appIdInFullscreenModal;`

    widget.logger.i("Attempting to show modal for web app: ${openApp.name}");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Make it full height
      useRootNavigator: true, // Allows modal to go above BottomNavigationBar
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext modalContext) {
        // Use the UniqueKey to ensure Flutter rebuilds the WebViewWidget when the app object changes (e.g., minimized state)
        // but doesn't create a *new* WebView if the same app instance is just being restored.
        return KeyedSubtree(
          key: openApp.key, // Associate the subtree with the app's unique key
          child: GestureDetector(
            // Allows tapping outside to potentially dismiss (controlled by isDismissible)
            // If isDismissible is true (default), dragging/tapping outside will pop the modal.
            // We handle this in .whenComplete below.
            onTap: () {
              // Optional: Custom tap handling if default dismiss is off
            },
            child: DraggableScrollableSheet(
              initialChildSize: 1.0, // Start full screen
              minChildSize: 0.9, // Can drag down slightly, but mostly fixed
              maxChildSize: 1.0,
              expand: true,
              builder: (_, scrollController) {
                // Use FutureBuilder with the completer's future to wait for the controller
                return PopScope(
                  // Handle back button presses
                  canPop: false, // Prevent back button from closing directly
                  onPopInvoked: (didPop) {
                    if (didPop) return; // Let system handle if didPop is true
                    // Instead of popping, minimize
                    _minimizeWebApp(openApp.id,
                        modalContext); // Pass modal context to dismiss
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20.0)),
                    ),
                    child: Column(
                      children: [
                        // Custom Header with App Name and Actions
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                          child: Row(
                            children: [
                              Icon(Icons.web,
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  openApp.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Minimize Button
                              IconButton(
                                icon: Icon(Icons.minimize,
                                    color: Colors.grey[600]),
                                tooltip: _translate('minimize'),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () =>
                                    _minimizeWebApp(openApp.id, modalContext),
                              ),
                              // Close Button
                              IconButton(
                                icon:
                                    Icon(Icons.close, color: Colors.grey[600]),
                                tooltip: _translate('close'),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () => _closeWebApp(openApp.id,
                                    modalContext), // Pass modal context
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1), // Separator
                        Expanded(
                          // WebView content
                          child: FutureBuilder<WebViewController>(
                            future: openApp
                                .controllerFuture, // Use the app's completer future
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child:
                                        CircularProgressIndicator()); // Loading indicator
                              } else if (snapshot.hasError) {
                                widget.logger.e(
                                    "WebView FutureBuilder error for ${openApp.name}",
                                    error: snapshot.error);
                                // Close the app state and modal on critical load error
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _closeWebApp(openApp.id, modalContext);
                                });
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      "Error loading web app: ${snapshot.error}", // Localize this error message
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasData) {
                                // Use the controller from the snapshot
                                // Ensure the WebViewWidget also uses the app's unique key
                                return WebViewWidget(
                                    key: openApp.key,
                                    controller: snapshot.data!);
                              }
                              return SizedBox.shrink(); // Should not happen
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ).whenComplete(() {
      // This happens when the modal is dismissed by dragging down or tapping outside (if allowed)
      // We should mark the app as minimized when the modal is dismissed this way
      // Find the app in the list by ID and mark it as minimized if it's not already closed
      // Using addPostFrameCallback to avoid calling setState during build cycle if this is
      // triggered by a state change that caused the modal to dismiss.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final app =
            _openWebApps.firstWhereOrNull((app) => app.id == openApp.id);
        // Check if the app still exists in our list and wasn't already closed by the close button
        if (app != null && !app.isMinimized) {
          widget.logger.i(
              "Modal for ${app.name} dismissed externally, marking as minimized.");
          setState(() {
            app.isMinimized = true;
          });
          _showMinimizedAppsOverlay(); // Ensure overlay is visible
        }
      });
    });

    // Start loading the controller asynchronously right after showing the modal
    // This is crucial to start the webview creation and loading process.
    // Handle potential errors during controller creation.
    openApp.getOrCreateController(widget.logger).catchError((e) {
      widget.logger
          .e("Initial controller creation error for ${openApp.name}", error: e);
      // The FutureBuilder will catch this error too, leading to dismissal.
      // No extra action needed here usually, as the modal handles the error state.
    });
  }

  void _minimizeWebApp(String appId, BuildContext modalContext) {
    widget.logger.i("Minimizing web app: $appId");
    final app = _openWebApps.firstWhereOrNull((app) => app.id == appId);
    if (app != null && !app.isMinimized) {
      setState(() {
        app.isMinimized = true;
      });
      // Dismiss the full screen modal immediately
      // Check if the modal context is still valid before popping
      if (Navigator.of(modalContext).mounted) {
        Navigator.of(modalContext).pop();
      } else {
        widget.logger.w("Attempted to pop modal context that is not mounted.");
      }

      // Ensure the minimized apps bar is visible after state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMinimizedAppsOverlay();
      });
    } else if (app != null && app.isMinimized) {
      // Already minimized, just close the modal if it's somehow still open
      // Check if the modal context is still valid before popping
      if (Navigator.of(modalContext).mounted &&
          Navigator.of(modalContext).canPop()) {
        Navigator.of(modalContext).pop();
      }
    }
  }

  void _closeWebApp(String appId, [BuildContext? modalContext]) {
    widget.logger.i("Closing web app: $appId");
    final appIndex = _openWebApps.indexWhere((app) => app.id == appId);
    if (appIndex != -1) {
      final app = _openWebApps[appIndex];
      app.disposeController(); // Clean up controller reference
      setState(() {
        _openWebApps.removeAt(appIndex);
      });
      // If the modal context was provided, close the modal first
      // Check if the modal context is still valid before popping
      if (modalContext != null &&
          Navigator.of(modalContext).mounted &&
          Navigator.of(modalContext).canPop()) {
        Navigator.of(modalContext).pop();
      }
      // Hide overlay if no apps are open AFTER state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hideMinimizedAppsOverlayIfNeeded();
      });
    }
  }

  void _showMinimizedAppsOverlay() {
    // Only show overlay if there are actually minimized apps
    final minimizedApps = _openWebApps.where((app) => app.isMinimized).toList();
    if (minimizedApps.isEmpty) {
      _hideMinimizedAppsOverlay(); // Hide if called but no minimized apps
      return;
    }

    if (_minimizedAppsOverlayEntry != null) {
      // Overlay is already shown or being shown, just update its state if needed
      // We don't need to re-insert, the builder handles rendering the list
      // of minimized apps based on the _openWebApps list.
      // You could trigger a setState on the overlay entry itself if its content
      // needed explicit updating, but the current builder relies on the main
      // widget tree's state which should rebuild when _openWebApps changes.
      widget.logger.i("Minimized apps overlay already exists.");
      return;
    }

    widget.logger.i("Creating and showing minimized apps overlay.");

    // Use a Builder here to get a context within the overlay that can be used
    // for things like showing dialogs or navigating, independent of the page below.
    _minimizedAppsOverlayEntry = OverlayEntry(
      builder: (context) => Builder(
        builder: (innerContext) {
          // Use innerContext for things needing a separate tree context
          return Positioned(
            bottom: 0, // Position at the bottom
            left: 0,
            right: 0,
            child: _buildMinimizedAppsBar(), // Your widget for the bar
          );
        },
      ),
    );

    // Insert the overlay entry into the overlay
    // Check if context is still valid before inserting
    if (mounted) {
      Overlay.of(context).insert(_minimizedAppsOverlayEntry!);
    } else {
      widget.logger
          .w("Attempted to insert overlay when widget is not mounted.");
      _minimizedAppsOverlayEntry = null; // Clear the entry if not mounted
    }
  }

  void _hideMinimizedAppsOverlay() {
    if (_minimizedAppsOverlayEntry != null) {
      widget.logger.i("Hiding minimized apps overlay.");
      _minimizedAppsOverlayEntry?.remove();
      _minimizedAppsOverlayEntry = null;
    }
  }

  void _hideMinimizedAppsOverlayIfNeeded() {
    // Hide the overlay only if NO apps are currently open (neither full screen nor minimized)
    // The list _openWebApps contains all apps, regardless of minimized state.
    // So if the list is empty, no apps are open.
    if (_openWebApps.isEmpty) {
      _hideMinimizedAppsOverlay();
    }
  }

  Widget _buildMinimizedAppsBar() {
    // Filter for apps that are currently minimized
    final minimizedApps = _openWebApps.where((app) => app.isMinimized).toList();

    if (minimizedApps.isEmpty) {
      // This check is also done before calling _buildMinimizedAppsBar,
      // but having it here provides a final safety net.
      _hideMinimizedAppsOverlay();
      return SizedBox.shrink();
    }

    // Using a Card or Container for the bar itself
    return Card(
      margin: EdgeInsets.zero, // Stick to edges
      elevation: 8.0, // Give it some shadow
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(12))), // Rounded top corners
      child: SafeArea(
        // Avoid system overlays like navigation bar
        top: false, // Don't add padding at the top
        bottom: true, // Add padding at the bottom if system nav bar is present
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Allow horizontal scrolling
            // Primary is false to prevent conflicts if this is nested in another scroll view
            primary: false,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Align items to the start
              crossAxisAlignment: CrossAxisAlignment.center,
              children: minimizedApps.map((app) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    // Make the icon/card tappable
                    onTap: () {
                      // When tapped, restore the app
                      _openWebApp(app.id, app.name, app.url);
                    },
                    // You can use an icon or a small card here
                    child: Container(
                      // Use a Container for better control over size/decoration
                      width: 80, // Fixed width for each item
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      decoration: BoxDecoration(
                        // Optional: Add a border or background on tap/hover
                        borderRadius: BorderRadius.circular(8.0),
                        // color: Colors.grey[200]?.withOpacity(0.5), // Example hover color
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.web_asset,
                              size: 30,
                              color: Theme.of(context)
                                  .primaryColor), // App icon placeholder
                          const SizedBox(height: 4),
                          Text(
                            app.name,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow
                                .ellipsis, // Ellipsis if name is too long
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1, // Ensure text is only one line
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canAddWebApp =
        _hasBigPlan(); // Check if user has active Big Plan

    // FIX: Check local _isLoading for this page
    if (widget.companyId == null && !_isLoading) {
      // Handle case where company ID is missing in the Admin tab
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_outlined, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _translate('company_id_not_found'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget
                    .fetchAdminData, // FIX: Call the passed callback to refresh AdminPage data
                icon: Icon(Icons.refresh),
                label: Text(_translate('refresh')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // AppBar is handled by the parent AdminPage scaffold
      // body: ...
      body: Stack(
        // Use a Stack to potentially layer content or handle overlay positioning
        children: [
          RefreshIndicator(
            onRefresh: _fetchWebApps,
            color: theme.primaryColor,
            child: _isLoading // FIX: Check local _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _webApps.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.web_asset_off_outlined,
                                  size: 60, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _translate('no_web_apps'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              if (!canAddWebApp) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _translate('add_button_disabled'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.orange.shade800),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _webApps.length,
                        itemBuilder: (context, index) {
                          final app = _webApps[index];
                          final String appName =
                              app['app_name'] ?? 'Unnamed App';
                          final String appUsername = app['username'] ?? '';
                          final String appUrl = app['app_url'] ?? '';
                          final String appId = app['id'];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            elevation: 1.0,
                            child: ListTile(
                              leading: Icon(Icons.web_asset,
                                  color: theme.primaryColor),
                              title: Text(appName,
                                  style: theme.textTheme.titleMedium),
                              subtitle: appUsername.isNotEmpty
                                  ? Text(
                                      '${_translate('web_app_username')}: $appUsername\nURL: $appUrl',
                                      style: theme.textTheme.bodySmall)
                                  : Text('URL: $appUrl',
                                      style: theme.textTheme.bodySmall),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.open_in_new,
                                        color: Colors.blue.shade700),
                                    tooltip: _translate('open_app'),
                                    onPressed: () {
                                      _openWebApp(appId, appName, appUrl);
                                    },
                                  ),
                                  // Optional: Add delete button (only for Big Plan?)
                                  if (canAddWebApp) // Assuming delete is also a Big Plan feature
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: Colors.red.shade700),
                                      tooltip:
                                          'Delete Web App', // Localize this
                                      onPressed: () => _deleteWebApp(appId),
                                    ),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              onTap: () {
                                // Tapping the list tile also opens the app
                                _openWebApp(appId, appName, appUrl);
                              },
                            ),
                          );
                        },
                      ),
          ),
          // The minimized apps bar will be placed in the Overlay, not in the Stack of the page body.
        ],
      ),
      floatingActionButton: canAddWebApp && widget.companyId != null
          ? FloatingActionButton.extended(
              onPressed: _showAddWebAppDialog,
              label: Text(_translate('add_web_app')),
              icon: const Icon(Icons.add),
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
            )
          : null, // Hide FAB if not Big Plan or companyId is null
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Extension to easily find an item in a list
extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
