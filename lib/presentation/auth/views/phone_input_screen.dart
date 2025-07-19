import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/auth/views/otp_verification_screen.dart';
import 'package:happy_farm/presentation/auth/widgets/custom_snackba_msg.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({Key? key}) : super(key: key);

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final UserService authService = UserService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
    });

    final result = await authService.requestOtp(
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null && result['error'] == null) {
      CustomSnackbar.showSuccess(
          context, "Success", "OTP sent to your phone number");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: _phoneController.text.trim(),
          ),
        ),
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
                  const Text('Welcome to Sabba Farm',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Enter your phone number to get started',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 40),

                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Phone Number', Icons.phone),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Phone number is required';
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _requestOtp();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const Text(
                              'Sending OTP...',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            )
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
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