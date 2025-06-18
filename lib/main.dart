import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math' as math;

import 'home_page.dart';
import 'account_page.dart';
import 'history_page.dart';
import 'login_page.dart';
import 'admin.dart';
import 'webview_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://vrvbmrmdcoxotyreevni.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZydmJtcm1kY294b3R5cmVldm5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxNDIxNzQsImV4cCI6MjA2NTcxODE3NH0.s_hDAQBPV27ikU289eOqPB-Au-M9eulMeqxNu4LMhM8';
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  await initializeDateFormatting();
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  int _currentTab = 0;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _userId;

  int _tapCount = 0;
  DateTime? _lastTapTime;
  String currentAppVersion = '2';
  String _currentLanguage = 'uz';

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Modern color scheme with the specified purple
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'home_page_nav': 'Home',
      'history_nav': 'History',
      'profile_nav': 'Profile',
      'update_dialog_title': 'New version available!',
      'update_dialog_content':
          'A new version ({version_number}) is available. Would you like to update now?',
      'update_dialog_later': 'Later',
      'update_dialog_update': 'Update Now',
      'update_error_title': 'Error',
      'update_error_message': 'Error opening update link: {error_message}',
      'update_link_not_open_error': 'Could not open update link.',
      'logout_triggered': 'Logout Triggered',
      'company_id_not_found': 'Company ID not found for user',
      'app_name': 'Attendance System',
    },
    'uz': {
      'home_page_nav': 'Home',
      'history_nav': 'History',
      'profile_nav': 'Profil',
      'update_dialog_title': 'Yangi versiya mavjud!',
      'update_dialog_content':
          'Dasturning yangi versiyasi ({version_number}) chiqdi. Hozir yangilashni xohlaysizmi?',
      'update_dialog_later': 'Keyinroq',
      'update_dialog_update': 'Hozir Yangilash',
      'update_error_title': 'Xatolik',
      'update_error_message':
          'Yangilanish linkini ochishda xatolik: {error_message}',
      'update_link_not_open_error': 'Yangilanish linkini ochib bo\'lmadi.',
      'logout_triggered': 'Akkauntdan Chiqildi',
      'company_id_not_found': 'Foydalanuvchi uchun Kompaniya ID topilmadi',
      'app_name': 'Davomat Tizimi',
    },
    'ru': {
      'home_page_nav': 'Главная',
      'history_nav': 'История',
      'profile_nav': 'Профиль',
      'update_dialog_title': 'Доступна новая версия!',
      'update_dialog_content':
          'Доступна новая версия ({version_number}). Обновить сейчас?',
      'update_dialog_later': 'Позже',
      'update_dialog_update': 'Обновить сейчас',
      'update_error_title': 'Ошибка',
      'update_error_message': 'Ошибка открытия ссылки: {error_message}',
      'update_link_not_open_error': 'Не удалось открыть ссылку.',
      'logout_triggered': 'Выход из аккаунта',
      'company_id_not_found': 'ID Компании не найден для пользователя',
      'app_name': 'Система Посещаемости',
    },
  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _loadPreferences();
    await _checkLoginAndAdminStatus();
    if (mounted) {
      setState(() => _isLoading = false);
      if (!_isLoading) {
        _checkAppUpdate();
      }
    }
  }

  Future<void> _loadPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('language') ?? 'uz';
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _isAdmin = prefs.getBool('isAdmin') ?? false;
      _userId = prefs.getString('userId');

      if (_isLoggedIn && supabase.auth.currentSession == null) {
        _isLoggedIn = false;
        _isAdmin = false;
        _userId = null;
        await prefs.remove('isLoggedIn');
        await prefs.remove('isAdmin');
        await prefs.remove('userId');
      }
    } catch (e) {
      print("Error loading preferences: $e");
      _currentLanguage = 'uz';
      _isLoggedIn = false;
      _isAdmin = false;
      _userId = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveAuthPreferences(
      bool loggedIn, bool isAdmin, String? userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', loggedIn);
      await prefs.setBool('isAdmin', isAdmin);
      if (userId != null) {
        await prefs.setString('userId', userId);
      } else {
        await prefs.remove('userId');
      }
    } catch (e) {
      print("Error saving auth preferences: $e");
    }
  }

  String _translate(String key, [Map<String, String>? params]) {
    final langKey =
        ['en', 'uz', 'ru'].contains(_currentLanguage) ? _currentLanguage : 'uz';
    String? translatedValue =
        _localizedStrings[langKey]?[key] ?? _localizedStrings['uz']?[key];
    translatedValue ??= key;
    if (params != null) {
      params.forEach((paramKey, value) {
        translatedValue = translatedValue!.replaceAll('{$paramKey}', value);
      });
    }
    return translatedValue!;
  }

  Future<void> _checkLoginAndAdminStatus() async {
    final session = supabase.auth.currentSession;
    bool loggedIn = false;
    bool isAdminUser = false;
    String? currentUserId;

    if (session != null && session.user != null) {
      loggedIn = true;
      currentUserId = session.user.id;
      try {
        final userDetails = await supabase
            .from('users')
            .select('is_super_admin')
            .eq('id', session.user.id)
            .maybeSingle();
        isAdminUser =
            (userDetails != null && userDetails['is_super_admin'] == true);
        if (userDetails == null)
          print("User details not found for ${session.user.id}");
      } catch (e) {
        print("Error fetching user admin status: $e");
        isAdminUser = false;
      }
    } else {
      loggedIn = false;
      isAdminUser = false;
      currentUserId = null;
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isAdmin = isAdminUser;
        _userId = currentUserId;
      });
    }
    await _saveAuthPreferences(loggedIn, isAdminUser, currentUserId);
  }

  void _setLoggedIn(bool loggedIn) {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _initialize().then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _handleTap() {
    if (_isLoading || !_isLoggedIn || _isAdmin) return;
    DateTime now = DateTime.now();
    bool triggerLogout = false;
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 1500) {
      _tapCount++;
      if (_tapCount >= 10) {
        triggerLogout = true;
        _tapCount = 0;
      }
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;

    if (triggerLogout) {
      print("Logout triggered by 10 taps.");
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
                content: Text(_translate('logout_triggered')),
                duration: Duration(seconds: 1)));
      }
      _logout();
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _setLoggedIn(false);
    } catch (error) {
      print('Logout error: $error');
      if (mounted && navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
                content: Text("Logout failed: $error"),
                backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int compareVersionStrings(String v1, String v2) {
    List<int> v1Parts = [];
    List<int> v2Parts = [];
    try {
      v1Parts = v1.split('.').map(int.parse).toList();
      v2Parts = v2.split('.').map(int.parse).toList();
    } catch (e) {
      print("Error parsing version strings: $v1, $v2. Error: $e");
      return 0;
    }
    for (int i = 0; i < math.max(v1Parts.length, v2Parts.length); i++) {
      int v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      int v2Part = i < v2Parts.length ? v2Parts[i] : 0;
      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }
    return 0;
  }

  Future<void> _checkAppUpdate() async {
    if (navigatorKey.currentContext == null) {
      await Future.delayed(Duration(milliseconds: 500));
      if (navigatorKey.currentContext == null || !mounted) return;
    }

    try {
      final List<dynamic> updates =
          await supabase.from('updates').select('version_number, update_link');

      if (updates.isNotEmpty) {
        Map<String, dynamic>? highestApplicableUpdate;
        String? highestVersionString;

        for (var updateDataDyn in updates) {
          final updateData = updateDataDyn as Map<String, dynamic>;
          final latestVersion = updateData['version_number'] as String?;
          if (latestVersion != null) {
            if (compareVersionStrings(latestVersion, currentAppVersion) > 0) {
              if (highestVersionString == null ||
                  compareVersionStrings(latestVersion, highestVersionString) >
                      0) {
                highestVersionString = latestVersion;
                highestApplicableUpdate = updateData;
              }
            }
          }
        }

        if (highestApplicableUpdate != null) {
          final latestVersion =
              highestApplicableUpdate['version_number'] as String;
          final updateLink = highestApplicableUpdate['update_link'] as String?;
          if (updateLink != null) {
            if (mounted && navigatorKey.currentContext != null) {
              _showUpdateBottomSheet(latestVersion, updateLink);
            }
          }
        }
      }
    } catch (error) {
      print('Failed to check for updates: $error');
    }
  }

  void _showUpdateBottomSheet(String latestVersion, String updateLink) {
    if (navigatorKey.currentContext == null || !mounted) return;

    showModalBottomSheet(
      context: navigatorKey.currentContext!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext errorDialogContext) {
        final theme = Theme.of(errorDialogContext);
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.system_update_alt_rounded,
                  size: 50, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                _translate('update_dialog_title'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _translate(
                    'update_dialog_content', {'version_number': latestVersion}),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(_translate('update_dialog_later'),
                          style: TextStyle(color: primaryColor)),
                      onPressed: () => Navigator.of(errorDialogContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(_translate('update_dialog_update')),
                      onPressed: () {
                        Navigator.of(errorDialogContext).pop();
                        _launchUpdateLink(updateLink);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUpdateLink(String updateLink) async {
    if (navigatorKey.currentContext == null || !mounted) return;
    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => InAppWebViewPage(
          url: updateLink,
          title:
              _translate('app_name') + " " + _translate('update_dialog_update'),
          currentLanguage: _currentLanguage,
        ),
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    if (navigatorKey.currentContext == null || !mounted) return;
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext dialogCtx) => AlertDialog(
        title: Text(_translate('update_error_title')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(
      primarySwatch: MaterialColor(0xFF6e38c9, {
        50: Color(0xFFF3EFFF),
        100: Color(0xFFE1D7FF),
        200: Color(0xFFC4AFFF),
        300: Color(0xFFA687FF),
        400: Color(0xFF8A5FFF),
        500: Color(0xFF6e38c9),
        600: Color(0xFF5D2FB3),
        700: Color(0xFF4C269D),
        800: Color(0xFF3B1D87),
        900: Color(0xFF2A1471),
      }),
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        background: backgroundColor,
        surface: cardColor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'SF Pro Display',
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textSecondary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        hintStyle: TextStyle(color: textSecondary),
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: _translate('app_name'),
      theme: themeData,
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.translucent,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : _isLoggedIn
                    ? _isAdmin
                        ? AdminPage()
                        : _buildUserInterface(context)
                    : ModernLoginPage(onLoginSuccess: _setLoggedIn),
          ),
        );
      }),
    );
  }

  Widget _buildUserInterface(BuildContext scaffoldContext) {
    return Column(
      children: [
        Expanded(
          child: _buildPageContent(_currentTab),
        ),
        _buildModernBottomBar(scaffoldContext),
      ],
    );
  }

  Widget _buildModernBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: CupertinoIcons.clock,
                label: _translate('history_nav'),
                index: 1,
                isSelected: _currentTab == 1,
              ),
              _buildQRButton(context),
              _buildBottomNavItem(
                icon: CupertinoIcons.person,
                label: _translate('profile_nav'),
                index: 2,
                isSelected: _currentTab == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          setState(() => _currentTab = 0);
        } else {
          setState(() => _currentTab = index);
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : textSecondary,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _currentTab = 0);
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.qrcode_viewfinder,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    Widget page;
    switch (index) {
      case 0:
        page = HomePage(key: ValueKey('HomePage_$_userId'));
        break;
      case 1:
        page = HistoryPage(key: ValueKey('HistoryPage_$_userId'));
        break;
      case 2:
        page = AccountPage(key: ValueKey('AccountPage_$_userId'));
        break;
      default:
        page = HomePage(key: ValueKey('HomePage_$_userId'));
    }
    return FadeIn(key: ValueKey<int>(index), child: page);
  }
}
