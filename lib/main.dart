import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_res.dart';
import 'controllers/app_bindings.dart';
import 'screens/home_screen.dart';
import 'screens/usb_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const NavAssistApp());
}

class NavAssistApp extends StatelessWidget {
  const NavAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppRes.appName,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(),
      theme: ThemeData(
        scaffoldBackgroundColor: AppRes.bgPrimary,
        fontFamily: AppRes.fontMono,
        colorScheme: const ColorScheme.dark(
          surface: AppRes.bgSurface,
          primary: AppRes.accentSafe,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppRes.bgPrimary,
          foregroundColor: AppRes.textPrimary,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: AppRes.fontMono,
            fontSize: AppRes.fontLG,
            fontWeight: FontWeight.bold,
            color: AppRes.textPrimary,
            letterSpacing: 2,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppRes.bgSurface,
          selectedItemColor: AppRes.accentSafe,
          unselectedItemColor: AppRes.textSecondary,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const _RootNav(),
    );
  }
}

class _RootNav extends StatelessWidget {
  const _RootNav();

  @override
  Widget build(BuildContext context) {
    final idx = 0.obs;
    const screens = [HomeScreen(), UsbScreen(), SettingsScreen()];

    return Obx(() => Scaffold(
          body: IndexedStack(index: idx.value, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: idx.value,
            onTap: (i) => idx.value = i,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: AppRes.tabHome,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.usb_outlined),
                activeIcon: Icon(Icons.usb),
                label: AppRes.tabConnect,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: AppRes.tabSettings,
              ),
            ],
          ),
        ));
  }
}
