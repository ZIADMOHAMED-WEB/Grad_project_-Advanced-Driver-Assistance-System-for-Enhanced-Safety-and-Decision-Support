import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'subscription_plans_screen.dart';
import 'screens/camera_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

late List<CameraDescription> cameras;

class ADASApp extends StatelessWidget {
  const ADASApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = <String, WidgetBuilder>{
      '/': (context) => const WelcomeScreen(),
      '/auth': (context) => const LoginScreen(),
      '/login': (context) => const LoginScreen(),
      '/signup': (context) => const SignupScreen(),
      '/home': (context) => const HomeScreen(),
      '/subscription-plans': (context) => const SubscriptionPlansScreen(),
      '/settings': (context) => const SettingsScreen(),
    };

    if (cameras.isNotEmpty) {
      // if (!kIsWeb) {
      //   routes.addAll({
      //     '/sleep_detection': (context) => MyApp(camera: cameras.first),
      //   });
      // }
      routes.addAll({'/camera': (context) => const DriverMonitoringScreen()});
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: routes,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  cameras = await availableCameras();
  runApp(const ADASApp());
}
