import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ask_question_screen.dart';

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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/ask': (_) => const AskQuestionScreen(),
        },
      ),
    );
  }
}
