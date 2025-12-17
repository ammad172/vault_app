import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/setup_master_password_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/vault_home_screen.dart';
import 'screens/add_edit_entry_screen.dart';
import 'screens/settings_screen.dart';

// Simple global theme controller
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize encrypted local DB
  runApp(const VaultApp());
}

class VaultApp extends StatelessWidget {
  const VaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        final baseLight = ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0EA5E9),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
        );

        final baseDark = ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0EA5E9),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF020617),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ),
        );

        return MaterialApp(
          title: 'VaultLock',
          debugShowCheckedModeBanner: false,
          theme: baseLight,
          darkTheme: baseDark,
          themeMode: themeMode,
          initialRoute: SplashScreen.routeName,
          routes: {
            SplashScreen.routeName: (_) => const SplashScreen(),
            SignInScreen.routeName: (_) => const SignInScreen(),
            SetupMasterPasswordScreen.routeName: (_) =>
                const SetupMasterPasswordScreen(),
            UnlockScreen.routeName: (_) => const UnlockScreen(),
            VaultHomeScreen.routeName: (_) => const VaultHomeScreen(),
            AddEditEntryScreen.routeName: (_) => const AddEditEntryScreen(),
            SettingsScreen.routeName: (_) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
