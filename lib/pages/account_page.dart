// ignore_for_file: unused_field

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery/pages/about_app.dart';
import 'package:food_delivery/pages/login_page.dart';
import 'package:food_delivery/pages/old_orders_page.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/supabase_controller.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final SupabaseController _supabaseController = Get.find();
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'لم يتم تسجيل الدخول';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _userData = {
          'id': user.id,
          'email': user.email,
          'created_at': user.createdAt,
        };
      });

      final profileResponse = await _supabaseClient
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      setState(() {
        _profileData = profileResponse;
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل بيانات المستخدم';
        _isLoading = false;
      });
    }
  }

  String get _userName {
    if (_profileData != null && _profileData!['full_name'] != null) {
      return _profileData!['full_name'];
    }
    if (_userData != null && _userData!['email'] != null) {
      return _userData!['email']!.split('@').first;
    }
    return 'المستخدم';
  }

  String get _userEmail {
    return _userData?['email'] ?? 'غير متوفر';
  }

  String get _userImageUrl {
    return _profileData?['avatar_url'] ?? '';
  }

  String get _userPhone {
    return _profileData?['phone'] ?? '';
  }

  String get _userAddress {
    return _profileData?['address'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.primaryColor),
              const SizedBox(height: 16),
              const Text('جاري تحميل البيانات...'),
            ],
          ),
        ),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.04),

            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: size.width * 0.3,
                  height: size.width * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primaryColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _userImageUrl.isNotEmpty
                        ? Image.network(
                            _userImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(size);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : _buildDefaultAvatar(size),
                  ),
                ),

                // زر تعديل الصورة
                Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 18),
                    color: Colors.white,
                    onPressed: _changeProfilePicture,
                    tooltip: 'تغيير الصورة',
                  ),
                ),
              ],
            ),

            SizedBox(height: size.height * 0.03),

            // اسم المستخدم
            Text(
              _userName,
              style: theme.textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: size.height * 0.03,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: size.height * 0.005),

            // البريد الإلكتروني
            Text(
              _userEmail,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: size.height * 0.03),

            // إحصائيات الحساب
            FutureBuilder(
              future: _loadUserStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    ),
                  );
                }

                final stats = snapshot.data ?? {'orders': 0, 'favorites': 0};

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        icon: Icons.shopping_bag,
                        value: stats['orders'].toString(),
                        label: "الطلبات",
                      ),

                      _buildStatItem(
                        context,
                        icon: Icons.favorite,
                        value: stats['favorites'].toString(),
                        label: "المفضلة",
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: size.height * 0.03),

            // قسم المعلومات الشخصية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "معلوماتي",
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // بطاقة المعلومات الشخصية
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // البريد الإلكتروني
                          _buildInfoRow(
                            icon: Icons.email,
                            title: "البريد الإلكتروني",
                            value: _userEmail,
                          ),

                          const SizedBox(height: 12),

                          // رقم الهاتف
                          if (_profileData?['phone'] != null &&
                              _profileData!['phone'].toString().isNotEmpty)
                            Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.phone,
                                  title: "رقم الهاتف",
                                  value: _userPhone,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),

                          // العنوان
                          if (_profileData?['address'] != null &&
                              _profileData!['address'].toString().isNotEmpty)
                            Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.location_on,
                                  title: "العنوان",
                                  value: _userAddress,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),

                          // زر تعديل المعلومات
                          OutlinedButton(
                            onPressed: () {
                              _showEditProfileDialog();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primaryColor,
                              side: BorderSide(color: theme.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text("تعديل المعلومات الشخصية"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.03),

            // قسم الإعدادات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "الإعدادات والخصائص",
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // قائمة الخيارات
            _buildOptionCard(
              context,
              title: "طلباتي ",
              icon: Icons.shopping_bag_outlined,
              onTap: () {
                _navigateToOrders();
              },
            ),

            _buildOptionCard(
              context,
              title: "تغيير كلمة المرور",
              icon: Icons.settings_outlined,
              onTap: () {
                _navigateToSettings();
              },
            ),

            _buildOptionCard(
              context,
              title: "عن التطبيق",
              icon: Icons.info_outline,
              onTap: () {
                _navigateToAbout();
              },
            ),

            SizedBox(height: size.height * 0.02),

            // زر تسجيل الخروج
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: OutlinedButton(
                onPressed: () {
                  _showLogoutConfirmation(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "تسجيل الخروج",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: size.height * 0.03),

            Text(
              "الإصدار 1.0.0",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),

            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }

  // الصورة الافتراضية
  Widget _buildDefaultAvatar(Size size) {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.person,
        size: size.width * 0.15,
        color: Colors.grey[400],
      ),
    );
  }

  // جلب إحصائيات المستخدم
  Future<Map<String, dynamic>> _loadUserStats() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return {'orders': 0, 'favorites': 0};
      }

      final ordersResponse = await _supabaseClient
          .from('orders')
          .select('id')
          .eq('user_id', user.id);

      final favoritesResponse = await _supabaseClient
          .from('favorites')
          .select('id')
          .eq('user_id', user.id);

      return {
        'orders': ordersResponse.length,
        'favorites': favoritesResponse.length,
      };
    } catch (e) {
      return {'orders': 0, 'favorites': 0};
    }
  }

  // عنصر الإحصائية
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  // بطاقة الخيار
  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // عرض dialog لتعديل الملف الشخصي
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final phoneController = TextEditingController(
      text: _profileData?['phone']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: _profileData?['address']?.toString() ?? '',
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "تعديل الملف الشخصي",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // النموذج
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // حقل الاسم
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: "الاسم الكامل",
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يجب إدخال الاسم';
                            }
                            if (value.length < 3) {
                              return 'الاسم يجب أن يكون على الأقل 3 أحرف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // حقل رقم الهاتف
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: "رقم الهاتف",
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: Theme.of(context).primaryColor,
                            ),
                            prefix: Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 8,
                              ),
                              child: Text(
                                "+967",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يجب إدخال رقم الهاتف';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'يجب أن يكون رقم هاتف صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // حقل العنوان
                        TextFormField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: "العنوان",
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: Theme.of(context).primaryColor,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 2,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يجب إدخال العنوان';
                            }
                            if (value.length < 10) {
                              return 'العنوان يجب أن يكون على الأقل 10 أحرف';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // الأزرار
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // زر الإلغاء
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "إلغاء",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // زر الحفظ
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              await _updateProfile(
                                nameController.text,
                                phoneController.text,
                                addressController.text,
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "حفظ التغييرات",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // تحديث الملف الشخصي
  Future<void> _updateProfile(
    String fullName,
    String phone,
    String address,
  ) async {
    try {
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator()],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return;
      await _supabaseClient
          .from('profiles')
          .update({
            'full_name': fullName,
            'phone': phone,
            'address': address,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      setState(() {
        _profileData = {
          ...?_profileData,
          'full_name': fullName,
          'phone': phone,
          'address': address,
        };
      });

      Get.snackbar(
        "تم التحديث",
        "تم تحديث الملف الشخصي بنجاح",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل في تحديث الملف الشخصي",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      Navigator.pop(context);
    }
  }

  // تأكيد تسجيل الخروج
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الرأس مع الأيقونة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "تسجيل الخروج",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),

              // المحتوى
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "هل أنت متأكد من رغبتك في تسجيل الخروج؟",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ستحتاج إلى إعادة تسجيل الدخول لاستخدام التطبيق",
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // الأزرار
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // زر الإلغاء
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "إلغاء",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // زر تسجيل الخروج
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "تسجيل الخروج",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تسجيل الخروج
  Future<void> _logout() async {
    try {
      // عرض مؤشر تحميل
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator()],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      await _supabaseClient.auth.signOut();

      Get.back();
      Get.offAllNamed(LoginPage.nameRoute);

      Get.snackbar(
        "تم تسجيل الخروج",
        "تم تسجيل الخروج بنجاح",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        "خطأ",
        "فشل في تسجيل الخروج",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // دوال التنقل للصفحات المختلفة
  void _navigateToOrders() {
    Get.toNamed(OldOrdersPage.nameRoute);
  }

  void _navigateToSettings() {
    //Get.toNamed('/settings');
    Get.snackbar("قريباً", "صفحة الإعدادات قيد التطوير");
  }

  void _navigateToAbout() {
    Get.toNamed(AboutApp.nameRoute);
  }

  // دالة لبناء صف معلومات
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changeProfilePicture() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final galleryStatus = await Permission.photos.status;
      if (cameraStatus != PermissionStatus.granted ||
          galleryStatus != PermissionStatus.granted) {
        await Permission.camera.request();
        await Permission.photos.request();
      }
      final theme = Theme.of(context);
      final ImagePicker picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Text(
                    'اختر مصدر الصورة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: theme.primaryColor),
                  title: const Text('اختر من المعرض'),
                  onTap: () => Get.back(result: ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: theme.primaryColor),
                  title: const Text('التقاط صورة'),
                  onTap: () => Get.back(result: ImageSource.camera),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (source == null) {
        return;
      }
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxHeight: 1080,
        maxWidth: 1080,
      );
      if (image == null) {
        return;
      }
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'قص الصورة',
            toolbarColor: theme.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            showCropGrid: true,
            hideBottomControls: false,
            activeControlsWidgetColor: theme.primaryColor,
          ),
        ],
      );
      if (croppedFile == null) return;

      // رفع الصورة إلى Supabase
      final file = File(croppedFile.path);
      await _uploadProfilePicture(file);
    } on PlatformException catch (e) {
      // معالجة أخطاء الصلاحيات
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        Get.snackbar(
          'الإذن مطلوب',
          'يجب منح إذن الوصول للكاميرا والمعرض لتغيير الصورة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          mainButton: const TextButton(
            onPressed: openAppSettings,
            child: Text('فتح الإعدادات', style: TextStyle(color: Colors.white)),
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل في تغيير صورة الملف الشخصي",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    try {
      // عرض مؤشر التحميل
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator()],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final user = _supabaseClient.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // إنشاء اسم فريد للصورة
      final String userFolder = user.id;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String fullPath = '$userFolder/$fileName';

      // 1. أولاً: جلب قائمة الصور القديمة للمستخدم
      final List<FileObject> oldFiles = await _supabaseClient.storage
          .from('profile-pictures')
          .list(path: userFolder);

      // 2. حذف الصور القديمة إذا وجدت
      if (oldFiles.isNotEmpty) {
        final List<String> filesToDelete = [];
        for (final file in oldFiles) {
          if (file.name.endsWith('.jpg') ||
              file.name.endsWith('.jpeg') ||
              file.name.endsWith('.png')) {
            filesToDelete.add('$userFolder/${file.name}');
          }
        }

        if (filesToDelete.isNotEmpty) {
          await _supabaseClient.storage
              .from('profile-pictures')
              .remove(filesToDelete);
        }
      }

      // 3. رفع الصورة الجديدة
      await _supabaseClient.storage
          .from('profile-pictures')
          .upload(fullPath, imageFile);

      // 4. الحصول على الرابط العام
      final String imageUrl = _supabaseClient.storage
          .from('profile-pictures')
          .getPublicUrl(fullPath);

      // 5. تحديث قاعدة البيانات
      await _supabaseClient
          .from('profiles')
          .update({
            'avatar_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // 6. تحديث الواجهة
      setState(() {
        _profileData = {...?_profileData, 'avatar_url': imageUrl};
      });

      // إغلاق مؤشر التحميل
      Get.back();

      // عرض رسالة نجاح
      Get.snackbar(
        "تم التحديث ✅",
        "تم تغيير صورة الملف الشخصي بنجاح",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Get.back();

      Get.snackbar(
        "خطأ ❌",
        "فشل في رفع الصورة: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
