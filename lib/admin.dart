// --- admin.dart ---
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as platform_io;
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:convert';
import 'admin_user_search.dart';
import 'app_bar/admin_info_custom_appbar.dart';
import 'apps.dart';
import 'webview_page.dart';
import 'widgets/custom_bottom_nav.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _logger = Logger();
  String? _companyName;
  bool _isLoading = true;
  double _balance = 0.0;
  int _employeeCount = 0;
  int _freeEmployeeLimit = 5;
  double _costPerExtraEmployee = 0.9;
  List<Map<String, dynamic>> _transactions = [];

  DateTime? _lastUpdated;
  String? _userEmail;
  String? _userId;
  String? _companyId;

  String _currentLanguage = 'uz';
  int _selectedIndex = 0;

  final Map<String, Map<String, String>> _localizedStrings = const {
    'en': {
      'company_name': 'Company Name',
      'balance': 'Balance',
      'deposit_funds': 'Deposit Funds',
      'admin_panel_title': "Admin Panel",
      'last_updated_data': 'Updated: {datetime}',
      'no_internet': 'No internet connection',
      'admin_panel_login': 'Admin Panel Login',
      'admin_credentials': 'Admin Credentials',
      'email': 'Email',
      'password': 'Password',
      'copied': 'Copied',
      'open': 'Open Website',
      'close': 'Close',
      'home': 'Home',
      'info': 'Info',
      'apps': 'Apps',
      'general_info': 'General Info',
      'user_email': 'User Email',
      'company_id': 'Company ID',
      'loading': 'Loading...',
      'company_id_not_found':
          'Company ID not found for user. Please contact support.',
      'refresh': 'Refresh',
      'admin_panel_webview_title': 'Admin Control Panel',
      'deposit_webview_title': 'Deposit Funds',
      'cached_data_notice': 'Displaying cached data. Connect to refresh.',
      'employees': 'Employees',
      'free_employees': 'Free employees: {count}',
      'paid_employees': 'Paid employees: {count}',
      'monthly_cost': 'Estimated monthly cost: \${cost}',
      'insufficient_balance_for_new_employee':
          'Insufficient balance to add new employees. Please deposit funds.',
      'cost_per_additional_employee':
          'Cost per additional employee: \${cost}/month',
      'total_employees': 'Total employees: {count}',
      'error_fetching_data': 'Error fetching data: {error}',
      'settings_not_found':
          'Billing details (cost per employee, free limit) not found. Contact support.',
      'transactions_history': 'Transactions History',
      'no_transactions_found': 'No transactions found.',
      'transaction_type': 'Type',
      'amount': 'Amount',
      'date': 'Date',
      'description': 'Description',
      'payment_method': 'Method',
      'status': 'Status',
      'error_fetching_transactions': 'Error fetching transactions: {error}',
    },
    'uz': {
      'company_name': 'Kompaniya nomi',
      'balance': 'Balans',
      'deposit_funds': 'Balansni To\'ldirish',
      'admin_panel_title': "Admin Panel",
      'last_updated_data': 'Yangilandi: {datetime}',
      'no_internet': 'Internet yo\'q',
      'admin_panel_login': 'Admin Kirish',
      'admin_credentials': 'Admin Ma\'lumotlari',
      'email': 'Email',
      'password': 'Parol',
      'copied': 'Nusxalandi',
      'open': 'Saytni Ochish',
      'close': 'Yopish',
      'home': 'Asosiy',
      'info': 'Ma\'lumot',
      'apps': 'Ilovalar',
      'general_info': 'Umumiy Ma\'lumot',
      'user_email': 'Foydalanuvchi Email',
      'company_id': 'Kompaniya IDsi',
      'loading': 'Yuklanmoqda...',
      'company_id_not_found':
          'Foydalanuvchi uchun Kompaniya ID topilmadi. Qo\'llab-quvvatlashga murojaat qiling.',
      'refresh': 'Yangilash',
      'admin_panel_webview_title': 'Admin Boshqaruv Paneli',
      'deposit_webview_title': 'Balansni To\'ldirish',
      'cached_data_notice':
          'Keshdagi ma\'lumotlar ko\'rsatilmoqda. Yangilash uchun internetga ulaning.',
      'employees': 'Xodimlar',
      'free_employees': 'Bepul xodimlar: {count} ta',
      'paid_employees': 'Pullik xodimlar: {count} ta',
      'monthly_cost': 'Taxminiy oylik xarajat: \${cost}',
      'insufficient_balance_for_new_employee':
          'Yangi xodim qo\'shish uchun balans yetarli emas. Iltimos, balansni to\'ldiring.',
      'cost_per_additional_employee':
          'Har bir qo\'shimcha xodim narxi: \${cost}/oyiga',
      'total_employees': 'Jami xodimlar: {count} ta',
      'error_fetching_data': 'Ma\'lumotlarni yuklashda xatolik: {error}',
      'settings_not_found':
          'Hisob-kitob ma\'lumotlari (xodim narxi, bepul limit) topilmadi. Qo\'llab-quvvatlashga murojaat qiling.',
      'transactions_history': 'Tranzaksiyalar Tarixi',
      'no_transactions_found': 'Tranzaksiyalar topilmadi.',
      'transaction_type': 'Turi',
      'amount': 'Miqdor',
      'date': 'Sana',
      'description': 'Tavsif',
      'payment_method': 'Usul',
      'status': 'Holati',
      'error_fetching_transactions':
          'Tranzaksiyalarni yuklashda xatolik: {error}',
    },
    'ru': {
      'company_name': 'Название компании',
      'balance': 'Баланс',
      'deposit_funds': 'Пополнить баланс',
      'admin_panel_title': "Панель Администратора",
      'last_updated_data': 'Обновлено: {datetime}',
      'no_internet': 'Нет интернета',
      'admin_panel_login': 'Вход Админа',
      'admin_credentials': 'Данные Админа',
      'email': 'Эл. адрес',
      'password': 'Пароль',
      'copied': 'Скопировано',
      'open': 'Открыть Сайт',
      'close': 'Закрыть',
      'home': 'Главная',
      'info': 'Инфо',
      'apps': 'Приложения',
      'general_info': 'Общая Инфо',
      'user_email': 'Email',
      'company_id': 'ID Компании',
      'loading': 'Загрузка...',
      'company_id_not_found':
          'ID Компании не найден для пользователя. Обратитесь в поддержку.',
      'refresh': 'Обновить',
      'admin_panel_webview_title': 'Панель Управления Администратора',
      'deposit_webview_title': 'Пополнить Баланс',
      'cached_data_notice':
          'Отображаются кэшированные данные. Подключитесь к интернету для обновления.',
      'employees': 'Сотрудники',
      'free_employees': 'Бесплатные сотрудники: {count}',
      'paid_employees': 'Платные сотрудники: {count}',
      'monthly_cost': 'Примерная месячная стоимость: \${cost}',
      'insufficient_balance_for_new_employee':
          'Недостаточно средств для добавления новых сотрудников. Пожалуйста, пополните баланс.',
      'cost_per_additional_employee':
          'Стоимость каждого дополнительного сотрудника: \${cost}/месяц',
      'total_employees': 'Всего сотрудников: {count}',
      'error_fetching_data': 'Ошибка загрузки данных: {error}',
      'settings_not_found':
          'Платежные данные (цена за сотрудника, бесплатный лимит) не найдены. Обратитесь в поддержку.',
      'transactions_history': 'История транзакций',
      'no_transactions_found': 'Транзакции не найдены.',
      'transaction_type': 'Тип',
      'amount': 'Сумма',
      'date': 'Дата',
      'description': 'Описание',
      'payment_method': 'Метод',
      'status': 'Статус',
      'error_fetching_transactions': 'Ошибка загрузки транзакций: {error}',
    },
  };

  String _infoFilter = 'Barchasi';
  final List<String> _infoFilterOptions = [
    'Barchasi',
    'Xodimlar',
    'Balans',
    'Tarix'
  ];

  String _translate(String key, [Map<String, dynamic>? params]) {
    final langKey =
        ['en', 'uz', 'ru'].contains(_currentLanguage) ? _currentLanguage : 'uz';
    String? translatedValue =
        _localizedStrings[langKey]?[key] ?? _localizedStrings['uz']?[key];
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
    tzdata.initializeTimeZones();
    _initializeAdminPage();
  }

  Future<void> _initializeAdminPage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _loadPreferences();
    await _fetchAdminData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('language') ?? 'uz';
      _userEmail = prefs.getString('cachedAdminUserEmail');
      _companyName = prefs.getString('cachedAdminCompanyName');
      _companyId = prefs.getString('cachedAdminCompanyId');
      _balance = prefs.getDouble('cachedAdminBalance') ?? 0.0;
      _employeeCount = prefs.getInt('cachedAdminEmployeeCount') ?? 0;
      _freeEmployeeLimit = prefs.getInt('cachedAdminFreeEmployeeLimit') ?? 5;
      _costPerExtraEmployee =
          prefs.getDouble('cachedAdminCostPerEmployee') ?? 0.9;
      _lastUpdated = prefs.getString('cachedAdminLastUpdated') != null
          ? DateTime.tryParse(prefs.getString('cachedAdminLastUpdated')!)
          : null;

      String? transactionsJson =
          prefs.getString('cachedAdminTransactions_${_companyId ?? ""}');
      if (transactionsJson != null) {
        try {
          _transactions =
              List<Map<String, dynamic>>.from(jsonDecode(transactionsJson));
        } catch (e) {
          _logger.e("Error decoding cached transactions: $e");
          _transactions = []; // Xatolikda bo'sh ro'yxat
        }
      } else {
        _transactions = [];
      }

      if (_companyId == null)
        _logger.i("AdminPage: No cached company ID found.");
    } catch (e, stackTrace) {
      _logger.e("AdminPage: Error loading preferences",
          error: e, stackTrace: stackTrace);
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveAdminDataToPrefs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_userEmail != null)
        await prefs.setString('cachedAdminUserEmail', _userEmail!);
      else
        await prefs.remove('cachedAdminUserEmail');
      if (_companyName != null)
        await prefs.setString('cachedAdminCompanyName', _companyName!);
      else
        await prefs.remove('cachedAdminCompanyName');
      if (_companyId != null)
        await prefs.setString('cachedAdminCompanyId', _companyId!);
      else
        await prefs.remove('cachedAdminCompanyId');
      await prefs.setDouble('cachedAdminBalance', _balance);
      await prefs.setInt('cachedAdminEmployeeCount', _employeeCount);
      await prefs.setInt('cachedAdminFreeEmployeeLimit', _freeEmployeeLimit);
      await prefs.setDouble(
          'cachedAdminCostPerEmployee', _costPerExtraEmployee);
      if (_lastUpdated != null)
        await prefs.setString(
            'cachedAdminLastUpdated', _lastUpdated!.toIso8601String());
      else
        await prefs.remove('cachedAdminLastUpdated');

      // Tranzaksiyalarni keshga saqlashda DateTime ni stringga o'tkazish
      List<Map<String, dynamic>> transactionsToCache = _transactions.map((tr) {
        Map<String, dynamic> newTr = Map.from(tr);
        if (newTr['created_at'] is DateTime) {
          newTr['created_at'] =
              (newTr['created_at'] as DateTime).toIso8601String();
        }
        return newTr;
      }).toList();
      if (_companyId != null) {
        await prefs.setString('cachedAdminTransactions_${_companyId!}',
            jsonEncode(transactionsToCache));
      } else {
        await prefs.remove(
            'cachedAdminTransactions_'); // Agar companyId bo'lmasa, umumiy keshni tozalash (yoki o'chirish)
      }
    } catch (e) {
      _logger.e("AdminPage: Error saving admin data to prefs: $e");
    }
  }

  Future<void> _setLanguagePreference(String language) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
      if (mounted) setState(() => _currentLanguage = language);
    } catch (e, stackTrace) {
      _logger.e("Error saving language", error: e, stackTrace: stackTrace);
    }
  }

  // --- admin.dart ---
