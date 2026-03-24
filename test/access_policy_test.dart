import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_060/services/access_policy.dart';

/// Unit test untuk AccessPolicy (RBAC - Role-Based Access Control)
///
/// Test Cases:
/// 1. Ketua harus bisa semua operasi (CREATE, READ, UPDATE, DELETE)
/// 2. Anggota hanya bisa CREATE, READ, dan UPDATE/DELETE milik sendiri
/// 3. Asisten bisa READ dan UPDATE saja (tidak bisa DELETE)
void main() {
  group('AccessPolicy - Ketua Role Tests', () {
    const role = 'Ketua';

    test('Ketua can CREATE', () {
      expect(AccessPolicy.canCreate(role), true);
    });

    test('Ketua can READ', () {
      expect(AccessPolicy.canRead(role), true);
    });

    test('Ketua can EDIT all logs (even not owner)', () {
      expect(AccessPolicy.canEdit(role, isOwner: false), true);
      expect(AccessPolicy.canEdit(role, isOwner: true), true);
    });

    test('Ketua can DELETE all logs (even not owner)', () {
      expect(AccessPolicy.canDelete(role, isOwner: false), true);
      expect(AccessPolicy.canDelete(role, isOwner: true), true);
    });

    test('Ketua is identified as leader', () {
      expect(AccessPolicy.isLeader(role), true);
    });
  });

  group('AccessPolicy - Anggota Role Tests', () {
    const role = 'Anggota';

    test('Anggota can CREATE', () {
      expect(AccessPolicy.canCreate(role), true);
    });

    test('Anggota can READ', () {
      expect(AccessPolicy.canRead(role), true);
    });

    test('Anggota can only EDIT own logs', () {
      expect(
        AccessPolicy.canEdit(role, isOwner: true),
        true,
        reason: 'Anggota should be able to edit their own logs',
      );
      expect(
        AccessPolicy.canEdit(role, isOwner: false),
        false,
        reason: 'Anggota should NOT be able to edit others\' logs',
      );
    });

    test('Anggota can only DELETE own logs', () {
      expect(
        AccessPolicy.canDelete(role, isOwner: true),
        true,
        reason: 'Anggota should be able to delete their own logs',
      );
      expect(
        AccessPolicy.canDelete(role, isOwner: false),
        false,
        reason: 'Anggota should NOT be able to delete others\' logs',
      );
    });

    test('Anggota is NOT identified as leader', () {
      expect(AccessPolicy.isLeader(role), false);
    });
  });

  group('AccessPolicy - Asisten Role Tests', () {
    const role = 'Asisten';

    test('Asisten CANNOT CREATE', () {
      expect(AccessPolicy.canCreate(role), false);
    });

    test('Asisten can READ', () {
      expect(AccessPolicy.canRead(role), true);
    });

    test('Asisten can UPDATE/EDIT all logs', () {
      expect(
        AccessPolicy.canEdit(role, isOwner: false),
        true,
        reason: 'Asisten can update any log (helper role)',
      );
      expect(AccessPolicy.canEdit(role, isOwner: true), true);
    });

    test('Asisten CANNOT DELETE any logs', () {
      expect(
        AccessPolicy.canDelete(role, isOwner: false),
        false,
        reason: 'Asisten cannot delete (read & update only)',
      );
      expect(
        AccessPolicy.canDelete(role, isOwner: true),
        false,
        reason: 'Asisten cannot delete even own logs',
      );
    });

    test('Asisten is NOT identified as leader', () {
      expect(AccessPolicy.isLeader(role), false);
    });
  });

  group('AccessPolicy - Edge Cases', () {
    test('Unknown role defaults to no permissions', () {
      const unknownRole = 'Unknown';
      expect(AccessPolicy.canCreate(unknownRole), false);
      expect(AccessPolicy.canDelete(unknownRole, isOwner: true), false);
    });

    test('Role info returns description', () {
      expect(AccessPolicy.getRoleInfo('Ketua'), contains('Full Access'));
      expect(AccessPolicy.getRoleInfo('Anggota'), contains('Limited Access'));
    });

    test('Debug permissions output is formatted correctly', () {
      final debug = AccessPolicy.debugPermissions('Ketua');
      expect(debug, contains('Ketua:'));
      expect(debug, contains('✅ Create'));
      expect(debug, contains('✅ Read'));
    });
  });

  group('AccessPolicy - Real-world Scenarios', () {
    test('Scenario: Anggota tries to edit someone else log', () {
      const anggota = 'Anggota';
      const isOwner = false; // Not the owner

      final canEdit = AccessPolicy.canEdit(anggota, isOwner: isOwner);
      expect(
        canEdit,
        false,
        reason: 'UI should hide/disable Edit button for non-owner Anggota',
      );
    });

    test('Scenario: Ketua edits any team member log', () {
      const ketua = 'Ketua';
      const isOwner = false; // Not the owner, but should still have access

      final canEdit = AccessPolicy.canEdit(ketua, isOwner: isOwner);
      expect(canEdit, true, reason: 'Ketua has full access to all team logs');
    });

    test('Scenario: Asisten updates log but cannot delete', () {
      const asisten = 'Asisten';

      expect(
        AccessPolicy.canEdit(asisten, isOwner: false),
        true,
        reason: 'Asisten can help update docs',
      );
      expect(
        AccessPolicy.canDelete(asisten, isOwner: true),
        false,
        reason: 'Asisten cannot delete to prevent data loss',
      );
    });
  });
}
