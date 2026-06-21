import 'package:flutter/material.dart';

class DesktopPhoneFrame extends StatelessWidget {
  const DesktopPhoneFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return child;
        }

        return Container(
          color: const Color(0xFFDFF3FF),
          alignment: Alignment.center,
          child: Container(
            width: 430,
            height: 932,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFF08090D),
              borderRadius: BorderRadius.circular(58),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66001430),
                  blurRadius: 70,
                  offset: Offset(0, 28),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
