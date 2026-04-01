import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart' as hive;
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:logbook_app_060/features/logbook/log_controller.dart';
import 'package:logbook_app_060/features/models/log_model.dart';
import 'package:logbook_app_060/services/log_remote_data_source.dart';

class MockRemoteDataSource extends Mock implements LogRemoteDataSource {}

class MockLogBox extends Mock implements hive.Box<LogModel> {}

class FakeLogModel extends Fake implements LogModel {}

void main() {
  void logEvidence(String tc, Object? expected, Object? actual) {
    print('$tc => expected: $expected, actual: $actual');
  }

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    registerFallbackValue(FakeLogModel());
  });

  group('Module 4 - Save Data to Cloud Service (T01-T06)', () {
    late MockRemoteDataSource remote;
    late MockLogBox box;
    late LogController controller;
    late List<LogModel> localLogs;

    setUp(() {
      remote = MockRemoteDataSource();
      box = MockLogBox();
      localLogs = <LogModel>[];

      when(() => box.values).thenAnswer((_) => localLogs);
      when(() => box.length).thenAnswer((_) => localLogs.length);
      when(() => box.getAt(any())).thenAnswer((invocation) {
        final index = invocation.positionalArguments[0] as int;
        if (index < 0 || index >= localLogs.length) {
          return null;
        }
        return localLogs[index];
      });
      when(() => box.add(any())).thenAnswer((invocation) async {
        localLogs.add(invocation.positionalArguments[0] as LogModel);
        return localLogs.length - 1;
      });
      when(() => box.putAt(any(), any())).thenAnswer((invocation) async {
        final index = invocation.positionalArguments[0] as int;
        final log = invocation.positionalArguments[1] as LogModel;
        localLogs[index] = log;
      });

      controller = LogController(remoteDataSource: remote, localBox: box);
    });

    test('T01 addLog sukses tersinkron ke cloud', () async {
      when(() => remote.insertLog(any())).thenAnswer((_) async => ObjectId());

      await controller.addLog('Judul A', 'Isi A', 'u1', 'team_alpha', false);

      final expected = true;
      final actual = controller.logsNotifier.value.first.isSynced;
      logEvidence('T01', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T02 addLog offline tetap tersimpan lokal sebagai pending', () async {
      when(() => remote.insertLog(any())).thenThrow(Exception('offline'));

      await controller.addLog('Judul B', 'Isi B', 'u1', 'team_alpha', false);

      final expected = false;
      final actual = controller.logsNotifier.value.first.isSynced;
      logEvidence('T02', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T03 dua addLog memanggil remote insert dua kali', () async {
      int callCount = 0;
      when(() => remote.insertLog(any())).thenAnswer((_) async {
        callCount++;
        return ObjectId();
      });

      await controller.addLog('A', 'A', 'u1', 'team_alpha', true);
      await controller.addLog('B', 'B', 'u1', 'team_alpha', false);

      final expected = 2;
      final actual = callCount;
      logEvidence('T03', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T04 kategori custom tersimpan pada data notifier', () async {
      when(() => remote.insertLog(any())).thenAnswer((_) async => ObjectId());

      await controller.addLog(
        'Judul C',
        'Isi C',
        'u1',
        'team_alpha',
        true,
        'Hardware',
      );

      final expected = 'Hardware';
      final actual = controller.logsNotifier.value.first.category;
      logEvidence('T04', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T05 saat offline data tetap masuk ke list lokal', () async {
      when(() => remote.insertLog(any())).thenThrow(Exception('offline'));

      await controller.addLog('Judul D', 'Isi D', 'u1', 'team_alpha', true);

      final expected = 1;
      final actual = controller.logsNotifier.value.length;
      logEvidence('T05', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T06 title kosong seharusnya ditolak dan tidak sync', () async {
      int callCount = 0;
      when(() => remote.insertLog(any())).thenAnswer((_) async {
        callCount++;
        return ObjectId();
      });

      await controller.addLog('', 'Isi E', 'u1', 'team_alpha', false);

      final expected = 0;
      final actual = callCount;
      logEvidence('T06', expected, actual);

      expect(
        actual,
        expected,
        reason: 'Expected empty title to be rejected before cloud sync',
      );
    });
  });
}
