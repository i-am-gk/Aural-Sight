import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'detection_constants.dart';

class ImageUtils {
  const ImageUtils._();

  /// Converts a [CameraImage] to an [img.Image] in RGB format.
  /// Handles YUV420 (Android default) and BGRA8888 (iOS default).
  /// Converts and resizes a [CameraImage] to an [img.Image] in one pass.
  /// This is much faster than converting full size and then resizing.
  static img.Image? convertAndResize(CameraImage cameraImage, int targetSize, {int sensorOrientation = 90}) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToImageOptimized(cameraImage, targetSize, sensorOrientation);
    } else {
      // For other formats, use standard conversion then resize
      final fullImage = convertCameraImage(cameraImage);
      if (fullImage == null) return null;

      // Handle fallback mathematical rotation
      img.Image processed = fullImage;
      if (sensorOrientation == 90) {
        processed = img.copyRotate(processed, angle: 90);
      } else if (sensorOrientation == 270) {
        processed = img.copyRotate(processed, angle: 270);
      } else if (sensorOrientation == 180) {
        processed = img.copyRotate(processed, angle: 180);
      }

      // Handle center crop
      final int size = processed.width < processed.height ? processed.width : processed.height;
      final int x = (processed.width - size) ~/ 2;
      final int y = (processed.height - size) ~/ 2;
      final cropped = img.copyCrop(processed, x: x, y: y, width: size, height: size);

      return img.copyResize(cropped, width: targetSize, height: targetSize);
    }
  }

  /// Optimized YUV420 to RGB conversion with built-in rotation and center crop
  static img.Image _convertYUV420ToImageOptimized(CameraImage cameraImage, int targetSize, int sensorOrientation) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel!;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    final image = img.Image(width: targetSize, height: targetSize);

    // 1. Determine rotated dimensions
    final bool isPortrait = sensorOrientation == 90 || sensorOrientation == 270;
    final int rW = isPortrait ? height : width;
    final int rH = isPortrait ? width : height;

    // 2. Center crop dimensions in the rotated space
    final int cropSize = rW < rH ? rW : rH;
    final int cropOffsetX = (rW - cropSize) ~/ 2;
    final int cropOffsetY = (rH - cropSize) ~/ 2;

    // 3. Step sizes to map 300x300 onto the cropSize square
    final double step = cropSize / targetSize;

    for (int h = 0; h < targetSize; h++) {
      // Y coordinate in rotated crop space
      final int ry = (h * step).toInt() + cropOffsetY;

      for (int w = 0; w < targetSize; w++) {
        // X coordinate in rotated crop space
        final int rx = (w * step).toInt() + cropOffsetX;

        // 4. Map back to raw physical sensor coordinates
        int rawX, rawY;
        if (sensorOrientation == 90) {
          rawX = ry;
          rawY = height - 1 - rx;
        } else if (sensorOrientation == 270) {
          rawX = width - 1 - ry;
          rawY = rx;
        } else if (sensorOrientation == 180) {
          rawX = width - 1 - rx;
          rawY = height - 1 - ry;
        } else {
          rawX = rx;
          rawY = ry;
        }

        // Bound safety
        if (rawX < 0) rawX = 0;
        if (rawX >= width) rawX = width - 1;
        if (rawY < 0) rawY = 0;
        if (rawY >= height) rawY = height - 1;

        // 5. YUV Extraction
        final int uvX = rawX ~/ 2;
        final int uvY = rawY ~/ 2;

        final int yIndex = (rawY * yRowStride) + (rawX * yPixelStride);
        final int y = yBuffer[yIndex];

        final int uvIndex = (uvY * uvRowStride) + (uvX * uvPixelStride);
        final int u = uBuffer[uvIndex];
        final int v = vBuffer[uvIndex];

        // Fast integer-based RGB conversion
        int r = (y + v * 1436 ~/ 1024 - 179).clamp(0, 255);
        int g = (y - u * 46549 ~/ 131072 + 44 - v * 93604 ~/ 131072 + 91).clamp(0, 255);
        int b = (y + u * 1814 ~/ 1024 - 227).clamp(0, 255);

        image.setPixelRgb(w, h, r, g, b);
      }
    }
    return image;
  }

  /// Converts a [CameraImage] to an [img.Image] in RGB format.
  static img.Image? convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToImage(cameraImage);
    }
    return null;
  }

  static img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final image = img.Image(width: width, height: height);
    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        final yIndex = (h * yPlane.bytesPerRow) + (w * yPlane.bytesPerPixel!);
        final int y = yPlane.bytes[yIndex];
        final int uvIndex = ((h ~/ 2) * uPlane.bytesPerRow) + ((w ~/ 2) * uPlane.bytesPerPixel!);
        final int u = uPlane.bytes[uvIndex];
        final int v = vPlane.bytes[uvIndex];
        int r = (y + v * 1436 ~/ 1024 - 179).clamp(0, 255);
        int g = (y - u * 46549 ~/ 131072 + 44 - v * 93604 ~/ 131072 + 91).clamp(0, 255);
        int b = (y + u * 1814 ~/ 1024 - 227).clamp(0, 255);
        image.setPixelRgb(w, h, r, g, b);
      }
    }
    return image;
  }
}
