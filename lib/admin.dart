// --- admin.dart ---
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as platform_io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:convert';

import 'apps.dart';
import 'webview_page.dart';

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
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      color: theme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Text('${_translate('company_name')}:',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.secondary))),
                      if (_isLoading && _companyName == null)
                        const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  Text(
                      _companyName ??
                          (_isLoading ? _translate('loading') : 'N/A'),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(_translate('balance'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.secondary)),
                  const SizedBox(height: 4),
                  Text('\$${_balance.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _balance >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(_translate('employees'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.secondary)),
                  const SizedBox(height: 4),
                  Text(
                      _translate('total_employees', {
                        'count': _isLoading &&
                                _employeeCount == 0 &&
                                _companyId != null
                            ? _translate('loading')
                            : _employeeCount.toString()
                      }),
                      style: theme.textTheme.titleMedium),
                  Text(
                      _translate(
                          'free_employees', {'count': _freeEmployeeLimit}),
                      style: theme.textTheme.bodyMedium),
                  Text(_translate('paid_employees', {'count': paidEmployees}),
                      style: theme.textTheme.bodyMedium),
                  Text(
                      _translate('cost_per_additional_employee',
                          {'cost': _costPerExtraEmployee.toStringAsFixed(2)}),
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                      _translate('monthly_cost',
                          {'cost': monthlyCost.toStringAsFixed(2)}),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  if (monthlyCost > _balance &&
                      _employeeCount > _freeEmployeeLimit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                          _translate('insufficient_balance_for_new_employee'),
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontStyle: FontStyle.italic)),
                    ),
                  const SizedBox(height: 12),
                  Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                          _translate('last_updated_data',
                              {'datetime': formattedUpdateDate}),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
            label: Text(_translate('deposit_funds'),
                style: const TextStyle(fontSize: 16)),
            onPressed: (_isLoading && _companyId == null) || _companyId == null
                ? null
                : _openDepositFundsInWebview,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          // Tranzaksiyalar tarixi
          Text(_translate('transactions_history'),
              style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor, fontWeight: FontWeight.bold)),
          const Divider(thickness: 1.5, height: 20),
          _isLoading &&
                  _transactions.isEmpty &&
                  _companyId !=
                      null // Faqat kompaniya ID mavjud bo'lganda va yuklanayotganda loader
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator()))
              : _transactions.isEmpty
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_translate('no_transactions_found'),
                              style: TextStyle(color: Colors.grey[600]))))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(_transactions[index]);
                      },
                    ),

          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text(_translate('admin_panel_login'),
                          style: theme.textTheme.titleMedium)),
                  ElevatedButton.icon(
                    onPressed: _showAdminCredentialsDialog,
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(_translate('open')),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
              child: Text('Powered by Supabase',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[500]))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoContent() {
    final theme = Theme.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (_isLoading && _companyName == null && _userEmail == null) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(_translate('general_info'),
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.primaryColor)),
        const Divider(thickness: 1, height: 20),
        _buildInfoTile(
            icon: Icons.business_outlined,
            title: _translate('company_name'),
            subtitle:
                _companyName ?? (_isLoading ? _translate('loading') : 'N/A')),
        _buildInfoTile(
            icon: Icons.alternate_email_outlined,
            title: _translate('user_email'),
            subtitle:
                _userEmail ?? (_isLoading ? _translate('loading') : 'N/A'),
            canCopy: true),
        _buildInfoTile(
            icon: Icons.perm_identity_outlined,
            title: 'User ID',
            subtitle: _userId ?? (currentUser?.id ?? 'N/A')),
        _buildInfoTile(
            icon: Icons.confirmation_number_outlined,
            title: _translate('company_id'),
            subtitle: _companyId ?? 'N/A',
            canCopy: true),
        const SizedBox(height: 24),
        Text(_translate('employees'),
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.primaryColor)),
        const Divider(thickness: 1, height: 20),
        _buildInfoTile(
            icon: Icons.people_outline,
            title: _translate('total_employees', {'count': ''})
                .replaceAll(': {count}', ''),
            subtitle: _isLoading && _employeeCount == 0 && _companyId != null
                ? _translate('loading')
                : _employeeCount.toString()),
        _buildInfoTile(
            icon: Icons.money_off_csred_outlined,
            title: _translate('free_employees', {'count': ''})
                .replaceAll(': {count}', ''),
            subtitle: _freeEmployeeLimit.toString()),
        _buildInfoTile(
            icon: Icons.monetization_on_outlined,
            title: _translate('paid_employees', {'count': ''})
                .replaceAll(': {count}', ''),
            subtitle: (_employeeCount > _freeEmployeeLimit
                    ? _employeeCount - _freeEmployeeLimit
                    : 0)
                .toString()),
        _buildInfoTile(
            icon: Icons.price_change_outlined,
            title: _translate('cost_per_additional_employee', {'cost': ''})
                .replaceAll(': \${cost}/month', ''),
            subtitle:
                '\$${_costPerExtraEmployee.toStringAsFixed(2)} / ${_translate('months')}'),
        _buildInfoTile(
            icon: Icons.request_quote_outlined,
            title: _translate('monthly_cost', {'cost': ''})
                .replaceAll(': \${cost}', ''),
            subtitle: '\$${_calculateMonthlyCost().toStringAsFixed(2)}'),
        const SizedBox(height: 20),
      ],
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
      _buildAdminContent(),
      _buildInfoContent(),
      const AppsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('admin_panel_title')),
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate_outlined),
            tooltip: 'Tilni tanlash',
            onSelected: _setLanguagePreference,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'en', child: Text('English')),
              const PopupMenuItem<String>(value: 'uz', child: Text("O'zbek")),
              const PopupMenuItem<String>(value: 'ru', child: Text('Русский')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled), label: _translate('home')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.info_outline), label: _translate('info')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.apps_outlined), label: _translate('apps')),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        onTap: (index) {
          if (mounted) setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
    );
  }
}
