import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/otp_login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/providers/dashboard_provider.dart';

import 'core/services/sync_service.dart';

import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable SQLite FFI for Desktop (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Cloudflare Workers + D1 SQLite Database Background Sync
  SyncService().startSync();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const ManishaCollectionApp(),
    ),
  );
}

class ManishaCollectionApp extends StatelessWidget {
  const ManishaCollectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Manisha Collection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('mr'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/login',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const OtpLoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
