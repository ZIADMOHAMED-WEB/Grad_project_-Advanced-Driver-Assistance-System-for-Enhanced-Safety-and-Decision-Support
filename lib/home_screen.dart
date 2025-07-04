import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ADAS System',
              style: TextStyle(
                fontSize: isMobile ? 24 : isTablet ? 28 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/sleep_detection');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 50 : isTablet ? 70 : 90,
                  vertical: isMobile ? 15 : isTablet ? 18 : 20,
                ),
                minimumSize: Size(
                  isMobile ? 200 : isTablet ? 250 : 300,
                  isMobile ? 50 : isTablet ? 60 : 70,
                ),
              ),
              child: Text(
                'Start Sleep Detection',
                style: TextStyle(
                  fontSize: isMobile ? 16 : isTablet ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
