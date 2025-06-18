import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:DavomatYettilik/main.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> attendanceHistory = [];
  String message = '';
  bool isLoading = false;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

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

  String _currentLanguage = 'uz';
  final Map<String, String> _languageTitlesForHistory = {
    'en': 'Attendance History',
    'uz': 'Davomat Tarixi',
    'ru': 'История Посещений',
  };
  final Map<String, Map<String, String>> _localizedStringsForHistory = {
    'en': {
      'attendance_history_title': 'Attendance History',
      'loading': 'Loading...',
      'user_data_not_found': 'User data not found.',
      'company_not_assigned': 'You are not assigned to a company.',
      'no_attendance_history': 'No attendance history found.',
      'error_loading_history': 'Error loading attendance history!',
      'unknown_time': 'Unknown time',
      'date': 'Date:',
      'arrival_time': 'Arrival time:',
      'departure_time': 'Departure time:',
      'not_recorded': 'Not recorded',
      'no_history_found': 'No attendance history found.',
      'filter_by_month': 'Filter by Month',
      'all_months': 'All Months',
      'present_days': 'Present Days',
      'total_days': 'Total Days',
      'complete': 'Complete',
      'incomplete': 'Incomplete',
      'refresh': 'Refresh',
      'pull_to_refresh': 'Pull to refresh',
      'refreshing': 'Refreshing...',
      'refresh_completed': 'Refresh completed',
      'refresh_failed': 'Refresh failed',
      'statistics': 'Statistics',
      'monthly_summary': 'Monthly Summary',
      'attendance_rate': 'Attendance Rate',
      'working_days': 'Working Days',
      'absent_days': 'Absent Days',
      'late_arrivals': 'Late Arrivals',
      'early_departures': 'Early Departures',
      'overtime_hours': 'Overtime Hours',
      'total_hours': 'Total Hours',
      'average_arrival': 'Average Arrival Time',
      'average_departure': 'Average Departure Time',
      'export_history': 'Export History',
      'share_report': 'Share Report',
      'print_report': 'Print Report',
      'detailed_view': 'Detailed View',
      'summary_view': 'Summary View',
      'calendar_view': 'Calendar View',
      'list_view': 'List View',
      'search_history': 'Search History',
      'filter_options': 'Filter Options',
      'date_range': 'Date Range',
      'from_date': 'From Date',
      'to_date': 'To Date',
      'apply_filter': 'Apply Filter',
      'clear_filter': 'Clear Filter',
      'no_data_available': 'No data available',
      'sync_data': 'Sync Data',
      'last_sync': 'Last Sync',
      'sync_now': 'Sync Now',
      'offline_mode': 'Offline Mode',
      'online_mode': 'Online Mode',
    },
    'uz': {
      'attendance_history_title': 'Davomat Tarixi',
      'loading': 'Yuklanmoqda...',
      'user_data_not_found': 'Foydalanuvchi maʼlumotlari topilmadi.',
      'company_not_assigned': "Siz kompaniyaga biriktirilmagansiz.",
      'no_attendance_history': 'Davomat tarixi topilmadi.',
      'error_loading_history': 'Davomat tarixini yuklashda xatolik bor!',
      'unknown_time': 'Noma\'lum vaqt',
      'date': 'Sana:',
      'arrival_time': 'Kelish vaqti:',
      'departure_time': 'Ketish vaqti:',
      'not_recorded': 'Qayd etilmagan',
      'no_history_found': 'Davomat tarixi topilmadi.',
      'filter_by_month': 'Oy bo\'yicha filter',
      'all_months': 'Barcha oylar',
      'present_days': 'Kelgan kunlar',
      'total_days': 'Jami kunlar',
      'complete': 'To\'liq',
      'incomplete': 'To\'liq emas',
      'refresh': 'Yangilash',
      'pull_to_refresh': 'Yangilash uchun torting',
      'refreshing': 'Yangilanmoqda...',
      'refresh_completed': 'Yangilash tugallandi',
      'refresh_failed': 'Yangilash muvaffaqiyatsiz',
      'statistics': 'Statistika',
      'monthly_summary': 'Oylik xulosalar',
      'attendance_rate': 'Davomat darajasi',
      'working_days': 'Ish kunlari',
      'absent_days': 'Yo\'q bo\'lgan kunlar',
      'late_arrivals': 'Kech kelishlar',
      'early_departures': 'Erta ketishlar',
      'overtime_hours': 'Qo\'shimcha ish soatlari',
      'total_hours': 'Jami soatlar',
      'average_arrival': 'O\'rtacha kelish vaqti',
      'average_departure': 'O\'rtacha ketish vaqti',
      'export_history': 'Tarixni eksport qilish',
      'share_report': 'Hisobotni ulashish',
      'print_report': 'Hisobotni chop etish',
      'detailed_view': 'Batafsil ko\'rinish',
      'summary_view': 'Qisqacha ko\'rinish',
      'calendar_view': 'Kalendar ko\'rinishi',
      'list_view': 'Ro\'yxat ko\'rinishi',
      'search_history': 'Tarixni qidirish',
      'filter_options': 'Filter sozlamalari',
      'date_range': 'Sana oralig\'i',
      'from_date': 'Boshlanish sanasi',
      'to_date': 'Tugash sanasi',
      'apply_filter': 'Filterni qo\'llash',
      'clear_filter': 'Filterni tozalash',
      'no_data_available': 'Ma\'lumot mavjud emas',
      'sync_data': 'Ma\'lumotlarni sinxronlash',
      'last_sync': 'Oxirgi sinxronlash',
      'sync_now': 'Hozir sinxronlash',
      'offline_mode': 'Oflayn rejim',
      'online_mode': 'Onlayn rejim',
    },
    'ru': {
      'attendance_history_title': 'История Посещений',
      'loading': 'Загрузка...',
      'user_data_not_found': 'Данные пользователя не найдены.',
      'company_not_assigned': 'Вы не прикреплены к компании.',
      'no_attendance_history': 'История посещений не найдена.',
      'error_loading_history': 'Ошибка загрузки истории посещений!',
      'unknown_time': 'Неизвестное время',
      'date': 'Дата:',
      'arrival_time': 'Время прихода:',
      'departure_time': 'Время ухода:',
      'not_recorded': 'Не записано',
      'no_history_found': 'История посещений не найдена.',
      'filter_by_month': 'Фильтр по месяцу',
      'all_months': 'Все месяцы',
      'present_days': 'Дни присутствия',
      'total_days': 'Всего дней',
      'complete': 'Завершено',
      'incomplete': 'Не завершено',
      'refresh': 'Обновить',
      'pull_to_refresh': 'Потяните для обновления',
      'refreshing': 'Обновление...',
      'refresh_completed': 'Обновление завершено',
      'refresh_failed': 'Обновление не удалось',
      'statistics': 'Статистика',
      'monthly_summary': 'Месячная сводка',
      'attendance_rate': 'Уровень посещаемости',
      'working_days': 'Рабочие дни',
      'absent_days': 'Дни отсутствия',
      'late_arrivals': 'Опоздания',
      'early_departures': 'Ранние уходы',
      'overtime_hours': 'Сверхурочные часы',
      'total_hours': 'Общее количество часов',
      'average_arrival': 'Среднее время прихода',
      'average_departure': 'Среднее время ухода',
      'export_history': 'Экспорт истории',
      'share_report': 'Поделиться отчетом',
      'print_report': 'Печать отчета',
      'detailed_view': 'Подробный вид',
      'summary_view': 'Сводный вид',
      'calendar_view': 'Вид календаря',
      'list_view': 'Вид списка',
      'search_history': 'Поиск в истории',
      'filter_options': 'Параметры фильтра',
      'date_range': 'Диапазон дат',
      'from_date': 'С даты',
      'to_date': 'По дату',
      'apply_filter': 'Применить фильтр',
      'clear_filter': 'Очистить фильтр',
      'no_data_available': 'Данные недоступны',
      'sync_data': 'Синхронизация данных',
      'last_sync': 'Последняя синхронизация',
      'sync_now': 'Синхронизировать сейчас',
      'offline_mode': 'Офлайн режим',
      'online_mode': 'Онлайн режим',
    },
  };

  String? _selectedMonth;
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _loadLanguagePreference();
    _loadCachedAttendanceHistory();
    _loadAttendanceHistory();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'uz';
    });
  }

  String _translate(String key) {
    return _localizedStringsForHistory[_currentLanguage]![key] ??
        _localizedStringsForHistory['uz']![key]!;
  }

  Future<void> _loadCachedAttendanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedHistory = prefs.getString('attendanceHistory');
    if (cachedHistory != null && mounted) {
      setState(() {
        attendanceHistory =
            List<Map<String, dynamic>>.from(jsonDecode(cachedHistory));
        _updateAvailableMonths();
      });
    }
  }

  void _updateAvailableMonths() {
    Set<String> months = {};
    for (var record in attendanceHistory) {
      final kelishSana = record['kelish_sana'];
      if (kelishSana != null) {
        final date = DateTime.parse(kelishSana);
        final monthKey = DateFormat('yyyy-MM').format(date);
        months.add(monthKey);
      }
    }
    setState(() {
      _availableMonths = months.toList()..sort((a, b) => b.compareTo(a));
    });
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedMonth == null) return attendanceHistory;

    return attendanceHistory.where((record) {
      final kelishSana = record['kelish_sana'];
      if (kelishSana == null) return false;
      final date = DateTime.parse(kelishSana);
      final monthKey = DateFormat('yyyy-MM').format(date);
      return monthKey == _selectedMonth;
    }).toList();
  }

  Future<void> _loadAttendanceHistory() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      message = _translate('loading');
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          message = _translate('user_data_not_found');
          isLoading = false;
        });
        _refreshController.refreshCompleted();
        return;
      }

      final companyData = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();
      final String? companyId = companyData?['company_id'] as String?;

      if (companyId == null) {
        setState(() {
          message = _translate('company_not_assigned');
          isLoading = false;
        });
        _refreshController.refreshCompleted();
        return;
      }

      final response = await supabase
          .from('davomat')
          .select('kelish_sana, kelish_vaqti, ketish_vaqti')
          .eq('xodim_id', userId)
          .eq('company_id', companyId)
          .order('kelish_sana', ascending: false);

      if (response == null || response.isEmpty) {
        setState(() {
          message = _translate('no_attendance_history');
          attendanceHistory = [];
        });
        _refreshController.refreshCompleted();
        return;
      }

      List<Map<String, dynamic>> loadedHistory = [];
      for (var record in response) {
        final kelishSana = record['kelish_sana'] as String?;
        final kelishVaqti = record['kelish_vaqti'] != null
            ? DateTime.parse(record['kelish_vaqti']).toUtc()
            : null;
        final ketishVaqti = record['ketish_vaqti'] != null
            ? DateTime.parse(record['ketish_vaqti']).toUtc()
            : null;

        loadedHistory.add({
          'kelish_sana': kelishSana,
          'kelish_vaqti': kelishVaqti,
          'ketish_vaqti': ketishVaqti,
        });
      }

      setState(() {
        attendanceHistory = loadedHistory;
        message = '';
        _updateAvailableMonths();
      });

      _cacheAttendanceHistory();
    } catch (error) {
      setState(() {
        message = _translate('error_loading_history');
        attendanceHistory = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
      _refreshController.refreshCompleted();
    }
  }

  Future<void> _cacheAttendanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('attendanceHistory', jsonEncode(attendanceHistory));
  }

  Future<void> _onRefresh() async {
    await _loadAttendanceHistory();
  }

  String _formatTashkentTime(DateTime? dateTime) {
    if (dateTime == null) return _translate('unknown_time');

    final tashkentTimeZone = tz.getLocation('Asia/Tashkent');
    final tashkentTime = tz.TZDateTime.from(dateTime, tashkentTimeZone);
    final vaqtFormat = DateFormat('HH:mm');
    return vaqtFormat.format(tashkentTime);
  }

  String _formatMonthYear(String monthKey) {
    final date = DateTime.parse('$monthKey-01');
    return DateFormat('MMMM yyyy', _currentLanguage).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _filteredHistory;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _translate('attendance_history_title'),
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _onRefresh,
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : Icon(CupertinoIcons.refresh, color: primaryColor),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatsCard(),
            _buildFilterSection(),
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                header: ClassicHeader(
                  refreshStyle: RefreshStyle.Follow,
                  textStyle: TextStyle(color: textSecondary),
                  releaseText: 'Release to refresh',
                  refreshingText: 'Refreshing...',
                  completeText: 'Refresh completed',
                  failedText: 'Refresh failed',
                ),
                child: isLoading || message.isNotEmpty
                    ? Center(
                        child: isLoading
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    _translate('loading'),
                                    style: TextStyle(color: textSecondary),
                                  ),
                                ],
                              )
                            : _buildEmptyState(),
                      )
                    : filteredHistory.isEmpty
                        ? _buildEmptyState()
                        : _buildHistoryList(filteredHistory),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final filteredHistory = _filteredHistory;
    final presentDays = filteredHistory.length;
    final currentMonth = DateTime.now();
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
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
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: CupertinoIcons.checkmark_circle_fill,
              label: _translate('present_days'),
              value: presentDays.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: CupertinoIcons.calendar,
              label: _translate('total_days'),
              value: _selectedMonth != null
                  ? _getDaysInSelectedMonth().toString()
                  : daysInMonth.toString(),
            ),
          ),
        ],
      ),
    );
  }

  int _getDaysInSelectedMonth() {
    if (_selectedMonth == null) return DateTime.now().day;
    final date = DateTime.parse('$_selectedMonth-01');
    return DateTime(date.year, date.month + 1, 0).day;
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(CupertinoIcons.slider_horizontal_3, color: primaryColor),
          SizedBox(width: 12),
          Text(
            _translate('filter_by_month'),
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedMonth,
                hint: Text(
                  _translate('all_months'),
                  style: TextStyle(color: primaryColor, fontSize: 14),
                ),
                icon: Icon(CupertinoIcons.chevron_down,
                    color: primaryColor, size: 16),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      _translate('all_months'),
                      style: TextStyle(color: textPrimary, fontSize: 14),
                    ),
                  ),
                  ..._availableMonths.map((month) => DropdownMenuItem<String>(
                        value: month,
                        child: Text(
                          _formatMonthYear(month),
                          style: TextStyle(color: textPrimary, fontSize: 14),
                        ),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.calendar_badge_minus,
              size: 48,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            message.isNotEmpty ? message : _translate('no_history_found'),
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> history) {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final attendance = history[index];
        return _buildHistoryCard(attendance, index);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> attendance, int index) {
    final kelishSana = attendance['kelish_sana'];
    final kelishVaqti = attendance['kelish_vaqti'];
    final ketishVaqti = attendance['ketish_vaqti'];

    final sanaFormat = DateFormat('dd.MM.yyyy');
    final formattedKelishSana = kelishSana != null
        ? sanaFormat.format(DateTime.parse(kelishSana))
        : 'Noma\'lum sana';
    final formattedKelishVaqti = kelishVaqti != null
        ? _formatTashkentTime(kelishVaqti)
        : _translate('unknown_time');
    final formattedKetishVaqti = ketishVaqti != null
        ? _formatTashkentTime(ketishVaqti)
        : _translate('not_recorded');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: EdgeInsets.all(20),
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
                Expanded(
                  child: Text(
                    formattedKelishSana,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ketishVaqti != null
                        ? successColor.withOpacity(0.1)
                        : warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ketishVaqti != null ? 'Complete' : 'Incomplete',
                    style: TextStyle(
                      color: ketishVaqti != null ? successColor : warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    icon: CupertinoIcons.arrow_down_circle_fill,
                    label: _translate('arrival_time'),
                    time: formattedKelishVaqti,
                    color: successColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard(
                    icon: CupertinoIcons.arrow_up_circle_fill,
                    label: _translate('departure_time'),
                    time: formattedKetishVaqti,
                    color: ketishVaqti != null ? warningColor : textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            time,
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
}
