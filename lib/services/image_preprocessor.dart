import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Prepares camera/gallery captures for ML Kit OCR.
class ImagePreprocessor {
  ImagePreprocessor._();

  static const _contentThreshold = 185;
  static const _cropPaddingFraction = 0.02;
  static const _minCropFraction = 0.15;
  static const _maxDeskewDegrees = 5.0;
  static const _deskewStepDegrees = 0.5;

  /// Minimal fast path: orient only, optional light contrast. No crop/deskew loops.
  static Future<File> processMinimal(File input, {bool lightContrast = false}) async {
    final bytes = await input.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) {
      throw FormatException('Could not decode image: ${input.path}');
    }

    image = img.bakeOrientation(image);
    if (lightContrast) {
      image = img.adjustColor(image, contrast: 1.15, brightness: 1.02);
    }

    final tempDir = await getTemporaryDirectory();
    final outPath = p.join(
      tempDir.path,
      'ocr_minimal_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final output = File(outPath);
    await output.writeAsBytes(img.encodeJpg(image, quality: 90));
    return output;
  }

  /// Runs decode → orient → crop → deskew → grayscale → contrast → sharpen.
  static Future<File> process(File input) async {
    final bytes = await input.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) {
      throw FormatException('Could not decode image: ${input.path}');
    }

    image = img.bakeOrientation(image);
    image = _cropToDocument(image);
    image = _deskew(image);
    image = img.grayscale(image);
    image = img.adjustColor(
      image,
      contrast: 1.35,
      brightness: 1.05,
      gamma: 0.95,
    );
    image = _sharpen(image);

    final tempDir = await getTemporaryDirectory();
    final outPath = p.join(
      tempDir.path,
      'ocr_preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final output = File(outPath);
    await output.writeAsBytes(img.encodeJpg(image, quality: 92));
    return output;
  }

  /// Crops to the bounding box of dark content after contrast boost + binarize.
  static img.Image _cropToDocument(img.Image source) {
    final analysis = img.grayscale(source.clone());
    img.adjustColor(analysis, contrast: 1.6);

    var minX = source.width;
    var minY = source.height;
    var maxX = 0;
    var maxY = 0;
    var foundContent = false;

    for (var y = 0; y < analysis.height; y++) {
      for (var x = 0; x < analysis.width; x++) {
        if (_luminance(analysis.getPixel(x, y)) < _contentThreshold) {
          foundContent = true;
          minX = math.min(minX, x);
          minY = math.min(minY, y);
          maxX = math.max(maxX, x);
          maxY = math.max(maxY, y);
        }
      }
    }

    if (!foundContent) {
      return source;
    }

    final padX = (source.width * _cropPaddingFraction).round();
    final padY = (source.height * _cropPaddingFraction).round();
    minX = math.max(0, minX - padX).toInt();
    minY = math.max(0, minY - padY).toInt();
    maxX = math.min(source.width - 1, maxX + padX).toInt();
    maxY = math.min(source.height - 1, maxY + padY).toInt();

    final cropWidth = maxX - minX + 1;
    final cropHeight = maxY - minY + 1;

    if (cropWidth < source.width * _minCropFraction ||
        cropHeight < source.height * _minCropFraction) {
      return source;
    }
    if (cropWidth >= source.width * 0.98 &&
        cropHeight >= source.height * 0.98) {
      return source;
    }

    return img.copyCrop(
      source,
      x: minX,
      y: minY,
      width: cropWidth,
      height: cropHeight,
    );
  }

  /// Picks a small rotation that maximizes horizontal text-line projection variance.
  static img.Image _deskew(img.Image source) {
    final gray = img.grayscale(source);
    var bestAngle = 0.0;
    var bestScore = double.negativeInfinity;

    for (var angle = -_maxDeskewDegrees;
        angle <= _maxDeskewDegrees;
        angle += _deskewStepDegrees) {
      final sample = angle == 0
          ? gray
          : img.copyRotate(gray, angle: angle);
      final score = _horizontalProjectionVariance(sample);
      if (score > bestScore) {
        bestScore = score;
        bestAngle = angle;
      }
    }

    if (bestAngle.abs() < 0.25) {
      return source;
    }

    return img.copyRotate(source, angle: bestAngle);
  }

  static double _horizontalProjectionVariance(img.Image gray) {
    final rowCounts = List<int>.filled(gray.height, 0);
    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        if (_luminance(gray.getPixel(x, y)) < 128) {
          rowCounts[y]++;
        }
      }
    }

    if (rowCounts.isEmpty) {
      return 0;
    }

    final mean = rowCounts.reduce((a, b) => a + b) / rowCounts.length;
    var variance = 0.0;
    for (final count in rowCounts) {
      final delta = count - mean;
      variance += delta * delta;
    }
    return variance;
  }

  static img.Image _sharpen(img.Image source) {
    return img.convolution(
      source,
      filter: [
        0,
        -1,
        0,
        -1,
        5,
        -1,
        0,
        -1,
        0,
      ],
    );
  }

  static int _luminance(img.Pixel pixel) {
    return pixel.r.toInt();
  }
}
