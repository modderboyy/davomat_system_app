//login_page.dart
import 'dart:io';
import 'package:DavomatYettilik/admin.dart'; // Import the admin page
import 'package:DavomatYettilik/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
// import 'package:crypto/crypto.dart'; // Remove unused import
// import 'dart:convert'; // Remove unused import
// import 'dart:io';// Remove unused import

// Modular UI Components (Cards and Buttons) - No changes
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

class MUIPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const MUIPrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: backgroundColor ?? const Color(0xFF6200EE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}

class MUIOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? textColor;

  const MUIOutlinedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor ?? const Color(0xFF6200EE),
        side: BorderSide(color: textColor ?? const Color(0xFF6200EE)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Color(0xFF6200EE),
                strokeWidth: 2,
              ),
            )
          : Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}

class MUISecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;

  const MUISecondaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textColor = const Color(0xFF6200EE),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

class MUITransparentButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;

  const MUITransparentButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textColor = const Color(0xFF6200EE),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 14)),
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
    Key? key,
    required this.controller,
    required this.placeholder,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: Icon(prefixIcon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        ),
      ),
    );
  }
}

enum LoginViewType { landing, login, registration }

class LoginPage extends StatefulWidget {
  final void Function(bool) onLoginSuccess;

  const LoginPage({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginViewType _currentView = LoginViewType.landing;
  final _logger = Logger();
  String _currentLanguage = 'uz';

  // Localization maps
  final Map<String, String> _languageTitles = {
    'en': 'Attendance',
    'uz': 'Davomat',
    'ru': 'Davomat',
  };
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'login': 'Login',
      'register': 'Register',
      'login_title': 'Login',
      'register_title': 'Register',
      'landing_login': 'Login',
      'landing_register': 'Register',
      'back_button': 'Back',
      'email_placeholder': 'Email',
      'password_placeholder': 'Password',
      'login_button': 'Login',
      'back_to_home': 'Back to Home',
      'registration_title': 'Registration',
      'fill_data': 'Fill in the details',
      'company_name_placeholder': 'Company Name',
      'admin_email_placeholder': 'Admin Email',
      'admin_password_placeholder': 'Admin Password',
      'create_account_button': 'Create Account',
      'email_required': 'Enter email',
      'password_required': 'Enter password',
      'company_name_required': 'Enter company name',
      'admin_email_required': 'Enter admin email',
      'admin_email_invalid': 'Enter valid email',
      'admin_password_required': 'Enter admin password',
      'existing_email': 'This email is already registered.',
      'registration_error': 'Error during registration: ',
      'confirm_email_sent': 'Confirmation email sent. Please check your inbox.',
      'back_to_landing': 'Back to Home',
      'guide_link_error_open': 'Error opening guide link: ',
      'guide_link_error_fetch': 'Error fetching guide link: ',
      'location_guide': 'Location Guide',
      'guide_button_text': 'Guide',
    },
    'uz': {
      'login': 'Kirish',
      'register': "Ro'yxatdan o'tish",
      'login_title': 'Kirish',
      'register_title': "Ro'yxatdan o'tish",
      'landing_login': 'Kirish',
      'landing_register': "Ro'yxatdan o'tish",
      'back_button': "Orqaga",
      'email_placeholder': "Email",
      'password_placeholder': "Parol",
      'login_button': "Kirish",
      'back_to_home': "Bosh sahifaga qaytish",
      'registration_title': "Ro'yxatdan o'tish",
      'fill_data': "Ma'lumotlarni to'ldiring",
      'company_name_placeholder': "Kompaniya nomi",
      'admin_email_placeholder': "Admin Email",
      'admin_password_placeholder': "Admin Parol",
      'create_account_button': "Akkaunt Yaratish",
      'email_required': "Emailni kiriting",
      'password_required': "Parolni kiriting",
      'company_name_required': "Kompaniya nomini kiriting",
      'admin_email_required': "Admin emailni kiriting",
      'admin_email_invalid': "Yaroqli email kiriting",
      'admin_password_required': "Admin parolni kiriting",
      'existing_email': "Ushbu email allaqachon ro'yxatdan o'tgan.",
      'registration_error': "Ro'yxatdan o'tishda xatolik: ",
      'confirm_email_sent':
          "Tasdiqlash xati yuborildi. Iltimos, pochta qutingizni tekshiring.",
      'back_to_landing': "Bosh sahifaga qaytish",
      'guide_link_error_open': "Qo'llanma linkini ochishda xatolik: ",
      'guide_link_error_fetch': "Qo'llanma linkini olishda xatolik yuz berdi: ",
      'location_guide': "Manzil Qo'llanmasi",
      'guide_button_text': "Qo'llanma",
    },
    'ru': {
      'login': 'Войти',
      'register': 'Регистрация',
      'login_title': 'Вход',
      'register_title': 'Регистрация',
      'landing_login': 'Войти',
      'landing_register': 'Регистрация',
      'back_button': 'Назад',
      'email_placeholder': 'Электронная почта',
      'password_placeholder': 'Пароль',
      'login_button': 'Войти',
      'back_to_home': 'Вернуться на главную',
      'registration_title': 'Регистрация',
      'fill_data': 'Заполните данные',
      'company_name_placeholder': 'Название компании',
      'admin_email_placeholder': 'Электронная почта администратора',
      'admin_password_placeholder': 'Пароль администратора',
      'create_account_button': 'Создать аккаунт',
      'email_required': 'Введите электронную почту',
      'password_required': 'Введите пароль',
      'company_name_required': 'Введите название компании',
      'admin_email_required': 'Введите электронную почту администратора',
      'admin_email_invalid': 'Введите действительную электронную почту',
      'admin_password_required': 'Введите пароль администратора',
      'existing_email': 'Эта электронная почта уже зарегистрирована.',
      'registration_error': 'Ошибка при регистрации: ',
      'confirm_email_sent':
          'Письмо с подтверждением отправлено. Пожалуйста, проверьте свой почтовый ящик.',
      'back_to_landing': 'Вернуться на главную',
      'guide_link_error_open': 'Ошибка открытия ссылки на руководство: ',
      'guide_link_error_fetch': 'Ошибка получения ссылки на руководство: ',
      'location_guide': 'Руководство по местоположению',
      'guide_button_text': 'Руководство',
    },
  };

