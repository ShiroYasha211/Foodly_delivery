import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery/controllers/favorite_controller.dart';
import 'package:food_delivery/pages/about_app.dart';
import 'package:food_delivery/pages/food_details_page.dart';
import 'package:food_delivery/pages/forgot_password_page.dart';
import 'package:food_delivery/pages/login_page.dart';
import 'package:food_delivery/pages/old_orders_page.dart';
import 'package:food_delivery/pages/register_page.dart';
import 'package:food_delivery/pages/reset_password_page.dart';
import '../themes/themes.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/custom_bottom_page.dart';
import 'controllers/cart_controller.dart';
import 'controllers/supabase_controller.dart';
import 'pages/cart_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Supabase.initialize(
    url: "https://ncmvygqltfqagzjdlsfq.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jbXZ5Z3FsdGZxYWd6amRsc2ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzNzgxNzEsImV4cCI6MjA3MTk1NDE3MX0.4LiwVPCgx6v0ACrm8bHgBrxioWpgyNL01w41xx8EsMc",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Delivery App",
      theme: Themes.lightTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      getPages: [
        GetPage(
          name: '/',
          page: Supabase.instance.client.auth.currentUser != null
              ? () => const CustomBottomPage()
              : () => const LoginPage(),
        ),
        GetPage(
          name: FoodDetailsPage.routeName,
          page: () => const FoodDetailsPage(),
        ),
        GetPage(name: LoginPage.nameRoute, page: () => const LoginPage()),
        GetPage(name: RegisterPage.nameRoute, page: () => const RegisterPage()),
        GetPage(
          name: ForgotPasswordPage.nameRoute,
          page: () => const ForgotPasswordPage(),
        ),
        GetPage(
          name: ResetPasswordPage.nameRoute,
          page: () => const ResetPasswordPage(),
        ),
        GetPage(
          name: CustomBottomPage.nameRoute,
          page: () => const CustomBottomPage(),
        ),
        GetPage(
          name: OldOrdersPage.nameRoute,
          page: () => const OldOrdersPage(),
        ),
        GetPage(name: AboutApp.nameRoute, page: () => const AboutApp()),
        GetPage(name: CartPage.nameRoute, page: () => CartPage()),
      ],
      initialBinding: BindingsBuilder(() {
        Get.put(SupabaseController());
        Get.put(CartController());
        Get.put(FavoriteController());
      }),
    );
  }
}
