import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'data/repositories/retail_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/retail_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/business_setup_screen.dart';
import 'screens/shell/main_shell.dart';

import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Cloud Backend (Project: rexon-35454)
  await FirebaseService().initialize();

  final repository = RetailRepository();
  await repository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(repository)),
        ChangeNotifierProvider(create: (_) => RetailProvider(repository)),
      ],
      child: const RexonApp(),
    ),
  );
}

class RexonApp extends StatelessWidget {
  const RexonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rexon Retail — Invoicing & Inventory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    if (!auth.hasBusinessSetup) {
      return const BusinessSetupScreen();
    }

    return const MainShell();
  }
}
