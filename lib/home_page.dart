import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'main.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:detect_fake_location/detect_fake_location.dart';
import 'package:safe_device/safe_device.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  bool _isCameraPaused = false;

  // User data
  String? userName;
  String? userEmail;
  String? userProfileImage;
  String? userPosition;

  // Subscription status
  bool _isSubscriptionActive = true;
  String _subscriptionStatus = 'Active';

  // Calendar data
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DateTime> _attendanceDays = [];
  Map<DateTime, Map<String, dynamic>> _attendanceDetails = {};

  // Settings
  bool _showTodayCard = true;
  bool _showCalendar = true;
  bool _compactView = false;
  bool _enableAttendanceMessage = false;
  String _attendanceMessage = '';

  // Colors
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  String _currentLanguage = 'uz';
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
      'today_attendance': 'Today\'s Attendance',
      'attendance_calendar': 'Attendance Calendar',
      'present': 'Present',
      'absent': 'Absent',
      'arrival_time': 'Arrival Time',
      'departure_time': 'Departure Time',
      'not_recorded': 'Not recorded',
      'subscription_status': 'Subscription Status',
      'active': 'Active',
      'stopped': 'Stopped',
      'subscription_expired': 'Subscription expired. Please contact admin.',
      'flash_on': 'Flash On',
      'flash_off': 'Flash Off',
      'complete': 'Complete',
      'incomplete': 'Incomplete',
      'loading': 'Loading...',
      'version': 'Version 2.0.0',
      'app_name': 'Modern Attendance System',
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
      'today_attendance': 'Bugungi davomat',
      'attendance_calendar': 'Davomat kalendari',
      'present': 'Kelgan',
      'absent': 'Kelmagan',
      'arrival_time': 'Kelish vaqti',
      'departure_time': 'Ketish vaqti',
      'not_recorded': 'Qayd etilmagan',
      'subscription_status': 'Obuna holati',
      'active': 'Faol',
      'stopped': 'To\'xtatilgan',
      'subscription_expired': 'Obuna muddati tugagan. Admin bilan bog\'laning.',
      'flash_on': 'Chiroqni yoqish',
      'flash_off': 'Chiroqni o\'chirish',
      'complete': 'To\'liq',
      'incomplete': 'To\'liq emas',
      'loading': 'Yuklanmoqda...',
      'version': 'Versiya 2.0.0',
      'app_name': 'Zamonaviy Davomat Tizimi',
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
      'today_attendance': 'Сегодняшняя посещаемость',
      'attendance_calendar': 'Календарь посещаемости',
      'present': 'Присутствовал',
      'absent': 'Отсутствовал',
      'arrival_time': 'Время прихода',
      'departure_time': 'Время ухода',
      'not_recorded': 'Не записано',
      'subscription_status': 'Статус подписки',
      'active': 'Активна',
      'stopped': 'Остановлена',
      'subscription_expired': 'Подписка истекла. Обратитесь к администратору.',
      'flash_on': 'Включить вспышку',
      'flash_off': 'Выключить вспышку',
      'complete': 'Завершено',
      'incomplete': 'Не завершено',
      'loading': 'Загрузка...',
      'version': 'Версия 2.0.0',
      'app_name': 'Современная система посещаемости',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (mounted) setState(() => _isLoadingUserData = true);
    await _loadLanguagePreference();
    await _loadSettings();
    await _loadUserDataFromPrefs();
    await _loadUserData();
    await _loadUserProfile();
    await _loadAttendanceData();
    await _checkSubscriptionStatus();
    if (mounted) setState(() => _isLoadingUserData = false);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showTodayCard = prefs.getBool('showTodayCard') ?? true;
      _showCalendar = prefs.getBool('showCalendar') ?? true;
      _compactView = prefs.getBool('compactView') ?? false;
      _enableAttendanceMessage =
          prefs.getBool('enableAttendanceMessage') ?? false;
      _attendanceMessage = prefs.getString('attendanceMessage') ?? '';
    });
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', currentUser.id)
          .maybeSingle();

      final companyId = userResponse?['company_id'];
      if (companyId == null) return;

      final companyResponse = await supabase
          .from('companies')
          .select('subscription_type, subscription_date')
          .eq('id', companyId)
          .maybeSingle();

      if (companyResponse != null) {
        final subscriptionType = companyResponse['subscription_type'];
        final subscriptionDate = companyResponse['subscription_date'];

        if (subscriptionType == 'monthly' && subscriptionDate != null) {
          final subDate = DateTime.parse(subscriptionDate);
          final now = DateTime.now();
          final expiryDate =
              DateTime(subDate.year, subDate.month + 1, subDate.day);

          final isActive = now.isBefore(expiryDate);

          if (mounted) {
            setState(() {
              _isSubscriptionActive = isActive;
              _subscriptionStatus =
                  isActive ? _translate('active') : _translate('stopped');
            });
          }
        }
      }
    } catch (e) {
      print("Error checking subscription status: $e");
    }
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

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings['uz']?[key] ??
        key;
  }

  Future<void> _loadUserProfile() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      final userDetails = await supabase
          .from('users')
          .select('full_name, email, profile_image, position, company_id')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userDetails != null && mounted) {
        setState(() {
          userName =
              userDetails['full_name'] ?? currentUser.email?.split('@')[0];
          userEmail = userDetails['email'] ?? currentUser.email;
          userProfileImage = userDetails['profile_image'];
          userPosition = userDetails['position'];
        });
      }
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }

  Future<void> _loadAttendanceData() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      final companyData = await supabase
          .from('users')
          .select('company_id')
          .eq('id', currentUser.id)
          .maybeSingle();

      final String? companyId = companyData?['company_id'] as String?;
      if (companyId == null) return;

      // Get attendance data for the current month
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final attendanceData = await supabase
          .from('davomat')
          .select('kelish_sana, kelish_vaqti, ketish_vaqti')
          .eq('xodim_id', currentUser.id)
          .eq('company_id', companyId)
          .gte('kelish_sana', DateFormat('yyyy-MM-dd').format(startOfMonth))
          .lte('kelish_sana', DateFormat('yyyy-MM-dd').format(endOfMonth));

      if (mounted) {
        List<DateTime> attendanceDays = [];
        Map<DateTime, Map<String, dynamic>> attendanceDetails = {};

        for (var record in attendanceData) {
          final dateStr = record['kelish_sana'] as String;
          final date = DateTime.parse(dateStr);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          attendanceDays.add(normalizedDate);

          attendanceDetails[normalizedDate] = {
            'arrival_time': record['kelish_vaqti'],
            'departure_time': record['ketish_vaqti'],
          };
        }

        setState(() {
          _attendanceDays = attendanceDays;
          _attendanceDetails = attendanceDetails;
        });
      }
    } catch (e) {
      print("Error loading attendance data: $e");
    }
  }

  // Add other necessary methods from the previous home_page.dart here...
  // (I'll include the key methods for QR scanning and data loading)

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
      print("Error loading user data from prefs: $e");
    }
  }

  Future<void> _loadUserData() async {
    if (mounted) setState(() => _isLoadingUserData = true);

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          message = 'User not logged in';
          _isLoadingUserData = false;
        });
      }
      return;
    }

    try {
      final companyDataRes = await supabase
          .from('users')
          .select('company_id')
          .eq('id', currentUser.id)
          .maybeSingle();

      final String? companyId = companyDataRes?['company_id'] as String?;

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
          setState(() {
            companyName = fetchedCompanyName;
            kelishQrCode = qrDataRes?['kelish_qrcode'] as String?;
            ketishQrCode = qrDataRes?['ketish_qrcode'] as String?;
            expectedLatitude =
                (locationDataRes?['latitude'] as num?)?.toDouble();
            expectedLongitude =
                (locationDataRes?['longitude'] as num?)?.toDouble();
            distanceThreshold =
                (locationDataRes?['distance'] as num?)?.toDouble() ?? 100.0;
          });
        }
      }
    } catch (error) {
      print("Error loading user data: $error");
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    }
  }

  void _showQRScanner() {
    if (!_isSubscriptionActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('subscription_expired')),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQRScannerModal(),
    );
  }

  Widget _buildQRScannerModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _translate('scan_qr_code'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(CupertinoIcons.xmark, color: textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildQrView(context, 300),
            ),
          ),
          if (message.isNotEmpty)
            Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getMessageColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getMessageColor().withOpacity(0.3)),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: _getMessageColor(),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context, double scanArea) {
    return Center(
      child: Container(
        width: scanArea,
        height: scanArea,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: primaryColor,
              borderRadius: 20,
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
      _isCameraPaused = false;
    });

    controller?.scannedDataStream.listen((scanData) async {
      if (_isCameraPaused) return;

      await controller?.pauseCamera();
      _isCameraPaused = true;

      if (mounted) {
        setState(() => result = scanData);
        await _handleScanLogic(scanData.code ?? '');
      }
    });
  }

  Future<void> _handleScanLogic(String data) async {
    if (!_isSubscriptionActive) {
      if (mounted) setState(() => message = _translate('subscription_expired'));
      return;
    }

    if (data.isEmpty) return;

    if (mounted) setState(() => message = _translate('checking'));

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final today = DateTime.now().toLocal().toString().split(' ')[0];
      final now = DateTime.now().toLocal().toIso8601String();

      final companyData = await supabase
          .from('users')
          .select('company_id')
          .eq('id', currentUser.id)
          .maybeSingle();

      final companyId = companyData?['company_id'];
      if (companyId == null) return;

      final existingAttendance = await supabase
          .from('davomat')
          .select()
          .eq('xodim_id', currentUser.id)
          .eq('kelish_sana', today)
          .eq('company_id', companyId)
          .maybeSingle();

      String finalMessage = _attendanceMessage;
      if (_enableAttendanceMessage && _attendanceMessage.isNotEmpty) {
        finalMessage = _attendanceMessage;
      }

      if (data == kelishQrCode) {
        if (existingAttendance == null) {
          await supabase.from('davomat').insert({
            'xodim_id': currentUser.id,
            'kelish_sana': today,
            'kelish_vaqti': now,
            'company_id': companyId,
            if (finalMessage.isNotEmpty) 'message': finalMessage,
          });
          if (mounted) setState(() => message = _translate('arrival_saved'));
          await _loadAttendanceData();
        } else {
          if (mounted)
            setState(() => message = _translate('already_marked_arrival'));
        }
      } else if (data == ketishQrCode) {
        if (existingAttendance != null) {
          if (existingAttendance['ketish_vaqti'] == null) {
            await supabase.from('davomat').update({
              'ketish_vaqti': now,
              if (finalMessage.isNotEmpty) 'message': finalMessage,
            }).eq('id', existingAttendance['id']);
            if (mounted)
              setState(() => message = _translate('departure_saved'));
            await _loadAttendanceData();
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
    } catch (e) {
      print("Error in scan logic: $e");
      if (mounted) setState(() => message = 'Error: ${e.toString()}');
    }

    // Auto-resume camera after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && controller != null && _isCameraPaused) {
        controller!.resumeCamera();
        _isCameraPaused = false;
        setState(() => message = '');
      }
    });
  }

  Color _getMessageColor() {
    if (message.contains('Error') ||
        message == _translate('subscription_expired')) {
      return errorColor;
    } else if (message == _translate('arrival_saved') ||
        message == _translate('departure_saved')) {
      return successColor;
    } else {
      return warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoadingUserData
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(),
                    SizedBox(height: 24),
                    _buildSubscriptionStatus(),
                    SizedBox(height: 24),
                    _buildQRScanButton(),
                    SizedBox(height: 24),
                    if (_showTodayCard) ...[
                      _buildTodayAttendanceCard(),
                      SizedBox(height: 24),
                    ],
                    if (_showCalendar) ...[
                      _buildAttendanceCalendar(),
                      SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: userProfileImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      userProfileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (userPosition != null) ...[
                  SizedBox(height: 4),
                  Text(
                    userPosition!,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', _currentLanguage)
                        .format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        CupertinoIcons.person_fill,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildSubscriptionStatus() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSubscriptionActive
                  ? successColor.withOpacity(0.1)
                  : errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isSubscriptionActive
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.xmark_circle_fill,
              color: _isSubscriptionActive ? successColor : errorColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('subscription_status'),
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                Text(
                  _subscriptionStatus,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isSubscriptionActive ? successColor : errorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceCard() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todayAttendance = _attendanceDetails[todayKey];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.clock,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                _translate('today_attendance'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceTimeCard(
                  icon: CupertinoIcons.arrow_down_circle_fill,
                  label: _translate('arrival_time'),
                  time: todayAttendance?['arrival_time'] != null
                      ? DateFormat('HH:mm').format(
                          DateTime.parse(todayAttendance!['arrival_time']))
                      : _translate('not_recorded'),
                  color: successColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildAttendanceTimeCard(
                  icon: CupertinoIcons.arrow_up_circle_fill,
                  label: _translate('departure_time'),
                  time: todayAttendance?['departure_time'] != null
                      ? DateFormat('HH:mm').format(
                          DateTime.parse(todayAttendance!['departure_time']))
                      : _translate('not_recorded'),
                  color: warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTimeCard({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCalendar() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.calendar,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                _translate('attendance_calendar'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TableCalendar<DateTime>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return _attendanceDays
                  .where((attendanceDay) =>
                      isSameDay(attendanceDay, normalizedDay))
                  .toList();
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: textSecondary),
              holidayTextStyle: TextStyle(color: textSecondary),
              defaultTextStyle: TextStyle(color: textPrimary),
              selectedDecoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: primaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: successColor,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              leftChevronIcon: Icon(
                CupertinoIcons.chevron_left,
                color: primaryColor,
              ),
              rightChevronIcon: Icon(
                CupertinoIcons.chevron_right,
                color: primaryColor,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showAttendanceDetails(selectedDay);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadAttendanceData();
            },
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(DateTime selectedDay) {
    final normalizedDay =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final attendanceDetail = _attendanceDetails[normalizedDay];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              DateFormat('dd MMMM yyyy', _currentLanguage).format(selectedDay),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 16),
            if (attendanceDetail != null) ...[
              _buildDetailRow(
                icon: CupertinoIcons.arrow_down_circle_fill,
                label: _translate('arrival_time'),
                value: attendanceDetail['arrival_time'] != null
                    ? DateFormat('HH:mm').format(
                        DateTime.parse(attendanceDetail['arrival_time']))
                    : _translate('not_recorded'),
                color: successColor,
              ),
              SizedBox(height: 12),
              _buildDetailRow(
                icon: CupertinoIcons.arrow_up_circle_fill,
                label: _translate('departure_time'),
                value: attendanceDetail['departure_time'] != null
                    ? DateFormat('HH:mm').format(
                        DateTime.parse(attendanceDetail['departure_time']))
                    : _translate('not_recorded'),
                color: warningColor,
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.xmark_circle, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Text(
                      _translate('absent'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanButton() {
    return GestureDetector(
      onTap: _showQRScanner,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _isSubscriptionActive
              ? LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey, Colors.grey.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isSubscriptionActive
                  ? primaryColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.qrcode_viewfinder,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              _isSubscriptionActive
                  ? _translate('scan_qr_code')
                  : _translate('subscription_expired'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
