import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/setup_master_password_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/vault_home_screen.dart';
import 'screens/add_edit_entry_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/password_generator_screen.dart';
import 'screens/password_health_screen.dart';
import 'screens/premium_screen.dart';
import 'services/session_manager.dart';
import 'services/subscription_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Global theme controller
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  
  await Hive.initFlutter(); // Initialize encrypted local DB
  await sessionManager.init(); // Initialize session manager
  
  // Initialize subscription service
  subscriptionService.addListener(() {
    // Premium service will check subscription status when needed
  });
  
  runApp(const ProviderScope(child: VaultApp()));
}

class VaultApp extends StatefulWidget {
  const VaultApp({super.key});

  @override
  State<VaultApp> createState() => _VaultAppState();
}

class _VaultAppState extends State<VaultApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Lock the app when it goes to background
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      // Only lock if session is currently unlocked
      if (sessionManager.state == SessionState.unlocked) {
        sessionManager.lock();
      }
    }
    
    // When app comes back to foreground, check session state
    if (state == AppLifecycleState.resumed) {
      // Session manager will handle navigation via listeners
      // No need to do anything here as VaultHomeScreen listener handles it
    }
  }

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
            OnboardingScreen.routeName: (_) => const OnboardingScreen(),
            SignInScreen.routeName: (_) => const SignInScreen(),
            SetupMasterPasswordScreen.routeName: (_) =>
                const SetupMasterPasswordScreen(),
            UnlockScreen.routeName: (_) => const UnlockScreen(),
            VaultHomeScreen.routeName: (_) => const VaultHomeScreen(),
            AddEditEntryScreen.routeName: (_) => const AddEditEntryScreen(),
            SettingsScreen.routeName: (_) => const SettingsScreen(),
            PasswordGeneratorScreen.routeName: (_) =>
                const PasswordGeneratorScreen(),
            PasswordHealthScreen.routeName: (_) =>
                const PasswordHealthScreen(),
            PremiumScreen.routeName: (_) => const PremiumScreen(),
          },
        );
      },
    );
  }
}
