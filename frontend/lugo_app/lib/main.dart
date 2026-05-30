import 'dart:async';

import 'package:flutter/material.dart';

import 'driver_home.dart';
import 'forgot_password_screen.dart';
import 'landing_screen.dart';
import 'login_screen.dart';
import 'otp.dart';
import 'register_screen.dart';
import 'routes_screen.dart';
import 'service.dart';
import 'student_home.dart';
import 'tracking_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(ApiService.warmUpLocalBackend());
  runApp(const LuGoApp());
}

class LuGoApp extends StatelessWidget {
  const LuGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LandingScreen(),
        '/register': (context) => RegisterScreen(),
        '/otp': (context) => OtpScreen(),
        '/login': (context) => LoginScreen(),
        '/forgotPassword': (context) => ForgotPasswordScreen(),
        '/verifyResetOtp': (context) => VerifyResetOtpScreen(),
        '/resetPassword': (context) => ResetPasswordScreen(),
        '/driverHome': (context) => DriverHome(),
        '/studentHome': (context) => StudentHome(),
        '/routes': (context) => RoutesScreen(),
        '/tracking': (context) => TrackingScreen(),
      },
    );
  }
}
