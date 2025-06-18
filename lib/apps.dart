// --- apps.dart ---
// MODERN & MODULARIZED: Custom widgets in design_apps/
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as platform_io;
import 'dart:typed_data';
import 'webview_page.dart';

// DESIGN COMPONENTS (these files must exist in lib/design_apps/)
import 'design_apps/app_search_bar.dart';
import 'design_apps/app_logo.dart';
import 'design_apps/app_type_chip.dart';
import 'design_apps/app_card.dart';

class AppsPage extends StatefulWidget {
  const AppsPage({Key? key}) : super(key: key);

  @override
  _AppsPageState createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  final _logger = Logger();
  List<Map<String, dynamic>> _allApps = [];
  List<Map<String, dynamic>> _recentApps = [];
  List<Map<String, dynamic>> _popularApps = [];
  List<Map<String, dynamic>> _searchResults = [];

  bool _isLoading = true;
  String? _fetchError;
  String _currentLanguage = 'uz';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final _createAppFormKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _appUrlController = TextEditingController();
  final _appUsernameController = TextEditingController();
  String _selectedAppType = 'public';
  platform_io.File? _pickedLogoNativeFile;
  Uint8List? _pickedLogoWebBytes;
  String? _pickedLogoFileName;
  bool _isCreatingApp = false;

  final Map<String, Map<String, String>> _embeddedLocalizedStrings = {
    // ... (copy your full localization map here as in your previous code)
  };

  String _translate(String key, [Map<String, dynamic>? params]) {
    final langKey =
        ['en', 'uz', 'ru'].contains(_currentLanguage) ? _currentLanguage : 'uz';
    String? translatedValue = _embeddedLocalizedStrings[langKey]?[key] ??
        _embeddedLocalizedStrings['uz']?[key];
    translatedValue ??= key;
    if (params != null) {
      params.forEach((pKey, value) {
        translatedValue =
            translatedValue!.replaceAll('{$pKey}', value.toString());
      });
    }
    return translatedValue!;
  }

