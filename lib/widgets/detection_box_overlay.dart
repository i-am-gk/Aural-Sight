import 'package:flutter/material.dart';
import '../models/detected_object.dart';

class DetectionBoxOverlay extends StatelessWidget {
  final List<DetectedObject> detections;
  final Size previewSize;

  const DetectionBoxOverlay({
    super.key,
    required this.detections,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetectionPainter(detections),
      size: Size.infinite,
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<DetectedObject> detections;

  _DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final Paint boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint textBgPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final TextStyle textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    // The 'size' parameter represents the actual canvas dimensions in logical pixels.
    // Using this ensures bounding boxes scale correctly to the screen regardless of preview resolution.
    final double width = size.width;
    final double height = size.height;
    
    if (width == 0 || height == 0) {
      print("Warning: Painter canvas size is 0x0. Bounding boxes won't be visible.");
    }

    for (var detection in detections) {
      // The boundingBox is normalized (0.0 to 1.0) relative to the model input.
      // Scaling it by the canvas size aligns it perfectly with the AspectRatio preview.
      final rect = Rect.fromLTWH(
        detection.boundingBox.left * width,
        detection.boundingBox.top * height,
        detection.boundingBox.width * width,
        detection.boundingBox.height * height,
      );

      // Draw bounding box
      canvas.drawRect(rect, boxPaint);

      // Prepare label text
      final String labelText = '${detection.label} ${(detection.confidence * 100).toStringAsFixed(1)}%';
      final TextSpan textSpan = TextSpan(
        text: labelText,
        style: textStyle,
      );
      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw label background
      final double textHeight = textPainter.height;
      final double textWidth = textPainter.width;
      final Rect textBgRect = Rect.fromLTWH(
        rect.left,
        rect.top - textHeight - 4, // Position above the box
        textWidth + 8,
        textHeight + 4,
      );
      
      // Adjust if label goes off screen (top)
      final correctedTextBgRect = textBgRect.top < 0 
          ? Rect.fromLTWH(rect.left, rect.top, textWidth + 8, textHeight + 4) // Move inside box if at top edge
          : textBgRect;

      canvas.drawRect(correctedTextBgRect, textBgPaint);

      // Draw text
      textPainter.paint(
        canvas,
        Offset(correctedTextBgRect.left + 4, correctedTextBgRect.top + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    // Repaint if detections change
    return oldDelegate.detections != detections;
  }
}
