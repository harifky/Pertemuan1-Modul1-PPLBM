import 'package:flutter/material.dart';
import 'package:logbook_app_060/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_060/features/widgets/widgets.dart';
import 'log_controller.dart';
import '../models/log_model.dart';

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .toLowerCase()
      .split(' ')
      .map(
        (word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
      )
      .join(' ');
}

class LogView extends StatefulWidget {
  final String username;

  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _welcomeMessage() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour >= 6 && hour <= 11) {
      greeting = "Selamat Pagi";
    } else if (hour >= 12 && hour <= 15) {
      greeting = "Selamat Siang";
    } else if (hour >= 16 && hour <= 18) {
      greeting = "Selamat Sore";
    } else {
      greeting = "Selamat Malam";
    }

    return "$greeting, ${toTitleCase(widget.username)}";
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text(
            "Apakah Anda yakin ingin keluar? Data yang belum disimpan mungkin akan hilang.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingView(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "Ya, Keluar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleClearAllLogs() async {
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus Semua"),
          content: const Text(
            "Hapus semua catatan? Tindakan ini tidak bisa dibatalkan.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Hapus Semua",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    while (_controller.logsNotifier.value.isNotEmpty) {
      _controller.removeLog(0);
    }

    if (!mounted) {
      return;
    }

    CustomSnackbar.warning(context, "Semua catatan berhasil dihapus");
  }

  void _showAddLogDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "Judul"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(hintText: "Deskripsi"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty &&
                  _contentController.text.isNotEmpty) {
                _controller.addLog(
                  _titleController.text,
                  _contentController.text,
                );

                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);

                CustomSnackbar.success(context, "Catatan berhasil ditambahkan");
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController),
            const SizedBox(height: 10),
            TextField(controller: _contentController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.updateLog(
                index,
                _titleController.text,
                _contentController.text,
              );

              Navigator.pop(context);
              CustomSnackbar.info(context, "Catatan berhasil diperbarui");
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Logbook: ${toTitleCase(widget.username)}",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Hapus Semua",
            onPressed: _handleClearAllLogs,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: _controller.logsNotifier,
        builder: (context, logs, _) {
          if (logs.isEmpty) {
            return EmptyStateWidget(
              title: "Belum ada catatan",
              subtitle: _welcomeMessage(),
              icon: Icons.note_outlined,
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GreetingMessage(
                  message: _welcomeMessage(),
                  secondaryText: "Anda memiliki ${logs.length} catatan",
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final log = logs[index];
                  return LogItemWidget(
                    log: log,
                    index: index,
                    onEdit: () => _showEditLogDialog(index, log),
                    onDelete: () {
                      _controller.removeLog(index);
                      CustomSnackbar.error(context, "Catatan berhasil dihapus");
                    },
                  );
                }, childCount: logs.length),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        tooltip: "Tambah Catatan",
        child: const Icon(Icons.add),
      ),
    );
  }
}