  // Language preference methods
  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'uz';
    });
  }

  Future<void> _setLanguagePreference(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _currentLanguage = language;
    });
  }

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]![key] ??
        _localizedStrings['uz']![key]!;
  }

  // View toggling methods
  void _toggleToRegister() {
    setState(() {
      _currentView = LoginViewType.registration;
    });
  }

  void _toggleToLogin() {
    setState(() {
      _currentView = LoginViewType.login;
    });
  }

  void _toggleToLanding() {
    setState(() {
      _currentView = LoginViewType.landing;
    });
  }

// Main build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        leading: _currentView != LoginViewType.landing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentView == LoginViewType.registration ||
                      _currentView == LoginViewType.login) {
                    _toggleToLanding();
                  }
                },
              )
            : null,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6200EE)),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: _translate('guide_button_text'),
            onPressed: _openGuideLink,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String language) {
              _setLanguagePreference(language);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'en',
                child: Text('English'),
              ),
              const PopupMenuItem<String>(
                value: 'uz',
                child: Text("O'zbek"),
              ),
              const PopupMenuItem<String>(
                value: 'ru',
                child: Text('Русский'),
              ),
            ],
          ),
        ],
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Container(
            color: Colors.white,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildView(),
            ),
          ),
        ),
      ),
    );
  }

  // AppBar title logic
  String _getAppBarTitle() {
    switch (_currentView) {
      case LoginViewType.registration:
        return _translate('register_title');
      case LoginViewType.login:
        return _translate('login_title');
      case LoginViewType.landing:
      default:
        return _languageTitles[_currentLanguage]!;
    }
  }

  // View building based on current state
  Widget _buildView() {
    switch (_currentView) {
      case LoginViewType.registration:
        return RegistrationView(
            onViewToggle: _toggleToLanding, translate: _translate);
      case LoginViewType.login:
        return LoginView(
          onLoginSuccess: widget.onLoginSuccess,
          onViewToggle: _toggleToLanding,
          translate: _translate,
        );
      case LoginViewType.landing:
      default:
        return _buildLandingPage(context);
    }
  }

  // Landing page building
  Widget _buildLandingPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: Image.asset(
                  'assets/logo.png',
                  height: 150,
                ),
              ),
            ),
          ),
          MUIPrimaryButton(
            text: _translate('landing_login'),
            onPressed: () {
              _toggleToLogin();
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6200EE),
              side: const BorderSide(color: Color(0xFF6200EE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            onPressed: () {
              _toggleToRegister();
            },
            child: Text(_translate('landing_register'),
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // Guide link opening
  Future<void> _openGuideLink() async {
    try {
      final response = await supabase
          .from('links')
          .select('link')
          .eq('name', 'guide')
          .single();
      final guideLink = response['link'] as String;
      if (await canLaunchUrlString(guideLink)) {
        await launchUrlString(guideLink);
      } else {
        _logger.e('Error opening guide link: $guideLink');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_translate('guide_link_error_open')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error fetching guide link: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translate('guide_link_error_fetch')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Registration View
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
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _isLoading = false;
  final _logger = Logger();
  final Color primaryColor = const Color(0xFF3700B3);

  @override
  void dispose() {
    _companyNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final companyName = _companyNameController.text.trim();
    final adminEmail = _adminEmailController.text.trim();
    final adminPassword = _adminPasswordController.text.trim();

    try {
      // Check if the email is already registered in your *users* table.
      final existingUser = await supabase
          .from('users')
          .select('email')
          .eq('email', adminEmail)
          .maybeSingle();

      if (existingUser != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.translate('existing_email')),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Sign up the user (this sends a confirmation email).
      final authResponse = await supabase.auth.signUp(
        email: adminEmail,
        password: adminPassword,
      );

      if (authResponse.user != null) {
        // 1. Create Company
        final companyResponse = await supabase.from('companies').insert({
          'company_name': companyName,
        }).select('id');

        final companyId = companyResponse[0]['id'];

        // 2.  *UPDATE* the user, don't insert.
        if (mounted) {
          //UPDATE in users table
          await supabase.from('users').upsert({
            'id': authResponse.user!.id, // Use the user's ID from auth
            'email': adminEmail,
            'is_super_admin': true,
            'lavozim': companyName,
            'company_id': companyId,
            'name': "Admin",
          }, onConflict: 'id'); // Specify the conflict resolution strategy

          // STORE is_super_admin IN SHARED PREFERENCES
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_super_admin', true);

          // Log login activity
          await supabase.from('login_activities').insert({
            'user_id': authResponse.user!.id,
            'login_time': DateTime.now().toIso8601String(),
            'success': true,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.translate('confirm_email_sent')),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPage()),
          ); // Go to Admin Page
        }
      } else if (authResponse.session == null) {
        //Check authResponse.session
        // Handle email confirmation case specifically (no user, but session)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.translate('confirm_email_sent')),
              backgroundColor: Colors.orange,
            ),
          );

          final user = await supabase
              .from('users')
              .select('id')
              .eq('email', adminEmail)
              .maybeSingle();
          if (user != null) {
            await supabase.from('login_activities').insert({
              'user_id': user['id'],
              'login_time': DateTime.now().toIso8601String(),
              'success': false, //set false
            });
          }
          widget.onViewToggle(); // Go back to landing page
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResponse.user?.email ?? 'Registration Failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on AuthException catch (error) {
      _logger.e('Auth error: ${error.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.translate('registration_error')}${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      _logger.e('Registration error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.translate('registration_error')}$error'),
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

  @override
  Widget build(BuildContext context) {
    return MUILoginCard(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.translate('registration_title'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.translate('fill_data'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 32),
            MUIPrimaryButton(
              text: widget.translate('create_account_button'),
              onPressed: _register,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            MUISecondaryButton(
              text: widget.translate('back_to_landing'),
              onPressed: widget.onViewToggle,
              textColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// Login View
class LoginView extends StatefulWidget {
  final void Function(bool) onLoginSuccess;
  final VoidCallback onViewToggle;
  final String Function(String) translate;

  const LoginView({
    Key? key,
    required this.onLoginSuccess,
    required this.onViewToggle,
    required this.translate,
  }) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();

  static _LoginViewState? of(BuildContext context) =>
      context.findAncestorStateOfType<_LoginViewState>();

  static bool isCheckingStatusGlobal = false;
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _logger = Logger();
  bool _isCheckingStatus = false;
  final Color primaryColor = const Color(0xFF3700B3);

  void _setIsCheckingStatus(bool value) {
    setState(() {
      _isCheckingStatus = value;
      LoginView.isCheckingStatusGlobal = value;
    });
  }

  @override
  void initState() {
    super.initState();
    LoginView.isCheckingStatusGlobal = false;
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
        // Successfully signed in

        await supabase.from('login_activities').insert({
          'user_id': response.user!.id,
          'login_time': DateTime.now().toIso8601String(),
          'success': true,
        });

        // CHECK FOR is_super_admin
        final userDetails = await supabase
            .from('users')
            .select('is_super_admin')
            .eq('id', response.user!.id)
            .single();

        // STORE is_super_admin IN SHARED PREFERENCES
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            'is_super_admin', userDetails['is_super_admin'] == true);

        if (userDetails['is_super_admin'] == true) {
          // Navigate to admin.dart
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminPage()),
          );
        } else {
          // Regular user login (your existing logic)
          widget.onLoginSuccess(true); // Notify successful login
        }
      }
    } on AuthException catch (error) {
      _logger.e('Login error: ${error.message}');
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
            .from('users') //CHANGED: Use 'users' table
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
        _logger.e('Error writing login log: $logError');
      }
    } catch (error) {
      _logger.e('Unexpected error: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
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

  @override
  Widget build(BuildContext context) {
    return MUILoginCard(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _emailController,
              placeholder: widget.translate('email_placeholder'),
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.translate('email_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _passwordController,
              placeholder: widget.translate('password_placeholder'),
              prefixIcon: Icons.lock,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.translate('password_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            MUIPrimaryButton(
              text: widget.translate('login_button'),
              onPressed: _signIn,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            MUISecondaryButton(
              text: widget.translate('back_to_home'),
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
