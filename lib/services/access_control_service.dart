import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service untuk Role-Based Access Control (RBAC)
/// Mengatur perizinan akses berdasarkan role pengguna dan kepemilikan data
class AccessControlService {
  // Mengambil roles dari .env di root
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

  // Definisi konstanta aksi
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix perizinan yang tetap fleksibel
  // Ketua: Full access (CRUD)
  // Anggota: Hanya bisa create dan read (update/delete hanya untuk data sendiri)
  // Asisten: Read dan update saja
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead],
    'Asisten': [actionRead, actionUpdate],
  };

  /// Mengecek apakah role tertentu dapat melakukan aksi tertentu
  ///
  /// Parameters:
  /// - [role]: Role pengguna (Ketua, Anggota, Asisten)
  /// - [action]: Aksi yang ingin dilakukan (create, read, update, delete)
  /// - [isOwner]: Apakah pengguna adalah pemilik data (untuk owner-based access)
  ///
  /// Returns: true jika diizinkan, false jika tidak
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final permissions = _rolePermissions[role] ?? [];
    bool hasBasicPermission = permissions.contains(action);

    // Logic khusus kepemilikan data (Owner-based RBAC)
    // Anggota bisa update/delete hanya jika dia pemilik data
    if (role == 'Anggota' &&
        (action == actionUpdate || action == actionDelete)) {
      return isOwner;
    }

    return hasBasicPermission;
  }

  /// Helper untuk mengecek apakah role adalah admin/ketua
  static bool isAdmin(String role) {
    return role == 'Ketua';
  }

  /// Helper untuk mendapatkan deskripsi perizinan role
  static String getRoleDescription(String role) {
    switch (role) {
      case 'Ketua':
        return 'Full Access - Bisa melakukan semua operasi';
      case 'Anggota':
        return 'Limited Access - Bisa edit/hapus data sendiri';
      case 'Asisten':
        return 'Read & Update Only - Tidak bisa hapus';
      default:
        return 'Unknown Role';
    }
  }
}
