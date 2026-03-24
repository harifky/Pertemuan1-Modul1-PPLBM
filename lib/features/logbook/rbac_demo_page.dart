import 'package:flutter/material.dart';
import 'package:logbook_app_060/services/access_policy.dart';

/// RBAC Demo Page - For testing different role permissions
///
/// Usage: Add this to your app for quick RBAC testing
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (context) => RBACDemoPage(),
/// ));
/// ```
class RBACDemoPage extends StatefulWidget {
  const RBACDemoPage({super.key});

  @override
  State<RBACDemoPage> createState() => _RBACDemoPageState();
}

class _RBACDemoPageState extends State<RBACDemoPage> {
  String _selectedRole = 'Anggota';
  bool _isOwner = true;

  final List<String> _roles = ['Ketua', 'Anggota', 'Asisten'];

  @override
  Widget build(BuildContext context) {
    // Calculate permissions based on selected options
    final canCreate = AccessPolicy.canCreate(_selectedRole);
    final canRead = AccessPolicy.canRead(_selectedRole);
    final canEdit = AccessPolicy.canEdit(_selectedRole, isOwner: _isOwner);
    final canDelete = AccessPolicy.canDelete(_selectedRole, isOwner: _isOwner);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RBAC Permission Tester'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role Selector
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎭 Select Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _roles.map((role) {
                        final isSelected = role == _selectedRole;
                        return ChoiceChip(
                          label: Text(role),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedRole = role;
                              });
                            }
                          },
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AccessPolicy.getRoleInfo(_selectedRole),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Owner Toggle
            Card(
              elevation: 4,
              child: SwitchListTile(
                title: const Text('📝 Is Log Owner?'),
                subtitle: Text(
                  _isOwner
                      ? 'User adalah pemilik log'
                      : 'User bukan pemilik log',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _isOwner,
                onChanged: (value) {
                  setState(() {
                    _isOwner = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ),

            const SizedBox(height: 24),

            // Permission Results
            const Text(
              '🔐 Permission Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildPermissionCard(
              'Create Log',
              canCreate,
              'Buat catatan baru',
              Icons.add_circle,
            ),
            _buildPermissionCard(
              'Read Log',
              canRead,
              'Lihat/baca catatan',
              Icons.visibility,
            ),
            _buildPermissionCard(
              'Edit Log',
              canEdit,
              _isOwner
                  ? 'Edit catatan milik sendiri'
                  : 'Edit catatan orang lain',
              Icons.edit,
            ),
            _buildPermissionCard(
              'Delete Log',
              canDelete,
              _isOwner
                  ? 'Hapus catatan milik sendiri'
                  : 'Hapus catatan orang lain',
              Icons.delete,
            ),

            const SizedBox(height: 24),

            // Debug Output
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐛 Debug Output',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AccessPolicy.debugPermissions(_selectedRole),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Code Example
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.code, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Implementation Example',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        '''// Di UI Widget:
final canEdit = AccessPolicy.canEdit(
  '$_selectedRole',
  isOwner: $_isOwner,
);

if (canEdit) {
  // Tampilkan tombol Edit
  IconButton(
    icon: Icon(Icons.edit),
    onPressed: () => editLog(),
  );
} else {
  // Tombol disabled
  Icon(Icons.edit_off, 
    color: Colors.grey,
  );
}''',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    String title,
    bool allowed,
    String description,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: allowed ? Colors.green[50] : Colors.red[50],
      child: ListTile(
        leading: Icon(
          icon,
          color: allowed ? Colors.green[700] : Colors.red[700],
          size: 32,
        ),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: allowed ? Colors.green[700] : Colors.red[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                allowed ? 'ALLOWED' : 'DENIED',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
        trailing: Icon(
          allowed ? Icons.check_circle : Icons.cancel,
          color: allowed ? Colors.green[700] : Colors.red[700],
          size: 28,
        ),
      ),
    );
  }
}
