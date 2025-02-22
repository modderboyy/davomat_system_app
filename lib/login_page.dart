import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:DavomatYettilik/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';
import 'package:url_launcher/url_launcher_string.dart';

// Modular UI Components (Cards and Buttons)
class MUILoginCard extends StatelessWidget {
  final Widget child;

  const MUILoginCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
        ),
        child: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }
}

class MUIPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor; // Allow custom background color

  const MUIPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor, // Initialize custom background color
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      borderRadius: BorderRadius.circular(12),
      onPressed: isLoading ? null : onPressed,
      // Use provided color or default
      child: isLoading
          ? const CupertinoActivityIndicator()
          : Text(text, style: const TextStyle(color: CupertinoColors.white)),
    );
  }
}

class MUISecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;

  const MUISecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor = CupertinoColors.activeBlue,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      borderRadius: BorderRadius.circular(12),
      child: Text(text, style: TextStyle(color: textColor)),
      onPressed: onPressed,
    );
  }
}

// Transparent Background Button
class MUITransparentButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;

  const MUITransparentButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor = CupertinoColors.activeBlue,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: CupertinoColors.white.withOpacity(0.0),
      borderRadius: BorderRadius.circular(12),
      child: Text(text, style: TextStyle(color: textColor)),
      onPressed: onPressed,
    );
  }
}

class MUIFormInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Color primaryColor;

  const MUIFormInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: CupertinoTextFormFieldRow(
          prefix: Icon(prefixIcon, color: primaryColor),
          placeholder: placeholder,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          placeholderStyle: theme.textTheme.textStyle
              .copyWith(color: CupertinoColors.placeholderText),
          validator: validator,
          inputFormatters: inputFormatters,
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final void Function(bool) onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isRegistering = false;

  void _toggleView() {
    setState(() {
      _isRegistering = !_isRegistering;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? CupertinoColors.systemGrey6.resolveFrom(context)
          : CupertinoColors.extraLightBackgroundGray,
      body: SuperScaffold(
        appBar: SuperAppBar(
          title: Text(_isRegistering ? 'Ro\'yxatdan o\'tish' : 'Kirish'),
          automaticallyImplyLeading: false, // Remove default back button
          leading: _isRegistering || LoginView.isCheckingStatusGlobal
              ? CupertinoButton(
                  // Conditionally show back button
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.back, color: CupertinoColors.link),
                  onPressed: () {
                    if (_isRegistering) {
                      _toggleView(); // Go back from registration to login
                    } else if (LoginView.isCheckingStatusGlobal) {
                      LoginView.of(context)?._setIsCheckingStatus(
                          false); // Go back from status view to login
                    }
                  },
                )
              : null,
          largeTitle: SuperLargeTitle(
            enabled: true,
            largeTitle: _isRegistering ? "Ro'yxatdan o'tish" : "Kirish",
          ),
          searchBar: SuperSearchBar(
            enabled: false,
          ),
          backgroundColor: isDarkMode
              ? CupertinoColors.systemGrey6.resolveFrom(context)
              : CupertinoColors.white,
          border: const Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey4,
              width: 0.0,
            ),
          ),
        ),
        body: SafeArea(
          child: _isRegistering
              ? RegistrationView(onViewToggle: _toggleView)
              : LoginView(
                  onLoginSuccess: widget.onLoginSuccess,
                  onViewToggle: _toggleView),
        ),
      ),
    );
  }
}

class LoginView extends StatefulWidget {
  final void Function(bool) onLoginSuccess;
  final VoidCallback onViewToggle;

  const LoginView(
      {super.key, required this.onLoginSuccess, required this.onViewToggle});

  @override
  _LoginViewState createState() => _LoginViewState();

  static _LoginViewState? of(BuildContext context) =>
      context.findAncestorStateOfType<_LoginViewState>();

  static bool isCheckingStatusGlobal =
      false; // Static variable to track status globally
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _logger = Logger();
  bool _isCheckingStatus = false;
  String? _applicationStatus;
  List<Map<String, dynamic>>? _userDetails;
  String? _companyPassword;
  bool _statusLoading = false;
  final Color primaryColor = const Color(0xFF3700B3); // Define primaryColor

