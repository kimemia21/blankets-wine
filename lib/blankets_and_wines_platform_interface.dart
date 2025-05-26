import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'blankets_and_wines_method_channel.dart';

abstract class BlanketsAndWinesPlatform extends PlatformInterface {
  /// Constructs a BlanketsAndWinesPlatform.
  BlanketsAndWinesPlatform() : super(token: _token);

  static final Object _token = Object();

  static BlanketsAndWinesPlatform _instance = MethodChannelBlanketsAndWines();

  /// The default instance of [BlanketsAndWinesPlatform] to use.
  ///
  /// Defaults to [MethodChannelBlanketsAndWines].
  static BlanketsAndWinesPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BlanketsAndWinesPlatform] when
  /// they register themselves.
  static set instance(BlanketsAndWinesPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
