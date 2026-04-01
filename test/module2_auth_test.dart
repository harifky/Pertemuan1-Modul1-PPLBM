import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:logbook_app_060/features/auth/login_controller.dart';
import 'package:logbook_app_060/services/user_context_service.dart';

void main() {
  void logEvidence(String tc, Object? expected, Object? actual) {
    print('$tc => expected: $expected, actual: $actual');
  }

  group('Module 2 - Authentication (T01-T06)', () {
    late LoginController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await UserContextService.clearUserContext();
      controller = LoginController();
    });

    test('T01 login valid berhasil', () async {
      final expected = true;
      final actual = await controller.login('harifky', '123');
      logEvidence('T01', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T02 login gagal jika password salah', () async {
      final expected = false;
      final actual = await controller.login('harifky', 'salah');
      logEvidence('T02', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T03 login gagal jika username tidak terdaftar', () async {
      final expected = false;
      final actual = await controller.login('tidak_ada', '123');
      logEvidence('T03', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T04 login valid menyimpan role dan team sesuai mapping', () async {
      await controller.login('harifky', '123');

      final expectedRole = 'Ketua';
      final actualRole = await UserContextService.getUserRole();
      logEvidence('T04-ROLE', expectedRole, actualRole);

      final expectedTeam = 'team_alpha';
      final actualTeam = await UserContextService.getTeamId();
      logEvidence('T04-TEAM', expectedTeam, actualTeam);

      expect(actualRole, expectedRole);
      expect(actualTeam, expectedTeam);
    });

    test('T05 logout menghapus user context', () async {
      await controller.login('harifky', '123');
      await controller.logout();

      final expected = 'guest';
      final actual = await UserContextService.getUsername();
      logEvidence('T05', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test(
      'T06 input dengan spasi tetap dapat login setelah normalisasi',
      () async {
        final expected = true;
        final actual = await controller.login(' harifky ', ' 123 ');
        logEvidence('T06', expected, actual);

        expect(
          actual,
          expected,
          reason: 'Expected login succeeds after trimming surrounding spaces',
        );
      },
    );
  });
}
