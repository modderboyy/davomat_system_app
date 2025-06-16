// --- apps.dart ---
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as platform_io;
import 'dart:typed_data'; // Uint8List uchun import
import 'webview_page.dart';

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
    'en': {
      'apps_title': 'Apps',
      'error_fetching_apps': 'Error loading apps: {error}',
      'no_apps_found': 'No apps found.',
      'created_by': 'By: {user_or_company}',
      'open_app': 'Open App',
      'no_internet': 'No internet. Cached data might be shown.',
      'search_placeholder': 'Search by name or @username',
      'recent_apps_title': 'Recently Opened',
      'popular_apps_title': 'Popular Apps',
      'no_search_results': 'No apps found matching "{query}"',
      'loading_apps': 'Loading apps...',
      'app_name_or_username_required':
          'App name or @username is required for search.',
      'create_app_fab': 'Create App',
      'create_new_app_title': 'Create New App',
      'app_name_label': 'App Name',
      'app_url_label': 'App URL (e.g., https://example.com)',
      'app_username_label':
          'App Username (e.g., mycoolapp, no @ needed here)', // @ olib tashlandi
      'app_type_label': 'App Type',
      'public_type': 'Public (Visible to all)',
      'private_type':
          'Private (Visible to your company only)', // Aniqlashtirildi
      'upload_logo_button': 'Upload Logo',
      'logo_uploaded_success': 'Logo: {filename}',
      'create_button': 'Create',
      'creating_app': 'Creating app...',
      'app_created_successfully': 'App created successfully!',
      'error_creating_app': 'Error creating app: {error}',
      'username_already_taken':
          'This username is already taken. Please choose another.',
      'field_required': 'This field is required.',
      'invalid_url':
          'Please enter a valid URL (starting with http:// or https://).',
      'invalid_username_format':
          'Username must contain only letters, numbers, or underscores (no @ at start).', // O'zgartirildi
      'uploading_logo': 'Uploading logo...',
      'error_uploading_logo': 'Error uploading logo: {error}',
      'logo_upload_failed_continue':
          'Logo upload failed. Continue without logo?',
      'yes': 'Yes',
      'no': 'No',
      'company_id_not_found_for_app':
          'Could not determine your company to create a private app. Please ensure you are part of a company.',
    },
    'uz': {
      'apps_title': 'Ilovalar',
      'error_fetching_apps': 'Ilovalarni yuklashda xatolik: {error}',
      'no_apps_found': 'Ilovalar topilmadi.',
      'created_by': 'Muallif: {user_or_company}',
      'open_app': 'Ilovani ochish',
      'no_internet':
          'Internet yo\'q. Keshdagi ma\'lumotlar ko\'rsatilishi mumkin.',
      'search_placeholder': 'Nomi yoki @username orqali qidirish',
      'recent_apps_title': 'Yaqinda Ochilganlar',
      'popular_apps_title': 'Ommabop Ilovalar',
      'no_search_results': '"{query}" bo\'yicha ilova topilmadi',
      'loading_apps': 'Ilovalar yuklanmoqda...',
      'app_name_or_username_required':
          'Qidirish uchun ilova nomi yoki @username kerak.',
      'create_app_fab': 'Ilova Yaratish',
      'create_new_app_title': 'Yangi Ilova Yaratish',
      'app_name_label': 'Ilova Nomi',
      'app_url_label': 'Ilova URL manzili (masalan, https://example.com)',
      'app_username_label':
          'Ilova Username (masalan, meningilovam, boshida @ shart emas)',
      'app_type_label': 'Ilova Turi',
      'public_type': 'Ommaviy (Hamma uchun ko\'rinadigan)',
      'private_type':
          'Shaxsiy (Faqat sizning kompaniyangiz uchun ko\'rinadigan)',
      'upload_logo_button': 'Logo Yuklash',
      'logo_uploaded_success': 'Logo: {filename}',
      'create_button': 'Yaratish',
      'creating_app': 'Ilova yaratilmoqda...',
      'app_created_successfully': 'Ilova muvaffaqiyatli yaratildi!',
      'error_creating_app': 'Ilova yaratishda xatolik: {error}',
      'username_already_taken': 'Bu username band. Boshqasini tanlang.',
      'field_required': 'Bu maydon to\'ldirilishi shart.',
      'invalid_url':
          'Yaroqli URL manzilini kiriting (http:// yoki https:// bilan boshlanadigan).',
      'invalid_username_format':
          'Username faqat harflar, raqamlar yoki pastki chiziqni o\'z ichiga olishi kerak (@ belgisisiz).',
      'uploading_logo': 'Logo yuklanmoqda...',
      'error_uploading_logo': 'Logoni yuklashda xatolik: {error}',
      'logo_upload_failed_continue':
          'Logo yuklashda xatolik. Logosiz davom etasizmi?',
      'yes': 'Ha',
      'no': 'Yo\'q',
      'company_id_not_found_for_app':
          'Shaxsiy ilova yaratish uchun kompaniyangiz aniqlanmadi. Kompaniyaga a\'zo ekanligingizni tekshiring.',
    },
    'ru': {
      'apps_title': 'Приложения',
      'error_fetching_apps': 'Ошибка загрузки приложений: {error}',
      'no_apps_found': 'Приложений не найдено.',
      'created_by': 'Автор: {user_or_company}',
      'open_app': 'Открыть приложение',
      'no_internet': 'Нет интернета. Могут отображаться кэшированные данные.',
      'search_placeholder': 'Поиск по названию или @username',
      'recent_apps_title': 'Недавно открытые',
      'popular_apps_title': 'Популярные приложения',
      'no_search_results': 'Приложений по запросу "{query}" не найдено',
      'loading_apps': 'Загрузка приложений...',
      'app_name_or_username_required':
          'Для поиска требуется название приложения или @username.',
      'create_app_fab': 'Создать Приложение',
      'create_new_app_title': 'Создать Новое Приложение',
      'app_name_label': 'Название приложения',
      'app_url_label': 'URL приложения (например, https://example.com)',
      'app_username_label':
          'Имя пользователя приложения (например, moeprilojenie, @ в начале не нужен)',
      'app_type_label': 'Тип приложения',
      'public_type': 'Публичное (видно всем)',
      'private_type': 'Частное (видно только вашей компании)',
      'upload_logo_button': 'Загрузить логотип',
      'logo_uploaded_success': 'Логотип: {filename}',
      'create_button': 'Создать',
      'creating_app': 'Создание приложения...',
      'app_created_successfully': 'Приложение успешно создано!',
      'error_creating_app': 'Ошибка создания приложения: {error}',
      'username_already_taken':
          'Это имя пользователя уже занято. Пожалуйста, выберите другое.',
      'field_required': 'Это поле обязательно для заполнения.',
      'invalid_url':
          'Введите действительный URL (начинающийся с http:// или https://).',
      'invalid_username_format':
          'Имя пользователя должно содержать только буквы, цифры или подчеркивания (без @ в начале).',
      'uploading_logo': 'Загрузка логотипа...',
      'error_uploading_logo': 'Ошибка загрузки логотипа: {error}',
      'logo_upload_failed_continue':
          'Ошибка загрузки логотипа. Продолжить без логотипа?',
      'yes': 'Да',
      'no': 'Нет',
      'company_id_not_found_for_app':
          'Не удалось определить вашу компанию для создания частного приложения. Убедитесь, что вы являетесь частью компании.',
    },
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
              'id, name, url, logo_url, username, created_by_company_id, companies!apps_created_by_company_id_fkey(company_name), view_count, created_at')
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
            if (e is PostgrestException && e.code == 'PGRST201') {
              // Aloqa muammosi
              _fetchError =
                  "Supabase query error: Could not determine relationship for 'companies'. Please check foreign key names or use explicit join hints in your Supabase Studio SQL editor for RLS policies or views if you are using them.";
            } else {
              _fetchError =
                  _translate('error_fetching_apps', {'error': e.toString()});
            }
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
            final String appUsernameWithAt = (app['username'] as String? ?? '')
                .toLowerCase(); // bazada @ bilan saqlanadi
            final String appUsernameWithoutAt =
                appUsernameWithAt.startsWith('@')
                    ? appUsernameWithAt.substring(1)
                    : appUsernameWithAt;

            bool queryIsUsername = _searchQuery.startsWith('@');
            String pureQuery =
                queryIsUsername ? _searchQuery.substring(1) : _searchQuery;

            return appName.contains(
                    _searchQuery) || // To'liq so'rov bo'yicha nomni tekshirish
                appUsernameWithoutAt
                    .contains(pureQuery); // @ siz username ni tekshirish
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

  Future<void> _pickLogo(StateSetter setModalState) async {
    // setModalState qabul qiladi
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );
      if (result != null) {
        setModalState(() {
          // Modalning state'ini yangilash
          if (kIsWeb) {
            _pickedLogoWebBytes = result.files.single.bytes;
            _pickedLogoNativeFile = null;
          } else {
            _pickedLogoNativeFile = platform_io.File(result.files.single.path!);
            _pickedLogoWebBytes = null;
          }
          _pickedLogoFileName = result.files.single.name;
        });
      }
    } catch (e) {
      _logger.e("Error picking logo: $e");
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error picking logo: $e")));
    }
  }

  Future<String?> _uploadLogoToSupabase(String companyIdForPath,
      String appNameForPath, StateSetter setModalState) async {
    if (_pickedLogoFileName == null ||
        (_pickedLogoNativeFile == null && _pickedLogoWebBytes == null)) {
      return null;
    }

    final fileExt = _pickedLogoFileName!.split('.').last.toLowerCase();
    // Fayl nomini xavfsiz qilish
    final safeAppName =
        appNameForPath.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final fileName =
        'app_logos/${companyIdForPath}/${safeAppName}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      setModalState(
          () => _isCreatingApp = true); // Yuklash jarayonini modalda ko'rsatish

      if (kIsWeb) {
        if (_pickedLogoWebBytes == null)
          throw Exception("Web logo bytes are null");
        await Supabase.instance.client.storage.from('appslogo').uploadBinary(
            fileName, _pickedLogoWebBytes!,
            fileOptions:
                FileOptions(contentType: 'image/$fileExt', upsert: false));
      } else {
        if (_pickedLogoNativeFile == null)
          throw Exception("Native logo file is null");
        await Supabase.instance.client.storage.from('appslogo').upload(
            fileName, _pickedLogoNativeFile!,
            fileOptions:
                FileOptions(contentType: 'image/$fileExt', upsert: false));
      }
      return Supabase.instance.client.storage
          .from('appslogo')
          .getPublicUrl(fileName);
    } catch (e) {
      _logger.e("Error uploading logo to Supabase: $e");
      if (mounted) {
        bool continueWithoutLogo = await showDialog<bool>(
              context: context, // Asosiy context
              builder: (BuildContext dialogContext) => AlertDialog(
                title: Text(_translate(
                    'error_uploading_logo', {'error': e.toString()})),
                content: Text(_translate('logo_upload_failed_continue')),
                actions: <Widget>[
                  TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(_translate('no'))),
                  TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(_translate('yes'))),
                ],
              ),
            ) ??
            false;
        return continueWithoutLogo ? "" : null;
      }
      return null;
    } finally {
      setModalState(
          () => _isCreatingApp = false); // Modal yuklanishini to'xtatish
    }
  }

  Future<void> _createNewApp(
      BuildContext modalContext, StateSetter setModalState) async {
    // Context va StateSetter qabul qiladi
    if (!_createAppFormKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("User not logged in!")));
      return;
    }

    String? userCompanyId;
    try {
      final companyData = await Supabase.instance.client
          .from('users')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();
      userCompanyId = companyData?['company_id'] as String?;
    } catch (e) {
      _logger.e("Error fetching user's company ID: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching company details.")));
      return;
    }

    if (_selectedAppType == 'private' && userCompanyId == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_translate('company_id_not_found_for_app'))));
      return;
    }

    setModalState(() => _isCreatingApp = true);

    String? logoUrl;
    if (_pickedLogoFileName != null) {
      // companyIdForPath uchun userCompanyId ni ishlatamiz, agar private bo'lsa, aks holda user.id (yoki boshqa bir global identifikator)
      String pathIdForLogo =
          (_selectedAppType == 'private' && userCompanyId != null)
              ? userCompanyId
              : user.id;
      logoUrl = await _uploadLogoToSupabase(
          pathIdForLogo, _appNameController.text.trim(), setModalState);
      if (logoUrl == null && _pickedLogoFileName != null) {
        setModalState(() => _isCreatingApp = false);
        return;
      }
    }

    try {
      final appName = _appNameController.text.trim();
      final appUrl = _appUrlController.text.trim();
      // Username @ bilan saqlanadi bazada
      final appUsername = _appUsernameController.text.trim().startsWith('@')
          ? _appUsernameController.text.trim()
          : '@${_appUsernameController.text.trim()}';

      final existingApp = await Supabase.instance.client
          .from('apps')
          .select('id')
          .eq('username', appUsername)
          .maybeSingle();
      if (existingApp != null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_translate('username_already_taken'))));
        setModalState(() => _isCreatingApp = false);
        return;
      }

      await Supabase.instance.client.from('apps').insert({
        'name': appName,
        'url': appUrl,
        'username': appUsername, // @ bilan saqlanadi
        'type': _selectedAppType,
        'logo_url': logoUrl == "" ? null : logoUrl,
        'created_by_company_id':
            _selectedAppType == 'private' ? userCompanyId : null,
        'created_by_user_id': user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_translate('app_created_successfully')),
            backgroundColor: Colors.green));
        Navigator.of(modalContext).pop(); // Modalni yopish
        _fetchAppsData();
        _appNameController.clear();
        _appUrlController.clear();
        _appUsernameController.clear();
        // setState bu yerda kerak emas, chunki modal yopiladi va uning state'i yo'qoladi
        // Lekin _pickedLogo larni tozalash yaxshi
        _pickedLogoFileName = null;
        _pickedLogoNativeFile = null;
        _pickedLogoWebBytes = null;
        _selectedAppType = 'public';
      }
    } catch (e) {
      _logger.e("Error creating app: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(_translate('error_creating_app', {'error': e.toString()})),
            backgroundColor: Colors.red));
    } finally {
      setModalState(() => _isCreatingApp = false);
    }
  }

  void _showCreateAppModal() {
    _appNameController.clear();
    _appUrlController.clear();
    _appUsernameController.clear();
    _pickedLogoFileName = null;
    _pickedLogoNativeFile = null;
    _pickedLogoWebBytes = null;
    _selectedAppType = 'public';

    showModalBottomSheet(
      context: context, // Asosiy context
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalSheetContext) {
        // Modal uchun alohida context
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          // Bu context modalniki
          final theme = Theme.of(context);
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                    color: theme.canvasColor,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 0),
                      child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10))),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_translate('create_new_app_title'),
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () =>
                                  Navigator.of(modalSheetContext).pop()),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _createAppFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _appNameController,
                                decoration: InputDecoration(
                                    labelText: _translate('app_name_label')),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? _translate('field_required')
                                        : null,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _appUrlController,
                                decoration: InputDecoration(
                                    labelText: _translate('app_url_label')),
                                keyboardType: TextInputType.url,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return _translate('field_required');
                                  if (!value.startsWith('http://') &&
                                      !value.startsWith('https://'))
                                    return _translate('invalid_url');
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _appUsernameController,
                                decoration: InputDecoration(
                                    labelText: _translate(
                                        'app_username_label')), // @ belgisi olib tashlandi
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return _translate('field_required');
                                  // @ belgisisiz tekshirish
                                  if (!RegExp(r'^[a-zA-Z0-9_]+$')
                                      .hasMatch(value))
                                    return _translate(
                                        'invalid_username_format');
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              Text(_translate('app_type_label'),
                                  style: theme.textTheme.titleSmall),
                              DropdownButtonFormField<String>(
                                value: _selectedAppType,
                                items: [
                                  DropdownMenuItem(
                                      value: 'public',
                                      child: Text(_translate('public_type'))),
                                  DropdownMenuItem(
                                      value: 'private',
                                      child: Text(_translate('private_type'))),
                                ],
                                onChanged: (value) {
                                  if (value != null)
                                    setModalState(
                                        () => _selectedAppType = value);
                                },
                                decoration: InputDecoration(
                                    border: OutlineInputBorder()),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await _pickLogo(
                                      setModalState); // setModalState uzatildi
                                },
                                icon: Icon(Icons.cloud_upload_outlined),
                                label: Text(_translate('upload_logo_button')),
                                style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 45)),
                              ),
                              if (_pickedLogoFileName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                      _translate('logo_uploaded_success',
                                          {'filename': _pickedLogoFileName!}),
                                      style: TextStyle(color: Colors.green)),
                                ),
                              SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isCreatingApp
                                    ? null
                                    : () => _createNewApp(modalSheetContext,
                                        setModalState), // modalSheetContext uzatildi
                                child: _isCreatingApp
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text(_translate('create_button')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, 50),
                                  textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
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

  Widget _buildAppIcon(Map<String, dynamic> app,
      {double size = 60.0, bool showName = true}) {
    final logoUrl = app['logo_url'] as String?;
    final appName = app['name'] as String? ?? 'App';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 5,
                    offset: Offset(0, 3))
              ]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: logoUrl != null && Uri.tryParse(logoUrl)?.hasScheme == true
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.public,
                          size: size * 0.6, color: Colors.grey[600]);
                    },
                  )
                : Icon(Icons.public, size: size * 0.6, color: Colors.grey[600]),
          ),
        ),
        if (showName) ...[
          SizedBox(height: 8),
          SizedBox(
            width: size + 20,
            child: Text(
              appName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500),
            ),
          ),
        ]
      ],
    );
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
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: _recentApps.length,
            itemBuilder: (context, index) {
              final app = _recentApps[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: () => _openAppInWebview(app),
                  borderRadius: BorderRadius.circular(16),
                  child: _buildAppIcon(app, size: 70, showName: true),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAppListItem(Map<String, dynamic> app) {
    final theme = Theme.of(context);
    final logoUrl = app['logo_url'] as String?;
    final appName = app['name'] as String? ?? 'Unnamed App';
    final appUsername = app['username'] as String?; // Bazadan @ bilan keladi
    final companyData = app['companies!apps_created_by_company_id_fkey'];
    String creatorIdentifier =
        _translate('public_type'); // Sukut bo'yicha public
    if (companyData != null &&
        companyData is Map &&
        companyData['company_name'] != null) {
      creatorIdentifier = companyData['company_name'] as String;
    } else if (app['type'] == 'private' &&
        app['created_by_company_id'] == null) {
      // Agar private bo'lsa lekin kompaniya nomi topilmasa (bu holat bo'lmasligi kerak)
      creatorIdentifier =
          _translate('private_type'); // Faqat 'Private' deb ko'rsatish
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        leading: SizedBox(
          width: 50,
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: logoUrl != null && Uri.tryParse(logoUrl)?.hasScheme == true
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.public_outlined,
                        color: Colors.grey[500],
                        size: 30),
                  )
                : Icon(Icons.public_outlined,
                    color: Colors.grey[500], size: 30),
          ),
        ),
        title: Text(appName,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (appUsername != null && appUsername.isNotEmpty)
              Text(appUsername,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor, fontWeight: FontWeight.w500)),
            if (creatorIdentifier.isNotEmpty) // "Public" yoki kompaniya nomi
              Text(
                  (app['type'] == 'private' && companyData != null)
                      ? _translate(
                          'created_by', {'user_or_company': creatorIdentifier})
                      : creatorIdentifier,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600])),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.grey[400], size: 18),
        onTap: () => _openAppInWebview(app),
      ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _translate('search_placeholder'),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor:
                    theme.inputDecorationTheme.fillColor ?? Colors.grey[150],
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 14.0),
              ),
            ),
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
                                        top: 0, bottom: 80.0), // FAB uchun joy
                                    itemCount: appsToDisplay.length,
                                    itemBuilder: (context, index) {
                                      final app = appsToDisplay[index];
                                      return _buildAppListItem(app);
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
