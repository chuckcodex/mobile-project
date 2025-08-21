import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['https://uiiyqvfntxjzjpdsaehh.supabase.co']!,
    anonKey: dotenv.env['eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVpaXlxdmZudHhqempwZHNhZWhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2NTY0NjUsImV4cCI6MjA3MTIzMjQ2NX0.nm7Pl9WSczcZMqdk0kSYPo3uZhXx7oR9330rtlIs4PU']!,
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS App',
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}
