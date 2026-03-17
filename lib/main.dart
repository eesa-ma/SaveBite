import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/firebase_options.dart';
import 'package:save_bite/screens/home_screen.dart'; // Import the HomeScreen
import 'package:save_bite/screens/entry_screen.dart'; // Import the EntryScreen
import 'package:save_bite/screens/initial_screen.dart'; // Import the InitialScreen
import 'package:save_bite/screens/owner_dashboard.dart';
import 'package:save_bite/screens/admin_dashboard.dart';
import 'package:save_bite/screens/signup_screen.dart';
import 'package:save_bite/screens/reset_password_screen.dart';
import 'package:save_bite/screens/profile_screen.dart';
import 'package:save_bite/screens/profile_sync_screen.dart';
import 'package:save_bite/screens/my_reservations_screen.dart';
import 'package:save_bite/screens/favorites_screen.dart';
import 'package:save_bite/screens/notifications_screen.dart';
import 'package:save_bite/utils/theme_manager.dart';

void main() async {
  // Firebase initialization
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    final colorScheme = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        textStyle: TextStyle(color: colorScheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.primary,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        selectedColor: const Color(0xFF2E7D32),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade900,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return MaterialApp(
          title: 'SaveBite',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const InitialScreen(),
          routes: {
            '/login': (context) => const SignupScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
            '/home': (context) => const HomeScreen(),
            '/entry': (context) => const EntryScreen(),
            '/owner': (context) => const OwnerDashboard(),
            '/restaurant': (context) => const OwnerDashboard(),
            '/admin': (context) => const AdminDashboard(),
            '/profile': (context) => const ProfileScreen(),
            '/favorites': (context) => const FavoritesScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/profile-sync': (context) => const ProfileSyncScreen(),
            '/reservations': (context) => const MyReservationsScreen(),
          },
        );
      },
    );
  }
}
