import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxibooking/data/datasources/remote/supabase_api.dart';
import 'package:taxibooking/presentation/screens/auth/login_screen.dart';
import 'package:taxibooking/presentation/screens/auth/register_screen.dart';
import 'package:taxibooking/presentation/screens/excursion/excursion_tab.dart';
import 'package:taxibooking/presentation/screens/home/home_screen.dart';
import 'package:taxibooking/presentation/screens/profile/profile_screen.dart';
import 'package:taxibooking/presentation/screens/reservas/reservas_tab.dart';
import 'package:taxibooking/providers/reservation_provider.dart';
import 'core/constants/app_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://shkalldjbvnepyfixvtm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNoa2FsbGRqYnZuZXB5Zml4dnRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxMDk3NzMsImV4cCI6MjA2MDY4NTc3M30.5AKIwnCkao1aZZ9pWsGcuXtvOBUgoml5kHyudBZcl00',
  );

  // Create SupabaseApi instance
  final supabaseApi = SupabaseApi();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReservationProvider(),
      child: MaterialApp(
      title: 'Cuba Taxi & Tours',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(), // Fixed route name
        '/excursion': (context) => const ExcursionTab(), // Fixed route name
        '/reservas': (context) => const ReservasTab(), // Fixed route name
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CU'),
        Locale('en', 'US'),
        Locale('es'),
      ],
    ),
    );
    
    
  }
}