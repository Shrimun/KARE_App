import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ask_question_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/mark_calculator_screen.dart';
import 'screens/cgpa_calculator_screen.dart';
import 'screens/credits_calculator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  runApp(MyApp(api: api));
}

class MyApp extends StatelessWidget {
  final ApiService api;
  const MyApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
      ],
      child: MaterialApp(
        title: 'AI Student Assistant',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF252525),
          primaryColor: const Color(0xFF3F967F),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF3F967F),
            secondary: const Color(0xFF7F5AB1),
            surface: const Color(0xFF252525),
            background: const Color(0xFF252525),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFD9D9D9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            labelStyle: TextStyle(
              color: const Color(0xFF252525).withOpacity(0.61),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF252525),
              foregroundColor: const Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xFFD9D9D9)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          useMaterial3: true,
        ),
        routes: {
          '/': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/ask': (_) => const AskQuestionScreen(),
          '/rules': (_) => const RulesScreen(),
          '/mark-calculator': (_) => const MarkCalculatorScreen(),
          '/cgpa-calculator': (_) => const CgpaCalculatorScreen(),
          '/credits-calculator': (_) => const CreditsCalculatorScreen(),
        },
      ),
    );
  }
}