// ... (yuqoridagi importlar va klass e'lonlari)

  Future<void> _fetchAdminData() async {
    if (!mounted) return;
    bool showLoadingIndicator = _companyId == null && _userEmail == null;
    if (showLoadingIndicator) setState(() => _isLoading = true);

    // Vaqtinchalik keshni saqlash (agar fetch xato bersa, qaytarish uchun)
    String? tempCompanyName = _companyName;
    String? tempCompanyId = _companyId;
    String? tempUserEmail = _userEmail;
    double tempBalance = _balance;
    int tempEmployeeCount = _employeeCount;
    int tempFreeLimit = _freeEmployeeLimit;
    double tempCostPerEmployee = _costPerExtraEmployee;
    DateTime? tempLastUpdated = _lastUpdated;
    List<Map<String, dynamic>> tempTransactions = List.from(_transactions);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");
      _userId = user.id;
      final currentUserEmail = user.email;

      final profileData = await Supabase.instance.client
          .from('users')
          .select('company_id')
          .eq('id', _userId!)
          .maybeSingle();

      final fetchedCompanyId = profileData?['company_id'] as String?;

      if (fetchedCompanyId == null) {
        _logger.w("No company_id found for user: $_userId");
        if (mounted) {
          setState(() {
            _companyName = "N/A";
            _companyId = null;
            _userEmail = currentUserEmail ?? _userEmail;
            _balance = 0.0;
            _employeeCount = 0;
            _lastUpdated = DateTime.now();
            _transactions = [];
          });
          _showErrorSnackbar(_translate('company_id_not_found'),
              isWarning: true);
        }
        await _saveAdminDataToPrefs(); // Keshni bo'sh holat bilan yangilash
        return;
      }

      // Ma'lumotlarni ketma-ket olish
      final settingsData = await Supabase.instance.client
          .from('details')
          .select('dollar_per_employee, free_employee_limit')
          .limit(1)
          .maybeSingle();

      final companyDetails = await Supabase.instance.client
          .from('companies')
          .select('company_name, balance')
          .eq('id', fetchedCompanyId)
          .single();

      final countResponse = await Supabase.instance.client
          .from('users')
          .count(CountOption.exact) // Bu to'g'ridan-to'g'ri int qaytaradi
          .eq('company_id', fetchedCompanyId)
          .eq('is_super_admin', false);

      final transactionsResponse = await Supabase.instance.client
          .from('transactions')
          .select() // Generic turini olib tashladik
          .eq('company_id', fetchedCompanyId)
          .order('created_at', ascending: false)
          .limit(20); // Natija List<dynamic> bo'ladi

      if (settingsData == null) {
        _logger.e("Billing details not found in 'details' table.");
        if (mounted) {
          _showErrorSnackbar(_translate('settings_not_found'), isWarning: true);
          // _freeEmployeeLimit va _costPerExtraEmployee allaqachon _loadPreferences da
          // keshdan yoki sukut bo'yicha o'rnatilgan, shuning uchun bu yerda
          // ularni qayta o'rnatish shart emas, agar serverdan kelmasa,
          // avvalgi (keshdagi/sukutdagi) qiymatlar ishlatiladi.
        }
      } else {
        // Agar serverdan qiymat kelsa, state o'zgaruvchilarini yangilaymiz
        _freeEmployeeLimit =
            (settingsData['free_employee_limit'] as num?)?.toInt() ??
                _freeEmployeeLimit;
        _costPerExtraEmployee =
            (settingsData['dollar_per_employee'] as num?)?.toDouble() ??
                _costPerExtraEmployee;
      }

      if (mounted) {
        setState(() {
          _companyName = companyDetails['company_name'] as String?;
          _companyId = fetchedCompanyId;
          _userEmail = currentUserEmail ?? _userEmail;
          _balance = (companyDetails['balance'] as num?)?.toDouble() ?? 0.0;
          _employeeCount = countResponse; // Bu endi to'g'ridan-to'g'ri int
          // transactionsResponse List<dynamic> bo'lgani uchun List<Map<String, dynamic>> ga o'tkazamiz
          _transactions = List<Map<String, dynamic>>.from(
              transactionsResponse as List? ?? []);
          _lastUpdated = DateTime.now();
        });
      }
      await _saveAdminDataToPrefs(); // Yangi ma'lumotlarni keshga saqlash
    } catch (e, stacktrace) {
      _logger.e('Error in _fetchAdminData', error: e, stackTrace: stacktrace);
      if (mounted) {
        _showErrorSnackbar(_translate('cached_data_notice'), isWarning: true);
        // Xatolikda eski keshni tiklash
        setState(() {
          _companyName = tempCompanyName;
          _companyId = tempCompanyId;
          _userEmail = tempUserEmail;
          _balance = tempBalance;
          _employeeCount = tempEmployeeCount;
          _freeEmployeeLimit = tempFreeLimit;
          _costPerExtraEmployee = tempCostPerEmployee;
          _transactions = tempTransactions;
          _lastUpdated = tempLastUpdated;
        });
      }
    } finally {
      if (mounted && showLoadingIndicator) {
        setState(() => _isLoading = false);
      } else if (mounted) {
        // Agar showLoadingIndicator false bo'lsa ham, setState chaqirish
        // keshdan yuklangan ma'lumotlar bilan UI ning yangilanishini ta'minlashi mumkin.
        setState(() {});
      }
    }
  }

  // ... (qolgan metodlar va build metodi)

  void _showErrorSnackbar(String message, {bool isWarning = false}) {
    if (!mounted || !context.mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isWarning ? Colors.orange.shade800 : Colors.red.shade700,
        duration: Duration(seconds: isWarning ? 4 : 3),
      ),
    );
  }

  void _navigateToInAppWebView(String url, String title) {
    if (!mounted || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppWebViewPage(
          url: url,
          title: title,
          currentLanguage: _currentLanguage,
        ),
      ),
    ).then((_) {
      _fetchAdminData();
    });
  }

  void _openAdminPanelInWebview() {
    _navigateToInAppWebView('https://davomat.modderboy.uz',
        _translate('admin_panel_webview_title'));
  }

  void _openDepositFundsInWebview() {
    String paymentUrl = 'https://davomatpayment.vercel.app/deposit';
    if (_userEmail != null) {
      paymentUrl += '?email=${Uri.encodeComponent(_userEmail!)}';
    }
    _navigateToInAppWebView(paymentUrl, _translate('deposit_webview_title'));
  }

  Future<void> _showAdminCredentialsDialog() async {
    final displayedEmail = _userEmail ?? 'N/A';
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(children: [
            Icon(Icons.admin_panel_settings_outlined,
                color: theme.primaryColor),
            const SizedBox(width: 10),
            Text(_translate('admin_credentials'))
          ]),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCredentialRow(
                    context: dialogCtx,
                    label: _translate('email'),
                    value: displayedEmail,
                    copyValue: displayedEmail),
                const SizedBox(height: 12),
                _buildCredentialRow(
                    context: dialogCtx,
                    label: _translate('password'),
                    value: '*********',
                    isPassword: true),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),
                Text('Admin Panel:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    _openAdminPanelInWebview();
                  },
                  child: Text('https://davomat.modderboy.uz',
                      style: TextStyle(
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 4),
                Text("(Login with email and password)",
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]))
              ]),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.login_outlined),
              label: Text(_translate('open')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _openAdminPanelInWebview();
              },
            ),
            TextButton(
                child: Text(_translate('close')),
                onPressed: () => Navigator.of(dialogCtx).pop()),
          ],
        );
      },
    );
  }

  Widget _buildCredentialRow(
      {required BuildContext context,
      required String label,
      required String value,
      String? copyValue,
      bool isPassword = false}) {
    final theme = Theme.of(context);
    final bool canCopy = !isPassword && value != '*********' && value != 'N/A';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                theme.textTheme.labelMedium?.copyWith(color: Colors.grey[700])),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            if (canCopy)
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: _translate('copied'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: copyValue ?? value));
                    ScaffoldMessenger.of(this.context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                          content: Text(_translate('copied')),
                          duration: const Duration(seconds: 1)),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  double _calculateMonthlyCost() {
    if (_employeeCount <= _freeEmployeeLimit) {
      return 0.0;
    }
    return (_employeeCount - _freeEmployeeLimit) * _costPerExtraEmployee;
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final theme = Theme.of(context);
    final String type = transaction['transaction_type'] as String? ?? 'N/A';
    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final String date = transaction['created_at'] != null
        ? DateFormat('yyyy-MM-dd HH:mm', _currentLanguage).format(
            tz.TZDateTime.from(
                DateTime.parse(transaction['created_at'] as String), tz.local))
        : 'N/A';
    final String description = transaction['description'] as String? ?? '';
    final String paymentMethod = transaction['payment_method'] as String? ?? '';
    final String status = transaction['status'] as String? ?? 'N/A';

    IconData typeIcon;
    Color amountColor;

    switch (type.toLowerCase()) {
      case 'deposit':
        typeIcon = Icons.arrow_downward_rounded;
        amountColor = Colors.green.shade700;
        break;
      case 'monthly_fee':
      case 'employee_addition_fee':
        typeIcon = Icons.arrow_upward_rounded;
        amountColor = Colors.red.shade700;
        break;
      default:
        typeIcon = Icons.history_toggle_off_rounded;
        amountColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(typeIcon, size: 20, color: amountColor),
                    const SizedBox(width: 8),
                    Text(_translate(type),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
                Text(
                  '${amount >= 0 ? "" : ""}\$${amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: amountColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${_translate('date')}: $date',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[700])),
            if (description.isNotEmpty)
              Text('${_translate('description')}: $description',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[700])),
            if (paymentMethod.isNotEmpty)
              Text('${_translate('payment_method')}: $paymentMethod',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[700])),
            Text('${_translate('status')}: ${_translate(status)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminContent() {
    String formattedUpdateDate = _lastUpdated == null
        ? (_isLoading ? _translate('loading') : 'N/A')
        : DateFormat('yyyy-MM-dd HH:mm', _currentLanguage)
            .format(_lastUpdated!);
    final theme = Theme.of(context);
    final double monthlyCost = _calculateMonthlyCost();
    final int paidEmployees = _employeeCount > _freeEmployeeLimit
        ? _employeeCount - _freeEmployeeLimit
        : 0;

    if (_isLoading && _companyName == null && _userEmail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Blurred glassmorphism container
    Widget glassCard({required Widget child, List<Color>? colors}) {
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Color(0xFF8811F7), // Zaxira holatida to‘liq rang
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Color(0xFF8811F7), // Asosiy binafsha
                Color(0xFF5A0EBB), // Pastga qarab to‘qroq
                Color(0xFF2F0A6B), // Yana chuqurroq fon
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.15), // Chegara nozik va shaffof
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Color(0xFF8811F7).withOpacity(0.35), // Yengil nur effekti
                blurRadius: 18,
                spreadRadius: 1,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.2), // Pastdan tushadigan chuqur soya
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // Shaffof yarim oq fon
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ));
    }

    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      color: Colors.white,
      backgroundColor: const Color(0xFF8811F7), // Purple background for refresh
      displacement: 70,
      strokeWidth: 2.8,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        children: [
          // Company & Balance glass card
          glassCard(
            colors: [
              const Color(0xFF43CEA2).withOpacity(0.5),
              const Color(0xFF185A9D).withOpacity(0.3)
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_translate('company_name'),
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(
                  _companyName ?? (_isLoading ? _translate('loading') : 'N/A'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        color: Colors.greenAccent, size: 28),
                    const SizedBox(width: 10),
                    Text(_translate('balance'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white)),
                    const Spacer(),
                    Text('\$${_balance.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _balance >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        )),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        color: Colors.blueAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                        _translate('total_employees', {'count': ''})
                            .replaceAll(': {count}', ''),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white)),
                    const Spacer(),
                    Text(_employeeCount.toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _translate('free_employees', {'count': _freeEmployeeLimit}),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                Text(
                  _translate('paid_employees', {'count': paidEmployees}),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                Text(
                  _translate('cost_per_additional_employee',
                      {'cost': _costPerExtraEmployee.toStringAsFixed(2)}),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calculate_outlined,
                        color: Colors.purpleAccent, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      _translate('monthly_cost',
                          {'cost': monthlyCost.toStringAsFixed(2)}),
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (monthlyCost > _balance &&
                    _employeeCount > _freeEmployeeLimit)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _translate('insufficient_balance_for_new_employee'),
                      style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                        _translate('last_updated_data',
                            {'datetime': formattedUpdateDate}),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          glassCard(
            colors: [
              const Color(0xFFff512f).withOpacity(0.35),
              const Color(0xFFdd2476).withOpacity(0.25),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Admin Panel',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text('Kirishga ruxsat berilsinmi?'),
                              content: const Text(
                                  'Web App ichida ochilsinmi yoki tashqi browserda?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop('web'),
                                  child: const Text('Web App ichida'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext)
                                      .pop('browser'),
                                  child: const Text('Tashqi browser'),
                                ),
                              ],
                            );
                          },
                        );

                        if (result == 'web') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InAppWebViewPage(
                                url: 'https://davomat.modderboy.uz',
                                title: 'Davomat - Admin paneli',
                                currentLanguage: 'uz',
                              ),
                            ),
                          );
                        } else if (result == 'browser') {
                          final url =
                              Uri.parse('https://davomat.modderboy.uz/');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('URL ochib bo‘lmadi')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Kirish',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                // Bu yerga boshqa kontent joylashadi, hozircha placeholder
              ],
            ),
          ),
          // Transactions glass card
          glassCard(
            colors: [
              const Color(0xFFff512f).withOpacity(0.35),
              const Color(0xFFdd2476).withOpacity(0.25)
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_translate('transactions_history'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
                const Divider(thickness: 1, height: 24, color: Colors.white38),
                _isLoading && _transactions.isEmpty && _companyId != null
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator()))
                    : _transactions.isEmpty
                        ? Text(_translate('no_transactions_found'),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 15))
                        : Column(
                            children: _transactions
                                .take(5)
                                .map((tr) => ListTile(
                                      leading: Icon(
                                          tr['transaction_type'] == 'deposit'
                                              ? Icons.arrow_downward_rounded
                                              : Icons.arrow_upward_rounded,
                                          color: tr['transaction_type'] ==
                                                  'deposit'
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          size: 26),
                                      title: Text(
                                        tr['transaction_type'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        tr['description'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                      trailing: Text(
                                        tr['amount'] != null
                                            ? '\$${tr['amount']}'
                                            : '',
                                        style: TextStyle(
                                          color: tr['transaction_type'] ==
                                                  'deposit'
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContent() {
    final theme = Theme.of(context);
    final filterOptions = ['Barchasi', 'Xodimlar', 'Balans', 'Tarix'];
    String _infoFilter = 'Barchasi';

    Widget glassInfoCard({required Widget child, List<Color>? colors}) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Color(0xFF8811F7), // Asosiy binafsha
              Color(0xFF5A0EBB), // Pastga qarab to‘qroq
              Color(0xFF2F0A6B), // Yana chuqurroq fon
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.15), // Chegara nozik va shaffof
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8811F7).withOpacity(0.35), // Yengil nur effekti
              blurRadius: 18,
              spreadRadius: 1,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.2), // Pastdan tushadigan chuqur soya
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.white.withOpacity(0.14), width: 1.2),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return RefreshIndicator(
          onRefresh: _fetchAdminData,
          color: Colors.white,
          backgroundColor: const Color(0xFF5B07E3),
          displacement: 70,
          strokeWidth: 2.5,
          child: Column(
            children: [
              // Glass Gradient Filter AppBar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xff5108c8),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8811F7), // Asosiy binafsha
                      Color(0xFF5A0EBB), // Pastga qarab to‘qroq
                      Color(0xFF2F0A6B), // Yana chuqurroq fon
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white
                        .withOpacity(0.15), // Chegara nozik va shaffof
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8811F7)
                          .withOpacity(0.35), // Yengil nur effekti
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.2), // Pastdan tushadigan chuqur soya
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(
                    top: 36, left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.white, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          _translate('general_info'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filterOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final isSelected = filterOptions[i] == _infoFilter;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _infoFilter = filterOptions[i]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.25),
                                  width: isSelected ? 1.8 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Text(
                                filterOptions[i],
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF5B07E3)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content - unchanged logic, retains design
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  children: [
                    if (_infoFilter == 'Barchasi' || _infoFilter == 'Xodimlar')
                      glassInfoCard(
                        colors: [
                          const Color(0xff5b07e3),
                          const Color(0xFF3B0CA9),
                        ],
                        child: ListTile(
                          leading: const Icon(Icons.people_outline,
                              color: Colors.white70, size: 30),
                          title: Text(_translate('employees'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(_employeeCount.toString(),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                        ),
                      ),
                    if (_infoFilter == 'Barchasi' || _infoFilter == 'Balans')
                      glassInfoCard(
                        colors: [
                          const Color(0xff5b07e3),
                          const Color(0xFF3B0CA9),
                        ],
                        child: ListTile(
                          leading: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.amberAccent,
                              size: 30),
                          title: Text(_translate('balance'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text('\$${_balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                        ),
                      ),
                    if (_infoFilter == 'Barchasi' || _infoFilter == 'Tarix')
                      glassInfoCard(
                        colors: [
                          const Color(0xff5b07e3),
                          const Color(0xFF3B0CA9),
                        ],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.history,
                                  color: Colors.white70, size: 30),
                              title: Text(_translate('transactions_history'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: _transactions.isEmpty
                                  ? Text(_translate('no_transactions_found'),
                                      style: const TextStyle(
                                          color: Colors.white70))
                                  : null,
                            ),
                            ..._transactions.map((tr) => ListTile(
                                  leading: Icon(
                                      tr['transaction_type'] == 'deposit'
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: tr['transaction_type'] == 'deposit'
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      size: 26),
                                  title: Text('${tr['transaction_type'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text('${tr['description'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  trailing: Text(
                                    tr['amount'] != null
                                        ? '\$${tr['amount']}'
                                        : '',
                                    style: TextStyle(
                                      color: tr['transaction_type'] == 'deposit'
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      Color? subtitleColor,
      bool canCopy = false,
      VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final String displaySubtitle = subtitle;
    final bool isValidForCopy = canCopy &&
        (subtitle != 'N/A') &&
        subtitle.isNotEmpty &&
        subtitle != _translate('loading');

    return ListTile(
      leading: Icon(icon, color: theme.primaryColor.withOpacity(0.8)),
      title: Text(title,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: Colors.grey.shade600)),
      subtitle: Text(displaySubtitle,
          style: theme.textTheme.titleMedium?.copyWith(
              color: subtitleColor ?? theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500)),
      trailing: isValidForCopy && onTap == null
          ? IconButton(
              icon: Icon(Icons.copy_rounded,
                  size: 18, color: Colors.grey.shade500),
              tooltip: _translate('copied'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: displaySubtitle));
                ScaffoldMessenger.of(this.context).removeCurrentSnackBar();
                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                    content: Text(_translate('copied')),
                    duration: const Duration(seconds: 1)));
              },
            )
          : (onTap != null
              ? Icon(Icons.open_in_new, color: Colors.blue.shade700)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      AdminUserSearchAppBar(adminContent: _buildAdminContent()),
      _buildInfoContent(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (mounted) setState(() => _selectedIndex = index);
        },
        translate: _translate,
      ),
    );
  }
}
