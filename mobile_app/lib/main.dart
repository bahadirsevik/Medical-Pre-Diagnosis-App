import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/user_provider.dart';
import 'package:mobile_app/screens/diagnosis_screen.dart';
import 'package:mobile_app/screens/auth/login_screen.dart';
import 'package:mobile_app/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://hqkcuxwxdsybtxqgnydx.supabase.co',
    anonKey: 'sb_publishable_efbQ-0WZV8kPB-Jb8aOHpg_S61Al-Iw',
  );

  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  runApp(MyApp(showHome: showHome));
}

class MyApp extends StatelessWidget {
  final bool showHome;

  const MyApp({super.key, required this.showHome});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..checkAuthStatus()),
      ],
      child: MaterialApp(
        title: 'Medical AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF009688), // Medical Teal
            secondary: const Color(0xFF2196F3), // Trust Blue
            surface: const Color(0xFFF5F7FA),
          ),
          textTheme: GoogleFonts.outfitTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        home: showHome ? const AuthWrapper() : const OnboardingScreen(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userProvider.isAuthenticated) {
      return const DiagnosisScreen();
    } else {
      return const LoginScreen();
    }
  }
}
