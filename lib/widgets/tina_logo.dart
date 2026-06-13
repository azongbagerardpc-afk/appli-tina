import 'package:flutter/material.dart';
import '../config/theme.dart';

class TinaLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const TinaLogo({super.key, this.size = 40, this.showGlow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.45),
                  blurRadius: size * 0.65,
                  spreadRadius: size * 0.05,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          'T',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.46,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
