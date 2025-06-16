// signup.dart
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
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';
import 'premium_page.dart'; // Import RegistrationView from premium_page.dart

// Modular UI Components (Cards and Buttons) - Assuming these are already defined as in your provided code

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _logger = Logger();
  final Color primaryColor = const Color(0xFF3700B3);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final companyName = _companyNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Sign up with email and password
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw Exception('User creation failed.');
      }

      final userId = res.user!.id;

      // 2.  Insert into `companies` table
      await supabase.from('companies').insert({
        'company_name': companyName,
        'created_at': DateTime.now().toIso8601String(), // Add created_at
      });
      //3. Insert into 'requests' table
      await supabase.from('requests').insert({
        'company_name': companyName,
        'admin_email': email, // Use the registered email
        'status': 'pending', // Initial status
        'request_time': DateTime.now().toIso8601String(),
      });

      // 3. Insert into `users` table (public schema)
      await supabase.from('users').insert({
        'email': email,
        'is_super_admin': true,
        'lavozim': companyName, // Store company name as lavozim
        'xodim_id': userId, // Foreign key to auth.users(id)
        'created_at': DateTime.now().toIso8601String(),
      });

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account created! Please activate your account."),
            backgroundColor: Colors.green,
          ),
        );
        widget.onViewToggle(); // Navigate back to landing page, or login page.
      }
    } on AuthException catch (error) {
      _logger.e('Registration AuthException: ${error.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      _logger.e('Registration error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $error'),
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
      // Using your MUILoginCard
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MUIFormInput(
              primaryColor: primaryColor, // Your MUIFormInput
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
            const SizedBox(height: 12),
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
                if (!value.contains('@')) {
                  return widget.translate('admin_email_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            MUIFormInput(
              primaryColor: primaryColor,
              controller: _passwordController,
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
              text: widget.translate('register'),
              onPressed: _register,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            MUISecondaryButton(
              // Using your MUISecondaryButton
              text: widget.translate('back_to_home'),
              onPressed: widget.onViewToggle, // Go back to landing page
              textColor: primaryColor, // Set text color
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

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
