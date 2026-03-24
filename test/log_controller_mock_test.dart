import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart' as hive;
import 'package:logbook_app_060/features/logbook/log_controller.dart';
import 'package:logbook_app_060/features/models/log_model.dart';
import 'package:logbook_app_060/services/log_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockLogRemoteDataSource extends Mock implements LogRemoteDataSource {}

class MockLogBox extends Mock implements hive.Box<LogModel> {}

class FakeLogModel extends Fake implements LogModel {}

class FakeObjectId extends Fake implements ObjectId {}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    registerFallbackValue(FakeLogModel());
    registerFallbackValue(FakeObjectId());
  });

  group('LogController dependency inversion', () {
    late MockLogRemoteDataSource remote;
    late MockLogBox box;
    late LogController controller;
    late List<LogModel> localLogs;

    setUp(() {
      remote = MockLogRemoteDataSource();
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
      when(() => box.addAll(any())).thenAnswer((invocation) async {
        final logs = (invocation.positionalArguments[0] as Iterable<dynamic>)
            .cast<LogModel>()
            .toList();
        localLogs.addAll(logs);
        return List<int>.generate(logs.length, (index) => index);
      });
      when(() => box.putAt(any(), any())).thenAnswer((invocation) async {
        final index = invocation.positionalArguments[0] as int;
        final log = invocation.positionalArguments[1] as LogModel;
        localLogs[index] = log;
      });
      when(() => box.deleteAt(any())).thenAnswer((invocation) async {
        final index = invocation.positionalArguments[0] as int;
        localLogs.removeAt(index);
      });

      controller = LogController(remoteDataSource: remote, localBox: box);
    });

    test(
      'loadLogs uses injected datasource instead of concrete MongoService',
      () async {
        when(() => remote.getLogs('team_alpha')).thenAnswer(
          (_) async => [
            LogModel(
              id: ObjectId().oid,
              title: 'Cloud log',
              description: 'desc',
              date: DateTime.now().toIso8601String(),
              authorId: 'u1',
              teamId: 'team_alpha',
            ),
          ],
        );

        await controller.loadLogs('team_alpha');

        verify(() => remote.getLogs('team_alpha')).called(1);
        expect(controller.logsNotifier.value.length, 1);
        expect(controller.logsNotifier.value.first.title, 'Cloud log');
      },
    );

    test(
      'addLog writes local first and then syncs via injected datasource',
      () async {
        when(() => remote.insertLog(any())).thenAnswer((_) async => ObjectId());

        await controller.addLog('Title', 'Body', 'u1', 'team_alpha', false);

        verify(() => box.add(any())).called(1);
        verify(() => remote.insertLog(any())).called(1);
        expect(controller.logsNotifier.value.length, 1);
      },
    );

    test(
      'offline delete keeps local tombstone and prevents ghost cloud data from reappearing',
      () async {
        final existingLog = LogModel(
          id: ObjectId().oid,
          title: 'Cloud-backed log',
          description: 'desc',
          date: DateTime.now().toIso8601String(),
          authorId: 'u1',
          teamId: 'team_alpha',
          isSynced: true,
          syncedAt: DateTime.now().toIso8601String(),
        );

        localLogs.add(existingLog);
        controller.logsNotifier.value = [existingLog];

        when(() => remote.deleteLog(any())).thenThrow(Exception('offline'));
        when(
          () => remote.getLogs('team_alpha'),
        ).thenAnswer((_) async => [existingLog]);

        await controller.removeLog(0);

        expect(controller.logsNotifier.value, isEmpty);
        expect(localLogs.single.isDeleted, true);

        await controller.loadLogs('team_alpha');

        expect(controller.logsNotifier.value.length, 1);
        expect(controller.logsNotifier.value.single.isDeleted, true);
        expect(localLogs.single.isDeleted, true);

        final visibleForOwner = controller.filterVisibleLogs(
          controller.logsNotifier.value,
          'u1',
          'team_alpha',
        );
        final visibleForTeammate = controller.filterVisibleLogs(
          controller.logsNotifier.value,
          'u2',
          'team_alpha',
        );

        expect(visibleForOwner.length, 1);
        expect(visibleForOwner.single.isDeleted, true);
        expect(visibleForTeammate, isEmpty);
      },
    );

    test('Visibility: Private owner-only, public only for same team', () {
      // 1. Setup Data:
      // User A memiliki 2 catatan: 1 private, 1 public, keduanya di team_alpha
      final userALogs = <LogModel>[
        LogModel(
          id: ObjectId().oid,
          title: 'A private note',
          description: 'secret',
          date: DateTime.now().toIso8601String(),
          authorId: 'user_a',
          teamId: 'team_alpha',
          isPublic: false,
        ),
        LogModel(
          id: ObjectId().oid,
          title: 'A public note',
          description: 'shareable',
          date: DateTime.now().toIso8601String(),
          authorId: 'user_a',
          teamId: 'team_alpha',
          isPublic: true,
        ),
      ];

      // 2. Action - User B dari team yang SAMA (team_alpha):
      // Catatan private harus tetap tersembunyi.
      final visibleForTeammate = controller.filterVisibleLogs(
        userALogs,
        'user_b',
        'team_alpha', // Same team
      );

      // 3. Assert: Teammate hanya bisa melihat catatan public.
      expect(visibleForTeammate.length, 1);
      expect(visibleForTeammate.first.title, 'A public note');
      expect(visibleForTeammate.first.isPublic, true);

      // 4. Action - User C dari team BERBEDA (team_beta):
      // Tidak boleh melihat catatan tim alpha, termasuk yang public.
      final visibleForOutsider = controller.filterVisibleLogs(
        userALogs,
        'user_c',
        'team_beta', // Different team
      );

      // 5. Assert: Outsider tidak melihat catatan apapun.
      expect(visibleForOutsider, isEmpty);
    });
  });
}
