import 'dart:async';

import 'package:flutter/services.dart';

class EdgeDetection {
  static const MethodChannel _channel = const MethodChannel('edge_detection');

  /// Call this method to scan the object edge in live camera.
  static Future<List<String>> detectEdge({
    bool multipleScan = false,
    bool canUseGallery = true,
    String androidScanTitle = "Scanning",
    String androidCropTitle = "Crop",
    String androidCropBlackWhiteTitle = "Black White",
    String androidCropReset = "Reset",
  }) async {
    final List<dynamic>? paths = await _channel.invokeMethod('edge_detect', {
      'multiple_scan': multipleScan,
      'can_use_gallery': canUseGallery,
      'scan_title': androidScanTitle,
      'crop_title': androidCropTitle,
      'crop_black_white_title': androidCropBlackWhiteTitle,
      'crop_reset_title': androidCropReset,
    });

    return paths?.map((path) => path.toString()).toList() ?? [];
  }

  /// Call this method to scan the object edge from a gallery image.
  static Future<bool> detectEdgeFromGallery(
    String saveTo, {
    String androidCropTitle = "Crop",
    String androidCropBlackWhiteTitle = "Black White",
    String androidCropReset = "Reset",
  }) async {
    return await _channel.invokeMethod('edge_detect_gallery', {
      'save_to': saveTo,
      'crop_title': androidCropTitle,
      'crop_black_white_title': androidCropBlackWhiteTitle,
      'crop_reset_title': androidCropReset,
      'from_gallery': true,
    });
  }
}
