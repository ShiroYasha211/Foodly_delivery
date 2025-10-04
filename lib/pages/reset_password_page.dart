// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:food_delivery/pages/forgot_password_page.dart';
import 'package:food_delivery/pages/login_page.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery/controllers/supabase_controller.dart';

class ResetPasswordPage extends StatefulWidget {
  static const nameRoute = "/reset-password";
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final SupabaseController _authController = Get.find();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTokenValid = false;
  bool _isCheckingToken = true;
  String _errorMessage = '';
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _extractTokenFromUrl();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // استخراج الـ token من الـ URL
  void _extractTokenFromUrl() async {
    try {
      _checkSessionFromSupabase();
    } catch (e) {
      setState(() {
        _isCheckingToken = false;
        _isTokenValid = false;
        _errorMessage = 'فشل في معالجة الرابط';
      });
    }
  }

  // التحقق من الجلسة مباشرة من Supabase
  Future<void> _checkSessionFromSupabase() async {
    try {
      final currentSession = _supabaseClient.auth.currentSession;

      if (currentSession != null) {
        setState(() {
          _isCheckingToken = false;
          _isTokenValid = true;
          _accessToken = currentSession.accessToken;
        });
      } else {
        // محاولة استعادة الجلسة من التخزين المحلي
        await _tryRecoverSession();
      }
    } catch (e) {
      setState(() {
        _isCheckingToken = false;
        _isTokenValid = false;
        _errorMessage = 'انتهت صلاحية رابط إعادة التعيين';
      });
    }
  }

  // محاولة استعادة الجلسة من التخزين المحلي
  Future<void> _tryRecoverSession() async {
    try {
      // هذه طريقة بديلة للتحقق من وجود جلسة صالحة
      final response = _supabaseClient.auth.currentSession;

      if (response != null) {
        setState(() {
          _isCheckingToken = false;
          _isTokenValid = true;
          _accessToken = response.accessToken;
        });
      } else {
        setState(() {
          _isCheckingToken = false;
          _isTokenValid = false;
          _errorMessage = 'رابط إعادة التعيين منتهي الصلاحية';
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingToken = false;
        _isTokenValid = false;
        _errorMessage = 'حدث خطأ أثناء التحقق من الرابط';
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // تحديث كلمة المرور مباشرة
        final response = await _supabaseClient.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );

        if (response.user != null) {
          // تسجيل الخروج بعد تغيير كلمة المرور
          await _supabaseClient.auth.signOut();

          Get.offAllNamed(LoginPage.nameRoute);

          Get.snackbar(
            'تم بنجاح ✅',
            'تم تحديث كلمة المرور بنجاح. يمكنك تسجيل الدخول الآن بكلمة المرور الجديدة',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
            borderRadius: 12,
            margin: const EdgeInsets.all(16),
          );
        }
      } on AuthException catch (e) {
        Get.snackbar(
          'خطأ',
          _getErrorMessage(e.message),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'خطأ',
          'حدث خطأ غير متوقع أثناء تحديث كلمة المرور',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    }
  }

  String _getErrorMessage(String message) {
    const errorMap = {
      'Password should be at least 6 characters':
          'كلمة المرور يجب أن تكون على الأقل 6 أحرف',
      'Invalid password': 'كلمة المرور غير صالحة',
      'Auth session missing': 'انتهت صلاحية رابط إعادة التعيين',
    };

    return errorMap[message] ?? message;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعادة تعيين كلمة المرور'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed(LoginPage.nameRoute),
        ),
      ),
      body: _isCheckingToken
          ? _buildLoadingState()
          : _isTokenValid
          ? _buildResetForm(theme, size)
          : _buildErrorState(theme, size),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('جاري التحقق من رابط إعادة التعيين...'),
        ],
      ),
    );
  }

  Widget _buildResetForm(ThemeData theme, Size size) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: size.height * 0.8,
        child: Column(
          children: [
            // صورة أو أيقونة
            Image.asset(
              'assets/images/reset_password.png',
              height: size.height * 0.2,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.lock_reset,
                  size: size.height * 0.15,
                  color: theme.primaryColor,
                );
              },
            ),
            SizedBox(height: size.height * 0.03),

            Text(
              'تعيين كلمة مرور جديدة',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: size.height * 0.01),

            Text(
              'أدخل كلمة المرور الجديدة لحسابك',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: size.height * 0.04),

            // نموذج إعادة التعيين
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // حقل كلمة المرور الجديدة
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: Icon(Icons.lock, color: theme.primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال كلمة المرور الجديدة';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون على الأقل 6 أحرف';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.02),

                  // حقل تأكيد كلمة المرور
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: theme.primaryColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى تأكيد كلمة المرور';
                      }
                      if (value != _passwordController.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.04),

                  // زر تعيين كلمة المرور
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'تعيين كلمة المرور',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // رابط العودة لتسجيل الدخول
            TextButton(
              onPressed: () => Get.offAllNamed(LoginPage.nameRoute),
              child: Text(
                'العودة لتسجيل الدخول',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Size size) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'رابط غير صالح',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.offAllNamed(ForgotPasswordPage.nameRoute),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('طلب رابط جديد'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.offAllNamed(LoginPage.nameRoute),
              child: Text(
                'العودة لتسجيل الدخول',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
