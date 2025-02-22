import 'package:flutter/cupertino.dart';
import 'package:DavomatYettilik/main.dart'; // Replace with your project name
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

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones(); // Initialize timezone data
    _loadCachedAttendanceHistory();
    _loadAttendanceHistory();
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
      message = 'Yuklanmoqda...';
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          message = 'Foydalanuvchi maʼlumotlari topilmadi.';
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
          message = "Siz kompaniyaga biriktirilmagansiz.";
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
          message = 'Davomat tarixi topilmadi.';
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
        message = 'Davomat tarixini yuklashda xatolik bor!';
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
    if (dateTime == null) return 'Noma\'lum vaqt';

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

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Davomat Tarixi'),
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
                        child: Text('Davomat tarixi topilmadi.',
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
                          final vaqtFormat = DateFormat('HH:mm');

                          final formattedKelishSana = kelishSana != null
                              ? sanaFormat.format(DateTime.parse(kelishSana))
                              : 'Noma\'lum sana';
                          final formattedKelishVaqti = kelishVaqti != null
                              ? _formatTashkentTime(
                                  kelishVaqti) // Use Tashkent time format
                              : 'Noma\'lum vaqt';
                          final formattedKetishVaqti = ketishVaqti != null
                              ? _formatTashkentTime(
                                  ketishVaqti) // Use Tashkent time format
                              : 'Qayd etilmagan';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    CupertinoColors.systemBlue.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: CupertinoColors.systemBlue
                                        .withOpacity(0.5),
                                    width: 2),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sana: $formattedKelishSana',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Kelish vaqti: ',
                                          style: TextStyle(
                                              color: CupertinoColors.white)),
                                      Text(formattedKelishVaqti,
                                          style: const TextStyle(
                                              color: CupertinoColors.white)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text('Ketish vaqti: ',
                                          style: TextStyle(
                                              color: CupertinoColors.white)),
                                      Text(formattedKetishVaqti,
                                          style: const TextStyle(
                                              color: CupertinoColors.white)),
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