  // Method to set _isCheckingStatus from outside
  void _setIsCheckingStatus(bool value) {
    setState(() {
      _isCheckingStatus = value;
      LoginView.isCheckingStatusGlobal = value; // Update global static variable
    });
  }

  @override
  void initState() {
    super.initState();
    LoginView.isCheckingStatusGlobal = false; // Initialize global state
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await supabase.from('login_activities').insert({
          'user_id': response.user!.id,
          'login_time': DateTime.now().toIso8601String(),
          'success': true,
        });
        _logger.i('Foydalanuvchi tizimga kirdi: ${response.user!.id}');
        widget.onLoginSuccess(true);
      }
    } on AuthException catch (error) {
      _logger.e('Kirish xatosi: ${error.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }

      final email = _emailController.text.trim();
      try {
        final user = await supabase
            .from('profiles')
            .select('id')
            .eq('email', email)
            .maybeSingle();
        if (user != null) {
          await supabase.from('login_activities').insert({
            'user_id': user['id'],
            'login_time': DateTime.now().toIso8601String(),
            'success': false,
          });
        }
      } catch (logError) {
        _logger.e('Login logini yozishda xatolik: $logError');
      }
    } catch (error) {
      _logger.e('Kutilmagan xatolik: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kutilmagan xatolik yuz berdi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchApplicationStatus() async {
    _setIsCheckingStatus(true); // Use the setter method
    setState(() {
      _statusLoading = true;
      _applicationStatus = null; // Reset status
      _userDetails = null; // Reset user details
      _companyPassword = null; // Reset company password
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? adminEmail = prefs.getString('adminEmail');

    if (adminEmail != null && adminEmail.isNotEmpty) {
      try {
        final request = await supabase
            .from('requests')
            .select('status, company_name')
            .eq('admin_email', adminEmail)
            .single();
        final status = request['status'] as String;
        final companyName = request['company_name'] as String;

        setState(() {
          _applicationStatus = status;
        });

        if (status == 'active') {
          await _fetchUserDetails(companyName);
        }
      } catch (e) {
        _logger.e('Error fetching application status: $e');
        setState(() {
          _applicationStatus = null;
        });
      } finally {
        setState(() {
          _statusLoading = false;
        });
      }
    } else {
      setState(() {
        _statusLoading = false;
      });
    }
  }

  Future<void> _fetchUserDetails(String companyName) async {
    try {
      final company = await supabase
          .from('companies')
          .select('id, password')
          .eq('company_name', companyName)
          .single();
      final companyId = company['id'];
      _companyPassword = company['password'];

      final users = await supabase
          .from('users')
          .select('email, name, lavozim')
          .eq('company_id', companyId);

      setState(() {
        _userDetails = List<Map<String, dynamic>>.from(users);
      });
    } catch (e) {
      _logger.e('Error fetching user details: $e');
      setState(() {
        _userDetails = null;
        _companyPassword = null;
      });
    }
  }

  Widget _buildStatusView(BuildContext context) {
    if (_statusLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_applicationStatus == 'pending')
            Center(
              child: Text(
                'Sizning arizangiz ko\'rib chiqilmoqda... Biz tez orada sizga aloqaga chiqamiz.',
                textAlign: TextAlign.center,
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
            )
          else if (_applicationStatus == 'active')
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Siz muvaffaqiyatli ro\'yxatdan o\'tdingiz, mana marhamat sizning login parollaringiz:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_userDetails != null && _companyPassword != null) ...[
                    const Text(
                      'Kompaniya Paroli:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_companyPassword!),
                    const SizedBox(height: 20),
                    const Text(
                      'Foydalanuvchilar:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _userDetails!.length,
                      itemBuilder: (context, index) {
                        final user = _userDetails![index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${user['email'] ?? 'N/A'}'),
                              Text('Ism: ${user['name'] ?? 'N/A'}'),
                              Text('Lavozim: ${user['lavozim'] ?? 'N/A'}'),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const Text(
                        'Foydalanuvchi ma\'lumotlarini yuklashda xatolik yuz berdi.'),
                  ],
                ],
              ),
            )
          else if (_applicationStatus == 'rejected')
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Arizangiz qabul qilinmadi.',
                    textAlign: TextAlign.center,
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agar sizga aloqaga chiqilmagan bo\'lsa, telegramdan aloqaga chiqing: @davomat_admin',
                    style: TextStyle(
                        fontSize: 14, color: CupertinoColors.systemRed),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Center(
              child: Text(
                'Ariza holati topilmadi.',
                textAlign: TextAlign.center,
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
            ),
          const SizedBox(height: 20),
          CupertinoButton(
            child: const Text('Orqaga'),
            onPressed: () {
              _setIsCheckingStatus(false); // Use the setter method
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MUILoginCard(
      child: _isCheckingStatus
          ? _buildStatusView(context)
          : Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Image.asset(
                      'assets/logo.png', // Add your logo image here
                      height: 120,
                    ),
                  ),
                  MUIFormInput(
                    primaryColor: primaryColor,
                    controller: _emailController,
                    placeholder: 'Email',
                    prefixIcon: CupertinoIcons.mail_solid,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Emailni kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  MUIFormInput(
                    primaryColor: primaryColor,
                    controller: _passwordController,
                    placeholder: 'Parol',
                    prefixIcon: CupertinoIcons.padlock_solid,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Parolni kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  MUIPrimaryButton(
                    text: 'Kirish',
                    onPressed: _signIn,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 12),
                  MUISecondaryButton(
                    text: 'Hisobingiz yo\'qmi? Ro\'yxatdan o\'tish',
                    onPressed: widget.onViewToggle,
                    textColor: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  MUITransparentButton(
                    // Use MUITransparentButton
                    text: 'Arizamni tekshirish',
                    onPressed: _fetchApplicationStatus,
                    textColor: primaryColor,
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }
}

class RegistrationView extends StatefulWidget {
  final VoidCallback onViewToggle;

  const RegistrationView({super.key, required this.onViewToggle});

  @override
  _RegistrationViewState createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _regFormKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _employeesCountController = TextEditingController();
  final _arrivalTimeController =
      TextEditingController(); // Arrival time controller
  final _departureTimeController =
      TextEditingController(); // Departure time controller
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _latitudeController = TextEditingController(); // Latitude controller
  final _longitudeController = TextEditingController(); // Longitude controller
  bool _regIsLoading = false;
  final _logger = Logger();

  final List<Map<String, String>> _employeePositions =
      []; // List of maps to store position and full name
  final _positionController = TextEditingController();
  final _fullNameController = TextEditingController(); // Full name controller

  String? _filePath;
  String? _fileUrl;
  String? _fileName;
  Uint8List? _fileBytes;

  final Color primaryColor = const Color(0xFF3700B3); // Define primaryColor

  void _addPosition() {
    final position = _positionController.text.trim();
    final fullName = _fullNameController.text.trim(); // Get full name
    if (position.isNotEmpty && fullName.isNotEmpty) {
      // Ensure both are not empty
      setState(() {
        _employeePositions
            .add({'position': position, 'fullName': fullName}); // Store as map
        _positionController.clear();
        _fullNameController.clear(); // Clear full name field as well
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lavozim va Ism-Familiyani kiriting',
              style: TextStyle(color: CupertinoColors.white)),
          backgroundColor: CupertinoColors.systemRed,
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
    final storagePath = 'uploads/$timestamp-$fileName';
    String contentType = 'application/octet-stream';

    switch (fileExt.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
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
            const SnackBar(
              content: Text('Qo\'llanma linkini ochishda xatolik yuz berdi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Qo\'llanma linkini olishda xatolik: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Qo\'llanma linkini olishda xatolik yuz berdi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyForAccount(BuildContext context) async {
    if (!_regFormKey.currentState!.validate()) {
      return;
    }

    if (_fileName == null) {
      // **Validation for file upload**
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chekni yuklang',
              style: TextStyle(color: CupertinoColors.white)),
          backgroundColor: CupertinoColors.systemRed,
        ),
      );
      return; // Prevent form submission if no file is selected
    }

    setState(() {
      _regIsLoading = true;
    });

    final adminEmail = _adminEmailController.text.trim();
    final phoneNumber =
        '+998${_phoneNumberController.text.replaceAll(RegExp(r'[^0-9]'), '')}';

    // Check for existing email
    final existingEmail = await supabase
        .from('requests')
        .select()
        .eq('admin_email', adminEmail)
        .maybeSingle();

    if (existingEmail != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ushbu email allaqachon ro\'yxatdan o\'tgan.',
                style: TextStyle(color: CupertinoColors.white)),
            backgroundColor: CupertinoColors.systemRed,
          ),
        );
      }
      setState(() {
        _regIsLoading = false;
      });
      return;
    }

    // Check for existing phone
    final existingPhone = await supabase
        .from('requests')
        .select()
        .eq('phone', phoneNumber)
        .maybeSingle();

    if (existingPhone != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Ushbu telefon raqami allaqachon ro\'yxatdan o\'tgan.',
                style: TextStyle(color: CupertinoColors.white)),
            backgroundColor: CupertinoColors.systemRed,
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
            const SnackBar(
              content: Text("Faylni yuklashda xatolik yuz berdi.",
                  style: TextStyle(color: CupertinoColors.white)),
              backgroundColor: CupertinoColors.systemRed,
            ),
          );
        }

        setState(() => _regIsLoading = false);
        return;
      }
    }

    try {
      final positionsString = _employeePositions
          .map((item) => item['position'])
          .join(', '); // Get positions
      final fullNamesString = _employeePositions
          .map((item) => item['fullName'])
          .join(', '); // Get full names
      final phone = phoneNumber;

      int? employeeCount = int.tryParse(_employeesCountController.text);
      if (employeeCount == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xodimlar soni maydoniga faqat raqam kiriting.',
                  style: TextStyle(color: CupertinoColors.white)),
              backgroundColor: CupertinoColors.systemRed,
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
        'full_names': fullNamesString, // Save full names
        'arrival_time': _arrivalTimeController.text, // Save arrival time
        'departure_time': _departureTimeController.text, // Save departure time
        'admin_email': adminEmail,
        'admin_password': _adminPasswordController.text,
        'phone': phone,
        'request_time': DateTime.now().toIso8601String(),
        'status': 'pending',
        'payment_check_url': fileUrl,
        'lat': _latitudeController.text, // Save latitude
        'lon': _longitudeController.text, // Save longitude
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminEmail', adminEmail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ariza berildi, kuting...',
                style: TextStyle(color: CupertinoColors.white)),
            backgroundColor: CupertinoColors.activeGreen,
          ),
        );
      }
      widget
          .onViewToggle(); // Switch back to login view after successful registration
    } catch (error) {
      _logger.e('Ariza berishda xatolik: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ariza berishda xatolik yuz berdi: ${error.toString()}',
                style: TextStyle(color: CupertinoColors.white)),
            backgroundColor: CupertinoColors.systemRed,
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

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;

    return MUILoginCard(
      child: Form(
        key: _regFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "Ma'lumotlarni to'ldiring",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
                textAlign: TextAlign.center,
              ),
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _companyNameController,
              placeholder: 'Kompaniya nomi',
              prefixIcon: CupertinoIcons.building_2_fill,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kompaniya nomini kiriting';
                }
                return null;
              },
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _employeesCountController,
              placeholder: 'Xodimlar soni',
              prefixIcon: CupertinoIcons.person_2_fill,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Xodimlar sonini kiriting';
                }
                if (int.tryParse(value) == null) {
                  return 'Raqam kiriting';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _positionController,
                        placeholder: 'Lavozim',
                        style: TextStyle(color: textColor),
                        placeholderStyle: theme.textTheme.textStyle
                            .copyWith(color: CupertinoColors.placeholderText),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                    ),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _fullNameController,
                        placeholder: 'Ism-familiya',
                        style: TextStyle(color: textColor),
                        placeholderStyle: theme.textTheme.textStyle
                            .copyWith(color: CupertinoColors.placeholderText),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.add_circled_solid,
                        color: primaryColor,
                      ),
                      onPressed: _addPosition,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                itemCount: _employeePositions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.secondarySystemFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lavozim: ${_employeePositions[index]['position']}',
                                    style: TextStyle(color: textColor),
                                  ),
                                  Text(
                                    'Ism-familiya: ${_employeePositions[index]['fullName']}',
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon(
                              CupertinoIcons.clear_circled_solid,
                              color: CupertinoColors.destructiveRed,
                            ),
                            onPressed: () => _removePosition(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: MUIFormInput(
                        primaryColor: primaryColor,
                        controller: _arrivalTimeController,
                        placeholder: 'Kelish vaqti (9:00)', // Arrival time
                        prefixIcon: CupertinoIcons.clock_fill,
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
                            return 'Kelish vaqtini kiriting';
                          }
                          if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$')
                              .hasMatch(value)) {
                            return 'Soat formatini kiriting (HH:MM)';
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
                        placeholder: 'Ketish vaqti (18:00)', // Departure time
                        prefixIcon: CupertinoIcons.clock_fill,
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
                            return 'Ketish vaqtini kiriting';
                          }
                          if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$')
                              .hasMatch(value)) {
                            return 'Soat formatini kiriting (HH:MM)';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _adminEmailController,
              placeholder: 'Admin Email',
              prefixIcon: CupertinoIcons.mail_solid,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Emailni kiriting';
                }
                if (!value.contains('@')) {
                  return 'Noto\'g\'ri email format';
                }
                return null;
              },
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _adminPasswordController,
              placeholder: 'Admin Parol',
              prefixIcon: CupertinoIcons.padlock_solid,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Parolni kiriting';
                }
                if (value.length < 6) {
                  return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
                }
                return null;
              },
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _phoneNumberController,
              placeholder: '+998 Telefon raqam',
              prefixIcon: CupertinoIcons.phone_solid,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                LengthLimitingTextInputFormatter(9),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Telefon raqamini kiriting';
                }
                if (value.length != 9) {
                  return '9 ta raqam kiriting';
                }
                return null;
              },
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _latitudeController,
              placeholder: 'Latitude',
              prefixIcon: CupertinoIcons.location_solid,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Latitude kiriting';
                }
                if (double.tryParse(value) == null) {
                  return 'Noto\'g\'ri format';
                }
                return null;
              },
            ),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _longitudeController,
              placeholder: 'Longitude',
              prefixIcon: CupertinoIcons.location_solid,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Longitude kiriting';
                }
                if (double.tryParse(value) == null) {
                  return 'Noto\'g\'ri format';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            MUIPrimaryButton(
              onPressed: _openMapGuide,
              text: 'Qo\'llanma',
            ),
            const SizedBox(height: 12),
            const Text(
              'Bir martalik to\'lov: 10\$',
              style: TextStyle(color: CupertinoColors.activeGreen),
              textAlign: TextAlign.center,
            ),
            const Text(
              "To'lov qilish uchun:",
              style: TextStyle(color: CupertinoColors.activeBlue),
              textAlign: TextAlign.center,
            ),
            const Text(
              "8600 0000 9000 8000 - Pardayev.M",
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              //color: CupertinoColors.systemGrey4,  // Removed 'color'
              padding: EdgeInsets.zero, // Added padding
              borderRadius: BorderRadius.circular(8),
              child: const Text('Chekni yuklash',
                  style: TextStyle(color: CupertinoColors.black)),
              onPressed: _pickFile,
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tanlangan fayl: $_fileName',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            MUIPrimaryButton(
              text: 'Ariza berish',
              onPressed: () => _applyForAccount(context),
              isLoading: _regIsLoading,
            ),
            const SizedBox(height: 12),
            MUISecondaryButton(
              text: 'Hisobingiz bormi? Kirish',
              onPressed: widget.onViewToggle,
              textColor: primaryColor,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
