import 'package:logbook_app_060/services/access_control_service.dart';

/// AccessPolicy: Simplified RBAC API untuk mahasiswa
/// Centralized role-checking policy untuk menghindari logic duplikasi di UI
///
/// Filosofi: "Single Source of Truth"
/// - Semua permission logic dipusatkan di satu file
/// - UI hanya memanggil method sederhana seperti: AccessPolicy.canEdit()
/// - Perubahan role policy cukup edit di satu tempat
///
/// Contoh Penggunaan:
/// ```dart
/// // Di UI Widget:
/// if (AccessPolicy.canEdit(userRole, isOwner: true)) {
///   // Tampilkan tombol edit
/// }
///
/// if (AccessPolicy.canDelete(userRole, isOwner: false)) {
///   // Tampilkan tombol delete (will return false for Anggota)
/// }
/// ```
class AccessPolicy {
  // Private constructor to prevent instantiation
  AccessPolicy._();

  /// Mengecek apakah user bisa CREATE log baru
  ///
  /// Rules:
  /// - Ketua: ✅ Bisa create
  /// - Anggota: ✅ Bisa create
  /// - Asisten: ❌ Tidak bisa create (read & update only)
  static bool canCreate(String role) {
    return AccessControlService.canPerform(
      role,
      AccessControlService.actionCreate,
    );
  }

  /// Mengecek apakah user bisa READ/VIEW log
  ///
  /// Rules:
  /// - Semua role: ✅ Bisa read
  static bool canRead(String role) {
    return AccessControlService.canPerform(
      role,
      AccessControlService.actionRead,
    );
  }

  /// Mengecek apakah user bisa EDIT/UPDATE log
  ///
  /// Rules:
  /// - Ketua: ✅ Bisa edit semua log tim (isOwner dipaksakan true)
  /// - Anggota: ✅ Hanya bisa edit log miliknya sendiri (butuh isOwner = true)
  /// - Asisten: ✅ Bisa edit semua log (helper role)
  ///
  /// Parameters:
  /// - [role]: Role user (Ketua/Anggota/Asisten)
  /// - [isOwner]: Apakah user adalah pemilik log yang akan diedit
  static bool canEdit(String role, {required bool isOwner}) {
    // Special case: Ketua bisa edit semua log tim
    if (role == 'Ketua') {
      return true;
    }

    // General case: gunakan RBAC standard
    return AccessControlService.canPerform(
      role,
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    );
  }

  /// Mengecek apakah user bisa DELETE/HAPUS log
  ///
  /// Rules:
  /// - Ketua: ✅ Bisa hapus semua log tim (isOwner dipaksakan true)
  /// - Anggota: ✅ Hanya bisa hapus log miliknya sendiri (butuh isOwner = true)
  /// - Asisten: ❌ Tidak bisa hapus log (read & update only)
  ///
  /// Parameters:
  /// - [role]: Role user (Ketua/Anggota/Asisten)
  /// - [isOwner]: Apakah user adalah pemilik log yang akan dihapus
  static bool canDelete(String role, {required bool isOwner}) {
    // Special case: Ketua bisa hapus semua log tim
    if (role == 'Ketua') {
      return true;
    }

    // General case: gunakan RBAC standard
    return AccessControlService.canPerform(
      role,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    );
  }

  /// Helper untuk mengecek apakah role adalah admin/ketua
  ///
  /// Use case: Conditional rendering untuk admin-only features
  /// ```dart
  /// if (AccessPolicy.isLeader(userRole)) {
  ///   // Tampilkan menu khusus ketua
  /// }
  /// ```
  static bool isLeader(String role) {
    return AccessControlService.isAdmin(role);
  }

  /// Mendapatkan deskripsi permission untuk role tertentu
  ///
  /// Berguna untuk:
  /// - Halaman profil/settings untuk info user
  /// - Debug permission issues
  /// - Help text di UI
  static String getRoleInfo(String role) {
    return AccessControlService.getRoleDescription(role);
  }

  /// Debug helper: Tampilkan semua permission untuk role
  ///
  /// Example output:
  /// ```
  /// Ketua:
  ///   ✅ Create
  ///   ✅ Read
  ///   ✅ Edit (all)
  ///   ✅ Delete (all)
  /// ```
  static String debugPermissions(String role) {
    final buffer = StringBuffer();
    buffer.writeln('$role:');
    buffer.writeln('  ${canCreate(role) ? "✅" : "❌"} Create');
    buffer.writeln('  ${canRead(role) ? "✅" : "❌"} Read');
    buffer.writeln(
      '  ${canEdit(role, isOwner: false) ? "✅ Edit (all)" : "⚠️  Edit (own only)"}',
    );
    buffer.writeln(
      '  ${canDelete(role, isOwner: false) ? "✅ Delete (all)" : "⚠️  Delete (own only)"}',
    );
    return buffer.toString();
  }
}
