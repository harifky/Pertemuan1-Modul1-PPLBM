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
  final TextEditingController _searchController = TextEditingController();

  late final ValueNotifier<String> _searchNotifier;
  late final ValueNotifier<LogCategory> _selectedCategoryNotifier;

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username);
    _searchNotifier = ValueNotifier<String>('');
    _selectedCategoryNotifier = ValueNotifier<LogCategory>(LogCategory.pribadi);
    _searchController.addListener(() {
      _searchNotifier.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    _searchNotifier.dispose();
    _selectedCategoryNotifier.dispose();
    super.dispose();
  }

  /// Filter logs berdasarkan search query
  List<LogModel> _filterLogs(List<LogModel> logs, String query) {
    if (query.isEmpty) {
      return logs;
    }
    return logs
        .where(
          (log) =>
              log.title.toLowerCase().contains(query.toLowerCase()) ||
              log.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
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

  Future<bool> _showDeleteConfirmationDialog(String logTitle) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Apakah Anda yakin ingin menghapus catatan ini?"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, color: Colors.blue[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        logTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tindakan ini tidak bisa dibatalkan.",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Hapus",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    return shouldDelete == true;
  }

  Future<void> _handleDeleteLog(int index, String logTitle) async {
    final bool shouldDelete = await _showDeleteConfirmationDialog(logTitle);
    if (!shouldDelete) {
      return;
    }

    _controller.removeLog(index);

    if (!mounted) {
      return;
    }

    CustomSnackbar.error(context, "Catatan berhasil dihapus");
  }

  void _showAddLogDialog() {
    _selectedCategoryNotifier.value = LogCategory.pribadi;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Catatan"),
        content: ValueListenableBuilder<LogCategory>(
          valueListenable: _selectedCategoryNotifier,
          builder: (context, selectedCategory, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "Judul",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: "Deskripsi",
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 15),
                // Category Dropdown
                DropdownButtonFormField<LogCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Kategori",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: LogCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: category == LogCategory.pekerjaan
                                  ? Colors.blue
                                  : category == LogCategory.pribadi
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(category.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (category) {
                    if (category != null) {
                      _selectedCategoryNotifier.value = category;
                    }
                  },
                ),
              ],
            );
          },
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
                  category: _selectedCategoryNotifier.value,
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
    _selectedCategoryNotifier.value = log.category;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: ValueListenableBuilder<LogCategory>(
          valueListenable: _selectedCategoryNotifier,
          builder: (context, selectedCategory, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "Judul",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: "Deskripsi",
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 15),
                // Category Dropdown
                DropdownButtonFormField<LogCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Kategori",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: LogCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: category == LogCategory.pekerjaan
                                  ? Colors.blue
                                  : category == LogCategory.pribadi
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(category.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (category) {
                    if (category != null) {
                      _selectedCategoryNotifier.value = category;
                    }
                  },
                ),
              ],
            );
          },
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
                category: _selectedCategoryNotifier.value,
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

          return ValueListenableBuilder<String>(
            valueListenable: _searchNotifier,
            builder: (context, searchQuery, _) {
              final filteredLogs = _filterLogs(logs, searchQuery);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: GreetingMessage(
                      message: _welcomeMessage(),
                      secondaryText: searchQuery.isEmpty
                          ? "Anda memiliki ${logs.length} catatan"
                          : "Ditemukan ${filteredLogs.length} dari ${logs.length} catatan",
                    ),
                  ),
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Cari catatan berdasarkan judul...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                  ),
                  // Empty search result
                  if (filteredLogs.isEmpty && searchQuery.isNotEmpty)
                    SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        title: "Tidak ada hasil",
                        subtitle:
                            'Catatan dengan judul "$searchQuery" tidak ditemukan',
                        icon: Icons.search_off,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final log = filteredLogs[index];
                        final originalIndex = logs.indexOf(log);
                        return Dismissible(
                          key: ValueKey(
                            '${log.title}-${log.date}-${log.category.value}',
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) =>
                              _showDeleteConfirmationDialog(log.title),
                          onDismissed: (_) {
                            _controller.removeLog(originalIndex);

                            if (!mounted) {
                              return;
                            }

                            CustomSnackbar.error(
                              context,
                              "Catatan berhasil dihapus",
                            );
                          },
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Icon(Icons.delete, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "Hapus",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: LogItemWidget(
                            log: log,
                            index: originalIndex,
                            onEdit: () => _showEditLogDialog(originalIndex, log),
                            onDelete: () =>
                                _handleDeleteLog(originalIndex, log.title),
                          ),
                        );
                      }, childCount: filteredLogs.length),
                    ),
                ],
              );
            },
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
