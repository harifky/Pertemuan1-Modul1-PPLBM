import 'package:flutter/material.dart';
import 'package:logbook_app_060/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_060/features/widgets/widgets.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:logbook_app_060/services/user_context_service.dart';
import 'package:logbook_app_060/services/connectivity_service.dart';
import 'package:logbook_app_060/helpers/log_helper.dart';
import 'log_controller.dart';
import 'log_editor_page.dart'; // NEW: Full-page editor with Markdown support
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
  late final ConnectivityService _connectivityService;

  final TextEditingController _searchController = TextEditingController();

  late final ValueNotifier<String> _searchNotifier;
  late final ValueNotifier<int> _refreshTrigger;
  late final ValueNotifier<String?> _connectionWarningNotifier;

  // RBAC: Store current user context for permission checking
  String _currentUserRole = 'Anggota';
  String _currentUserId = 'unknown_user';
  String _currentTeamId = 'no_team';

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    _connectivityService = ConnectivityService();
    _searchNotifier = ValueNotifier<String>('');
    _refreshTrigger = ValueNotifier<int>(0);
    _connectionWarningNotifier = ValueNotifier<String?>(null);

    _searchController.addListener(() {
      _searchNotifier.value = _searchController.text;
    });

    _connectivityService.startListening(
      onReconnect: () async {
        await _loadLogsWithFallback(showFeedback: true);
        _refreshTrigger.value++;
      },
    );

    // Load user context for RBAC
    _loadUserContext();
  }

  /// Load current user role and ID for permission checking
  Future<void> _loadUserContext() async {
    final role = await UserContextService.getUserRole();
    final userId = await UserContextService.getUserId();
    final teamId = await UserContextService.getTeamId();

    setState(() {
      _currentUserRole = role;
      _currentUserId = userId;
      _currentTeamId = teamId;
    });

    await LogHelper.writeLog(
      "👤 User context loaded: Role=$role, UserID=$userId, TeamID=$teamId",
      source: "log_view.dart",
      level: 3,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchNotifier.dispose();
    _refreshTrigger.dispose();
    _connectionWarningNotifier.dispose();
    _connectivityService.stopListening();
    super.dispose();
  }

  Future<List<LogModel>> _loadLogsWithFallback({
    bool showFeedback = false,
  }) async {
    try {
      final teamId = await UserContextService.getTeamId();
      await _controller.loadLogs(teamId);
      _connectionWarningNotifier.value = null;

      if (showFeedback && mounted) {
        CustomSnackbar.success(context, "Data berhasil diperbarui");
      }

      return _controller.logsNotifier.value;
    } catch (e) {
      _connectionWarningNotifier.value = "Offline Mode: Menggunakan data lokal";

      if (showFeedback && mounted) {
        CustomSnackbar.warning(context, "Mode offline: Menggunakan data lokal");
      }

      await LogHelper.writeLog(
        "📴 Loading in offline mode: $e",
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

  List<LogModel> _applyVisibilityFilter(List<LogModel> logs) {
    return _controller.filterVisibleLogs(logs, _currentUserId, _currentTeamId);
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
              onPressed: () async {
                await UserContextService.clearUserContext();
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
    final ownLogs = _controller.logsNotifier.value
        .where((log) => log.authorId == _currentUserId)
        .toList();

    if (ownLogs.isEmpty) {
      CustomSnackbar.warning(
        context,
        "Tidak ada catatan milik Anda yang bisa dihapus",
      );
      return;
    }

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus Semua"),
          content: Text(
            "Hapus semua catatan milik Anda (${ownLogs.length} item)? Catatan pengguna lain tidak akan terhapus.",
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

    var deletedCount = 0;
    for (final log in ownLogs) {
      if (log.id == null) {
        continue;
      }

      try {
        await _controller.removeLogByObjectId(
          mongo.ObjectId.fromHexString(log.id!),
          log.title,
        );
        deletedCount++;
      } catch (_) {
        // Keep processing remaining owned logs even if one deletion fails.
      }
    }

    if (!mounted) {
      return;
    }

    // Refresh FutureBuilder
    _refreshTrigger.value++;

    if (deletedCount == 0) {
      CustomSnackbar.error(context, "Gagal menghapus catatan milik Anda");
    } else {
      CustomSnackbar.warning(
        context,
        "$deletedCount catatan milik Anda berhasil dihapus",
      );
    }

    await LogHelper.writeLog(
      "✅ Clear owned logs completed: deleted=$deletedCount, FutureBuilder refreshed",
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

  Future<void> _handleDeleteLog(
    LogModel log, {
    bool askConfirmation = true,
  }) async {
    if (log.authorId != _currentUserId) {
      CustomSnackbar.error(
        context,
        "Owner only: Anda tidak bisa menghapus catatan ini",
      );
      return;
    }

    if (askConfirmation) {
      final bool shouldDelete = await _showDeleteConfirmationDialog(log.title);
      if (!shouldDelete) {
        return;
      }
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
      await _controller.removeLogByObjectId(
        mongo.ObjectId.fromHexString(log.id!),
        log.title,
      );

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

  /// Navigate to full-page editor for adding new log
  void _navigateToAddLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(controller: _controller),
      ),
    ).then((_) {
      // Refresh data after returning from editor
      _refreshTrigger.value++;
    });
  }

  /// Navigate to full-page editor for editing existing log
  void _navigateToEditLog(int index, LogModel log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LogEditorPage(log: log, index: index, controller: _controller),
      ),
    ).then((_) {
      // Refresh data after returning from editor
      _refreshTrigger.value++;
    });
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
              final allLogs = snapshot.data ?? [];
              final logs = _applyVisibilityFilter(allLogs);

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
                              title: "Belum ada aktivitas hari ini?",
                              subtitle:
                                  "Mulai catat kemajuan proyek Anda!\nTekan tombol + di bawah untuk membuat catatan pertama.",
                              icon: Icons.rocket_launch_outlined,
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
                              final isOwner =
                                  log.authorId == _currentUserId &&
                                  !log.isDeleted;
                              return Dismissible(
                                key: ValueKey(
                                  '${log.title}-${log.date}-${log.id ?? "temp"}',
                                ),
                                direction: isOwner
                                    ? DismissDirection.endToStart
                                    : DismissDirection.none,
                                confirmDismiss: (_) async {
                                  await _handleDeleteLog(
                                    log,
                                    askConfirmation: true,
                                  );
                                  return false;
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
                                  currentUserRole: _currentUserRole,
                                  currentUserId: _currentUserId,
                                  onEdit: () =>
                                      _navigateToEditLog(originalIndex, log),
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
        onPressed: _navigateToAddLog,
        tooltip: "Tambah Catatan",
        child: const Icon(Icons.add),
      ),
    );
  }
}
