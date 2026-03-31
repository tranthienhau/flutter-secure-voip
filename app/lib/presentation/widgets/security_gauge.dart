import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/security_config.dart';

/// Animated circular gauge showing fraud score 0-100.
class SecurityGauge extends StatelessWidget {
  final int score;
  final double size;

  const SecurityGauge({
    super.key,
    required this.score,
    this.size = 200,
  });

  Color get _color {
    if (score < SecurityConfig.fraudScoreLow) return Colors.green;
    if (score < SecurityConfig.fraudScoreMedium) return Colors.orange;
    if (score < SecurityConfig.fraudScoreHigh) return Colors.deepOrange;
    return Colors.red;
  }

  String get _label {
    if (score < SecurityConfig.fraudScoreLow) return 'Low Risk';
    if (score < SecurityConfig.fraudScoreMedium) return 'Medium Risk';
    if (score < SecurityConfig.fraudScoreHigh) return 'High Risk';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _GaugePainter(
              progress: value,
              color: _color,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}',
                    style: TextStyle(
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: size * 0.08,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    const startAngle = 0.75 * pi;
    const sweepRange = 1.5 * pi;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepRange,
      false,
      bgPaint,
    );

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepRange * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
