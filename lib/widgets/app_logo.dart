import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 120,
    this.fit = BoxFit.contain,
  });

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'App logo',
      child: Image.asset(
        'assets/images/AI_age_logo-02.jpg',
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            alignment: Alignment.center,
            child: const Text(
              'Logo not found',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        },
      ),
    );
  }
}
