import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/auth/widgets/custom_snackba_msg.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:provider/provider.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({Key? key}) : super(key: key);

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final UserService _authService = UserService();
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.onboard(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null && result['error'] == null) {
      // Get updated user details
      final userDetailsResult = await _authService.getMe();
      
      if (userDetailsResult != null && userDetailsResult['error'] == null) {
        final user = userDetailsResult;
        
        Provider.of<UserProvider>(context, listen: false).setUser(
          username: user['name'],
          email: user['email'],
          phoneNumber: user['phone'],
          image: user['image'],
        );
      }

      CustomSnackbar.showSuccess(
          context, "Success", "Welcome to Sabba Farm!");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      CustomSnackbar.showError(context, "Error", result?['error']);
    }
  }

  InputDecoration _inputDecoration(String label, IconData prefixIcon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAFBF3), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/images/sb.png', height: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tell us a bit about yourself',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Full Name', Icons.person),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Full name is required';
                      if (value.trim().length < 2)
                        return 'Full name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field (Optional)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email (Optional)', Icons.email),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _completeOnboarding,
                      child: _isLoading
                          ? const Text(
                              'Completing...',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600),
                            )
                          : const Text(
                              'Complete Profile',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}