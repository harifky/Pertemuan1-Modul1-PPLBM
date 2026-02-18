import 'package:flutter/material.dart';
import 'package:logbook_app_060/features/logbook/counter_controller.dart';
import 'package:logbook_app_060/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late final CounterController _controller;
  int _stepPreview = 1;

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

    return "$greeting, ${widget.username}";
  }

  @override
  void initState() {
    super.initState();
    _controller = CounterController(username: widget.username);
    _loadState();
  }

  Future<void> _loadState() async {
    await _controller.loadState();
    if (!mounted) {
      return;
    }
    setState(() {
      _stepPreview = _controller.step;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text(
            "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
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

  Future<void> _handleReset() async {
    if (_controller.value == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Angka sudah 0")),
      );
      return;
    }

    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Reset"),
          content: const Text("Reset angka ke 0?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Reset",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    await _controller.reset();
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Angka berhasil direset")),
    );
  }

  Future<void> _handleDecrement() async {
    if (_controller.value == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Angka sudah 0")),
      );
      return;
    }

    await _controller.decrement();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _updateStep() async {
    await _controller.newStep(_stepPreview);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Color _entryColor(String entry) {
    if (entry.contains("menambah")) {
      return Colors.green;
    }
    if (entry.contains("mengurangi")) {
      return Colors.red;
    }
    if (entry.contains("mereset")) {
      return Colors.amber;
    }

    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleReset,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _welcomeMessage(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text("Angka Terakhir:"),
            const SizedBox(height: 8),
            Text(
              '${_controller.value}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Langkah: $_stepPreview",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: _stepPreview.toDouble(),
              label: _stepPreview.toString(),
              onChanged: (value) {
                setState(() {
                  _stepPreview = value.round();
                });
              },
              onChangeEnd: (_) => _updateStep(),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Riwayat Aktivitas",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _controller.logEntries.isEmpty
                  ? const Center(child: Text("Belum ada aktivitas"))
                  : ListView.separated(
                      itemCount: _controller.logEntries
                          .take(_controller.limit)
                          .length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = _controller.logEntries
                            .take(_controller.limit)
                            .toList()[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            entry,
                            style: TextStyle(color: _entryColor(entry)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'decrement',
            onPressed: _handleDecrement,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'increment',
            onPressed: () async {
              await _controller.increment();
              if (!mounted) {
                return;
              }
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
