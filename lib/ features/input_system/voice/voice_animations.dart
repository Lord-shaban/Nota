import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceAnimations {
  // Pulse animation for recording
  static Widget pulseAnimation({
    required AnimationController controller,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 120 + (40 * controller.value),
          height: 120 + (40 * controller.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.3 * (1 - controller.value)),
          ),
        );
      },
    );
  }

  // Wave animation for voice input
  static Widget waveAnimation() {
    return SizedBox(
      width: 120,
      height: 40,
      child: CustomPaint(painter: WavePainter()),
    );
  }

  // Recording indicator (blinking dot)
  static Widget recordingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(Colors.red, Colors.red.withOpacity(0.3), value),
          ),
        );
      },
      onEnd: () {
        // Restart animation
      },
    );
  }

  // Sound bars animation
  static Widget soundBars({
    required bool isActive,
    Color color = const Color(0xFFFFB800),
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 100 + (index * 100)),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 4,
          height: isActive ? 20.0 + (math.Random().nextDouble() * 20) : 8.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// Custom wave painter
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB800)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = size.height / 2;
    final waveLength = size.width / 3;

    path.moveTo(0, waveHeight);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        waveHeight + math.sin((i / waveLength) * 2 * math.pi) * 10,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
