import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_060/features/models/log_model.dart';
import 'package:logbook_app_060/features/logbook/log_controller.dart';
import 'package:logbook_app_060/services/user_context_service.dart';
import 'package:logbook_app_060/helpers/log_helper.dart';

/// Full-page editor untuk membuat atau mengedit log dengan Markdown support
/// Features:
/// - Tabbed interface: Editor & Preview
/// - Real-time Markdown rendering
/// - Auto-save with user context (authorId, teamId)
class LogEditorPage extends StatefulWidget {
  final LogModel? log; // Null untuk create baru, filled untuk edit
  final int? index; // Index untuk update operation
  final LogController controller;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isPublic = false;
  bool _isSaving = false;
  String _selectedCategory = 'Software';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _isPublic = widget.log?.isPublic ?? false;
    _selectedCategory = normalizeLogCategory(widget.log?.category);

    // PENTING: Listener agar Pratinjau terupdate otomatis saat user mengetik
    _descController.addListener(() {
      setState(() {}); // Trigger rebuild untuk update preview tab
    });
  }

  /// Menyimpan data log (create baru atau update existing)
  Future<void> _save() async {
    // Validasi input
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deskripsi tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Ambil user context untuk authorId dan teamId
      final userId = await UserContextService.getUserId();
      final teamId = await UserContextService.getTeamId();
      if (widget.log == null) {
        // CREATE NEW LOG

        await widget.controller.addLogAsync(
          _titleController.text.trim(),
          _descController.text.trim(),
          authorId: userId,
          teamId: teamId,
          isPublic: _isPublic,
          category: _selectedCategory,
        );

        await LogHelper.writeLog(
          "✅ New log created: ${_titleController.text}",
          source: "log_editor_page.dart",
          level: 2,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Catatan baru berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // UPDATE EXISTING LOG
        // Privacy sovereignty: owner only
        final isOwner = widget.log!.authorId == userId;
        if (!isOwner) {
          throw Exception(
            'Owner only: Anda hanya bisa mengedit catatan milik Anda sendiri',
          );
        }

        await widget.controller.updateLogAsync(
          widget.index!,
          _titleController.text.trim(),
          _descController.text.trim(),
          isPublic: _isPublic,
          category: _selectedCategory,
        );

        await LogHelper.writeLog(
          "✅ Log updated: ${_titleController.text}",
          source: "log_editor_page.dart",
          level: 2,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Catatan berhasil diperbarui'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
    } catch (e) {
      await LogHelper.writeLog(
        "❌ Error saving log: $e",
        source: "log_editor_page.dart",
        level: 1,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.edit), text: "Editor"),
              Tab(icon: Icon(Icons.preview), text: "Pratinjau"),
            ],
          ),
          actions: [
            // Save button dengan loading indicator
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: "Simpan",
                onPressed: _save,
              ),
          ],
        ),
        body: TabBarView(
          children: [
            // TAB 1: EDITOR
            _buildEditorTab(),

            // TAB 2: MARKDOWN PREVIEW
            _buildPreviewTab(),
          ],
        ),
      ),
    );
  }

  /// Tab Editor - Area untuk menulis konten
  Widget _buildEditorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Input Judul
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Judul",
              hintText: "Masukkan judul catatan...",
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Markdown Guide
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tips: Gunakan Markdown untuk format teks (# Heading, **bold**, *italic*, - list)',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Input Deskripsi (Markdown Editor)
          Expanded(
            child: TextField(
              controller: _descController,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText:
                    "Tulis laporan dengan format Markdown...\n\n"
                    "Contoh:\n"
                    "# Judul Besar\n"
                    "## Sub Judul\n"
                    "**Teks Tebal**\n"
                    "*Teks Miring*\n"
                    "- Item 1\n"
                    "- Item 2",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),

          // Dropdown Kategori
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Kategori',
              prefixIcon: Icon(
                _categoryIcon(_selectedCategory),
                color: _categoryColor(_selectedCategory),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: kLogCategories.map((cat) {
              return DropdownMenuItem<String>(
                value: cat,
                child: Row(
                  children: [
                    Icon(
                      _categoryIcon(cat),
                      color: _categoryColor(cat),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(cat),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
          const SizedBox(height: 8),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Publik untuk Tim'),
            subtitle: Text(
              _isPublic
                  ? 'Semua anggota tim bisa melihat catatan ini'
                  : 'Private: hanya pemilik yang bisa melihat',
            ),
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (normalizeLogCategory(category)) {
      case 'Mechanical':
        return Colors.green[700]!;
      case 'Electronic':
        return Colors.blue[700]!;
      case 'Software':
      default:
        return Colors.deepPurple[700]!;
    }
  }

  IconData _categoryIcon(String category) {
    switch (normalizeLogCategory(category)) {
      case 'Mechanical':
        return Icons.settings;
      case 'Electronic':
        return Icons.memory;
      case 'Software':
      default:
        return Icons.code;
    }
  }

  /// Tab Preview - Tampilan hasil render Markdown
  Widget _buildPreviewTab() {
    // Jika belum ada konten, tampilkan placeholder
    if (_descController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.preview, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Pratinjau akan muncul di sini',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai menulis di tab Editor',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Render Markdown content
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan judul
          if (_titleController.text.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
              ),
              child: Text(
                _titleController.text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Markdown content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data: _descController.text,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  p: const TextStyle(fontSize: 16, height: 1.5),
                  code: TextStyle(
                    backgroundColor: Colors.grey[200],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
