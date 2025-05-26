import 'package:flutter_test/flutter_test.dart';
import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines/blankets_and_wines_platform_interface.dart';
import 'package:blankets_and_wines/blankets_and_wines_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBlanketsAndWinesPlatform
    with MockPlatformInterfaceMixin
    implements BlanketsAndWinesPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

// void main() {
//   final BlanketsAndWinesPlatform initialPlatform = BlanketsAndWinesPlatform.instance;

//   test('$MethodChannelBlanketsAndWines is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelBlanketsAndWines>());
//   });

//   test('getPlatformVersion', () async {
//     BlanketsAndWines blanketsAndWinesPlugin = BlanketsAndWines();
//     MockBlanketsAndWinesPlatform fakePlatform = MockBlanketsAndWinesPlatform();
//     BlanketsAndWinesPlatform.instance = fakePlatform;

//     expect(await blanketsAndWinesPlugin.getPlatformVersion(), '42');
//   });
// }
