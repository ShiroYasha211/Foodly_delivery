import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_delivery/pages/custom_bottom_page.dart';
import 'package:food_delivery/pages/login_page.dart';
import 'package:food_delivery/pages/register_page.dart';
import 'package:food_delivery/pages/reset_password_page.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseController extends GetxController {
  static SupabaseController get instance => Get.find();

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  User? get currentUser => _currentUser.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isLoggedIn => _currentUser.value != null;
  final box = GetStorage();
  @override
  void onInit() {
    super.onInit();
    _getCurrentUser();
    _setupAuthListener();
  }

  // الحصول على المستخدم الحالي
  void _getCurrentUser() {
    _currentUser.value = _supabaseClient.auth.currentUser;
  }

  //تجربة كود الاستماع والتحقق من الاخطاء الجديد

  void _setupAuthListener() {
    _supabaseClient.auth.onAuthStateChange.listen(
      (AuthState data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        final User? user = session?.user;

        try {
          switch (event) {
            case AuthChangeEvent.signedIn:
              await _handleSignedInEvent(session, user);
              break;

            case AuthChangeEvent.signedOut:
              await _handleSignedOutEvent();
              break;

            case AuthChangeEvent.passwordRecovery:
              await _handlePasswordRecoveryEvent();
              break;

            case AuthChangeEvent.userUpdated:
              await _handleUserUpdatedEvent(user);
              break;

            case AuthChangeEvent.userDeleted:
              await _handleUserDeletedEvent();
              break;

            case AuthChangeEvent.tokenRefreshed:
              await _handleTokenRefreshedEvent(session);
              break;

            case AuthChangeEvent.mfaChallengeVerified:
              await _handleMFAVerifiedEvent();
              break;

            case AuthChangeEvent.initialSession:
              await _handleInitialSessionEvent(session, user);
              break;
          }
        } catch (error) {
          await _handleAuthError(error, event);
        }
      },
      onError: (error) {
        _handleAuthError(error, null);
      },
      cancelOnError: false,
    );
  }

  Future<void> _handleSignedInEvent(Session? session, User? user) async {
    if (session != null && user != null) {
      // التحقق من صلاحية الجلسة
      if (DateTime.fromMillisecondsSinceEpoch(
        (session.expiresAt ?? 0) * 1000,
      ).isBefore(DateTime.now())) {
        await _handleExpiredSession();
        return;
      }

      _currentUser.value = user;

      // حفظ بيانات المستخدم بشكل آمن
      await _saveUserData(user);

      _showWelcomeMessage(user);

      // التنقل فقط إذا لم نكن بالفعل في الصفحة المستهدفة
      if (Get.currentRoute != CustomBottomPage.nameRoute) {
        Get.offAllNamed(CustomBottomPage.nameRoute);
      }
    } else {
      // حالة تسجيل دخول بدون جلسة صالحة (رابط منتهي)
      await _handleInvalidSession();
    }
  }

  Future<void> _handleSignedOutEvent() async {
    _currentUser.value = null;
    await box.remove('userId');
    await box.remove('userEmail');
    await _clearAllUserData();

    // التنقل إلى صفحة تسجيل الدخول إذا لم نكن فيها بالفعل
    if (Get.currentRoute != LoginPage.nameRoute) {
      Get.offAllNamed(LoginPage.nameRoute);
    }
  }

  Future<void> _handlePasswordRecoveryEvent() async {
    if (Get.currentRoute != ResetPasswordPage.nameRoute) {
      Get.toNamed(ResetPasswordPage.nameRoute);
    }
  }

  Future<void> _handleUserUpdatedEvent(User? user) async {
    if (user != null) {
      _currentUser.value = user;
      await _saveUserData(user);
      Get.snackbar(
        "تم التحديث",
        "تم تحديث بيانات حسابك بنجاح",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleUserDeletedEvent() async {
    _currentUser.value = null;
    await _clearAllUserData();
    Get.offAllNamed(RegisterPage.nameRoute);
    Get.snackbar(
      "الحساب محذوف",
      "تم حذف حسابك بنجاح",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  Future<void> _handleTokenRefreshedEvent(Session? session) async {
    if (session != null) {
      // يمكنك تحديث أي بيانات مرتبطة بالجلسة هنا
      debugPrint('Token refreshed successfully');
    }
  }

  Future<void> _handleMFAVerifiedEvent() async {
    Get.snackbar(
      "تم التحقق",
      "تم التحقق من الهوية بنجاح",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> _handleInitialSessionEvent(Session? session, User? user) async {
    if (session != null && user != null) {
      _currentUser.value = user;
      await _saveUserData(user);
    }
  }

  Future<void> _handleExpiredSession() async {
    await _supabaseClient.auth.signOut();
    await _clearAllUserData();

    Get.snackbar(
      "انتهت الجلسة",
      "انتهت صلاحية جلسة العمل، يرجى تسجيل الدخول مرة أخرى",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );

    Get.offAllNamed(LoginPage.nameRoute);
  }

  Future<void> _handleInvalidSession() async {
    Get.snackbar(
      "رابط غير صالح",
      "انتهت صلاحية الرابط أو الرابط غير صالح. يرجى طلب رابط جديد أو إنشاء حساب",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
    );

    // إعطاء خيارين للمستخدم: طلب رابط جديد أو إنشاء حساب
    Get.toNamed(RegisterPage.nameRoute);
  }

  Future<void> _handleAuthError(dynamic error, AuthChangeEvent? event) async {
    debugPrint('Auth Error: $error during event: $event');

    String errorMessage = "حدث خطأ غير متوقع";

    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          errorMessage = "بيانات الدخول غير صحيحة";
          break;
        case 'Email not confirmed':
          errorMessage = "البريد الإلكتروني غير مفعل";
          break;
        case 'User already registered':
          errorMessage = "المستخدم مسجل بالفعل";
          break;
        case 'Weak password':
          errorMessage = "كلمة المرور ضعيفة";
          break;
        case 'Expired recovery link':
          errorMessage = "انتهت صلاحية رابط الاستعادة";
          break;
        case 'Invalid recovery link':
          errorMessage = "رابط الاستعادة غير صالح";
          break;
        default:
          errorMessage = error.message;
      }
    }

    Get.snackbar(
      "خطأ في المصادقة",
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> _saveUserData(User user) async {
    await box.write('userId', user.id);
    await box.write('userEmail', user.email);
    await box.write('lastLogin', DateTime.now().toIso8601String());
  }

  Future<void> _clearAllUserData() async {
    await box.remove('userId');
    await box.remove('userEmail');
    await box.remove('lastLogin');
  }

  //الى هنا......

  // إعداد مستمع لتغيرات حالة المصادقة

  // void _setupAuthListener() {
  //   _supabaseClient.auth.onAuthStateChange.listen((AuthState data) {
  //     final AuthChangeEvent event = data.event;
  //     final Session? session = data.session;

  //     if (event == AuthChangeEvent.signedIn && session != null) {
  //       if (Get.currentRoute != CustomBottomPage.nameRoute) {
  //         _currentUser.value = session.user;

  //         _showWelcomeMessage(_currentUser.value!);
  //         box.write('userId', _currentUser.value!.id);
  //         Get.offAllNamed(CustomBottomPage.nameRoute);
  //       }
  //     } else if (event == AuthChangeEvent.signedOut) {
  //       _currentUser.value = null;
  //       box.remove('userId');
  //     } else if (event == AuthChangeEvent.passwordRecovery) {
  //       Get.toNamed(ResetPasswordPage.nameRoute);
  //     } else if (event == AuthChangeEvent.signedIn && session == null) {
  //       Get.snackbar(
  //         "تنبيه",
  //         "انتهت صلاحية الرابط. يرجى إنشاء حساب جديد أو طلب رابط جديد.",
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: Colors.redAccent,
  //         colorText: Colors.white,
  //       );
  //       Get.toNamed(RegisterPage.nameRoute);
  //     }
  //   });
  // }

  // تسجيل مستخدم جديد
  //used
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'created_at': DateTime.now().toIso8601String(),
        },
        emailRedirectTo: 'io.supabase.flutterdemo://login-callback',
      );

      if (response.user != null) {
        _currentUser.value = response.user;
        Get.snackbar(
          "تم إنشاء الحساب بنجاح",
          "سيصلك رابط التفعيل الى الايميل قم بتفعيله وتسجيل الدخول ",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
        Get.offAllNamed(LoginPage.nameRoute);
      }
    } on AuthException catch (e) {
      _errorMessage.value = _getErrorMessage(e.message);
      Get.snackbar('خطأ', _errorMessage.value);
    } catch (e) {
      _errorMessage.value = 'حدث خطأ غير متوقع';
      Get.snackbar('خطأ', _errorMessage.value);
    } finally {
      _isLoading.value = false;
    }
  }

  //دالة للتحقق من ان الايميل مسجل او لا
  //used
  Future<bool> _checkIfEmailExists(String email) async {
    try {
      // محاولة تسجيل دخول لمعرفة إذا كان الحساب موجوداً
      await _supabaseClient.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // لا تنشئ مستخدم جديد
      );

      // إذا نجحت العملية بدون إنشاء مستخدم، فهذا يعني أن البريد موجود
      return true;
    } on AuthException catch (e) {
      // إذا كان الخطأ يشير إلى أن المستخدم غير موجود
      if (e.message.contains('user not found') ||
          e.message.contains('User not found') ||
          e.message.contains('not exist')) {
        return false;
      }
      // أخطاء أخرى قد تعني أن البريد موجود لكن هناك مشكلة أخرى
      return true;
    } catch (e) {
      // في حالة حدوث خطأ غير متوقع، نفترض أن البريد موجود لمنع التكرار
      return true;
    }
  }

  // بديل أكثر دقة للتحقق من وجود البريد الإلكتروني

  // تسجيل الدخول
  //used
  Future<void> signIn({required String email, required String password}) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final AuthResponse response = await _supabaseClient.auth
          .signInWithPassword(email: email, password: password);

      if (response.user != null) {
        _currentUser.value = response.user;
      }
    } on AuthException catch (e) {
      _errorMessage.value = _getErrorMessage(e.message);
      Get.snackbar('خطأ', _errorMessage.value);
    } catch (e) {
      _errorMessage.value = 'حدث خطأ غير متوقع';
      Get.snackbar('خطأ', _errorMessage.value);
    } finally {
      _isLoading.value = false;
    }
  }

  // تسجيل الدخول بـ Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterdemo://login-callback/',
      );
    } on AuthException catch (e) {
      _errorMessage.value = _getErrorMessage(e.message);
      Get.snackbar('خطأ', _errorMessage.value);
    } catch (e) {
      _errorMessage.value = 'حدث خطأ غير متوقع';
      Get.snackbar('خطأ', _errorMessage.value);
    } finally {
      _isLoading.value = false;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _supabaseClient.auth.signOut();
      _currentUser.value = null;

      Get.snackbar('نجح', 'تم تسجيل الخروج بنجاح');
      Get.offAllNamed(LoginPage.nameRoute);
    } on AuthException catch (e) {
      _errorMessage.value = _getErrorMessage(e.message);
      Get.snackbar('خطأ', _errorMessage.value);
    } catch (e) {
      _errorMessage.value = 'حدث خطأ أثناء تسجيل الخروج';
      Get.snackbar('خطأ', _errorMessage.value);
    } finally {
      _isLoading.value = false;
    }
  }

  // إعادة تعيين كلمة المرور
  //used
  Future<void> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      Get.snackbar('انتظر', 'جاري إرسال رابط إعادة التعيين...');

      await _supabaseClient.auth.resetPasswordForEmail(email);

      Get.snackbar(
        'تم الإرسال ✅',
        'إذا كان البريد الإلكتروني مسجَّلاً لدينا، فسيصلك رابط لإعادة تعيين كلمة المرور.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed(LoginPage.nameRoute);
      });
    } on AuthException catch (e) {
      _errorMessage.value = _getErrorMessage(e.message);
      Get.snackbar(
        'خطأ',
        _errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      _errorMessage.value = 'حدث خطأ غير متوقع';
      Get.snackbar(
        'خطأ',
        _errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // تحديث بيانات المستخدم
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      if (currentUser == null) throw Exception('لم يتم تسجيل الدخول');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabaseClient
          .from('profiles')
          .update(updates)
          .eq('id', currentUser!.id);

      Get.snackbar('نجح', 'تم تحديث الملف الشخصي بنجاح');
    } catch (e) {
      _errorMessage.value = 'حدث خطأ أثناء تحديث الملف الشخصي';
      Get.snackbar('خطأ', _errorMessage.value);
    } finally {
      _isLoading.value = false;
    }
  }

  // الحصول على بيانات المستخدم
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // الحصول على الطعام من Supabase
  Future<List<Map<String, dynamic>>> getFoodItems() async {
    try {
      final response = await _supabaseClient
          .from('food_items')
          .select('*')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل البيانات');
      return [];
    }
  }

  // الحصول على التصنيفات من Supabase
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabaseClient
          .from('categories')
          .select('*')
          .order('title');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل التصنيفات');
      return [];
    }
  }

  // إضافة طعام إلى المفضلة
  Future<void> addToFavorites(String foodId) async {
    try {
      if (currentUser == null) throw Exception('لم يتم تسجيل الدخول');

      await _supabaseClient.from('favorites').upsert({
        'user_id': currentUser!.id,
        'food_id': foodId,
        'created_at': DateTime.now().toIso8601String(),
      });

      Get.snackbar('نجح', 'تمت الإضافة إلى المفضلة');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في الإضافة إلى المفضلة');
    }
  }

  // إزالة طعام من المفضلة
  Future<void> removeFromFavorites(String foodId) async {
    try {
      if (currentUser == null) throw Exception('لم يتم تسجيل الدخول');

      await _supabaseClient
          .from('favorites')
          .delete()
          .eq('user_id', currentUser!.id)
          .eq('food_id', foodId);

      Get.snackbar('نجح', 'تمت الإزالة من المفضلة');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في الإزالة من المفضلة');
    }
  }

  // الحصول على المفضلة
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      if (currentUser == null) return [];

      final response = await _supabaseClient
          .from('favorites')
          .select('''
            food_id,
            food_items (*)
          ''')
          .eq('user_id', currentUser!.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // إضافة طلب جديد
  Future<void> createOrder(Map<String, dynamic> orderData) async {
    try {
      if (currentUser == null) throw Exception('لم يتم تسجيل الدخول');

      await _supabaseClient.from('orders').insert({
        'user_id': currentUser!.id,
        'items': orderData['items'],
        'total_amount': orderData['total_amount'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      Get.snackbar('نجح', 'تم إنشاء الطلب بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إنشاء الطلب');
    }
  }

  // الحصول على طلبات المستخدم
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      if (currentUser == null) return [];

      final response = await _supabaseClient
          .from('orders')
          .select('*')
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // تحميل الصور إلى التخزين
  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      // ignore: unused_local_variable
      final response = await _supabaseClient.storage
          .from('images')
          .upload(fileName, File(filePath));

      return _supabaseClient.storage.from('images').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  // ترجمة رسائل الخطأ
  String _getErrorMessage(String message) {
    const errorMap = {
      'Invalid login credentials': 'بيانات الدخول غير صحيحة',
      'Email not confirmed': 'البريد الإلكتروني غير مفعل',
      'User already registered': 'المستخدم مسجل بالفعل',
      'Weak password': 'كلمة المرور ضعيفة',
    };

    return errorMap[message] ?? message;
  }

  // مسح رسالة الخطأ
  void clearError() {
    _errorMessage.value = '';
  }

  void _showWelcomeMessage(User user) {
    // استخراج الاسم من البيانات أو من البريد الإلكتروني
    String userName =
        user.userMetadata?['full_name'] ??
        user.userMetadata?['name'] ??
        user.email?.split('@').first ??
        'المستخدم';

    Get.snackbar(
      'مرحباً بعودتك! 👋',
      'سعيدون برؤيتك مرة أخرى $userName',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      animationDuration: const Duration(milliseconds: 500),
      icon: const Icon(Icons.emoji_emotions, color: Colors.white),
      shouldIconPulse: true,
    );
  }
}
