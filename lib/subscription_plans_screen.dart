import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/responsive_background.dart';
import 'package:flutter_application_1/settings_screen.dart';
import 'package:flutter_application_1/payment_screen.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  static const String routeName = '/subscription-plans';

  const SubscriptionPlansScreen({super.key});

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }

  void _navigateToCamera(BuildContext context) {
    Navigator.of(context).pushNamed('/camera');
  }

  void _onSelectPlan(BuildContext context, String plan) {
    // TODO: Implement plan selection logic or payment flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: $plan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final crossAxisCount = size.width > 900 ? 3 : 1;
    final aspectRatio = size.width > 900 ? 0.85 : 1.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => _navigateToSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Go to Camera',
            onPressed: () => _navigateToCamera(context),
          ),
        ],
      ),
      body: ResponsiveBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16.0 : 40.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPlanCard(
                        context,
                        title: 'Free Trial',
                        price: 'Free',
                        period: '1 week',
                        features: const [
                          'Full access for 7 days',
                          'Limited features',
                          'No database persistence',
                        ],
                        highlight: false,
                        onTap: () => _onSelectPlan(context, 'Free Trial'),
                      ),
                      _buildPlanCard(
                        context,
                        title: 'Monthly',
                        price: '\$15',
                        period: 'per month',
                        features: const [
                          'Standard features',
                          'Database resets daily',
                          'Mobile app only',
                        ],
                        highlight: false,
                        onTap: () => _onSelectPlan(context, 'Monthly'),
                      ),
                      _buildPlanCard(
                        context,
                        title: 'Hardware + Pro',
                        price: '\$30 + \$50',
                        period: 'per month + hardware',
                        features: const [
                          'All features unlocked',
                          'Camera hardware: \$50 one-time',
                          'Database saves every alert',
                          'Priority support',
                        ],
                        highlight: true,
                        onTap: () => _onSelectPlan(context, 'Hardware + Pro'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _navigateToSettings(context),
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToCamera(context),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Go to Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFECA660),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool highlight,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    return Card(
      color: highlight ? const Color(0xFFECA660) : Colors.grey[900],
      elevation: highlight ? 10 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: highlight
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (highlight)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              if (highlight) const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: highlight ? Colors.black : Colors.white,
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                price,
                style: TextStyle(
                  color: highlight ? Colors.black : const Color(0xFFECA660),
                  fontSize: isSmallScreen ? 32 : 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                period,
                style: TextStyle(
                  color: highlight ? Colors.black87 : Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features
                    .map((feature) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: highlight
                                    ? Colors.black
                                    : const Color(0xFFECA660),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    color: highlight
                                        ? Colors.black87
                                        : Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      highlight ? Colors.black : const Color(0xFFECA660),
                  foregroundColor: highlight ? Colors.white : Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Select Plan',
                  style: TextStyle(
                    color: highlight ? Colors.white : Colors.black,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
