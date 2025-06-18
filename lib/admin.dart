import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:DavomatYettilik/main.dart';
import 'package:DavomatYettilik/settings_page.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  int _currentTab = 0;
  late TabController _tabController;
  
  // Modern colors
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // Data
  String? _companyName;
  String? _companyLogo;
  double _balance = 0.0;
  int _employeeCount = 0;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendanceData = [];
  DateTime _selectedDate = DateTime.now();
  String _attendanceFilter = 'Barchasi';
  
  // Company settings
  TimeOfDay _arrivalTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _departureTime = TimeOfDay(hour: 18, minute: 0);
  int _graceMinutes = 15;
  
  // Loading states
  bool _isLoading = true;
  bool _isUploadingLogo = false;
  
  String _currentLanguage = 'uz';
  
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'admin_panel': 'Admin Panel',
      'dashboard': 'Dashboard',
      'employees': 'Employees',
      'attendance': 'Attendance',
      'settings': 'Settings',
      'company_info': 'Company Information',
      'balance': 'Balance',
      'employee_count': 'Employees',
      'upload_logo': 'Upload Logo',
      'change_logo': 'Change Logo',
      'remove_logo': 'Remove Logo',
      'arrival_time': 'Arrival Time',
      'departure_time': 'Departure Time',
      'grace_period': 'Grace Period (minutes)',
      'save_settings': 'Save Settings',
      'attendance_filter': 'Filter',
      'all': 'All',
      'present': 'Present',
      'absent': 'Absent',
      'late': 'Late',
      'loading': 'Loading...',
      'no_data': 'No data available',
      'success': 'Success',
      'error': 'Error',
      'settings_saved': 'Settings saved successfully',
      'logo_uploaded': 'Logo uploaded successfully',
      'logo_removed': 'Logo removed successfully',
      'select_date': 'Select Date',
      'employee_name': 'Employee Name',
      'check_in': 'Check In',
      'check_out': 'Check Out',
      'status': 'Status',
      'late_minutes': 'Late (min)',
      'search_employees': 'Search employees...',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'logout': 'Logout',
    },
    'uz': {
      'admin_panel': 'Admin Panel',
      'dashboard': 'Boshqaruv',
      'employees': 'Xodimlar',
      'attendance': 'Davomat',
      'settings': 'Sozlamalar',
      'company_info': 'Kompaniya ma\'lumotlari',
      'balance': 'Balans',
      'employee_count': 'Xodimlar',
      'upload_logo': 'Logo yuklash',
      'change_logo': 'Logo o\'zgartirish',
      'remove_logo': 'Logo o\'chirish',
      'arrival_time': 'Kelish vaqti',
      'departure_time': 'Ketish vaqti',
      'grace_period': 'Hisobsiz vaqt (minut)',
      'save_settings': 'Sozlamalarni saqlash',
      'attendance_filter': 'Filter',
      'all': 'Barchasi',
      'present': 'Kelgan',
      'absent': 'Kelmagan',
      'late': 'Kechikkan',
      'loading': 'Yuklanmoqda...',
      'no_data': 'Ma\'lumot yo\'q',
      'success': 'Muvaffaqiyat',
      'error': 'Xatolik',
      'settings_saved': 'Sozlamalar saqlandi',
      'logo_uploaded': 'Logo yuklandi',
      'logo_removed': 'Logo o\'chirildi',
      'select_date': 'Sana tanlash',
      'employee_name': 'Xodim nomi',
      'check_in': 'Kelish',
      'check_out': 'Ketish',
      'status': 'Holat',
      'late_minutes': 'Kechikish (min)',
      'search_employees': 'Xodimlarni qidirish...',
      'notifications': 'Bildirishnomalar',
      'profile': 'Profil',
      'logout': 'Chiqish',
    },
    'ru': {
      'admin_panel': 'Админ Панель',
      'dashboard': 'Панель управления',
      'employees': 'Сотрудники',
      'attendance': 'Посещаемость',
      'settings': 'Настройки',
      'company_info': 'Информация о компании',
      'balance': 'Баланс',
      'employee_count': 'Сотрудники',
      'upload_logo': 'Загрузить логотип',
      'change_logo': 'Изменить логотип',
      'remove_logo': 'Удалить логотип',
      'arrival_time': 'Время прихода',
      'departure_time': 'Время ухода',
      'grace_period': 'Льготное время (минуты)',
      'save_settings': 'Сохранить настройки',
      'attendance_filter': 'Фильтр',
      'all': 'Все',
      'present': 'Присутствовал',
      'absent': 'Отсутствовал',
      'late': 'Опоздал',
      'loading': 'Загрузка...',
      'no_data': 'Нет данных',
      'success': 'Успех',
      'error': 'Ошибка',
      'settings_saved': 'Настройки сохранены',
      'logo_uploaded': 'Логотип загружен',
      'logo_removed': 'Логотип удален',
      'select_date': 'Выбрать дату',
      'employee_name': 'Имя сотрудника',
      'check_in': 'Приход',
      'check_out': 'Уход',
      'status': 'Статус',
      'late_minutes': 'Опоздание (мин)',
      'search_employees': 'Поиск сотрудников...',
      'notifications': 'Уведомления',
      'profile': 'Профиль',
      'logout': 'Выйти',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLanguagePreference();
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'uz';
    });
  }

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings['uz']?[key] ??
        key;
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get user's company
      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      final companyId = userResponse?['company_id'];
      if (companyId == null) return;

      // Get company info
      final companyResponse = await supabase
          .from('companies')
          .select('company_name, logo_url, kelish_vaqti, ketish_vaqti, hisobsiz_vaqt')
          .eq('id', companyId)
          .maybeSingle();

      if (companyResponse != null) {
        setState(() {
          _companyName = companyResponse['company_name'];
          _companyLogo = companyResponse['logo_url'];
          
          // Parse time settings
          if (companyResponse['kelish_vaqti'] != null) {
            final arrivalParts = companyResponse['kelish_vaqti'].split(':');
            _arrivalTime = TimeOfDay(
              hour: int.parse(arrivalParts[0]),
              minute: int.parse(arrivalParts[1]),
            );
          }
          
          if (companyResponse['ketish_vaqti'] != null) {
            final departureParts = companyResponse['ketish_vaqti'].split(':');
            _departureTime = TimeOfDay(
              hour: int.parse(departureParts[0]),
              minute: int.parse(departureParts[1]),
            );
          }
          
          _graceMinutes = companyResponse['hisobsiz_vaqt'] ?? 15;
        });
      }

      // Get balance
      final detailsResponse = await supabase
          .from('details')
          .select('balance')
          .eq('company_id', companyId)
          .maybeSingle();

      if (detailsResponse != null) {
        setState(() {
          _balance = (detailsResponse['balance'] as num?)?.toDouble() ?? 0.0;
        });
      }

      // Get employees
      final employeesResponse = await supabase
          .from('users')
          .select('id, full_name, email, position, profile_image')
          .eq('company_id', companyId)
          .neq('is_super_admin', true);

      setState(() {
        _employees = List<Map<String, dynamic>>.from(employeesResponse);
        _employeeCount = _employees.length;
      });

      // Load attendance for selected date
      await _loadAttendanceData();

    } catch (e) {
      print('Error loading admin data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendanceData() async {
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

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final attendanceResponse = await supabase
          .from('davomat')
          .select('''
            xodim_id,
            kelish_vaqti,
            ketish_vaqti,
            status,
            kechikish_minut,
            users!davomat_xodim_id_fkey(full_name)
          ''')
          .eq('company_id', companyId)
          .eq('kelish_sana', dateStr);

      setState(() {
        _attendanceData = List<Map<String, dynamic>>.from(attendanceResponse);
      });

    } catch (e) {
      print('Error loading attendance data: $e');
    }
  }

  Future<void> _uploadLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploadingLogo = true);

        final file = result.files.first;
        final fileName = 'company_logo/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        
        Uint8List? fileBytes;
        if (kIsWeb) {
          fileBytes = file.bytes;
        } else {
          fileBytes = await File(file.path!).readAsBytes();
        }

        if (fileBytes != null) {
          // Upload to Supabase Storage
          await supabase.storage
              .from('photos')
              .uploadBinary(fileName, fileBytes);

          // Get public URL
          final logoUrl = supabase.storage
              .from('photos')
              .getPublicUrl(fileName);

          // Update company record
          final userId = supabase.auth.currentUser?.id;
          final userResponse = await supabase
              .from('users')
              .select('company_id')
              .eq('id', userId!)
              .maybeSingle();

          final companyId = userResponse?['company_id'];
          if (companyId != null) {
            await supabase
                .from('companies')
                .update({'logo_url': logoUrl})
                .eq('id', companyId);

            setState(() {
              _companyLogo = logoUrl;
            });

            _showSnackBar(_translate('logo_uploaded'), isSuccess: true);
          }
        }
      }
    } catch (e) {
      print('Error uploading logo: $e');
      _showSnackBar(_translate('error'), isSuccess: false);
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId!)
          .maybeSingle();

      final companyId = userResponse?['company_id'];
      if (companyId != null) {
        await supabase
            .from('companies')
            .update({'logo_url': null})
            .eq('id', companyId);

        setState(() {
          _companyLogo = null;
        });

        _showSnackBar(_translate('logo_removed'), isSuccess: true);
      }
    } catch (e) {
      print('Error removing logo: $e');
      _showSnackBar(_translate('error'), isSuccess: false);
    }
  }

  Future<void> _saveCompanySettings() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId!)
          .maybeSingle();

      final companyId = userResponse?['company_id'];
      if (companyId != null) {
        await supabase
            .from('companies')
            .update({
              'kelish_vaqti': '${_arrivalTime.hour.toString().padLeft(2, '0')}:${_arrivalTime.minute.toString().padLeft(2, '0')}:00',
              'ketish_vaqti': '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}:00',
              'hisobsiz_vaqt': _graceMinutes,
            })
            .eq('id', companyId);

        _showSnackBar(_translate('settings_saved'), isSuccess: true);
      }
    } catch (e) {
      print('Error saving settings: $e');
      _showSnackBar(_translate('error'), isSuccess: false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? successColor : errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Navigation will be handled by main app
    } catch (e) {
      print('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDashboard(),
                        _buildEmployees(),
                        _buildAttendance(),
                        _buildSettings(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: BoxDecoration(
        color: cardColor,
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
          // Top row with company info and actions
          Row(
            children: [
              // Company logo and name
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: _companyLogo == null
                          ? LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: _companyLogo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _companyLogo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(CupertinoIcons.building_2_fill,
                                      color: Colors.white, size: 20),
                            ),
                          )
                        : Icon(CupertinoIcons.building_2_fill,
                            color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _companyName ?? 'Company',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '\$${_balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              // Action buttons
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Search functionality
                    },
                    icon: Icon(CupertinoIcons.search, color: textSecondary),
                  ),
                  IconButton(
                    onPressed: () {
                      // Notifications
                    },
                    icon: Icon(CupertinoIcons.bell, color: textSecondary),
                  ),
                  PopupMenuButton(
                    icon: Icon(CupertinoIcons.person_circle, color: textSecondary),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.person, size: 16),
                            SizedBox(width: 8),
                            Text(_translate('profile')),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingsPage()),
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.square_arrow_right, size: 16, color: errorColor),
                            SizedBox(width: 8),
                            Text(_translate('logout'), style: TextStyle(color: errorColor)),
                          ],
                        ),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: textSecondary,
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              tabs: [
                Tab(text: _translate('dashboard')),
                Tab(text: _translate('employees')),
                Tab(text: _translate('attendance')),
                Tab(text: _translate('settings')),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: _translate('balance'),
                  value: '\$${_balance.toStringAsFixed(2)}',
                  icon: CupertinoIcons.money_dollar_circle,
                  color: successColor,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: _translate('employee_count'),
                  value: _employeeCount.toString(),
                  icon: CupertinoIcons.group,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Quick attendance overview
          _buildTodayAttendanceCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceCard() {
    final todayAttendance = _attendanceData.where((attendance) {
      final attendanceDate = DateTime.parse(attendance['kelish_vaqti'] ?? DateTime.now().toIso8601String());
      return DateFormat('yyyy-MM-dd').format(attendanceDate) == 
             DateFormat('yyyy-MM-dd').format(DateTime.now());
    }).toList();

    final presentCount = todayAttendance.where((a) => a['status'] == 'kelgan' || a['status'] == 'kechikkan').length;
    final lateCount = todayAttendance.where((a) => a['status'] == 'kechikkan').length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
              Icon(CupertinoIcons.calendar_today, color: primaryColor),
              SizedBox(width: 8),
              Text(
                'Bugungi davomat',
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
                child: _buildMiniStatCard(
                  title: _translate('present'),
                  value: presentCount.toString(),
                  color: successColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  title: _translate('late'),
                  value: lateCount.toString(),
                  color: warningColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  title: _translate('absent'),
                  value: (_employeeCount - presentCount).toString(),
                  color: errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployees() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(20),
          child: TextField(
            decoration: InputDecoration(
              hintText: _translate('search_employees'),
              prefixIcon: Icon(CupertinoIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: backgroundColor,
            ),
          ),
        ),
        // Employees list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _employees.length,
            itemBuilder: (context, index) {
              final employee = _employees[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 1),
                    ),
                  ],
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
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(CupertinoIcons.person_fill,
                                        color: Colors.white, size: 24),
                              ),
                            )
                          : Icon(CupertinoIcons.person_fill,
                              color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee['full_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          if (employee['position'] != null) ...[
                            SizedBox(height: 4),
                            Text(
                              employee['position'],
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                          if (employee['email'] != null) ...[
                            SizedBox(height: 4),
                            Text(
                              employee['email'],
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendance() {
    return Column(
      children: [
        // Date selector and filter
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                      await _loadAttendanceData();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar, color: primaryColor),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('dd.MM.yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _attendanceFilter,
                    items: ['Barchasi', 'Kelgan', 'Kelmagan', 'Kechikkan']
                        .map((filter) => DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _attendanceFilter = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Attendance list
        Expanded(
          child: _attendanceData.isEmpty
              ? Center(
                  child: Text(
                    _translate('no_data'),
                    style: TextStyle(color: textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _attendanceData.length,
                  itemBuilder: (context, index) {
                    final attendance = _attendanceData[index];
                    final user = attendance['users'];
                    
                    // Apply filter
                    if (_attendanceFilter != 'Barchasi') {
                      final status = attendance['status'] ?? 'kelmagan';
                      if (_attendanceFilter == 'Kelgan' && status != 'kelgan') return SizedBox.shrink();
                      if (_attendanceFilter == 'Kechikkan' && status != 'kechikkan') return SizedBox.shrink();
                      if (_attendanceFilter == 'Kelmagan' && status != 'kelmagan') return SizedBox.shrink();
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user?['full_name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              _buildStatusChip(attendance['status']),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeInfo(
                                  _translate('check_in'),
                                  attendance['kelish_vaqti'],
                                  CupertinoIcons.arrow_down_circle,
                                  successColor,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeInfo(
                                  _translate('check_out'),
                                  attendance['ketish_vaqti'],
                                  CupertinoIcons.arrow_up_circle,
                                  warningColor,
                                ),
                              ),
                            ],
                          ),
                          if (attendance['kechikish_minut'] != null && attendance['kechikish_minut'] > 0) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.clock, color: errorColor, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    '${_translate('late_minutes')}: ${attendance['kechikish_minut']}',
                                    style: TextStyle(
                                      color: errorColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String text;
    
    switch (status) {
      case 'kelgan':
        color = successColor;
        text = _translate('present');
        break;
      case 'kechikkan':
        color = warningColor;
        text = _translate('late');
        break;
      default:
        color = errorColor;
        text = _translate('absent');
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String? time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            time != null 
                ? DateFormat('HH:mm').format(DateTime.parse(time))
                : '--:--',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Company logo section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
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
                Text(
                  _translate('company_info'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _companyLogo == null
                              ? LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: _companyLogo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _companyLogo!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(CupertinoIcons.building_2_fill,
                                          color: Colors.white, size: 40),
                                ),
                              )
                            : Icon(CupertinoIcons.building_2_fill,
                                color: Colors.white, size: 40),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_companyLogo == null) ...[
                            ElevatedButton.icon(
                              onPressed: _isUploadingLogo ? null : _uploadLogo,
                              icon: _isUploadingLogo
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Icon(CupertinoIcons.cloud_upload),
                              label: Text(_translate('upload_logo')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              onPressed: _isUploadingLogo ? null : _uploadLogo,
                              icon: Icon(CupertinoIcons.pencil),
                              label: Text(_translate('change_logo')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _removeLogo,
                              icon: Icon(CupertinoIcons.trash, color: errorColor),
                              label: Text(_translate('remove_logo')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: errorColor,
                                side: BorderSide(color: errorColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Time settings
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
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
                Text(
                  'Ish vaqti sozlamalari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                _buildTimeSetting(
                  _translate('arrival_time'),
                  _arrivalTime,
                  (time) => setState(() => _arrivalTime = time),
                ),
                SizedBox(height: 16),
                _buildTimeSetting(
                  _translate('departure_time'),
                  _departureTime,
                  (time) => setState(() => _departureTime = time),
                ),
                SizedBox(height: 16),
                _buildGracePeriodSetting(),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveCompanySettings,
                    child: Text(_translate('save_settings')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildTimeSetting(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (newTime != null) {
          onChanged(newTime);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.clock, color: primaryColor),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    time.format(context),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGracePeriodSetting() {
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
            _translate('grace_period'),
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _graceMinutes.toDouble(),
                  min: 0,
                  max: 60,
                  divisions: 12,
                  activeColor: primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _graceMinutes = value.round();
                    });
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_graceMinutes min',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}