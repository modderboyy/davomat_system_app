// premium_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:DavomatYettilik/main.dart'; // Assuming main.dart is in the lib folder
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';
import 'login_page.dart'; // Import LoginPage and MUI Components if needed or move MUI Components to a separate file

class RegistrationView extends StatefulWidget {
  final VoidCallback onViewToggle;
  final String Function(String) translate;

  const RegistrationView(
      {Key? key, required this.onViewToggle, required this.translate})
      : super(key: key);

  @override
  _RegistrationViewState createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _regFormKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _employeesCountController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _regIsLoading = false;
  final _logger = Logger();

  final List<Map<String, String>> _employeePositions = [];
  final _positionController = TextEditingController();
  final _fullNameController = TextEditingController();

  String? _filePath;
  String? _fileUrl;
  String? _fileName;
  Uint8List? _fileBytes;

  final Color primaryColor = const Color(0xFF3700B3);

  // Payment details state variables
  List<Map<String, dynamic>> _paymentDetailsList = [];

  @override
  void initState() {
    super.initState();
    _fetchPaymentDetails();
  }

  Future<void> _fetchPaymentDetails() async {
    try {
      final List<dynamic> paymentData =
          await supabase.from('paycards').select('name, code, owner');

      setState(() {
        _paymentDetailsList = List<Map<String, dynamic>>.from(paymentData);
      });
    } catch (e) {
      _logger.e('Error fetching payment details: $e');
      // Handle error, maybe set default values or show an error message
    }
  }

  void _addPosition() {
    final position = _positionController.text.trim();
    final fullName = _fullNameController.text.trim();
    if (position.isNotEmpty && fullName.isNotEmpty) {
      setState(() {
        _employeePositions.add({'position': position, 'fullName': fullName});
        _positionController.clear();
        _fullNameController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.translate('position_fullname_required'),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePosition(int index) {
    setState(() {
      _employeePositions.removeAt(index);
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: kIsWeb ? true : false,
      withReadStream: !kIsWeb,
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          _fileBytes = result.files.single.bytes;
          _filePath = 'web_file';
        } else {
          _filePath = result.files.single.path!;
          _fileBytes = null;
        }
      });
    }
  }

  Future<String?> _uploadFile() async {
    if (_fileName == null) {
      return null;
    }

    final fileName = _fileName!;
    final fileExt = fileName.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'uploads/${timestamp}-${fileName}';
    String contentType = 'application/octet-stream';

    switch (fileExt.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'pdf':
        contentType = 'application/pdf';
        break;
    }

    try {
      if (kIsWeb) {
        if (_fileBytes == null) {
          _logger.e('Webda fayl baytlari null');
          return null;
        }
        await supabase.storage.from('company_docs').uploadBinary(
              storagePath,
              _fileBytes!,
              fileOptions: FileOptions(contentType: contentType),
            );
      } else {
        if (_filePath == null) {
          _logger.e('Mobil qurilmada fayl yo\'li null');
          return null;
        }
        final file = File(_filePath!);
        await supabase.storage.from('company_docs').upload(
              storagePath,
              file,
              fileOptions: FileOptions(contentType: contentType),
            );
      }

      final response =
          supabase.storage.from('company_docs').getPublicUrl(storagePath);
      return response;
    } catch (error) {
      _logger.e('Faylni yuklashda xatolik: $error');
      return null;
    }
  }

  Future<void> _openMapGuide() async {
    try {
      final response = await supabase
          .from('links')
          .select('link')
          .eq('name', 'manzil')
          .single();
      final guideLink = response['link'] as String;
      if (await canLaunchUrlString(guideLink)) {
        await launchUrlString(guideLink);
      } else {
        _logger.e('Qo\'llanma linkini ochishda xatolik: $guideLink');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.translate('guide_link_error_open')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Qo\'llanma linkini olishda xatolik: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.translate('guide_link_error_fetch')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _calculatePrice() {
    int positionCount = _employeePositions.length;
    if (positionCount <= 10) {
      return 60000;
    } else if (positionCount <= 30) {
      return 100000;
    } else if (positionCount <= 60) {
      return 180000;
    } else {
      return 180000; // Default to the highest tier if more than 60, or define a new tier if needed
    }
  }

  Future<void> _applyForAccount(BuildContext context) async {
    if (!_regFormKey.currentState!.validate()) {
      return;
    }

    if (_fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.translate('check_upload_required'),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _regIsLoading = true;
    });

    final adminEmail = _adminEmailController.text.trim();
    final phoneNumber =
        '+998${_phoneNumberController.text.replaceAll(RegExp(r'[^0-9]'), '')}';

    final existingEmail = await supabase
        .from('requests')
        .select()
        .eq('admin_email', adminEmail)
        .maybeSingle();

    if (existingEmail != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.translate('existing_email'),
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _regIsLoading = false;
      });
      return;
    }

    final existingPhone = await supabase
        .from('requests')
        .select()
        .eq('phone', phoneNumber)
        .maybeSingle();

    if (existingPhone != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.translate('existing_phone'),
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _regIsLoading = false;
      });
      return;
    }