  @override
  void initState() {
    super.initState();
    _initializeAppsPage();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeAppsPage() async {
    await _loadLanguagePreference();
    await _loadCachedAppsData();
    _fetchAppsData();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _currentLanguage = prefs.getString('language') ?? 'uz';
        });
      }
    } catch (e) {
      _logger.e("Error loading language preference in AppsPage: $e");
    }
  }

  Future<void> _loadCachedAppsData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? allAppsJson = prefs.getString('cachedAllApps');
      String? recentAppsJson = prefs.getString('cachedRecentAppsList');
      String? popularAppsJson = prefs.getString('cachedPopularApps');

      if (allAppsJson != null)
        _allApps = List<Map<String, dynamic>>.from(jsonDecode(allAppsJson));
      if (recentAppsJson != null)
        _recentApps =
            List<Map<String, dynamic>>.from(jsonDecode(recentAppsJson));
      if (popularAppsJson != null)
        _popularApps =
            List<Map<String, dynamic>>.from(jsonDecode(popularAppsJson));

      if (mounted) {
        setState(() {
          _isLoading = _allApps.isEmpty && _recentApps.isEmpty;
        });
      }
    } catch (e) {
      _logger.e("Error loading cached apps data: $e");
      if (mounted) setState(() => _isLoading = true);
    }
  }

  Future<void> _saveAppsDataToCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cachedAllApps', jsonEncode(_allApps));
      await prefs.setString('cachedRecentAppsList', jsonEncode(_recentApps));
      await prefs.setString('cachedPopularApps', jsonEncode(_popularApps));
    } catch (e) {
      _logger.e("Error saving apps data to cache: $e");
    }
  }

  Future<void> _fetchAppsData() async {
    if (!mounted) return;
    if (_allApps.isEmpty && _recentApps.isEmpty) {
      setState(() {
        _isLoading = true;
        _fetchError = null;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('apps')
          .select(
              'id, name, url, logo_url, username, type, created_by_company_id, companies!apps_created_by_company_id_fkey(company_name), view_count, created_at')
          .order('view_count', ascending: false);

      if (response.isEmpty) {
        if (mounted) {
          setState(() {
            _allApps = [];
            _popularApps = [];
            _isLoading = false;
            _fetchError = _allApps.isEmpty && _recentApps.isEmpty
                ? _translate('no_apps_found')
                : null;
          });
        }
      } else {
        final fetchedApps = List<Map<String, dynamic>>.from(response);
        if (mounted) {
          setState(() {
            _allApps = fetchedApps;
            _popularApps = fetchedApps.take(5).toList();
            _isLoading = false;
            _fetchError = null;
          });
        }
      }
      await _loadRecentAppsFromHistory();
      await _saveAppsDataToCache();
    } catch (e, stackTrace) {
      _logger.e('AppsPage: Error fetching apps data',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_allApps.isEmpty && _recentApps.isEmpty) {
            _fetchError =
                _translate('error_fetching_apps', {'error': e.toString()});
          } else {
            _fetchError = _translate('no_internet');
          }
        });
      }
    }
  }

  Future<void> _loadRecentAppsFromHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? recentAppIds = prefs.getStringList('recentAppIdsList');

    if (recentAppIds != null && recentAppIds.isNotEmpty) {
      List<Map<String, dynamic>> newRecentApps = [];
      for (String appId in recentAppIds.reversed) {
        final foundApp =
            _allApps.firstWhere((app) => app['id'] == appId, orElse: () => {});
        if (foundApp.isNotEmpty &&
            !newRecentApps.any((a) => a['id'] == appId)) {
          newRecentApps.add(foundApp);
          if (newRecentApps.length >= 10) break;
        }
      }
      if (mounted) {
        setState(() {
          _recentApps = newRecentApps;
        });
      }
    }
  }

  Future<void> _addAppToRecents(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentAppIds = prefs.getStringList('recentAppIdsList') ?? [];
    recentAppIds.remove(appId);
    recentAppIds.add(appId);
    if (recentAppIds.length > 10) recentAppIds.removeAt(0);
    await prefs.setStringList('recentAppIdsList', recentAppIds);
    await _loadRecentAppsFromHistory();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        if (_searchQuery.isNotEmpty) {
          _searchResults = _allApps.where((app) {
            final String appName = (app['name'] as String? ?? '').toLowerCase();
            final String appUsernameWithAt =
                (app['username'] as String? ?? '').toLowerCase();
            final String appUsernameWithoutAt =
                appUsernameWithAt.startsWith('@')
                    ? appUsernameWithAt.substring(1)
                    : appUsernameWithAt;

            bool queryIsUsername = _searchQuery.startsWith('@');
            String pureQuery =
                queryIsUsername ? _searchQuery.substring(1) : _searchQuery;

            return appName.contains(_searchQuery) ||
                appUsernameWithoutAt.contains(pureQuery);
          }).toList();
        } else {
          _searchResults = [];
        }
      });
    }
  }

  Future<void> _openAppInWebview(Map<String, dynamic> app) async {
    final appUrl = app['url'] as String? ?? '';
    final appName = app['name'] as String? ?? 'Unnamed App';
    final appId = app['id'] as String?;

    if (appUrl.isEmpty ||
        (!appUrl.startsWith('http://') && !appUrl.startsWith('https://'))) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid URL for app: $appName')));
      return;
    }

    if (appId != null) {
      await _addAppToRecents(appId);
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('app_views')
              .insert({'app_id': appId, 'user_id': user.id});
        }
      } catch (e) {
        _logger.e("Error tracking app view: $e");
      }
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InAppWebViewPage(
            url: appUrl,
            title: appName,
            currentLanguage: _currentLanguage,
          ),
        ),
      ).then((_) {
        _fetchAppsData();
      });
    }
  }

  void _showCreateAppModal() {
    // ... Your full modal logic here from your original code ...
    // See your previous _showCreateAppModal implementation.
    // Nothing else to change here, just keep your logic unchanged.
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _appNameController.dispose();
    _appUrlController.dispose();
    _appUsernameController.dispose();
    super.dispose();
  }

  Widget _buildRecentAppsList() {
    if (_recentApps.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(_translate('recent_apps_title'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
        ),
        Container(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: _recentApps.length,
            itemBuilder: (context, index) {
              final app = _recentApps[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: AppCard(
                  app: app,
                  onTap: () => _openAppInWebview(app),
                  publicLabel: _translate('public_type'),
                  privateLabel: _translate('private_type'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Map<String, dynamic>> appsToDisplay;

    if (_searchQuery.isNotEmpty) {
      appsToDisplay = _searchResults;
    } else if (_popularApps.isNotEmpty) {
      appsToDisplay = _popularApps;
    } else {
      appsToDisplay = _allApps;
    }

    bool showNoResultsMessage =
        _searchQuery.isNotEmpty && _searchResults.isEmpty;
    bool showNoAppsFoundOverall =
        _searchQuery.isEmpty && _allApps.isEmpty && _recentApps.isEmpty;

    return Scaffold(
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hint: _translate('search_placeholder'),
            onClear: () => _searchController.clear(),
          ),
          if (_searchQuery.isEmpty) _buildRecentAppsList(),
          if (_searchQuery.isEmpty && _popularApps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              child: Text(_translate('popular_apps_title'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
            ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primaryColor))
                : RefreshIndicator(
                    onRefresh: _fetchAppsData,
                    color: theme.primaryColor,
                    child: showNoResultsMessage
                        ? Center(
                            child: Text(
                                _translate('no_search_results',
                                    {'query': _searchQuery}),
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16)))
                        : showNoAppsFoundOverall && _fetchError == null
                            ? Center(
                                child: Text(_translate('no_apps_found'),
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 16)))
                            : _fetchError != null && appsToDisplay.isEmpty
                                ? Center(
                                    child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(_fetchError!,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 16))))
                                : ListView.builder(
                                    padding: const EdgeInsets.only(
                                        top: 0, bottom: 80.0),
                                    itemCount: appsToDisplay.length,
                                    itemBuilder: (context, index) {
                                      final app = appsToDisplay[index];
                                      return AppCard(
                                        app: app,
                                        onTap: () => _openAppInWebview(app),
                                        publicLabel: _translate('public_type'),
                                        privateLabel:
                                            _translate('private_type'),
                                      );
                                    },
                                  ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAppModal,
        label: Text(_translate('create_app_fab')),
        icon: Icon(Icons.add),
        backgroundColor: theme.primaryColor,
      ),
    );
  }
}
