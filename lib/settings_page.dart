import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:DavomatYettilik/main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Modern colors
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  String _currentLanguage = 'uz';
  bool _enableAttendanceMessage = false;
  String _attendanceMessage = '';
  bool _showTodayCard = true;
  bool _showCalendar = true;
  bool _compactView = false;

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'settings': 'Settings',
      'general': 'General',
      'language': 'Language',
      'attendance_settings': 'Attendance Settings',
      'enable_message': 'Enable Attendance Message',
      'attendance_message': 'Attendance Message',
      'message_placeholder': 'Enter your attendance message...',
      'home_customization': 'Home Page Customization',
      'show_today_card': 'Show Today\'s Attendance Card',
      'show_calendar': 'Show Attendance Calendar',
      'compact_view': 'Compact View',
      'about': 'About',
      'version': 'Version',
      'app_info': 'App Information',
      'save': 'Save',
      'saved': 'Settings saved successfully',
      'uzbek': 'O\'zbekcha',
      'english': 'English',
      'russian': 'Русский',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'system_default': 'System Default',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Email Notifications',
      'reminder_notifications': 'Reminder Notifications',
      'sound_settings': 'Sound Settings',
      'notification_sound': 'Notification Sound',
      'vibration': 'Vibration',
      'privacy': 'Privacy',
      'data_usage': 'Data Usage',
      'location_access': 'Location Access',
      'camera_access': 'Camera Access',
      'storage_access': 'Storage Access',
      'backup_restore': 'Backup & Restore',
      'backup_data': 'Backup Data',
      'restore_data': 'Restore Data',
      'auto_backup': 'Auto Backup',
      'advanced': 'Advanced',
      'developer_options': 'Developer Options',
      'debug_mode': 'Debug Mode',
      'clear_cache': 'Clear Cache',
      'reset_settings': 'Reset Settings',
      'export_data': 'Export Data',
      'import_data': 'Import Data',
      'app_version_info': 'App Version Information',
      'build_date': 'Build Date',
      'last_update': 'Last Update',
      'support_contact': 'Support Contact',
      'feedback': 'Send Feedback',
      'report_bug': 'Report Bug',
      'feature_request': 'Feature Request',
      'help_documentation': 'Help & Documentation',
      'user_guide': 'User Guide',
      'faq': 'Frequently Asked Questions',
      'contact_support': 'Contact Support',
      'legal': 'Legal',
      'terms_conditions': 'Terms & Conditions',
      'privacy_policy': 'Privacy Policy',
      'licenses': 'Open Source Licenses',
      'acknowledgments': 'Acknowledgments',
    },
    'uz': {
      'settings': 'Sozlamalar',
      'general': 'Umumiy',
      'language': 'Til',
      'attendance_settings': 'Davomat sozlamalari',
      'enable_message': 'Davomat xabarini yoqish',
      'attendance_message': 'Davomat xabari',
      'message_placeholder': 'Davomat xabaringizni kiriting...',
      'home_customization': 'Bosh sahifa sozlamalari',
      'show_today_card': 'Bugungi davomat kartasini ko\'rsatish',
      'show_calendar': 'Davomat kalendarini ko\'rsatish',
      'compact_view': 'Ixcham ko\'rinish',
      'about': 'Dastur haqida',
      'version': 'Versiya',
      'app_info': 'Dastur ma\'lumotlari',
      'save': 'Saqlash',
      'saved': 'Sozlamalar muvaffaqiyatli saqlandi',
      'uzbek': 'O\'zbekcha',
      'english': 'English',
      'russian': 'Русский',
      'appearance': 'Ko\'rinish',
      'theme': 'Mavzu',
      'dark_mode': 'Qorong\'u rejim',
      'light_mode': 'Yorug\' rejim',
      'system_default': 'Tizim bo\'yicha',
      'notifications': 'Bildirishnomalar',
      'push_notifications': 'Push bildirishnomalar',
      'email_notifications': 'Email bildirishnomalar',
      'reminder_notifications': 'Eslatma bildirishnomalari',
      'sound_settings': 'Ovoz sozlamalari',
      'notification_sound': 'Bildirishnoma ovozi',
      'vibration': 'Tebranish',
      'privacy': 'Maxfiylik',
      'data_usage': 'Ma\'lumotlar foydalanishi',
      'location_access': 'Joylashuvga kirish',
      'camera_access': 'Kameraga kirish',
      'storage_access': 'Xotiraga kirish',
      'backup_restore': 'Zaxira nusxa va tiklash',
      'backup_data': 'Ma\'lumotlarni zaxiralash',
      'restore_data': 'Ma\'lumotlarni tiklash',
      'auto_backup': 'Avtomatik zaxiralash',
      'advanced': 'Qo\'shimcha',
      'developer_options': 'Dasturchi sozlamalari',
      'debug_mode': 'Debug rejimi',
      'clear_cache': 'Keshni tozalash',
      'reset_settings': 'Sozlamalarni tiklash',
      'export_data': 'Ma\'lumotlarni eksport qilish',
      'import_data': 'Ma\'lumotlarni import qilish',
      'app_version_info': 'Dastur versiyasi ma\'lumotlari',
      'build_date': 'Yaratilgan sana',
      'last_update': 'Oxirgi yangilanish',
      'support_contact': 'Yordam aloqasi',
      'feedback': 'Fikr-mulohaza yuborish',
      'report_bug': 'Xato haqida xabar berish',
      'feature_request': 'Yangi funksiya so\'rash',
      'help_documentation': 'Yordam va hujjatlar',
      'user_guide': 'Foydalanuvchi qo\'llanmasi',
      'faq': 'Tez-tez so\'raladigan savollar',
      'contact_support': 'Yordam xizmati bilan bog\'lanish',
      'legal': 'Huquqiy',
      'terms_conditions': 'Shartlar va qoidalar',
      'privacy_policy': 'Maxfiylik siyosati',
      'licenses': 'Ochiq manba litsenziyalari',
      'acknowledgments': 'Minnatdorchilik',
    },
    'ru': {
      'settings': 'Настройки',
      'general': 'Общие',
      'language': 'Язык',
      'attendance_settings': 'Настройки посещаемости',
      'enable_message': 'Включить сообщение посещаемости',
      'attendance_message': 'Сообщение посещаемости',
      'message_placeholder': 'Введите ваше сообщение посещаемости...',
      'home_customization': 'Настройка главной страницы',
      'show_today_card': 'Показать карточку сегодняшней посещаемости',
      'show_calendar': 'Показать календарь посещаемости',
      'compact_view': 'Компактный вид',
      'about': 'О приложении',
      'version': 'Версия',
      'app_info': 'Информация о приложении',
      'save': 'Сохранить',
      'saved': 'Настройки успешно сохранены',
      'uzbek': 'O\'zbekcha',
      'english': 'English',
      'russian': 'Русский',
      'appearance': 'Внешний вид',
      'theme': 'Тема',
      'dark_mode': 'Темный режим',
      'light_mode': 'Светлый режим',
      'system_default': 'По умолчанию системы',
      'notifications': 'Уведомления',
      'push_notifications': 'Push-уведомления',
      'email_notifications': 'Email-уведомления',
      'reminder_notifications': 'Напоминания',
      'sound_settings': 'Настройки звука',
      'notification_sound': 'Звук уведомлений',
      'vibration': 'Вибрация',
      'privacy': 'Конфиденциальность',
      'data_usage': 'Использование данных',
      'location_access': 'Доступ к местоположению',
      'camera_access': 'Доступ к камере',
      'storage_access': 'Доступ к хранилищу',
      'backup_restore': 'Резервное копирование и восстановление',
      'backup_data': 'Резервное копирование данных',
      'restore_data': 'Восстановление данных',
      'auto_backup': 'Автоматическое резервное копирование',
      'advanced': 'Дополнительно',
      'developer_options': 'Параметры разработчика',
      'debug_mode': 'Режим отладки',
      'clear_cache': 'Очистить кэш',
      'reset_settings': 'Сбросить настройки',
      'export_data': 'Экспорт данных',
      'import_data': 'Импорт данных',
      'app_version_info': 'Информация о версии приложения',
      'build_date': 'Дата сборки',
      'last_update': 'Последнее обновление',
      'support_contact': 'Контакт поддержки',
      'feedback': 'Отправить отзыв',
      'report_bug': 'Сообщить об ошибке',
      'feature_request': 'Запрос функции',
      'help_documentation': 'Справка и документация',
      'user_guide': 'Руководство пользователя',
      'faq': 'Часто задаваемые вопросы',
      'contact_support': 'Связаться с поддержкой',
      'legal': 'Правовая информация',
      'terms_conditions': 'Условия использования',
      'privacy_policy': 'Политика конфиденциальности',
      'licenses': 'Лицензии с открытым исходным кодом',
      'acknowledgments': 'Благодарности',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'uz';
      _enableAttendanceMessage =
          prefs.getBool('enableAttendanceMessage') ?? false;
      _attendanceMessage = prefs.getString('attendanceMessage') ?? '';
      _showTodayCard = prefs.getBool('showTodayCard') ?? true;
      _showCalendar = prefs.getBool('showCalendar') ?? true;
      _compactView = prefs.getBool('compactView') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    await prefs.setBool('enableAttendanceMessage', _enableAttendanceMessage);
    await prefs.setString('attendanceMessage', _attendanceMessage);
    await prefs.setBool('showTodayCard', _showTodayCard);
    await prefs.setBool('showCalendar', _showCalendar);
    await prefs.setBool('compactView', _compactView);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('saved')),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings['uz']?[key] ??
        key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _translate('settings'),
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: primaryColor),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              _translate('save'),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildGeneralSection(),
              SizedBox(height: 24),
              _buildAttendanceSection(),
              SizedBox(height: 24),
              _buildHomeCustomizationSection(),
              SizedBox(height: 24),
              _buildAboutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return _buildSection(
      title: _translate('general'),
      icon: CupertinoIcons.settings,
      children: [
        _buildLanguageSelector(),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    return _buildSection(
      title: _translate('attendance_settings'),
      icon: CupertinoIcons.clock,
      children: [
        _buildSwitchTile(
          title: _translate('enable_message'),
          value: _enableAttendanceMessage,
          onChanged: (value) {
            setState(() => _enableAttendanceMessage = value);
          },
        ),
        if (_enableAttendanceMessage) ...[
          SizedBox(height: 16),
          _buildMessageInput(),
        ],
      ],
    );
  }

  Widget _buildHomeCustomizationSection() {
    return _buildSection(
      title: _translate('home_customization'),
      icon: CupertinoIcons.house,
      children: [
        _buildSwitchTile(
          title: _translate('show_today_card'),
          value: _showTodayCard,
          onChanged: (value) {
            setState(() => _showTodayCard = value);
          },
        ),
        SizedBox(height: 12),
        _buildSwitchTile(
          title: _translate('show_calendar'),
          value: _showCalendar,
          onChanged: (value) {
            setState(() => _showCalendar = value);
          },
        ),
        SizedBox(height: 12),
        _buildSwitchTile(
          title: _translate('compact_view'),
          value: _compactView,
          onChanged: (value) {
            setState(() => _compactView = value);
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: _translate('about'),
      icon: CupertinoIcons.info_circle,
      children: [
        _buildInfoTile(
          title: _translate('version'),
          value: '2.0.0',
          icon: CupertinoIcons.tag,
        ),
        SizedBox(height: 12),
        _buildInfoTile(
          title: _translate('app_info'),
          value: 'Davomat - By ModderBoy',
          icon: CupertinoIcons.device_phone_portrait,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.globe, color: primaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _translate('language'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentLanguage,
                icon: Icon(CupertinoIcons.chevron_down,
                    color: primaryColor, size: 16),
                items: [
                  DropdownMenuItem(
                      value: 'uz', child: Text(_translate('uzbek'))),
                  DropdownMenuItem(
                      value: 'en', child: Text(_translate('english'))),
                  DropdownMenuItem(
                      value: 'ru', child: Text(_translate('russian'))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _currentLanguage = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('attendance_message'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _attendanceMessage),
            onChanged: (value) => _attendanceMessage = value,
            decoration: InputDecoration(
              hintText: _translate('message_placeholder'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
}
