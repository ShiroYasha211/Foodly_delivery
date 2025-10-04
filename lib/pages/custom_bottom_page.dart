import 'dart:ui';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/controllers/cart_controller.dart';
import 'package:food_delivery/controllers/supabase_controller.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/account_page.dart';
import '../pages/favorite_page.dart';
import '../pages/homepage.dart';
import 'cart_page.dart';

class CustomBottomPage extends StatefulWidget {
  static const nameRoute = "/customBottomPage";
  const CustomBottomPage({super.key});

  @override
  State<CustomBottomPage> createState() => _CustomBottomPageState();
}

class _CustomBottomPageState extends State<CustomBottomPage> {
  final SupabaseController _authController = Get.find();
  final CartController _cartController = Get.find();
  final user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? profileData;

  int _selectedIndex = 0;

  List<Widget> bodyOptions = [
    const HomePage(),
    const FavoritePage(),
    const AccountPage(),
  ];

  void onTapIndex(int indexTap) {
    setState(() {
      _selectedIndex = indexTap;
    });
  }

  void showComingSnackBar() {
    Get.snackbar(
      "قريباَ",
      "هذه الميزه ستكون متاحه قريبا جدا ",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.deepOrange.withOpacity(0.9),
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      animationDuration: const Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInOut,
      icon: const Icon(Icons.construction, color: Colors.white, size: 28),
      mainButton: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          "حسناَ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      overlayBlur: 0.5,
      overlayColor: Colors.black.withOpacity(0.1),
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      showProgressIndicator: true,
      progressIndicatorBackgroundColor: Colors.white.withOpacity(0.3),
      progressIndicatorValueColor: const AlwaysStoppedAnimation<Color>(
        Colors.white,
      ),
      barBlur: 10,
    );
  }

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  void loadProfileData() async {
    profileData = await _authController.getUserProfile();
  }

  String get _userImageUrl {
    return profileData?['avatar_url'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          "توصيل الطعام",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded),
                onPressed: () {
                  Get.toNamed(CartPage.nameRoute);
                },
                tooltip: 'سلة التسوق',
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Obx(() {
                  final cartCount = _cartController.itemCount;
                  if (cartCount == 0) return const SizedBox();

                  return Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cartCount > 9 ? '9+' : cartCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                profileData?['full_name'] ?? 'المستخدم',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? 'البريد الالكتروني'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.black45,
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
              decoration: BoxDecoration(color: theme.primaryColor),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("الرئيسية"),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text("المفضلة"),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("حسابي"),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("سلة التسوق"),
              onTap: () {
                Get.toNamed(CartPage.nameRoute);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("الإعدادات"),
              onTap: () {
                showComingSnackBar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("المساعدة"),
              onTap: () {
                showComingSnackBar();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("تسجيل الخروج"),
              onTap: () {
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(child: bodyOptions[_selectedIndex]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.white.withOpacity(0.2),
          ),
          child: Stack(
            children: [
              // تأثير الخلفية الزجاجية
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // شريط التنقل
              CurvedNavigationBar(
                index: _selectedIndex,
                height: 75.0,
                items: [
                  _buildTransparentNavItem(Icons.home_rounded, 0),
                  _buildTransparentNavItem(Icons.favorite_rounded, 1),
                  _buildTransparentNavItem(Icons.person_rounded, 2),
                ],
                color: Colors.transparent,
                buttonBackgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.8),
                backgroundColor: Colors.transparent,
                animationCurve: Curves.easeInOutQuint,
                animationDuration: const Duration(milliseconds: 600),
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  onTapIndex(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransparentNavItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;

    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).primaryColor.withOpacity(0.5),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : Colors.white.withOpacity(0.4),
          width: isSelected ? 0 : 1.5,
        ),
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
        size: isSelected ? 26 : 24,
      ),
    );
  }

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
                          await _authController.signOut();
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
}
