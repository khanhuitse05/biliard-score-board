import 'package:flutter_test/flutter_test.dart';
import 'package:score_board/services/wakelock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WakelockService', () {
    test('enable runs safely without throwing', () async {
      await expectLater(WakelockService.enable(), completes);
    });
  });
}
