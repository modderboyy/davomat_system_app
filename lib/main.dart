// --- main.dart --
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math' as math;

import 'home_page.dart';
import 'account_page.dart';
import 'history_page.dart';
import 'login_page.dart';
import 'admin.dart';
import 'webview_page.dart'; // In-app browser uchun

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://kkhmbqabryruqxfiascm.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtraG1icWFicnlydXF4Zmlhc2NtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU5OTQ5OTMsImV4cCI6MjA1MTU3MDk5M30.0YPVTWKG3qMZ7J8twFjKWwVNNqqpz8YX3rkQiAiT2YQ';

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
  String currentAppVersion =
      '2'; // Hozirgi versiya 1, yangilanishni tekshirish uchun
  String _currentLanguage = 'uz';

  // GlobalKey MaterialApp uchun, bottom sheetni to'g'ri context bilan ko'rsatish uchun
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      'home_page_nav': 'Bosh sahifa',
      'history_nav': 'Tarix',
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
    // _checkAppUpdate() endi _checkLoginAndAdminStatus dan keyin chaqiriladi,
    // chunki _showUpdateBottomSheet to'g'ri contextga ega bo'lishi kerak.
    // Agar MaterialApp qurilmagan bo'lsa, showModalBottomSheet xatolik berishi mumkin.
    // Shuning uchun uni _checkLoginAndAdminStatus tugaganidan keyin chaqiramiz.
    if (mounted) {
      setState(() => _isLoading = false);
      // Faqatgina MaterialApp qurilganidan so'ng (ya'ni _isLoading false bo'lganda)
      // yangilanishni tekshirishni boshlaymiz.
      if (!_isLoading) {
        // Dublikat tekshiruv, lekin zararsiz
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
        // Context mavjudligini tekshirish
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
      // Barcha kesh ma'lumotlarini tozalash
      await prefs.clear(); // Yoki faqat keraklilarni:
      // await prefs.remove('isLoggedIn');
      // await prefs.remove('isAdmin');
      // await prefs.remove('userId');
      // ... boshqa keshlar ...

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
    // Bu funksiya MaterialApp qurilganidan keyin chaqirilishi kerak
    if (navigatorKey.currentContext == null) {
      // Agar context hali tayyor bo'lmasa, bir oz kutib qayta urinib ko'ramiz
      await Future.delayed(Duration(milliseconds: 500));
      if (navigatorKey.currentContext == null || !mounted)
        return; // Agar hali ham yo'q bo'lsa yoki widget yo'q bo'lsa, chiqib ketamiz
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
            // Endi WidgetsBinding.instance.addPostFrameCallback kerak emas,
            // chunki _checkAppUpdate o'zi MaterialApp qurilgandan keyin chaqiriladi.
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
    // navigatorKey.currentContext orqali to'g'ri contextni olamiz
    if (navigatorKey.currentContext == null || !mounted) return;

    showModalBottomSheet(
      context:
          navigatorKey.currentContext!, // MaterialApp contextidan foydalanish
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext errorDialogContext) {
        // Bu yerda yangi context olinadi
        final theme = Theme.of(errorDialogContext);
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.system_update_alt_rounded,
                  size: 50, color: theme.primaryColor),
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
                        side: BorderSide(color: theme.primaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(_translate('update_dialog_later'),
                          style: TextStyle(color: theme.primaryColor)),
                      onPressed: () => Navigator.of(errorDialogContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
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
    // Linklarni InAppWebViewPage orqali ochish
    if (navigatorKey.currentContext == null || !mounted) return;
    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => InAppWebViewPage(
          url: updateLink,
          title: _translate('app_name') +
              " " +
              _translate('update_dialog_update'), // Sarlavha
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
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        backgroundColor: Colors.white,
      ).copyWith(
        primary: const Color(0xFF5d1cad),
        secondary: Colors.deepOrange,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'SFUIDisplay',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1.0,
        iconTheme: IconThemeData(color: Colors.black54),
        titleTextStyle: TextStyle(
            color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w500),
      ),
      bottomAppBarTheme:
          const BottomAppBarTheme(color: Colors.white, elevation: 4.0),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2.0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      ),
      textButtonTheme: TextButtonThemeData(
          style:
              TextButton.styleFrom(foregroundColor: const Color(0xFF5d1cad))),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5d1cad),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide:
                  BorderSide(color: const Color(0xFF5d1cad), width: 1.5)),
          hintStyle: TextStyle(color: Colors.grey[500])),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey, // GlobalKey ni MaterialApp ga berish
      title: _translate('app_name'),
      theme: themeData,
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        // Bu Builder kerak emas, chunki navigatorKey ishlatilyapti
        return Scaffold(
          body: GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.translucent,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isLoggedIn
                    ? _isAdmin
                        ? AdminPage() // AdminPage o'zining til sozlamalarini boshqaradi
                        : _buildUserInterface(
                            context) // Bu yerda context Scaffold contexti
                    : LoginPage(onLoginSuccess: _setLoggedIn),
          ),
        );
      }),
    );
  }

  Widget _buildUserInterface(BuildContext scaffoldContext) {
    // Bu context endi Scaffold'niki
    return Column(
      children: [
        Expanded(
          child: _buildPageContent(_currentTab),
        ),
        Container(
          decoration: BoxDecoration(
              color: Theme.of(scaffoldContext).bottomAppBarTheme.color ??
                  Colors.white,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, -2))
              ]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              haptic: true,
              tabBorderRadius: 15,
              tabActiveBorder: Border.all(
                  color: Theme.of(scaffoldContext).colorScheme.primary,
                  width: 1.5),
              curve: Curves.easeOutExpo,
              duration: const Duration(milliseconds: 400),
              gap: 8,
              color: Colors.grey[600],
              activeColor: Theme.of(scaffoldContext).colorScheme.primary,
              iconSize: 24,
              tabBackgroundColor: Theme.of(scaffoldContext)
                  .colorScheme
                  .primary
                  .withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              tabs: [
                GButton(
                    icon: LineIcons.home, text: _translate('home_page_nav')),
                GButton(
                    icon: LineIcons.history, text: _translate('history_nav')),
                GButton(icon: LineIcons.user, text: _translate('profile_nav')),
              ],
              selectedIndex: _currentTab,
              onTabChange: (index) {
                if (!mounted) return;
                setState(() => _currentTab = index);
              },
            ),
          ),
        ),
      ],
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
