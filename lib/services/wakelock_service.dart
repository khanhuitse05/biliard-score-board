import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Service to keep the screen awake to prevent the device
/// from auto-locking while the app is open.
class WakelockService {
  /// Enables the screen wakelock so the display stays awake.
  static Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('WakelockService: Error enabling wakelock: $e');
    }
  }
}
