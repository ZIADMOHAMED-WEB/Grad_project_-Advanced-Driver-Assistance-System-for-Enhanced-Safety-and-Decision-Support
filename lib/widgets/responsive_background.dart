import 'package:flutter/material.dart';

class ResponsiveBackground extends StatelessWidget {
  final Widget child;

  const ResponsiveBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withAlpha(102),
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
