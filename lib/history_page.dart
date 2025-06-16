//history_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Import Material library for Card
import 'package:DavomatYettilik/main.dart'; // Replace with your project name
import 'package:intl/intl.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

// Modular UI Components (Cards and Buttons) - from your provided code (ensure this is in the same file or correctly imported)
class MUILoginCard extends StatelessWidget {
  final Widget child;

  const MUILoginCard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.07,
          vertical: 8.0, // Reduced vertical padding for history items
        ),
        child: SingleChildScrollView(
          // Removed SingleChildScrollView - not needed for card itself
          physics:
              NeverScrollableScrollPhysics(), // Disable scrolling inside card
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(16.0), // Reduced padding inside card
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

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
  final Color primaryColor = const Color(0xFF3700B3); // Define primaryColor

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
      'no_history_found':
          'No attendance history found.', // repeated for empty list case
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
      'no_history_found':
          'Davomat tarixi topilmadi.', // repeated for empty list case
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
      'no_history_found':
          'История посещений не найдена.', // repeated for empty list case
    },
  };

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones(); // Initialize timezone data
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
      });
    }
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

      // Foydalanuvchi uchun kompaniya ID sini olish
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

      // Davomat maʼlumotlarini olish
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
        // Assuming kelish_vaqti and ketish_vaqti are stored in UTC in Supabase
        final kelishVaqti = record['kelish_vaqti'] != null
            ? DateTime.parse(record['kelish_vaqti']).toUtc() // Parse as UTC
            : null;
        final ketishVaqti = record['ketish_vaqti'] != null
            ? DateTime.parse(record['ketish_vaqti']).toUtc() // Parse as UTC
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
    // Assuming dateTime is in UTC, convert to Tashkent time
    final tashkentTime = tz.TZDateTime.from(dateTime, tashkentTimeZone);
    final vaqtFormat = DateFormat('HH:mm');
    return vaqtFormat.format(tashkentTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;
    final cardTextColor = Colors.black87; // Text color inside the card

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_translate('attendance_history_title')),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _onRefresh,
          child: isLoading
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          header: const ClassicHeader(refreshStyle: RefreshStyle.Follow),
          child: CupertinoScrollbar(
            child: isLoading || message.isNotEmpty
                ? Center(
                    child: isLoading
                        ? const CupertinoActivityIndicator()
                        : Text(message, style: TextStyle(color: textColor)),
                  )
                : attendanceHistory.isEmpty
                    ? Center(
                        child: Text(_translate('no_history_found'),
                            style: TextStyle(color: textColor)),
                      )
                    : ListView.builder(
                        itemCount: attendanceHistory.length,
                        itemBuilder: (context, index) {
                          final attendance = attendanceHistory[index];
                          final kelishSana = attendance['kelish_sana'];
                          final kelishVaqti = attendance['kelish_vaqti'];
                          final ketishVaqti = attendance['ketish_vaqti'];

                          final sanaFormat = DateFormat('dd.MM.yyyy');

                          final formattedKelishSana = kelishSana != null
                              ? sanaFormat.format(DateTime.parse(kelishSana))
                              : 'Noma\'lum sana'; // No need to translate date format
                          final formattedKelishVaqti = kelishVaqti != null
                              ? _formatTashkentTime(
                                  kelishVaqti) // Use Tashkent time format
                              : _translate('unknown_time');
                          final formattedKetishVaqti = ketishVaqti != null
                              ? _formatTashkentTime(
                                  ketishVaqti) // Use Tashkent time format
                              : _translate('not_recorded');

                          return MUILoginCard(
                            // Use MUILoginCard here
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_translate('date')} $formattedKelishSana',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            cardTextColor), // Use cardTextColor
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('${_translate('arrival_time')} ',
                                          style: TextStyle(
                                              color:
                                                  cardTextColor)), // Use cardTextColor
                                      Text(formattedKelishVaqti,
                                          style: TextStyle(
                                              color:
                                                  cardTextColor)), // Use cardTextColor
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text('${_translate('departure_time')} ',
                                          style: TextStyle(
                                              color:
                                                  cardTextColor)), // Use cardTextColor
                                      Text(formattedKetishVaqti,
                                          style: TextStyle(
                                              color:
                                                  cardTextColor)), // Use cardTextColor
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
