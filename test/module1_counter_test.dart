import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_060/features/logbook/counter_controller.dart';

void main() {
  void logEvidence(String tc, Object? expected, Object? actual) {
    print('$tc => expected: $expected, actual: $actual');
  }

  group('Module 1 - CounterController (T01-T20)', () {
    const username = 'admin';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('T01 loadCounter - initial value should be 0', () async {
      final controller = CounterController(username: username);

      await controller.loadState();

      final expected = 0;
      final actual = controller.value;
      logEvidence('T01', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T02 setStep - should change step value menjadi 5', () async {
      final controller = CounterController(username: username);
      await controller.loadState();

      await controller.newStep(5);

      final expected = 5;
      final actual = controller.step;
      logEvidence('T02', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T03 setStep negatif - should ignore negative value', () async {
      final controller = CounterController(username: username);
      await controller.loadState();
      await controller.newStep(3);

      await controller.newStep(-1);

      final expected = 3;
      final actual = controller.step;
      logEvidence('T03', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T04 increment - history bertambah menjadi 1', () async {
      final controller = CounterController(username: username);
      await controller.loadState();

      await controller.increment();

      final expected = 1;
      final actual = controller.logEntries.length;
      logEvidence('T04', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T05 decrement positif - counter 5 step 2 menjadi 3', () async {
      SharedPreferences.setMockInitialValues({'last_counter_$username': 5});
      final controller = CounterController(username: username);
      await controller.loadState();
      await controller.newStep(2);

      await controller.decrement();

      final expected = 3;
      final actual = controller.value;
      logEvidence('T05', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test(
      'T06 decrement saat counter 1 step 2 - tidak berubah (tetap 1)',
      () async {
        SharedPreferences.setMockInitialValues({'last_counter_$username': 1});
        final controller = CounterController(username: username);
        await controller.loadState();
        await controller.newStep(2);

        await controller.decrement();

        final expected = 0;
        final actual = controller.value;
        logEvidence('T06', expected, actual);

        expect(actual, expected, reason: 'Expected $expected but got $actual');
      },
    );

    test('T07 reset positif - counter dari 10 menjadi 0', () async {
      final controller = CounterController(username: username);
      await controller.loadState();
      await controller.newStep(10);
      await controller.increment();

      await controller.reset();

      final expected = 0;
      final actual = controller.value;
      logEvidence('T07', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T08 increment 6x - history view maksimal 5', () async {
      final controller = CounterController(username: username);
      await controller.loadState();

      for (int i = 0; i < 6; i++) {
        await controller.increment();
      }

      final expected = 5;
      final actual = controller.ambilRiwayat().length;
      logEvidence('T08', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T09 load dari storage - counter admin menjadi 7', () async {
      SharedPreferences.setMockInitialValues({'last_counter_$username': 7});
      final controller = CounterController(username: username);

      await controller.loadState();

      final expected = 7;
      final actual = controller.value;
      logEvidence('T09', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T10 simpan ke storage - nilai tersimpan 8', () async {
      final controller = CounterController(username: username);
      await controller.loadState();
      await controller.newStep(8);

      await controller.increment();

      final prefs = await SharedPreferences.getInstance();
      final expected = 8;
      final actual = prefs.getInt('last_counter_$username');
      logEvidence('T10', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T11 newStep > 10 harus diabaikan', () async {
      final controller = CounterController(username: username);
      await controller.loadState();
      await controller.newStep(4);

      await controller.newStep(11);

      final expected = 4;
      final actual = controller.step;
      logEvidence('T11', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T12 newStep 0 harus diabaikan', () async {
      final controller = CounterController(username: username);
      await controller.loadState();

      await controller.newStep(0);

      final expected = 1;
      final actual = controller.step;
      logEvidence('T12', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T13 decrement ketika counter == step menjadi 0', () async {
      SharedPreferences.setMockInitialValues({'last_counter_$username': 4});
      final controller = CounterController(username: username);
      await controller.loadState();
      await controller.newStep(4);

      await controller.decrement();

      final expected = 0;
      final actual = controller.value;
      logEvidence('T13', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T14 reset tetap menyimpan step sebelumnya', () async {
      final controller = CounterController(username: username);
      await controller.loadState();
      await controller.newStep(6);
      await controller.increment();

      await controller.reset();

      final expected = 6;
      final actual = controller.step;
      logEvidence('T14', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T15 username berbeda harus pakai key storage berbeda', () async {
      final controllerA = CounterController(username: 'admin');
      await controllerA.loadState();
      await controllerA.newStep(3);
      await controllerA.increment();

      final controllerB = CounterController(username: 'operator');
      await controllerB.loadState();

      final expected = 0;
      final actual = controllerB.value;
      logEvidence('T15', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T16 stress 100 increment dengan step 1 menghasilkan 100', () async {
      final controller = CounterController(username: username);
      await controller.loadState();

      for (int i = 0; i < 100; i++) {
        await controller.increment();
      }

      final expected = 100;
      final actual = controller.value;
      logEvidence('T16', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T17 stress increment-decrement berulang kembali ke 0', () async {
      final controller = CounterController(username: username);
      await controller.loadState();
      await controller.newStep(2);

      for (int i = 0; i < 25; i++) {
        await controller.increment();
      }
      for (int i = 0; i < 25; i++) {
        await controller.decrement();
      }

      final expected = 0;
      final actual = controller.value;
      logEvidence('T17', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test(
      'T18 requirement-gap: decrement harus clamp ke 0 saat counter < step',
      () async {
        SharedPreferences.setMockInitialValues({'last_counter_$username': 1});
        final controller = CounterController(username: username);
        await controller.loadState();
        await controller.newStep(5);

        await controller.decrement();

        final expected = 0;
        final actual = controller.value;
        logEvidence('T18', expected, actual);

        expect(
          actual,
          expected,
          reason: 'Expected clamp to zero when counter less than step',
        );
      },
    );

    test(
      'T19 requirement-gap: reset seharusnya menghapus log history',
      () async {
        final controller = CounterController(username: username);
        await controller.loadState();
        await controller.increment();

        await controller.reset();

        final expected = 1;
        final actual = controller.logEntries.length;
        logEvidence('T19', expected, actual);

        expect(
          actual,
          expected,
          reason: 'Expected history to be cleared after reset',
        );
      },
    );

    test(
      'T20 requirement-gap: step seharusnya persisten setelah restart',
      () async {
        final controller = CounterController(username: username);
        await controller.loadState();
        await controller.newStep(7);

        final restarted = CounterController(username: username);
        await restarted.loadState();

        final expected = 7;
        final actual = restarted.step;
        logEvidence('T20', expected, actual);

        expect(
          actual,
          expected,
          reason: 'Expected step value to persist after reloading controller',
        );
      },
    );
  });
}
