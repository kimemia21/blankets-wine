import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'blankets_and_wines_platform_interface.dart';

/// An implementation of [BlanketsAndWinesPlatform] that uses method channels.
class MethodChannelBlanketsAndWines extends BlanketsAndWinesPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('blankets_and_wines');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
