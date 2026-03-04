import 'package:flutter/material.dart';
import 'package:logbook_app_060/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_060/features/widgets/widgets.dart';
import 'package:logbook_app_060/services/mongo_service.dart';
import 'package:logbook_app_060/helpers/log_helper.dart';
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
  late final ValueNotifier<int> _refreshTrigger;
  late final ValueNotifier<String?> _connectionWarningNotifier;

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username);
    _searchNotifier = ValueNotifier<String>('');
    _selectedCategoryNotifier = ValueNotifier<LogCategory>(LogCategory.pribadi);
    _refreshTrigger = ValueNotifier<int>(0);
    _connectionWarningNotifier = ValueNotifier<String?>(null);

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
    _refreshTrigger.dispose();
    _connectionWarningNotifier.dispose();
    super.dispose();
  }

  Future<List<LogModel>> _loadLogsWithFallback({
    bool showFeedback = false,
  }) async {
    try {
      final cloudLogs = await MongoService().getLogs();
      _connectionWarningNotifier.value = null;

      if (showFeedback && mounted) {
        CustomSnackbar.success(context, "Data berhasil diperbarui dari cloud");
      }

      return cloudLogs;
    } on MongoConnectionException catch (e) {
      await _controller.loadFromDisk();
      _connectionWarningNotifier.value = e.message;

      if (showFeedback && mounted) {
        CustomSnackbar.warning(context, e.message);
      }

      return _controller.logsNotifier.value;
    } catch (e) {
      await _controller.loadFromDisk();
      _connectionWarningNotifier.value =
          "Offline Mode Warning: Sinkronisasi cloud gagal. Menampilkan data lokal.";

      if (showFeedback && mounted) {
        CustomSnackbar.warning(
          context,
          "Sinkronisasi cloud gagal. Menampilkan data lokal.",
        );
      }

      await LogHelper.writeLog(
        "⚠️  Cloud fetch failed, fallback to local cache: $e",
        source: "log_view.dart",
        level: 2,
      );

      return _controller.logsNotifier.value;
    }
  }

  Future<void> _handlePullToRefresh() async {
    await _loadLogsWithFallback(showFeedback: true);
    _refreshTrigger.value++;
  }

  Widget _buildConnectionWarningBanner(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange[900],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filters logs by search query
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

    // Refresh FutureBuilder
    _refreshTrigger.value++;

    CustomSnackbar.warning(context, "Semua catatan berhasil dihapus");

    await LogHelper.writeLog(
      "✅ All logs cleared successfully, FutureBuilder refreshed",
      source: "log_view.dart",
      level: 3,
    );
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
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    return shouldDelete == true;
  }

  Future<void> _handleDeleteLog(LogModel log) async {
    final bool shouldDelete = await _showDeleteConfirmationDialog(log.title);
    if (!shouldDelete) {
      return;
    }

    // Check if log has ObjectId from cloud
    if (log.id == null) {
      CustomSnackbar.error(
        context,
        "Cannot delete: Log not synced to cloud yet",
      );
      return;
    }

    try {
      // Delete directly by ObjectId (safer for FutureBuilder pattern)
      await _controller.removeLogByObjectId(log.id!, log.title);

      // Refresh FutureBuilder
      _refreshTrigger.value++;

      if (!mounted) {
        return;
      }

      CustomSnackbar.error(context, "Catatan berhasil dihapus");

      await LogHelper.writeLog(
        "✅ Log deleted successfully, FutureBuilder refreshed",
        source: "log_view.dart",
        level: 3,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      CustomSnackbar.error(context, "Gagal menghapus catatan: $e");

      await LogHelper.writeLog(
        "❌ Error deleting log: $e",
        source: "log_view.dart",
        level: 1,
      );
    }
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
            onPressed: () async {
              if (_titleController.text.isNotEmpty &&
                  _contentController.text.isNotEmpty) {
                try {
                  // Use async method for Cloud integration
                  await _controller.addLogAsync(
                    _titleController.text,
                    _contentController.text,
                    category: _selectedCategoryNotifier.value,
                  );

                  // Refresh FutureBuilder
                  _refreshTrigger.value++;

                  _titleController.clear();
                  _contentController.clear();

                  if (!mounted) return;
                  Navigator.pop(context);

                  CustomSnackbar.success(
                    context,
                    "Catatan berhasil ditambahkan",
                  );

                  await LogHelper.writeLog(
                    "✅ Log added successfully, FutureBuilder refreshed",
                    source: "log_view.dart",
                    level: 3,
                  );
                } catch (e) {
                  if (!mounted) return;
                  CustomSnackbar.error(
                    context,
                    "Gagal menambahkan catatan: $e",
                  );

                  await LogHelper.writeLog(
                    "❌ Error adding log in dialog: $e",
                    source: "log_view.dart",
                    level: 1,
                  );
                }
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
            onPressed: () async {
              try {
                // Use async method for Cloud integration
                await _controller.updateLogAsync(
                  index,
                  _titleController.text,
                  _contentController.text,
                  category: _selectedCategoryNotifier.value,
                );

                // Refresh FutureBuilder
                _refreshTrigger.value++;

                if (!mounted) return;
                Navigator.pop(context);
                CustomSnackbar.info(context, "Catatan berhasil diperbarui");

                await LogHelper.writeLog(
                  "✅ Log updated successfully, FutureBuilder refreshed",
                  source: "log_view.dart",
                  level: 3,
                );
              } catch (e) {
                if (!mounted) return;
                CustomSnackbar.error(context, "Gagal memperbarui catatan: $e");

                await LogHelper.writeLog(
                  "❌ Error updating log in dialog: $e",
                  source: "log_view.dart",
                  level: 1,
                );
              }
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
        titleWidget: ValueListenableBuilder<String?>(
          valueListenable: _connectionWarningNotifier,
          builder: (context, warningMessage, _) {
            final isOffline = warningMessage != null;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    "Logbook: ${toTitleCase(widget.username)}",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOffline) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      "Data lokal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
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
      body: ValueListenableBuilder<int>(
        valueListenable: _refreshTrigger,
        builder: (context, _, _) {
          // FutureBuilder with cloud integration and loading states
          return FutureBuilder<List<LogModel>>(
            future: _loadLogsWithFallback(),
            builder: (context, snapshot) {
              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blue[400]),
                      const SizedBox(height: 16),
                      Text(
                        "Loading logs from cloud...",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              // Handle error state
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Gagal mengambil data",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Error: ${snapshot.error}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Trigger refresh by updating the notifier
                            _refreshTrigger.value++;
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Coba Lagi"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Handle empty data
              List<LogModel> logs = snapshot.data ?? [];
              if (logs.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _handlePullToRefresh,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _connectionWarningNotifier,
                    builder: (context, warningMessage, _) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (warningMessage != null)
                            _buildConnectionWarningBanner(warningMessage),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: EmptyStateWidget(
                              title: "Data Kosong",
                              subtitle: _welcomeMessage(),
                              icon: Icons.note_outlined,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }

              // Handle data state with search filter
              return ValueListenableBuilder<String>(
                valueListenable: _searchNotifier,
                builder: (context, searchQuery, _) {
                  final filteredLogs = _filterLogs(logs, searchQuery);

                  return RefreshIndicator(
                    onRefresh: _handlePullToRefresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        ValueListenableBuilder<String?>(
                          valueListenable: _connectionWarningNotifier,
                          builder: (context, warningMessage, _) {
                            if (warningMessage == null) {
                              return const SliverToBoxAdapter(
                                child: SizedBox(),
                              );
                            }

                            return SliverToBoxAdapter(
                              child: _buildConnectionWarningBanner(
                                warningMessage,
                              ),
                            );
                          },
                        ),
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
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final log = filteredLogs[index];
                              final originalIndex = logs.indexOf(log);
                              return Dismissible(
                                key: ValueKey(
                                  '${log.title}-${log.date}-${log.category.value}',
                                ),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) =>
                                    _showDeleteConfirmationDialog(log.title),
                                onDismissed: (_) async {
                                  await _handleDeleteLog(log);
                                },
                                background: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
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
                                  onEdit: () =>
                                      _showEditLogDialog(originalIndex, log),
                                  onDelete: () => _handleDeleteLog(log),
                                ),
                              );
                            }, childCount: filteredLogs.length),
                          ),
                      ],
                    ),
                  );
                },
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
