//account_page.dart
//F7BD41GB7E28HN6S85KZE731 - don't remove
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:DavomatYettilik/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modular UI Components (Cards and Buttons) - from your provided code
class MUILoginCard extends StatelessWidget {
  final Widget child;

  const MUILoginCard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.07,
          vertical: 24.0,
        ),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

enum FilterType { myself, allEmployees }

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? userName;
  String? userRole;
  String? userAvatarUrl;
  String message = '';
  FilterType _selectedFilter = FilterType.myself;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingProfile = false;
  bool _isLoadingEmployees = false;

  String _currentLanguage = 'uz';
  // Language Titles moved to _localizedStringsForAccount
  final Map<String, Map<String, String>> _localizedStringsForAccount = {
    'en': {
      'account_title': 'Account',
      'name_surname': 'Name and Surname:',
      'loading_username': 'Loading username...',
      'position': 'Position:',
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
    },
    'uz': {
      'account_title': 'Profil',
      'name_surname': 'Ism-familiya:',
      'loading_username': 'Foydalanuvchi nomi yuklanmoqda...',
      'position': 'Lavozim:',
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
    },
    'ru': {
      'account_title': 'Аккаунт',
      'name_surname': 'Имя и Фамилия:',
      'loading_username': 'Загрузка имени пользователя...',
      'position': 'Должность:',
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
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAccountPage();
  }

  Future<void> _initializeAccountPage() async {
    await _loadLanguagePreference();
    await _loadCachedUserData(); // Load cached data first
    _loadInitialData(); // Then attempt to load fresh data
  }

  void _loadInitialData() {
    if (_selectedFilter == FilterType.myself) {
      _loadUserData();
    } else {
      _loadAllEmployees();
    }
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
    return _localizedStringsForAccount[_currentLanguage]?[key] ??
        _localizedStringsForAccount['uz']![key]!;
  }

  Future<void> _loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        userName = prefs.getString('userName');
        userRole = prefs.getString('userRole');
        userAvatarUrl = prefs.getString('userAvatarUrl');
        if (userName == null && _selectedFilter == FilterType.myself) {
          // Only show this specific message if 'myself' is selected and cache is empty
          message = _translate('user_data_not_found');
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
      // Keep existing message if loading from cache, otherwise show loading
      if (userName == null) message = _translate('loading_username');
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            message = _translate(
                'error_loading_user_data'); // Or "User not logged in"
            _isLoadingProfile = false;
          });
        }
        return;
      }
      print('Foydalanuvchi ID: $userId');

      final response = await supabase
          .from('users')
          .select('name, lavozim, avatar')
          .eq('id', userId)
          .single();

      print('Supabase javobi: $response');

      if (mounted) {
        setState(() {
          userName = response['name'] as String?;
          userRole = response['lavozim'] as String?;
          userAvatarUrl = response['avatar'] as String?;
          message = ''; // Clear error/loading message on success
          _isLoadingProfile = false;
        });
        _cacheUserData();
      }
    } catch (error) {
      print("Foydalanuvchi ma'lumotlarini yuklashda xatolik: $error");
      if (mounted) {
        setState(() {
          // Only set error if not already showing cached data or "user_data_not_found"
          if (userName == null) message = _translate('error_loading_user_data');
          // Don't clear cached data on error, let it persist for offline
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadAllEmployees() async {
    if (!mounted) return;
    setState(() {
      _isLoadingEmployees = true;
      _employees = [];
      message = _translate('loading_employees');
    });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted)
          setState(() {
            message = _translate('error_loading_employees_data');
            _isLoadingEmployees = false;
          });
        return;
      }
      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .single();

      final companyId = userResponse['company_id'];
      if (companyId == null) {
        if (mounted)
          setState(() {
            message = _translate('no_company_for_employees');
            _isLoadingEmployees = false;
          });
        return;
      }
      print('Company ID: $companyId');

      final response = await supabase
          .from('users')
          .select('name, lavozim, avatar')
          .eq('company_id', companyId)
          .eq('is_super_admin', false);

      print('All employees Supabase response: $response');

      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(response);
          message = '';
          _isLoadingEmployees = false;
        });
      }
    } catch (error) {
      print("Xodimlar ma'lumotlarini yuklashda xatolik: $error");
      if (mounted) {
        setState(() {
          message = _translate(
              'no_internet_employees'); // More specific error for likely offline
          _employees = [];
          _isLoadingEmployees = false;
        });
      }
    }
  }

  Future<void> _cacheUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null)
      await prefs.setString('userName', userName!);
    else
      await prefs.remove('userName');
    if (userRole != null)
      await prefs.setString('userRole', userRole!);
    else
      await prefs.remove('userRole');
    if (userAvatarUrl != null)
      await prefs.setString('userAvatarUrl', userAvatarUrl!);
    else
      await prefs.remove('userAvatarUrl');
  }

  Widget _employeeListWidget() {
    if (_isLoadingEmployees) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (message.isNotEmpty && _selectedFilter == FilterType.allEmployees) {
      // Show message only if it's for 'all_employees'
      // Check if the message is specifically an error related to loading employees.
      bool isEmployeeLoadingError =
          message == _translate('error_loading_employees_data') ||
              message == _translate('no_internet_employees') ||
              message == _translate('no_company_for_employees');
      if (isEmployeeLoadingError) {
        return Center(
            child: Text(message,
                style: TextStyle(color: CupertinoColors.systemRed)));
      }
    }
    if (_employees.isEmpty) {
      return Center(child: Text(_translate('loading_employees')));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        return CupertinoListTile(
          leading: employee['avatar'] != null &&
                  (employee['avatar'] as String).isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    employee['avatar'] as String,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(CupertinoIcons.person_circle_fill, size: 40),
                  ),
                )
              : const Icon(CupertinoIcons.person_circle_fill, size: 40),
          title: Text(employee['name'] as String? ?? 'No Name'),
          subtitle: Text(employee['lavozim'] as String? ?? 'No Position'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;
    final secondaryTextColor = isDarkMode
        ? CupertinoColors.white.withOpacity(0.8)
        : CupertinoColors.black.withOpacity(0.8);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_translate('account_title')),
        backgroundColor: theme.barBackgroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: CupertinoSegmentedControl<FilterType>(
                groupValue: _selectedFilter,
                onValueChanged: (FilterType newValue) {
                  if (mounted) {
                    setState(() {
                      _selectedFilter = newValue;
                      message =
                          ''; // Clear general messages when switching tabs
                    });
                  }
                  if (newValue == FilterType.allEmployees) {
                    _loadAllEmployees();
                  } else {
                    _loadUserData(); // This will re-check cache and then fetch if needed
                  }
                },
                children: {
                  FilterType.myself: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(_translate('myself'),
                        style: TextStyle(fontSize: 16)),
                  ),
                  FilterType.allEmployees: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(_translate('all_employees'),
                        style: TextStyle(fontSize: 16)),
                  ),
                },
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_selectedFilter == FilterType.myself)
                        Column(
                          children: [
                            if (_isLoadingProfile &&
                                userName ==
                                    null) // Show loader only if no cached data
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CupertinoActivityIndicator(radius: 20),
                              )
                            else if (userName != null ||
                                userRole != null ||
                                userAvatarUrl !=
                                    null) // If any cached data exists, show card
                              MUILoginCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      userAvatarUrl != null &&
                                              userAvatarUrl!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(75),
                                              child: Image.network(
                                                userAvatarUrl!,
                                                width: 150,
                                                height: 150,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                        CupertinoIcons
                                                            .person_circle_fill,
                                                        size: 150,
                                                        color: CupertinoColors
                                                            .systemGrey),
                                              ),
                                            )
                                          : const Icon(
                                              CupertinoIcons.person_circle_fill,
                                              size: 150,
                                              color:
                                                  CupertinoColors.systemGrey),
                                      const SizedBox(height: 20),
                                      Text(_translate('name_surname'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 22,
                                              color: secondaryTextColor)),
                                      Text(
                                        userName ??
                                            _translate(
                                                'loading_username'), // Show loading if specifically null
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: textColor),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(_translate('position'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: secondaryTextColor)),
                                      Text(
                                        userRole ??
                                            _translate(
                                                'loading_position'), // Show loading if specifically null
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 24, color: textColor),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (message.isNotEmpty &&
                                message != _translate('loading_username') &&
                                message !=
                                    _translate(
                                        'loading_position')) // Show message if no data and not loading
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(message,
                                    style: TextStyle(
                                        color: CupertinoColors.systemRed,
                                        fontSize: 16),
                                    textAlign: TextAlign.center),
                              )
                          ],
                        )
                      else if (_selectedFilter == FilterType.allEmployees)
                        MUILoginCard(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                0), // MUILoginCard already has padding
                            child:
                                _employeeListWidget(), // This handles its own loading/error states
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
