import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:DavomatYettilik/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? userName;
  String? userEmail;
  String? userRole;
  String? userAvatarUrl;
  String? companyName;
  String message = '';
  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingProfile = false;
  bool _isLoadingEmployees = false;

  // Modern colors
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  String _currentLanguage = 'uz';
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'profile': 'Profile',
      'loading': 'Loading...',
      'error_loading_data': 'Error loading data',
      'company_employees': 'Company Employees',
      'no_employees': 'No employees found',
      'settings': 'Settings',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'rate_us': 'Rate Us',
      'logout': 'Logout',
      'version': 'Version',
      'position': 'Position',
      'email': 'Email',
      'company': 'Company',
      'name_surname': 'Name and Surname',
      'loading_username': 'Loading username...',
      'loading_position': 'Loading position...',
      'error_loading_user_data': 'Error loading user data!',
      'myself': 'Myself',
      'all_employees': 'All Employees',
      'error_loading_employees_data': 'Error loading employees data!',
      'loading_employees': 'Loading employees...',
      'user_data_not_found': 'User data not found for offline display.',
      'no_internet_employees':
          'No internet to load employees. Please connect and retry.',
      'no_company_for_employees':
          'Cannot load employees, user not assigned to a company.',
      'account_title': 'Account',
      'user_profile': 'User Profile',
      'personal_info': 'Personal Information',
      'work_info': 'Work Information',
      'quick_actions': 'Quick Actions',
      'app_settings': 'App Settings',
      'support': 'Support & Feedback',
      'about_app': 'About App',
      'contact_admin': 'Contact Administrator',
      'help_center': 'Help Center',
      'report_issue': 'Report an Issue',
      'app_version': 'App Version',
      'build_number': 'Build Number',
      'last_updated': 'Last Updated',
      'developer': 'Developer',
      'copyright': '© 2024 Modern Attendance System',
    },
    'uz': {
      'profile': 'Profil',
      'loading': 'Yuklanmoqda...',
      'error_loading_data': 'Ma\'lumotlarni yuklashda xatolik',
      'company_employees': 'Kompaniya xodimlari',
      'no_employees': 'Xodimlar topilmadi',
      'settings': 'Sozlamalar',
      'privacy_policy': 'Maxfiylik siyosati',
      'terms_of_service': 'Foydalanish shartlari',
      'rate_us': 'Baholang',
      'logout': 'Chiqish',
      'version': 'Versiya',
      'position': 'Lavozim',
      'email': 'Email',
      'company': 'Kompaniya',
      'name_surname': 'Ism-familiya',
      'loading_username': 'Foydalanuvchi nomi yuklanmoqda...',
      'loading_position': 'Lavozim yuklanmoqda...',
      'error_loading_user_data':
          'Foydalanuvchi ma\'lumotlarini yuklashda xatolik!',
      'myself': 'O\'zim',
      'all_employees': 'Barcha xodimlar',
      'error_loading_employees_data':
          'Xodimlar ma\'lumotlarini yuklashda xatolik!',
      'loading_employees': 'Xodimlar yuklanmoqda...',
      'user_data_not_found':
          'Oflayn rejim uchun foydalanuvchi ma\'lumotlari topilmadi.',
      'no_internet_employees':
          'Xodimlarni yuklash uchun internet yo\'q. Iltimos ulaning va qayta urinib ko\'ring.',
      'no_company_for_employees':
          'Xodimlarni yuklab bo\'lmadi, foydalanuvchi kompaniyaga biriktirilmagan.',
      'account_title': 'Hisob',
      'user_profile': 'Foydalanuvchi profili',
      'personal_info': 'Shaxsiy ma\'lumotlar',
      'work_info': 'Ish ma\'lumotlari',
      'quick_actions': 'Tezkor amallar',
      'app_settings': 'Ilova sozlamalari',
      'support': 'Yordam va fikr-mulohaza',
      'about_app': 'Ilova haqida',
      'contact_admin': 'Administrator bilan bog\'lanish',
      'help_center': 'Yordam markazi',
      'report_issue': 'Muammo haqida xabar berish',
      'app_version': 'Ilova versiyasi',
      'build_number': 'Build raqami',
      'last_updated': 'Oxirgi yangilanish',
      'developer': 'Dasturchi',
      'copyright': '© 2024 Zamonaviy Davomat Tizimi',
    },
    'ru': {
      'profile': 'Профиль',
      'loading': 'Загрузка...',
      'error_loading_data': 'Ошибка загрузки данных',
      'company_employees': 'Сотрудники компании',
      'no_employees': 'Сотрудники не найдены',
      'settings': 'Настройки',
      'privacy_policy': 'Политика конфиденциальности',
      'terms_of_service': 'Условия использования',
      'rate_us': 'Оценить нас',
      'logout': 'Выйти',
      'version': 'Версия',
      'position': 'Должность',
      'email': 'Email',
      'company': 'Компания',
      'name_surname': 'Имя и Фамилия',
      'loading_username': 'Загрузка имени пользователя...',
      'loading_position': 'Загрузка должности...',
      'error_loading_user_data': 'Ошибка загрузки данных пользователя!',
      'myself': 'Я',
      'all_employees': 'Все сотрудники',
      'error_loading_employees_data': 'Ошибка загрузки данных сотрудников!',
      'loading_employees': 'Загрузка сотрудников...',
      'user_data_not_found':
          'Данные пользователя не найдены для отображения в офлайн-режиме.',
      'no_internet_employees':
          'Нет интернета для загрузки сотрудников. Пожалуйста, подключитесь и повторите попытку.',
      'no_company_for_employees':
          'Не удается загрузить сотрудников, пользователь не привязан к компании.',
      'account_title': 'Аккаунт',
      'user_profile': 'Профиль пользователя',
      'personal_info': 'Личная информация',
      'work_info': 'Рабочая информация',
      'quick_actions': 'Быстрые действия',
      'app_settings': 'Настройки приложения',
      'support': 'Поддержка и отзывы',
      'about_app': 'О приложении',
      'contact_admin': 'Связаться с администратором',
      'help_center': 'Центр помощи',
      'report_issue': 'Сообщить о проблеме',
      'app_version': 'Версия приложения',
      'build_number': 'Номер сборки',
      'last_updated': 'Последнее обновление',
      'developer': 'Разработчик',
      'copyright': '© 2024 Современная система посещаемости',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadLanguagePreference();
    await _loadUserProfile();
    await _loadCompanyEmployees();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentLanguage = prefs.getString('language') ?? 'uz';
      });
    }
  }

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings['uz']?[key] ??
        key;
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoadingProfile = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userResponse = await supabase
          .from('users')
          .select('full_name, email, position, profile_image, company_id')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse != null) {
        final companyId = userResponse['company_id'];
        String? fetchedCompanyName;

        if (companyId != null) {
          final companyResponse = await supabase
              .from('companies')
              .select('company_name')
              .eq('id', companyId)
              .maybeSingle();
          fetchedCompanyName = companyResponse?['company_name'];
        }

        if (mounted) {
          setState(() {
            userName = userResponse['full_name'];
            userEmail = userResponse['email'];
            userRole = userResponse['position'];
            userAvatarUrl = userResponse['profile_image'];
            companyName = fetchedCompanyName;
          });
        }
      }
    } catch (e) {
      print("Error loading user profile: $e");
      if (mounted) {
        setState(() => message = _translate('error_loading_data'));
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadCompanyEmployees() async {
    if (!mounted) return;
    setState(() => _isLoadingEmployees = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      final companyId = userResponse?['company_id'];
      if (companyId == null) return;

      final employeesResponse = await supabase
          .from('users')
          .select('full_name, email, position, profile_image')
          .eq('company_id', companyId)
          .neq('id', userId);

      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(employeesResponse);
        });
      }
    } catch (e) {
      print("Error loading employees: $e");
    } finally {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // The main app will handle navigation
    } catch (e) {
      print('Logout error: $e');
    }
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
          _translate('profile'),
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            icon: Icon(CupertinoIcons.settings, color: primaryColor),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingProfile
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    SizedBox(height: 24),
                    _buildCompanyEmployeesSection(),
                    SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(24),
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
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: userAvatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      userAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          SizedBox(height: 16),
          Text(
            userName ?? 'User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          if (userEmail != null) ...[
            SizedBox(height: 4),
            Text(
              userEmail!,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
          SizedBox(height: 16),
          _buildInfoRow(CupertinoIcons.briefcase, _translate('position'),
              userRole ?? 'N/A'),
          if (companyName != null) ...[
            SizedBox(height: 12),
            _buildInfoRow(CupertinoIcons.building_2_fill, _translate('company'),
                companyName!),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        CupertinoIcons.person_fill,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 16),
          ),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildCompanyEmployeesSection() {
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
                  CupertinoIcons.group,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                _translate('company_employees'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_isLoadingEmployees)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          else if (_employees.isEmpty)
            Center(
              child: Text(
                _translate('no_employees'),
                style: TextStyle(color: textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _employees.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final employee = _employees[index];
                return _buildEmployeeCard(employee);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: employee['profile_image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      employee['profile_image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          CupertinoIcons.person_fill,
                          color: Colors.white,
                          size: 24),
                    ),
                  )
                : Icon(CupertinoIcons.person_fill,
                    color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee['full_name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (employee['position'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    employee['position'],
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
        children: [
          _buildActionButton(
            icon: CupertinoIcons.settings,
            title: _translate('settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          SizedBox(height: 12),
          _buildActionButton(
            icon: CupertinoIcons.doc_text,
            title: _translate('privacy_policy'),
            onTap: () {
              // Handle privacy policy
            },
          ),
          SizedBox(height: 12),
          _buildActionButton(
            icon: CupertinoIcons.doc_checkmark,
            title: _translate('terms_of_service'),
            onTap: () {
              // Handle terms of service
            },
          ),
          SizedBox(height: 12),
          _buildActionButton(
            icon: CupertinoIcons.star,
            title: _translate('rate_us'),
            onTap: () {
              // Handle rate us
            },
          ),
          SizedBox(height: 12),
          _buildActionButton(
            icon: CupertinoIcons.square_arrow_right,
            title: _translate('logout'),
            onTap: _logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : textPrimary,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
