import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_screen.dart';
import 'kitchen_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = supabase.auth.currentSession;

    if (session == null) {
      // Not logged in → go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // Logged in → fetch role
    final userId = session.user.id;
    final userData = await supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    if (userData == null) {
      // No matching user row → force login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final role = userData['role'];

    if (role == 'cashier') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderScreen()),
      );
    } else if (role == 'kitchen') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KitchenScreen()),
      );
    } else {
      // Default fallback
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
