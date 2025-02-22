import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:DavomatYettilik/main.dart'; // Replace with your project name
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:detect_fake_location/detect_fake_location.dart';
import 'package:safe_device/safe_device.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

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
  String? companyName; // Company name

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void initState() {
    super.initState();
    _loadUserDataFromPrefs(); // Load from prefs first
    _loadUserData(); // Then try to load from Supabase and update prefs
  }

  // Function to save companyName to shared preferences
  Future<void> _saveUserDataToPrefs(String? companyName) async {
    final prefs = await SharedPreferences.getInstance();
    if (companyName != null) {
      await prefs.setString('companyName', companyName);
    } else {
      await prefs.remove('companyName'); // Remove if null
    }
  }

  // Function to load companyName from shared preferences
  Future<void> _loadUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      companyName = prefs.getString('companyName');
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      print('Foydalanuvchi IDsi: $userId');

      final companyData = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();
      print('Foydalanuvchi ma\'lumotlari (users jadvalidan): $companyData');

      String? companyId = companyData?['company_id'] as String?;

      print('Kompaniya IDsi: $companyId');

      if (companyId != null) {
        final companyNameData = await supabase
            .from('companies')
            .select('company_name')
            .eq('id', companyId)
            .maybeSingle();
        print(
            'Kompaniya nomi ma\'lumotlari (companies jadvalidan): $companyNameData');

        String? fetchedCompanyName =
            companyNameData?['company_name'] as String?;

        if (mounted) {
          setState(() {
            companyName = fetchedCompanyName;
          });
        }
        _saveUserDataToPrefs(fetchedCompanyName); // Save to prefs

        // Modified QR code query to fetch global QR codes, no company filter
        final qrData = await supabase
            .from('qrcodes')
            .select('kelish_qrcode, ketish_qrcode')
            .limit(1)
            .maybeSingle(); // Get the first set of QR codes from qrcodes table, assuming it's global
        print('Global QR kod ma\'lumotlari (qrcodes jadvalidan): $qrData');

        final locationData = await supabase
            .from('location')
            .select('latitude, longitude, distance')
            .eq('company_id', companyId) // Location still company specific
            .maybeSingle();
        print('Joylashuv ma\'lumotlari (location jadvalidan): $locationData');

        if (mounted) {
          setState(() {
            kelishQrCode = qrData?['kelish_qrcode'] as String?;
            ketishQrCode = qrData?['ketish_qrcode'] as String?;
            expectedLatitude = locationData?['latitude'] as double?;
            expectedLongitude = locationData?['longitude'] as double?;
            distanceThreshold =
                (locationData?['distance'] as num?)?.toDouble() ?? 100;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            message =
                "Siz kompaniyaga biriktirilmagansiz. Admin bilan bog'laning.";
            companyName = null; // Clear company name from UI and prefs
          });
          _saveUserDataToPrefs(null); // Clear from prefs as well
        }
      }
    } catch (error) {
      print(
          "Foydalanuvchi ma'lumotlarini yuklashda xatolik: $error"); // Xatolik logi
      if (mounted) {
        setState(() {
          message = 'Foydalanuvchi ma\'lumotlarini yuklashda xatolik!';
        });
      }
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final cameraStatus = await Permission.camera.status;
      final locationStatus = await Permission.location.status;

      if (!cameraStatus.isGranted) {
        await Permission.camera.request();
      }
      if (!locationStatus.isGranted) {
        await Permission.location.request();
      }

      return await Permission.camera.isGranted &&
          await Permission.location.isGranted;
    } else if (Platform.isIOS) {
      final cameraStatus = await Permission.camera.status;
      final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
      final locationAlwaysStatus = await Permission.locationAlways.status;

      if (!cameraStatus.isGranted) {
        await Permission.camera.request();
      }
      // Ilovadan foydalanish vaqtida joylashuvni so'rash
      if (!locationWhenInUseStatus.isGranted) {
        await Permission.locationWhenInUse.request();
      }
      // Fon rejimida joylashuvni so'rash (agar kerak bo'lsa)
      if (!locationAlwaysStatus.isGranted) {
        await Permission.locationAlways.request();
      }

      return await Permission.camera.isGranted &&
          (await Permission.locationWhenInUse.isGranted ||
              await Permission.locationAlways.isGranted);
    }
    return false;
  }

  Future<bool> _isFakeDevice() async {
    // Added async
    try {
      bool isFakeLocationByDetectFakeLocation =
          await DetectFakeLocation().detectFakeLocation();
      bool isMockLocationBySafeDevice = await SafeDevice.isMockLocation;

      return !isFakeLocationByDetectFakeLocation && !isMockLocationBySafeDevice;
    } catch (e) {
      print("Soxta joylashuvni aniqlashda xatolik: $e");
      return false; // Return false on error
    }
  }

  Future<void> _handleScanLogic(String data) async {
    if (data.isEmpty) return;

    setState(() {
      message = 'Tekshirilmoqda...';
    });

    final userId = supabase.auth.currentUser!.id;

    // Get company ID.  We still need company ID for location and attendance records.
    final companyData = await supabase
        .from('users')
        .select('company_id')
        .eq('id', userId)
        .maybeSingle();

    final String? companyId = companyData?['company_id'] as String?;
    if (companyId == null) {
      setState(() {
        message = "Siz kompaniyaga biriktirilmagansiz. Admin bilan bog'laning.";
      });
      return;
    }

    // Check if user is blocked, now checking with company_id as well
    final blockedUser = await supabase
        .from('blocked')
        .select()
        .eq('user_id', userId)
        .eq('company_id', companyId) // Added company_id check
        .maybeSingle();

    if (blockedUser != null) {
      setState(() {
        message =
            'Siz bloklangansiz! Blokdan chiqish uchun admin bilan bog\'laning'; // Blocked message
      });
      return; // Stop the function here
    }

    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      setState(() {
        message = 'Kamera va joylashuvga ruxsat berilmagan.';
      });
      return;
    }

    final isRealDeviceResult = await _isFakeDevice();
    if (!isRealDeviceResult) {
      setState(() {
        message = 'Qurilmangizda soxta joylashuv aniqlandi!';
      });
      await supabase.from('blocked').insert({
        'user_id': userId,
        'company_id': companyId // Include company_id when blocking
      });
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Check if expectedLatitude and expectedLongitude are not null
      if (expectedLatitude == null || expectedLongitude == null) {
        setState(() {
          message =
              'Joylashuv ma\'lumotlari yuklanmadi, iltimos ma\'muri bilan bog\'laning!';
        });
        return;
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        expectedLatitude!,
        expectedLongitude!,
      );

      if (distance > distanceThreshold) {
        setState(() {
          message = 'Siz ish joyingizda emassiz!';
        });
        return;
      }

      final today = DateTime.now().toLocal().toString().split(' ')[0];
      final now = DateTime.now().toLocal().toIso8601String();

      // Make sure existingAttendance query uses companyId.
      final existingAttendance = await supabase
          .from('davomat')
          .select()
          .eq('xodim_id', userId)
          .eq('kelish_sana', today)
          .eq('company_id', companyId) // Use String comparison
          .maybeSingle();

      if (kelishQrCode == null || ketishQrCode == null) {
        setState(() {
          message =
              'Global QR kodlar topilmadi, admin bilan bog\'laning.'; // Updated message
        });
        return;
      }

      if (kelishQrCode == data) {
        if (existingAttendance == null) {
          await supabase.from('davomat').insert({
            'xodim_id': userId,
            'kelish_sana': today,
            'kelish_vaqti': now,
            'company_id': companyId, // Use companyId for attendance record
          });

          if (mounted) {
            setState(() {
              message = 'Kelish saqlandi.';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              message = 'Siz bugun allaqachon kelganingizni qayd etgansiz.';
            });
          }
        }
      } else if (ketishQrCode == data) {
        if (existingAttendance != null &&
            existingAttendance['ketish_vaqti'] == null) {
          await supabase
              .from('davomat')
              .update({
                'ketish_vaqti': now,
              })
              .eq('xodim_id', userId)
              .eq('kelish_sana', today)
              .eq('company_id',
                  companyId); // Use companyId for attendance record

          if (mounted) {
            setState(() {
              message = 'Ketish saqlandi.';
            });
          }
        } else if (existingAttendance != null) {
          if (mounted) {
            setState(() {
              message = 'Siz bugun allaqachon ketganingizni qayd etgansiz.';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              message = 'Avval kelganingizni qayd eting.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            message = 'Boshqa QR kod.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          message = 'Xatolik yuz berdi: $e';
        });
      }
    }
  }

  void _onRebuildQrView() {
    if (mounted) {
      setState(() {
        result = null; // Clear the previous result
        message = ''; // Clear the message
      });
    }
    controller?.resumeCamera(); // Resume camera to start scanning again
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Xatolik'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600; // Example breakpoint for tablets
    final titleFontSize = isTablet ? 48.0 : 32.0;
    final subtitleFontSize = isTablet ? 24.0 : 18.0;
    final messageFontSize = isTablet ? 20.0 : 16.0;
    var scanArea = isTablet ? 500.0 : 300.0; // Larger scan area for tablets

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(companyName ?? 'Davomat tizimi'), // Show company name
      ),
      child: SingleChildScrollView(
        // Added SingleChildScrollView here
        child: Column(
          children: <Widget>[
            // Tepaga joylashtirilgan matnlar
            Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: CupertinoColors.black,
                        fontFamily: 'Arial Black', // Example custom font
                      ),
                      children: <TextSpan>[
                        TextSpan(
                            text: '"$companyName" ',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: 'Davomati',
                            style:
                                const TextStyle(fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Maxsus QR kodni skanerlash orqali xodimlar davomati tizimiga davomatni qayd etish mumkin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: CupertinoColors.black.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: CupertinoColors.black.withOpacity(0.6),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: messageFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20), // Added spacing between text and QRView

            // Markazga joylashtirilgan QRView
            _buildQrView(context, scanArea),

            SizedBox(height: 30), // Spacing below QRView

            // Markazga joylashtirilgan "Yangilash" tugmasi
            Center(
              child: CupertinoButton.filled(
                onPressed: _onRebuildQrView,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.arrow_2_circlepath,
                        color: CupertinoColors.white),
                    SizedBox(width: 8),
                    Text('Yangilash',
                        style: TextStyle(color: CupertinoColors.white)),
                  ],
                ),
              ),
            ),

            // Pastki qism (Flash tugmasi)
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 50.0, top: 30), // Added top padding here
              child: Center(
                child: CupertinoButton(
                  // Flash button
                  onPressed: () async {
                    if (controller != null) {
                      await controller?.toggleFlash();
                      setState(() {
                        isFlashOn = !isFlashOn;
                      });
                    }
                  },
                  child: Icon(
                    isFlashOn
                        ? CupertinoIcons.bolt_fill
                        : CupertinoIcons.bolt_slash_fill,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context, double scanArea) {
    return Container(
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: scanArea,
          height: scanArea,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
            overlay: QrScannerOverlayShape(
              borderColor: CupertinoColors.activeGreen,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: scanArea,
            ),
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.resumeCamera(); // Resume in case it was paused
    controller.scannedDataStream.listen((scanData) async {
      if (mounted) {
        //check if the state is mounted before setting state
        setState(() {
          result = scanData;
          message = 'Skanerlandi: ${result!.code}';
        });

        controller.pauseCamera();
        await _handleScanLogic(scanData.code ?? ''); // Await the result

        if (message != 'Sizning qilgan soxta xatti-harakatingiz aniqlandi!' &&
            mounted) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                message = '';
              });
              controller.resumeCamera();
            }
          });
        }
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      _showErrorDialog("Ruxsat berilmagan");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

extension ParseToString on double {
  LocationAccuracy toLocationAccuracy() {
    if (this <= 10) {
      return LocationAccuracy.high;
    } else if (this <= 100) {
      return LocationAccuracy.medium;
    } else {
      return LocationAccuracy.low;
    }
  }
}