    String? fileUrl;
    if (_fileName != null) {
      fileUrl = await _uploadFile();
      if (fileUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.translate('file_upload_error'),
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }

        setState(() => _regIsLoading = false);
        return;
      }
    }

    try {
      final positionsString =
          _employeePositions.map((item) => item['position']).join(', ');
      final fullNamesString =
          _employeePositions.map((item) => item['fullName']).join(', ');
      final phone = phoneNumber;
      final priceUZS = _calculatePrice();

      int? employeeCount = int.tryParse(_employeesCountController.text);
      if (employeeCount == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.translate('employees_count_number'),
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }

        setState(() {
          _regIsLoading = false;
        });
        return;
      }

      await supabase.from('requests').insert({
        'company_name': _companyNameController.text,
        'employees_count': employeeCount,
        'employee_positions': positionsString,
        'full_names': fullNamesString,
        'arrival_time': _arrivalTimeController.text,
        'departure_time': _departureTimeController.text,
        'admin_email': adminEmail,
        'admin_password': _adminPasswordController.text,
        'phone': phone,
        'request_time': DateTime.now().toIso8601String(),
        'status': 'pending',
        'payment_check_url': fileUrl,
        'lat': _latitudeController.text,
        'lon': _longitudeController.text,
        'price': priceUZS, // Save the calculated price
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminEmail', adminEmail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.translate(
                    'application_submitted_toast'), // Show toast message
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
      widget.onViewToggle();
    } catch (error) {
      _logger.e(
          'Ariza berishda xatolik: ${widget.translate('application_error')} ${error.toString()}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.translate('application_error')} ${error.toString()}',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _regIsLoading = false;
        });
      }
    }
  }

  Future<void> _showPaymentPopup(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.translate(
              'payment_instructions_title')), // Use widget.translate here
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if (_paymentDetailsList.isNotEmpty)
                  ExpansionPanelList.radio(
                    children: _paymentDetailsList.map<ExpansionPanelRadio>(
                        (Map<String, dynamic> paymentDetail) {
                      return ExpansionPanelRadio(
                        value: paymentDetail['name'] ?? 'Payment Option',
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(paymentDetail['name'] ?? 'N/A'),
                          );
                        },
                        body: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${paymentDetail['name'] ?? 'N/A'}'),
                              Text('Code: ${paymentDetail['code'] ?? 'N/A'}'),
                              Text('Owner: ${paymentDetail['owner'] ?? 'N/A'}'),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text('No payment details available.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                  widget.translate('back_button')), // Use widget.translate here
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int calculatedPriceUZS = _calculatePrice();
    final double usdRate = 60000 / 4.66; // Approximate rate from prompt
    final double rubRate = 60000 / 399.84; // Approximate rate from prompt

    final double calculatedPriceUSD = calculatedPriceUZS / usdRate;
    final double calculatedPriceRUB = calculatedPriceUZS / rubRate;

    final formattedUSD =
        NumberFormat("#,##0.00", "en_US").format(calculatedPriceUSD);
    final formattedRUB =
        NumberFormat("#,##0.00", "ru_RU").format(calculatedPriceRUB);
    final formattedUZS =
        NumberFormat("#,##0", "uz_UZ").format(calculatedPriceUZS);

    return MUILoginCard(
      child: Form(
        key: _regFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                widget.translate('registration_title'),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
                textAlign: TextAlign.center,
              ),
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _companyNameController,
              placeholder: widget.translate('company_name_placeholder'),
              prefixIcon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.translate('company_name_required');
                }
                return null;
              },
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _employeesCountController,
              placeholder: widget.translate('employees_count_placeholder'),
              prefixIcon: Icons.people,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.translate('employees_count_required');
                }
                if (int.tryParse(value) == null) {
                  return widget.translate('employees_count_number');
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: MUIFormInput(
                    primaryColor: primaryColor,
                    controller: _positionController,
                    placeholder: widget.translate('position_placeholder'),
                    prefixIcon: Icons.work,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MUIFormInput(
                    primaryColor: primaryColor,
                    controller: _fullNameController,
                    placeholder: widget.translate('fullname_placeholder'),
                    prefixIcon: Icons.person,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF6200EE)),
                  onPressed: _addPosition,
                ),
              ],
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _employeePositions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.translate('position_placeholder')}: ${_employeePositions[index]['position']}, ${widget.translate('fullname_placeholder')}: ${_employeePositions[index]['fullName']}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.redAccent),
                          onPressed: () => _removePosition(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: MUIFormInput(
                    primaryColor: primaryColor,
                    controller: _arrivalTimeController,
                    placeholder: widget.translate('arrival_time_placeholder'),
                    prefixIcon: Icons.access_time,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final newText = newValue.text;
                        if (newText.length <= 5) {
                          return newValue;
                        } else {
                          return oldValue;
                        }
                      })
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.translate('arrival_time_required');
                      }
                      if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$')
                          .hasMatch(value)) {
                        return widget.translate('arrival_time_format');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(' - ', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: MUIFormInput(
                    primaryColor: primaryColor,
                    controller: _departureTimeController,
                    placeholder: widget.translate('departure_time_placeholder'),
                    prefixIcon: Icons.access_time,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final newText = newValue.text;
                        if (newText.length <= 5) {
                          return newValue;
                        } else {
                          return oldValue;
                        }
                      })
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.translate('departure_time_required');
                      }
                      if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$')
                          .hasMatch(value)) {
                        return widget.translate('departure_time_format');
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _adminEmailController,
              placeholder: widget.translate('admin_email_placeholder'),
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.translate('admin_email_required');
                }
                if (!value.contains('@')) {
                  return widget.translate('admin_email_invalid');
                }
                return null;
              },
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _adminPasswordController,
              placeholder: widget.translate('admin_password_placeholder'),
              prefixIcon: Icons.lock,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.translate('admin_password_required');
                }
                return null;
              },
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _phoneNumberController,
              placeholder: widget
                  .translate('phone_number_placeholder'), // Changed placeholder
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.translate('phone_number_required');
                }
                if (!RegExp(r'^[9]{1}[01345789]{1}[0-9]{7}$').hasMatch(value)) {
                  return widget.translate('phone_number_invalid');
                }
                return null;
              },
            ),
            Row(
              children: [
                Expanded(
                  child: MUIFormInput(
                    primaryColor: primaryColor,
                    controller: _latitudeController,
                    placeholder: widget.translate('latitude_placeholder'),
                    prefixIcon: Icons.location_on,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.translate('latitude_required');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MUIFormInput(
                    primaryColor: primaryColor,
                    controller: _longitudeController,
                    placeholder: widget.translate('longitude_placeholder'),
                    prefixIcon: Icons.location_on,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.translate('longitude_required');
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map, color: Color(0xFF6200EE)),
                  onPressed: _openMapGuide,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.translate('payment_calculation_title'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.translate('price_per_year')}: $formattedUZS UZS',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '≈ $formattedUSD USD',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '≈ $formattedRUB RUB',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            MUIOutlinedButton(
              text: widget.translate('pay_button'), // Changed button text
              onPressed: () => _showPaymentPopup(context),
              textColor: primaryColor,
            ),
            const SizedBox(height: 12),
            MUIPrimaryButton(
              text: widget.translate('upload_check_button'),
              onPressed: _pickFile,
            ),
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${widget.translate('selected_file')} $_fileName',
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            MUIPrimaryButton(
              text: widget.translate('apply_button'),
              onPressed: () => _applyForAccount(context),
              isLoading: _regIsLoading,
            ),
            const SizedBox(height: 12),
            MUISecondaryButton(
              text: widget.translate('back_to_landing'),
              onPressed: widget.onViewToggle,
              textColor: primaryColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
