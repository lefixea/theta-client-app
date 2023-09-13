import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theta_client_flutter/theta_client_flutter.dart';
import 'package:theta_client_flutter/theta_client_flutter_method_channel.dart';

void main() {
  MethodChannelThetaClientFlutter platform = MethodChannelThetaClientFlutter();
  const MethodChannel channel = MethodChannel('theta_client_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    platform = MethodChannelThetaClientFlutter();
    channel.setMockMethodCallHandler(null);
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('buildTimeShiftCapture', () async {
    final timeShift = TimeShift(
        isFrontFirst: true,
        firstInterval: TimeShiftIntervalEnum.interval_1,
        secondInterval: TimeShiftIntervalEnum.interval_2);

    Map<String, dynamic> options = {
      'TimeShift': timeShift,
    };

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      var arguments = methodCall.arguments as Map<dynamic, dynamic>;
      final timeShiftMap = arguments['TimeShift'];
      expect(arguments['_capture_interval'], 1);
      expect(timeShiftMap, isNotNull);
      expect(timeShiftMap['isFrontFirst'], true);
      expect(timeShiftMap['firstInterval'], 'INTERVAL_1');
      expect(timeShiftMap['secondInterval'], 'INTERVAL_2');

      return Future.value();
    });
    await platform.buildTimeShiftCapture(options, 1);
  });

  test('startTimeShiftCapture', () async {
    const fileUrl =
        'http://192.168.1.1/files/150100524436344d4201375fda9dc400/100RICOH/R0013336.MP4';
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return fileUrl;
    });
    expect(await platform.startTimeShiftCapture(null), fileUrl);
  });

  test('startTimeShiftCapture no file', () async {
    const fileUrl = null;
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return fileUrl;
    });
    expect(await platform.startTimeShiftCapture(null), null);
  });

  test('startTimeShiftCapture exception', () async {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      throw Exception('test error');
    });
    try {
      await platform.startTimeShiftCapture(null);
      expect(true, false, reason: 'not exception');
    } catch (error) {
      expect(error.toString().contains('test error'), true);
    }
  });

  test('progress of capture', () async {
    const fileUrl =
        'http://192.168.1.1/files/150100524436344d4201375fda9dc400/100RICOH/R0013336.MP4';

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      expect(platform.notifyList.containsKey(10002), true,
          reason: 'add notify progress');

      // native event
      platform.onNotify({
        'id': 10002,
        'params': {
          'completion': 0.1,
        },
      });
      await Future.delayed(const Duration(milliseconds: 10));
      platform.onNotify({
        'id': 10002,
        'params': {
          'completion': 0.2,
        },
      });
      await Future.delayed(const Duration(milliseconds: 10));

      return fileUrl;
    });

    int progressCount = 0;
    var resultCapture = platform.startTimeShiftCapture((completion) {
      progressCount++;
    });
    var result = await resultCapture.timeout(const Duration(seconds: 5));
    expect(result, fileUrl);
    expect(progressCount, 2);
    expect(platform.notifyList.containsKey(10002), false,
        reason: 'remove notify progress');
  });
}
