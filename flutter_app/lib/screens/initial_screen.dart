import 'package:flutter/material.dart';

class InitialScreen extends StatelessWidget {
  final VoidCallback onEnableVoice;

  const InitialScreen({
    super.key,
    required this.onEnableVoice,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEnableVoice,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0A0A0A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.yellow.shade400,
                  width: 8,
                ),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellow.shade400,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.shade400.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'VisionGuide',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFACC15),
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF27272A),
                  width: 1,
                ),
              ),
              child: const Text(
                'TAP TO ACTIVATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
