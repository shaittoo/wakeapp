import 'package:flutter/material.dart';
import 'dart:math';

class SemiCircleSlider extends StatefulWidget {
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;
  final String unit;

  const SemiCircleSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.unit = 'M',
  });

  @override
  State<SemiCircleSlider> createState() => _SemiCircleSliderState();
}

class _SemiCircleSliderState extends State<SemiCircleSlider> {
  double? _dragValue;

  void _handleDrag(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    double angle = atan2(dy, dx);
    // Clamp angle to [pi, 0] (semi-circle)
    if (angle > 0) angle = 0;
    if (angle < -pi) angle = -pi;
    double t = 1 - (angle.abs() / pi); // 0 (left) to 1 (right)
    double value = widget.min + t * (widget.max - widget.min);
    widget.onChanged(value.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        _handleDrag(details.localPosition, box.size);
      },
      onPanUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        _handleDrag(details.localPosition, box.size);
      },
      child: CustomPaint(
        size: Size(220, 110),
        painter: _SemiCirclePainter(
          min: widget.min,
          max: widget.max,
          value: widget.value,
        ),
        child: SizedBox(
          width: 220,
          height: 110,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Set radius',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[900],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${widget.value.round()} ${widget.unit}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SemiCirclePainter extends CustomPainter {
  final double min;
  final double max;
  final double value;

  _SemiCirclePainter({required this.min, required this.max, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 16;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Draw background arc
    final bgPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawArc(arcRect, pi, pi, false, bgPaint);

    // Draw active arc
    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, pi, pi * t, false, activePaint);

    // Draw thumb
    final thumbAngle = pi + pi * t;
    final thumbX = center.dx + radius * cos(thumbAngle);
    final thumbY = center.dy + radius * sin(thumbAngle);
    final thumbPaint = Paint()..color = Colors.orange;
    canvas.drawCircle(Offset(thumbX, thumbY), 14, thumbPaint);
    canvas.drawCircle(Offset(thumbX, thumbY), 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 