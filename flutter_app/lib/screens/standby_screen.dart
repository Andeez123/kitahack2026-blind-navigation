import 'package:flutter/material.dart';

class StandbyScreen extends StatelessWidget {
  final bool gpsActive;
  final String? error;
  final VoidCallback onStart;

  const StandbyScreen({
    super.key,
    required this.gpsActive,
    this.error,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000000),
            Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const Text(
                    'Standby',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFACC15),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF27272A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade500,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade500.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Listening for "Start"',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GPS: ${gpsActive ? 'ACTIVE' : 'NO SIGNAL'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: gpsActive ? Colors.green.shade500 : Colors.red.shade500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onStart,
                child: Container(
                  width: 288,
                  height: 288,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF18181B),
                    border: Border.all(
                      color: const Color(0xFF27272A),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (error != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade400,
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
