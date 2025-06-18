import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:DavomatYettilik/main.dart'; // supabase instance uchun
import 'package:DavomatYettilik/admin.dart';

// Modern Animated Components
class ModernAnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ModernAnimatedCard({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<ModernAnimatedCard> createState() => _ModernAnimatedCardState();
}

class _ModernAnimatedCardState extends State<ModernAnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: 20.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;

  const ModernButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
  }) : super(key: key);

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        if (widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: widget.isPrimary
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF667eea),
                          const Color(0xFF764ba2),
                        ],
                      )
                    : null,
                border: !widget.isPrimary
                    ? Border.all(color: const Color(0xFF667eea), width: 2)
                    : null,
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: widget.isPrimary
                                  ? Colors.white
                                  : const Color(0xFF667eea),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: widget.isPrimary
                                  ? Colors.white
                                  : const Color(0xFF667eea),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const ModernTextField({
    Key? key,
    required this.controller,
    required this.placeholder,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: Colors.grey.shade300,
      end: const Color(0xFF667eea),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? const Color(0xFF667eea).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  blurRadius: _isFocused ? 20 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onTap: () {
                setState(() => _isFocused = true);
                _controller.forward();
              },
              onEditingComplete: () {
                setState(() => _isFocused = false);
                _controller.reverse();
              },
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  color: _colorAnimation.value,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _colorAnimation.value!,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18.0,
                  horizontal: 20.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LoadingIndicator extends StatefulWidget {
  final bool isVisible;

  const LoadingIndicator({Key? key, required this.isVisible}) : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value * 2 * 3.14159,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667eea),
                            const Color(0xFF764ba2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum LoginViewType { landing, login, registration }

class ModernLoginPage extends StatefulWidget {
  final void Function(bool) onLoginSuccess;

  const ModernLoginPage({Key? key, required this.onLoginSuccess})
      : super(key: key);

  @override
  State<ModernLoginPage> createState() => _ModernLoginPageState();
}

class _ModernLoginPageState extends State<ModernLoginPage>
    with TickerProviderStateMixin {
  LoginViewType _currentView = LoginViewType.landing;
  final _logger = Logger();
  String _currentLanguage = 'uz';
  late AnimationController _pageController;
  late Animation<Offset> _slideAnimation;

  // Localization maps (keeping your existing translations)
  final Map<String, String> _languageTitles = {
    'en': 'Attendance',
    'uz': 'Davomat',
    'ru': 'Davomat',
  };

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'login': 'Login',
      'register': 'Register',
      'login_title': 'Welcome Back',
      'register_title': 'Create Account',
      'landing_login': 'Sign In',
      'landing_register': 'Get Started',
      'back_button': 'Back',
      'email_placeholder': 'Email Address',
      'password_placeholder': 'Password',
      'login_button': 'Sign In',
      'back_to_home': 'Back to Home',
      'registration_title': 'Join Us',
      'fill_data': 'Create your account',
      'company_name_placeholder': 'Company Name',
      'admin_email_placeholder': 'Admin Email',
      'admin_password_placeholder': 'Admin Password',
      'create_account_button': 'Create Account',
      'email_required': 'Email is required',
      'password_required': 'Password is required',
      'company_name_required': 'Company name is required',
      'admin_email_required': 'Admin email is required',
      'admin_email_invalid': 'Please enter a valid email',
      'admin_password_required': 'Admin password is required',
      'existing_email': 'This email is already registered.',
      'registration_error': 'Registration error: ',
      'confirm_email_sent': 'Confirmation email sent. Please check your inbox.',
      'back_to_landing': 'Back to Home',
      'guide_button_text': 'Guide',
    },
    'uz': {
      'login': 'Kirish',
      'register': "Ro'yxatdan o'tish",
      'login_title': 'Xush kelibsiz',
      'register_title': "Akkaunt yaratish",
      'landing_login': 'Kirish',
      'landing_register': "Boshlash",
      'back_button': "Orqaga",
      'email_placeholder': "Email manzil",
      'password_placeholder': "Parol",
      'login_button': "Kirish",
      'back_to_home': "Bosh sahifaga qaytish",
      'registration_title': "Bizga qo'shiling",
      'fill_data': "Akkauntingizni yarating",
      'company_name_placeholder': "Kompaniya nomi",
      'admin_email_placeholder': "Admin Email",
      'admin_password_placeholder': "Admin Parol",
      'create_account_button': "Akkaunt Yaratish",
      'email_required': "Email talab qilinadi",
      'password_required': "Parol talab qilinadi",
      'company_name_required': "Kompaniya nomi talab qilinadi",
      'admin_email_required': "Admin email talab qilinadi",
      'admin_email_invalid': "Yaroqli email kiriting",
      'admin_password_required': "Admin parol talab qilinadi",
      'existing_email': "Ushbu email allaqachon ro'yxatdan o'tgan.",
      'registration_error': "Ro'yxatdan o'tishda xatolik: ",
      'confirm_email_sent':
          "Tasdiqlash xati yuborildi. Pochta qutingizni tekshiring.",
      'back_to_landing': "Bosh sahifaga qaytish",
      'guide_button_text': "Qo'llanma",
    },
    'ru': {
      'login': 'Войти',
      'register': 'Регистрация',
      'login_title': 'Добро пожаловать',
      'register_title': 'Создать аккаунт',
      'landing_login': 'Войти',
      'landing_register': 'Начать',
      'back_button': 'Назад',
      'email_placeholder': 'Email адрес',
      'password_placeholder': 'Пароль',
      'login_button': 'Войти',
      'back_to_home': 'Вернуться на главную',
      'registration_title': 'Присоединяйтесь',
      'fill_data': 'Создайте свой аккаунт',
      'company_name_placeholder': 'Название компании',
      'admin_email_placeholder': 'Email администратора',
      'admin_password_placeholder': 'Пароль администратора',
      'create_account_button': 'Создать аккаунт',
      'email_required': 'Email обязателен',
      'password_required': 'Пароль обязателен',
      'company_name_required': 'Название компании обязательно',
      'admin_email_required': 'Email администратора обязателен',
      'admin_email_invalid': 'Введите действительный email',
      'admin_password_required': 'Пароль администратора обязателен',
      'existing_email': 'Этот email уже зарегистрирован.',
      'registration_error': 'Ошибка регистрации: ',
      'confirm_email_sent':
          'Письмо с подтверждением отправлено. Проверьте почту.',
      'back_to_landing': 'Вернуться на главную',
      'guide_button_text': 'Руководство',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _toggleToRegister() {
    setState(() {
      _currentView = LoginViewType.registration;
    });
    _pageController.forward();
  }

  void _toggleToLogin() {
    setState(() {
      _currentView = LoginViewType.login;
    });
    _pageController.forward();
  }

  void _toggleToLanding() {
    setState(() {
      _currentView = LoginViewType.landing;
    });
    _pageController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _buildView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          if (_currentView != LoginViewType.landing)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _toggleToLanding,
            ),
          Expanded(
            child: Text(
              _getAppBarTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: _currentView == LoginViewType.landing
                  ? TextAlign.center
                  : TextAlign.left,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: _setLanguagePreference,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'uz', child: Text("O'zbek")),
              const PopupMenuItem(value: 'ru', child: Text('Русский')),
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _buildView() {
    switch (_currentView) {
      case LoginViewType.registration:
        return ModernRegistrationView(
          onViewToggle: _toggleToLanding,
          translate: _translate,
          key: const ValueKey('registration'),
        );
      case LoginViewType.login:
        return ModernLoginView(
          onLoginSuccess: widget.onLoginSuccess,
          onViewToggle: _toggleToLanding,
          translate: _translate,
          key: const ValueKey('login'),
        );
      case LoginViewType.landing:
      default:
        return _buildLandingPage();
    }
  }

  Widget _buildLandingPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Hero(
              tag: 'logo',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business,
                  size: 60,
                  color: Color(0xFF667eea),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _languageTitles[_currentLanguage]!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Modern attendance tracking',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 60),
            ModernAnimatedCard(
              child: Column(
                children: [
                  ModernButton(
                    text: _translate('landing_login'),
                    onPressed: _toggleToLogin,
                    icon: Icons.login,
                  ),
                  const SizedBox(height: 16),
                  ModernButton(
                    text: _translate('landing_register'),
                    onPressed: _toggleToRegister,
                    isPrimary: false,
                    icon: Icons.person_add,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Login View
class ModernLoginView extends StatefulWidget {
  final void Function(bool) onLoginSuccess;
  final VoidCallback onViewToggle;
  final String Function(String) translate;

  const ModernLoginView({
    Key? key,
    required this.onLoginSuccess,
    required this.onViewToggle,
    required this.translate,
  }) : super(key: key);

  @override
  State<ModernLoginView> createState() => _ModernLoginViewState();
}

class _ModernLoginViewState extends State<ModernLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _logger = Logger();

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        print("Login successful for user: ${response.user!.id}");
        
        // TUZATILGAN: Foydalanuvchi ma'lumotlarini tekshirish
        final userDetails = await supabase
            .from('users')
            .select('is_super_admin, full_name, email')
            .eq('id', response.user!.id)  // users.id = auth.users.id
            .maybeSingle();

        final prefs = await SharedPreferences.getInstance();

        if (userDetails != null) {
          print("User details found: $userDetails");
          final isSuperAdmin = userDetails['is_super_admin'] == true;
          await prefs.setBool('is_super_admin', isSuperAdmin);

          if (isSuperAdmin) {
            print("User is admin, navigating to AdminPage");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPage()),
            );
          } else {
            print("User is regular user");
            widget.onLoginSuccess(true);
          }
        } else {
          print("User details not found, creating new record");
          
          // TUZATILGAN: Yangi user record yaratish
          try {
            await supabase.from('users').insert({
              'id': response.user!.id,
              'email': response.user!.email,
              'full_name': response.user!.email?.split('@')[0] ?? 'User',
              'is_super_admin': false,
              'created_at': DateTime.now().toIso8601String(),
            });
            
            await prefs.setBool('is_super_admin', false);
            print("Created new user record, regular user");
            widget.onLoginSuccess(true);
          } catch (e) {
            print("Error creating user record: $e");
            // Agar user record yaratib bo'lmasa, lekin login muvaffaqiyatli bo'lsa,
            // oddiy user sifatida davom ettiramiz
            await prefs.setBool('is_super_admin', false);
            widget.onLoginSuccess(true);
          }
        }
      }
    } on AuthException catch (error) {
      _logger.e('Login error: ${error.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (error) {
      _logger.e('Unexpected error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ModernAnimatedCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.translate('login_title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ModernTextField(
                  controller: _emailController,
                  placeholder: widget.translate('email_placeholder'),
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.translate('email_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _passwordController,
                  placeholder: widget.translate('password_placeholder'),
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.translate('password_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ModernButton(
                  text: widget.translate('login_button'),
                  onPressed: _signIn,
                  isLoading: _isLoading,
                  icon: Icons.login,
                ),
                const SizedBox(height: 16),
                ModernButton(
                  text: widget.translate('back_to_home'),
                  onPressed: widget.onViewToggle,
                  isPrimary: false,
                  icon: Icons.home,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modern Registration View
class ModernRegistrationView extends StatefulWidget {
  final VoidCallback onViewToggle;
  final String Function(String) translate;

  const ModernRegistrationView({
    Key? key,
    required this.onViewToggle,
    required this.translate,
  }) : super(key: key);

  @override
  State<ModernRegistrationView> createState() => _ModernRegistrationViewState();
}

class _ModernRegistrationViewState extends State<ModernRegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _isLoading = false;
  final _logger = Logger();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final companyName = _companyNameController.text.trim();
    final adminEmail = _adminEmailController.text.trim();
    final adminPassword = _adminPasswordController.text.trim();

    try {
      // TUZATILGAN: Avval users jadvalini tekshirish
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
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Auth user yaratish
      final authResponse = await supabase.auth.signUp(
        email: adminEmail,
        password: adminPassword,
      );

      if (authResponse.user != null) {
        print("Auth user created: ${authResponse.user!.id}");
        
        // Company yaratish
        final companyResponse = await supabase.from('companies').insert({
          'company_name': companyName,
          'created_at': DateTime.now().toIso8601String(),
        }).select('id');

        final companyId = companyResponse[0]['id'];
        print("Company created: $companyId");

        // TUZATILGAN: Users jadvaliga ma'lumot qo'shish
        await supabase.from('users').insert({
          'id': authResponse.user!.id,  // users.id = auth.users.id
          'email': adminEmail,
          'full_name': "Admin",
          'is_super_admin': true,
          'position': 'Administrator',
          'company_id': companyId,
          'created_at': DateTime.now().toIso8601String(),
        });

        print("User record created successfully");

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_super_admin', true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.translate('confirm_email_sent')),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );

          widget.onViewToggle();
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
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ModernAnimatedCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.translate('registration_title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.translate('fill_data'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ModernTextField(
                  controller: _companyNameController,
                  placeholder: widget.translate('company_name_placeholder'),
                  prefixIcon: Icons.business_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.translate('company_name_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _adminEmailController,
                  placeholder: widget.translate('admin_email_placeholder'),
                  prefixIcon: Icons.email_outlined,
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
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _adminPasswordController,
                  placeholder: widget.translate('admin_password_placeholder'),
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.translate('admin_password_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ModernButton(
                  text: widget.translate('create_account_button'),
                  onPressed: _register,
                  isLoading: _isLoading,
                  icon: Icons.person_add,
                ),
                const SizedBox(height: 16),
                ModernButton(
                  text: widget.translate('back_to_landing'),
                  onPressed: widget.onViewToggle,
                  isPrimary: false,
                  icon: Icons.home,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}