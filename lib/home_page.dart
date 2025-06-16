// home_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui'; // Keep if needed, often implicitly imported

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'main.dart'; // Correct way to potentially access something public from main.dart if needed (like supabase instance)
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:detect_fake_location/detect_fake_location.dart';
import 'package:safe_device/safe_device.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Use this for launching URLs

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  String message = '';
  bool isFlashOn = false;
  String? kelishQrCode;
  String? ketishQrCode;
  double? expectedLatitude;
  double? expectedLongitude;
  double distanceThreshold = 100;
  String? companyName;
  bool _isLoadingUserData = true;
  bool _isCameraPaused = false; // Flag to track camera pause state

  String _currentLanguage = 'uz';
  final Map<String, String> _languageTitles = {
    'en': 'Attendance System',
    'uz': 'Davomat tizimi',
    'ru': 'Система посещаемости',
  };
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'welcome_message': 'Welcome',
      'davomat_system_title': 'Attendance System',
      'scan_qr_code': 'Scan QR Code',
      'checking': 'Checking...',
      'company_not_assigned':
          'You are not assigned to a company. Contact your admin.',
      'blocked': 'You are blocked! Contact your admin to unblock.',
      'camera_location_permission_denied':
          'Camera and location permissions are not granted. Please grant permissions in settings.',
      'fake_location_detected': 'Fake location detected on your device!',
      'location_data_not_loaded':
          'Location data not loaded, please contact admin!',
      'not_at_workplace': 'You are not at your workplace!',
      'arrival_saved': 'Arrival saved.',
      'already_marked_arrival': 'You have already marked your arrival today.',
      'departure_saved': 'Departure saved.',
      'already_marked_departure':
          'You have already marked your departure today.',
      'mark_arrival_first': 'Mark your arrival first.',
      'wrong_qr_code': 'Wrong QR code.',
      'error_occurred': 'An error occurred: ',
      'error': 'Error',
      'ok': 'OK',
      'about_attendance_system': 'About Attendance System',
      'about_text': 'Attendance can be recorded by scanning a special QR code.',
      'close': 'Close',
      'refresh': 'Refresh',
      'global_qr_codes_not_found': 'Global QR codes not found, contact admin.',
      'telegram_channel': 'Telegram Channel',
      'telegram_group': 'Telegram Group',
      'telegram_admin': 'Telegram Admin',
      'user_not_logged_in': 'User not logged in. Please log in again.',
      'error_fetching_company_id': 'Error fetching company details.',
      'location_retrieval_timeout': 'Location retrieval timed out.',
      'location_services_disabled':
          'Location services are disabled. Please enable them.',
      'no_internet_for_data':
          'No internet. Displaying cached data if available.',
      'settings': 'Settings',
    },
    'uz': {
      'welcome_message': 'Xush kelibsiz',
      'davomat_system_title': 'Davomat tizimi',
      'scan_qr_code': 'QR kodni skanerlang',
      'checking': 'Tekshirilmoqda...',
      'company_not_assigned':
          "Siz kompaniyaga biriktirilmagansiz. Admin bilan bog'laning.",
      'blocked':
          'Siz bloklangansiz! Blokdan chiqish uchun admin bilan bog\'laning',
      'camera_location_permission_denied':
          'Kamera va joylashuvga ruxsat berilmagan. Iltimos sozlamalardan ruxsat bering.',
      'fake_location_detected': 'Qurilmangizda soxta joylashuv aniqlandi!',
      'location_data_not_loaded':
          'Joylashuv ma\'lumotlari yuklanmadi, iltimos ma\'muri bilan bog\'laning!',
      'not_at_workplace': 'Siz ish joyingizda emassiz!',
      'arrival_saved': 'Kelish saqlandi.',
      'already_marked_arrival':
          'Siz bugun allaqachon kelganingizni qayd etgansiz.',
      'departure_saved': 'Ketish saqlandi.',
      'already_marked_departure':
          'Siz bugun allaqachon ketganingizni qayd etgansiz.',
      'mark_arrival_first': 'Avval kelganingizni qayd eting.',
      'wrong_qr_code': 'Boshqa QR kod.',
      'error_occurred': 'Xatolik yuz berdi: ',
      'error': 'Xatolik',
      'ok': 'OK',
      'about_attendance_system': 'Davomat tizimi haqida',
      'about_text':
          "Maxsus QR kodni skanerlash orqali xodimlar davomati tizimiga davomatni qayd etish mumkin.",
      'close': 'Yopish',
      'refresh': 'Yangilash',
      'global_qr_codes_not_found':
          'Global QR kodlar topilmadi, admin bilan bog\'laning.',
      'telegram_channel': 'Telegram Kanal',
      'telegram_group': 'Telegram Guruh',
      'telegram_admin': 'Telegram Admin',
      'user_not_logged_in':
          'Foydalanuvchi tizimga kirmagan. Iltimos, qayta kiring.',
      'error_fetching_company_id': 'Kompaniya ma\'lumotlarini olishda xatolik.',
      'location_retrieval_timeout': 'Joylashuvni aniqlash vaqti tugadi.',
      'location_services_disabled':
          'Joylashuv xizmatlari yoqilmagan. Iltimos yoqing.',
      'no_internet_for_data':
          'Internet yo\'q. Mavjud bo\'lsa keshdagi ma\'lumotlar ko\'rsatiladi.',
      'settings': 'Sozlamalar',
    },
    'ru': {
      'welcome_message': 'Добро пожаловать',
      'davomat_system_title': 'Система посещаемости',
      'scan_qr_code': 'Сканировать QR-код',
      'checking': 'Проверяется...',
      'company_not_assigned':
          'Вы не прикреплены к компании. Свяжитесь с администратором.',
      'blocked':
          'Вы заблокированы! Свяжитесь с администратором для разблокировки.',
      'camera_location_permission_denied':
          'Разрешения камеры и местоположения не предоставлены. Пожалуйста, предоставьте разрешения в настройках.',
      'fake_location_detected':
          'Обнаружено поддельное местоположение на вашем устройстве!',
      'location_data_not_loaded':
          'Данные о местоположении не загружены, пожалуйста, свяжитесь с администратором!',
      'not_at_workplace': 'Вы не на рабочем месте!',
      'arrival_saved': 'Приход сохранен.',
      'already_marked_arrival': 'Вы уже отметили свой приход сегодня.',
      'departure_saved': 'Уход сохранен.',
      'already_marked_departure': 'Вы уже отметили свой уход сегодня.',
      'mark_arrival_first': 'Сначала отметьте свой приход.',
      'wrong_qr_code': 'Неверный QR-код.',
      'error_occurred': 'Произошла ошибка: ',
      'error': 'Ошибка',
      'ok': 'OK',
      'about_attendance_system': 'О системе посещаемости',
      'about_text':
          'Посещаемость можно регистрировать, сканируя специальный QR-код.',
      'close': 'Закрыть',
      'refresh': 'Обновить',
      'global_qr_codes_not_found':
          'Глобальные QR-коды не найдены, свяжитесь с администратором.',
      'telegram_channel': 'Telegram Канал',
      'telegram_group': 'Telegram Группа',
      'telegram_admin': 'Telegram Админ',
      'user_not_logged_in':
          'Пользователь не вошел в систему. Пожалуйста, войдите снова.',
      'error_fetching_company_id': 'Ошибка при получении данных о компании.',
      'location_retrieval_timeout':
          'Время ожидания определения местоположения истекло.',
      'location_services_disabled':
          'Службы геолокации отключены. Пожалуйста, включите их.',
      'no_internet_for_data':
          'Нет интернета. По возможности будут отображены кэшированные данные.',
      'settings': 'Настройки',
    },
  };

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller!.pauseCamera();
        _isCameraPaused = true;
      }
      controller!.resumeCamera();
      _isCameraPaused = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (mounted) setState(() => _isLoadingUserData = true);
    await _loadLanguagePreference();
    await _loadUserDataFromPrefs();
    await _loadUserData();
    if (mounted) setState(() => _isLoadingUserData = false);
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
      print("Error loading language preference: $e");
      if (mounted) {
        setState(() {
          _currentLanguage = 'uz';
        });
      }
    }
  }

  Future<void> _setLanguagePreference(String language) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
      if (mounted) {
        setState(() {
          _currentLanguage = language;
        });
      }
    } catch (e) {
      print("Error saving language preference: $e");
    }
  }

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings['uz']?[key] ??
        key;
  }

  Future<void> _saveUserDataToPrefs(
      {String? companyName,
      String? kelishQr,
      String? ketishQr,
      double? lat,
      double? lon,
      double? threshold}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (companyName != null)
        await prefs.setString('cachedCompanyName', companyName);
      else
        await prefs.remove('cachedCompanyName');
      if (kelishQr != null)
        await prefs.setString('cachedKelishQr', kelishQr);
      else
        await prefs.remove('cachedKelishQr');
      if (ketishQr != null)
        await prefs.setString('cachedKetishQr', ketishQr);
      else
        await prefs.remove('cachedKetishQr');
      if (lat != null)
        await prefs.setDouble('cachedLatitude', lat);
      else
        await prefs.remove('cachedLatitude');
      if (lon != null)
        await prefs.setDouble('cachedLongitude', lon);
      else
        await prefs.remove('cachedLongitude');
      if (threshold != null)
        await prefs.setDouble('cachedThreshold', threshold);
      else
        await prefs.remove('cachedThreshold');
    } catch (e) {
      print("Error saving user data to prefs (HomePage): $e");
    }
  }

  Future<void> _loadUserDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          companyName = prefs.getString('cachedCompanyName');
          kelishQrCode = prefs.getString('cachedKelishQr');
          ketishQrCode = prefs.getString('cachedKetishQr');
          expectedLatitude = prefs.getDouble('cachedLatitude');
          expectedLongitude = prefs.getDouble('cachedLongitude');
          distanceThreshold = prefs.getDouble('cachedThreshold') ?? 100.0;
        });
      }
    } catch (e) {
      print("Error loading user data from prefs (HomePage): $e");
      if (mounted) {
        setState(() {
          companyName = null;
          kelishQrCode = null;
          ketishQrCode = null;
          expectedLatitude = null;
          expectedLongitude = null;
          distanceThreshold = 100.0;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    if (mounted) setState(() => _isLoadingUserData = true);

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      print("User not logged in. Cannot load user data.");
      if (mounted) {
        setState(() {
          message = _translate('user_not_logged_in');
          _isLoadingUserData = false;
        });
        await _clearCachedUserData();
      }
      return;
    }

    final userId = currentUser.id;
    print('Foydalanuvchi IDsi: $userId');

    try {
      final companyDataRes = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      final String? companyId = companyDataRes?['company_id'] as String?;
      print('Kompaniya IDsi: $companyId');

      if (companyId != null) {
        final companyNameDataRes = await supabase
            .from('companies')
            .select('company_name')
            .eq('id', companyId)
            .maybeSingle();
        final String? fetchedCompanyName =
            companyNameDataRes?['company_name'] as String?;

        final qrDataRes = await supabase
            .from('qrcodes')
            .select('kelish_qrcode, ketish_qrcode')
            .limit(1)
            .maybeSingle();

        final locationDataRes = await supabase
            .from('location')
            .select('latitude, longitude, distance')
            .eq('company_id', companyId)
            .maybeSingle();

        if (mounted) {
          final newKelishQr = qrDataRes?['kelish_qrcode'] as String?;
          final newKetishQr = qrDataRes?['ketish_qrcode'] as String?;
          final newLat = (locationDataRes?['latitude'] as num?)?.toDouble();
          final newLon = (locationDataRes?['longitude'] as num?)?.toDouble();
          final newThreshold =
              (locationDataRes?['distance'] as num?)?.toDouble() ?? 100.0;

          setState(() {
            companyName = fetchedCompanyName;
            kelishQrCode = newKelishQr;
            ketishQrCode = newKetishQr;
            expectedLatitude = newLat;
            expectedLongitude = newLon;
            distanceThreshold = newThreshold;
          });
          await _saveUserDataToPrefs(
              companyName: fetchedCompanyName,
              kelishQr: newKelishQr,
              ketishQr: newKetishQr,
              lat: newLat,
              lon: newLon,
              threshold: newThreshold);
        }
      } else {
        if (mounted) {
          setState(() {
            message = _translate('company_not_assigned');
            companyName = null;
            kelishQrCode = null;
            ketishQrCode = null;
            expectedLatitude = null;
            expectedLongitude = null;
          });
          await _clearCachedUserData();
        }
      }
    } catch (error) {
      print("Foydalanuvchi ma'lumotlarini yuklashda xatolik: $error");
      if (mounted) {
        setState(() {
          message = _translate('no_internet_for_data');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    }
  }

  Future<void> _clearCachedUserData() async {
    await _saveUserDataToPrefs(
        companyName: null,
        kelishQr: null,
        ketishQr: null,
        lat: null,
        lon: null,
        threshold: null);
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};
    bool granted = true;

    PermissionStatus cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }
    statuses[Permission.camera] = cameraStatus;

    PermissionStatus locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted && !locationStatus.isPermanentlyDenied) {
      locationStatus = await Permission.locationWhenInUse.request();
    }
    statuses[Permission.location] = await Permission.location.status;

    print("Permission Statuses: $statuses");

    if (!await Permission.camera.isGranted ||
        !(await Permission.location.isGranted ||
            await Permission.locationWhenInUse.isGranted)) {
      granted = false;
      if (await Permission.camera.isPermanentlyDenied ||
          await Permission.location.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionSettingsDialog();
        }
      }
    }
    return granted;
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_translate('error')),
        content: Text(_translate('camera_location_permission_denied')),
        actions: [
          TextButton(
            child: Text(_translate('ok')),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(_translate('settings')),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _isRealDevice() async {
    bool isMock = false;
    try {
      bool isFakeLocationDetected =
          await DetectFakeLocation().detectFakeLocation();
      if (isFakeLocationDetected) {
        print("Fake location detected by detect_fake_location.");
        isMock = true;
      }
      bool isMockLocationBySafeDevice = await SafeDevice.isMockLocation;
      if (isMockLocationBySafeDevice) {
        print("Mock location detected by safe_device.");
        isMock = true;
      }
      return !isMock;
    } catch (e) {
      print("Soxta joylashuvni/qurilmani aniqlashda xatolik: $e");
      return false;
    }
  }

  Future<void> _handleScanLogic(String data) async {
    if (data.isEmpty) return;

    // KERAKSIZ QAYTA E'LON QILISHNI Oлиб ташлаймиз:
    // final currentUser = supabase.auth.currentUser; // BU QATORNI OLIB TASHLAYMIZ
    // if (currentUser == null) { // BU SHARTNI O'ZGARTIRAMIZ
    if (supabase.auth.currentUser == null) {
      // TO'G'RIDAN-TO'G'RI TEKSHIRAMIZ
      if (mounted) setState(() => message = _translate('user_not_logged_in'));
      return;
    }
    // final userId = currentUser.id; // BU QATORNI OLIB TASHLAYMIZ
    final userId = supabase.auth.currentUser!.id; // TO'G'RIDAN-TO'G'RI OLAMIZ

    if (mounted) setState(() => message = _translate('checking'));

    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      if (mounted)
        setState(
            () => message = _translate('camera_location_permission_denied'));
      return;
    }

    String? companyIdLocal;
    // Agar `companyName` keshdan yuklangan bo'lsa va `companyIdLocal` hali olinmagan bo'lsa,
    // yoki `companyName` keshdan yuklanmagan bo'lsa (birinchi marta yuklash yoki kesh yo'q bo'lsa)
    // unda `company_id` ni Supabasedan olishga harakat qilamiz.
    if ((companyName != null && companyIdLocal == null) ||
        companyName == null) {
      try {
        final companyData = await supabase
            .from('users')
            .select('company_id')
            .eq('id', userId) // `userId` ni ishlatamiz
            .maybeSingle();

        if (companyData != null && companyData['company_id'] != null) {
          companyIdLocal = companyData['company_id'] as String?;
        } else {
          if (mounted && companyName == null) {
            setState(() => message = _translate('company_not_assigned'));
          }
        }
      } catch (e) {
        print("Error fetching company_id for user $userId: $e");
        if (mounted) {
          setState(() => message = _translate('error_fetching_company_id'));
        }
        if (companyName == null) return;
      }
    }

    if (companyIdLocal == null && companyName == null) {
      if (mounted) setState(() => message = _translate('company_not_assigned'));
      return;
    }
    // `effectiveCompanyId` ni `userId` dan keyin va `companyIdLocal`ni olgandan keyin aniqlaymiz
    final String effectiveCompanyId = companyIdLocal ??
        "CACHE_BASED_ID_IF_NEEDED"; // Agar companyIdLocal null bo'lsa, bu qiymat ishlatiladi.
    // Haqiqiy oflayn rejim uchun bu qismni qayta ko'rib chiqish kerak bo'lishi mumkin.

    try {
      final blockedUser = await supabase
          .from('blocked')
          .select()
          .eq('user_id', userId) // `userId` ni ishlatamiz
          .eq('company_id', effectiveCompanyId)
          .maybeSingle();
      if (blockedUser != null) {
        if (mounted) setState(() => message = _translate('blocked'));
        return;
      }
    } catch (e) {
      print("Error checking blocked status: $e");
      if (mounted)
        setState(() => message =
            "${_translate('error_occurred')}Bloklanganlikni tekshirishda xatolik.");
      return;
    }

    final isReal = await _isRealDevice();
    if (!isReal) {
      if (mounted)
        setState(() => message = _translate('fake_location_detected'));
      try {
        await supabase.from('blocked').insert({
          'user_id': userId,
          'company_id': effectiveCompanyId
        }); // `userId` ni ishlatamiz
      } catch (e) {/* ... */}
      return;
    }

    if (expectedLatitude == null || expectedLongitude == null) {
      if (mounted)
        setState(() => message = _translate('location_data_not_loaded'));
      await _loadUserData();
      if (expectedLatitude == null || expectedLongitude == null) return;
    }

    if (kelishQrCode == null || ketishQrCode == null) {
      if (mounted)
        setState(() => message = _translate('global_qr_codes_not_found'));
      await _loadUserData();
      if (kelishQrCode == null || ketishQrCode == null) return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15));
      final distance = Geolocator.distanceBetween(position.latitude,
          position.longitude, expectedLatitude!, expectedLongitude!);

      if (distance > distanceThreshold) {
        if (mounted)
          setState(() => message =
              "${_translate('not_at_workplace')} (${distance.toStringAsFixed(1)}m)");
        return;
      }

      final today = DateTime.now().toLocal().toString().split(' ')[0];
      final now = DateTime.now().toLocal().toIso8601String();
      final existingAttendance = await supabase
          .from('davomat')
          .select()
          .eq('xodim_id', userId) // `userId` ni ishlatamiz
          .eq('kelish_sana', today)
          .eq('company_id', effectiveCompanyId)
          .maybeSingle();

      if (data == kelishQrCode) {
        if (existingAttendance == null) {
          await supabase.from('davomat').insert({
            'xodim_id': userId, 'kelish_sana': today, 'kelish_vaqti': now,
            'company_id': effectiveCompanyId, // `userId` ni ishlatamiz
          });
          if (mounted) setState(() => message = _translate('arrival_saved'));
        } else {
          if (mounted)
            setState(() => message = _translate('already_marked_arrival'));
        }
      } else if (data == ketishQrCode) {
        if (existingAttendance != null) {
          if (existingAttendance['ketish_vaqti'] == null) {
            await supabase.from('davomat').update({'ketish_vaqti': now}).eq(
                'id', existingAttendance['id']);
            if (mounted)
              setState(() => message = _translate('departure_saved'));
          } else {
            if (mounted)
              setState(() => message = _translate('already_marked_departure'));
          }
        } else {
          if (mounted)
            setState(() => message = _translate('mark_arrival_first'));
        }
      } else {
        if (mounted) setState(() => message = _translate('wrong_qr_code'));
      }
    } on TimeoutException catch (_) {
      if (mounted)
        setState(() => message = _translate('location_retrieval_timeout'));
    } on PermissionDeniedException {
      if (mounted) {
        setState(
            () => message = _translate('camera_location_permission_denied'));
        _showPermissionSettingsDialog();
      }
    } on LocationServiceDisabledException {
      if (mounted)
        setState(() => message = _translate('location_services_disabled'));
    } catch (e) {
      print("An error occurred during scan logic: $e");
      if (mounted)
        setState(
            () => message = "${_translate('error_occurred')}${e.toString()}");
    } finally {
      if (mounted && message != _translate('checking')) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && controller != null && !_isCameraPaused) {
            controller!.resumeCamera();
            _isCameraPaused = false;
            if (mounted)
              setState(() {
                message = '';
              });
          }
        });
      }
    }
  }

  void _resetScanner() {
    if (mounted) {
      setState(() {
        result = null;
        message = '';
      });
    }
    if (controller != null) {
      controller!.resumeCamera();
      _isCameraPaused = false;
    }
    _loadUserData();
  }

  void _showInfoDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_translate('about_attendance_system')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_translate('about_text')),
                const SizedBox(height: 20),
                _buildLinkButton(context, _translate('telegram_channel'),
                    'https://t.me/davomat_system'),
                _buildLinkButton(context, _translate('telegram_group'),
                    'https://t.me/davomat_system_chat'),
                _buildLinkButton(context, _translate('telegram_admin'),
                    'https://t.me/modderboy'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(_translate('close')),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLinkButton(BuildContext context, String text, String url) {
    return TextButton(
      onPressed: () async {
        final Uri uri = Uri.parse(url);
        try {
          // Use launchUrl instead of canLaunchUrl + launchUrl
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            print('Could not launch $uri');
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Could not open link.")));
          }
        } catch (e) {
          print('Error launching URL $url: $e');
          if (mounted)
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Error opening link.")));
        }
      },
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final messageFontSize = isTablet ? 18.0 : 14.0;
    var scanArea = screenSize.width * (isTablet ? 0.5 : 0.8);
    scanArea = scanArea > (isTablet ? 450.0 : 300.0)
        ? (isTablet ? 450.0 : 300.0)
        : scanArea;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: Text(
          _isLoadingUserData
              ? _translate('davomat_system_title')
              : (companyName != null
                  ? '"$companyName" - ${_translate('davomat_system_title')}'
                  : _translate('davomat_system_title')),
          style: TextStyle(
              fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: _translate('about_attendance_system'),
            onPressed: _showInfoDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: "Tilni tanlash",
            onSelected: (String language) async {
              await _setLanguagePreference(language);
              await _loadUserData();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'en', child: Text('English')),
              const PopupMenuItem<String>(value: 'uz', child: Text('O\'zbek')),
              const PopupMenuItem<String>(value: 'ru', child: Text('Русский')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 10),
                if (_isLoadingUserData)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _translate('welcome_message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 28.0 : 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Container(
                        // Corrected the conditional logic for color
                        decoration: BoxDecoration(
                            color: (message.contains(_translate('error')) ||
                                    message.contains(_translate('blocked')) ||
                                    message.contains(
                                        'Xatolik') || // Assuming 'Xatolik' is an error term
                                    message ==
                                        _translate('fake_location_detected') ||
                                    message ==
                                        _translate(
                                            'camera_location_permission_denied') ||
                                    message ==
                                        _translate(
                                            'location_data_not_loaded') ||
                                    message ==
                                        _translate('no_internet_for_data'))
                                ? Colors.red[100]
                                : (message == _translate('arrival_saved') ||
                                        message ==
                                            _translate('departure_saved'))
                                    ? Colors.green[100]
                                    : Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: (message.contains(_translate('error')) ||
                                        message
                                            .contains(_translate('blocked')) ||
                                        message.contains('Xatolik') ||
                                        message ==
                                            _translate(
                                                'fake_location_detected') ||
                                        message ==
                                            _translate(
                                                'camera_location_permission_denied') ||
                                        message ==
                                            _translate(
                                                'location_data_not_loaded') ||
                                        message ==
                                            _translate('no_internet_for_data'))
                                    ? Colors.red[300]!
                                    : (message == _translate('arrival_saved') ||
                                            message ==
                                                _translate('departure_saved'))
                                        ? Colors.green[300]!
                                        : Colors.blue[300]!,
                                width: 1)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: messageFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  _buildQrView(context, scanArea),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 20),
                        label: Text(_translate('refresh')),
                        onPressed: _resetScanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
                        tooltip: isFlashOn
                            ? "Chiroqni o'chirish"
                            : "Chiroqni yoqish",
                        iconSize: 30,
                        color: Colors.black54,
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            padding: const EdgeInsets.all(12)),
                        onPressed: () async {
                          if (controller != null) {
                            try {
                              await controller?.toggleFlash();
                              bool? flashStatus =
                                  await controller?.getFlashStatus();
                              if (mounted)
                                setState(
                                    () => isFlashOn = flashStatus ?? false);
                            } catch (e) {
                              print("Error toggling flash: $e");
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context, double scanArea) {
    return Center(
      child: Container(
        width: scanArea,
        height: scanArea,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
            overlay: QrScannerOverlayShape(
              borderColor: Colors.lightGreenAccent,
              borderRadius: 12,
              borderLength: 40,
              borderWidth: 8,
              cutOutSize: scanArea * 0.85,
            ),
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController newController) {
    setState(() {
      controller = newController;
      _isCameraPaused = false; // Initially not paused
    });
    controller?.resumeCamera(); // Ensure camera starts
    _isCameraPaused = false;

    StreamSubscription? scanSubscription;
    scanSubscription = controller?.scannedDataStream.listen((scanData) async {
      if (_isCameraPaused) return; // Don't process if already paused/processing

      await controller?.pauseCamera();
      _isCameraPaused = true;
      print("QR Detected: ${scanData.code}. Camera paused.");

      if (mounted) {
        setState(() => result = scanData);
        await _handleScanLogic(scanData.code ?? '');

        bool shouldResume = true;
        if (message == _translate('fake_location_detected') ||
            message == _translate('blocked')) {
          shouldResume = false;
        }

        if (shouldResume && mounted) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && controller != null && _isCameraPaused) {
              // Resume only if it was paused
              print("Resuming camera after processing.");
              controller?.resumeCamera();
              _isCameraPaused = false;
              if (mounted)
                setState(() {
                  message = '';
                });
            }
          });
        } else if (!shouldResume) {
          print("Camera remains paused.");
        }
      } else {
        await scanSubscription?.cancel();
      }
    }, onError: (error) {
      print("Error on scannedDataStream: $error");
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    print('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_translate('camera_location_permission_denied'))),
        );
      }
    } else {
      ctrl.resumeCamera();
      _isCameraPaused = false;
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

extension ParseToString on double {
  LocationAccuracy toLocationAccuracy() {
    if (this <= 10) return LocationAccuracy.high;
    if (this <= 100) return LocationAccuracy.medium;
    return LocationAccuracy.low;
  }
}
