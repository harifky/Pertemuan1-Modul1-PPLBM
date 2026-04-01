import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:logbook_app_060/services/user_context_service.dart';

void main() {
  void logEvidence(String tc, Object? expected, Object? actual) {
    print('$tc => expected: $expected, actual: $actual');
  }

  group('Module 3 - Save Data to Disk (T01-T06)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('T01 simpan context lengkap ke local storage', () async {
      await UserContextService.setUserContext(
        userId: 'u001',
        username: 'rifky',
        role: 'Ketua',
        teamId: 'team_alpha',
      );

      final expected = 'u001';
      final actual = await UserContextService.getUserId();
      logEvidence('T01', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T02 teamId default tersimpan saat tidak diisi', () async {
      await UserContextService.setUserContext(
        userId: 'u002',
        username: 'salma',
        role: 'Anggota',
      );

      final expected = 'default_team';
      final actual = await UserContextService.getTeamId();
      logEvidence('T02', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T03 context baru menimpa data lama', () async {
      await UserContextService.setUserContext(
        userId: 'old_user',
        username: 'old_name',
        role: 'Anggota',
        teamId: 'team_alpha',
      );
      await UserContextService.setUserContext(
        userId: 'new_user',
        username: 'new_name',
        role: 'Ketua',
        teamId: 'team_beta',
      );

      final expected = 'new_user';
      final actual = await UserContextService.getUserId();
      logEvidence('T03', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T04 clear context mengembalikan nilai default', () async {
      await UserContextService.setUserContext(
        userId: 'u003',
        username: 'temp_user',
        role: 'Ketua',
        teamId: 'team_alpha',
      );

      await UserContextService.clearUserContext();

      final expected = 'unknown_user';
      final actual = await UserContextService.getUserId();
      logEvidence('T04', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T05 isOwner bernilai true jika authorId sama', () async {
      await UserContextService.setUserContext(
        userId: 'u777',
        username: 'owner',
        role: 'Ketua',
      );

      final expected = true;
      final actual = await UserContextService.isOwner('u777');
      logEvidence('T05', expected, actual);

      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    test('T06 userId kosong harus ditolak oleh validasi', () async {
      final call = UserContextService.setUserContext(
        userId: '',
        username: 'invalid',
        role: 'Anggota',
      );

      logEvidence('T06', 'throws', 'no validation in current impl');

      await expectLater(
        call,
        throwsA(anything),
        reason: 'Expected empty userId to be rejected',
      );
    });
  });
}
