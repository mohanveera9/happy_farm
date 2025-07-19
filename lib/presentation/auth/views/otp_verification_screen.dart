import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happy_farm/presentation/auth/views/onboard_screen.dart';
import 'package:happy_farm/presentation/auth/widgets/custom_snackba_msg.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:provider/provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final UserService authService = UserService();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      CustomSnackbar.showError(context, "Error", "Please enter complete OTP");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await authService.verifyOtp(
      phoneNumber: widget.phoneNumber,
      otp: _otpCode,
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null && result['error'] == null) {
      final user = result['user'];
      
      // Check if user needs onboarding
      if (user['name'] == null || user['name'].isEmpty || user['onboardingComplete'] != true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardScreen()),
        );
      } else {
        // User is already onboarded, go to main screen
        Provider.of<UserProvider>(context, listen: false).setUser(
          username: user['name'],
          email: user['email'],
          phoneNumber: user['phone'],
          image: user['image'],
        );

        CustomSnackbar.showSuccess(
            context, "Success", "Welcome back to Sabba Farm!");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      CustomSnackbar.showError(context, "Error", result?['error']);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    final result = await authService.requestOtp(
      phoneNumber: widget.phoneNumber,
    );

    setState(() {
      _isResending = false;
    });

    if (result != null && result['error'] == null) {
      CustomSnackbar.showSuccess(
          context, "Success", "OTP sent again to your phone number");
    } else {
      CustomSnackbar.showError(context, "Error", result?['error']);
    }
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
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
            child: Column(
              children: [
                Image.asset('assets/images/sb.png', height: 80),
                const SizedBox(height: 24),
                const Text('Verify Phone Number',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Enter the 6-digit code sent to ${widget.phoneNumber}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 40),

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildOtpField(index)),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const Text(
                            'Verifying...',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Didn't receive the code? "),
                    GestureDetector(
                      onTap: _isResending ? null : _resendOtp,
                      child: Text(
                        _isResending ? 'Resending...' : 'Resend OTP',
                        style: TextStyle(
                          color: _isResending ? Colors.grey : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}