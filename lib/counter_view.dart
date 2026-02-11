import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Reset'),
        content: const Text('Yakin mau mereset counter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _controller.reset());
              Navigator.pop(context);
              _showSnackBar('Counter berhasil di-reset');
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riwayat = _controller.ambilRiwayat();

    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: Versi SRP")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Counter
          Column(
            children: [
              const Text("Total Hitungan:"),
              Text(
                '${_controller.value}',
                style: const TextStyle(fontSize: 40),
              ),

              const SizedBox(height: 10),

              const Text("Pilih nilai Step:"),
              Slider(
                min: 1,
                max: 10,
                divisions: 9,
                value: _controller.step.toDouble(),
                label: _controller.step.toString(),
                onChanged: (value) {
                  setState(() {
                    _controller.newStep(value.toInt());
                  });
                  _showSnackBar('Step diubah menjadi ${value.toInt()}');
                },
              ),

              Text(
                'Nilai step : ${_controller.step}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Riwayat
          Text("Riwayat Aktivitas (${riwayat.length})"),

          Expanded(
            child: ListView.builder(
              itemCount: riwayat.length,
              itemBuilder: (context, index) {
                final activity = riwayat[index];

                Color color;
                String text;

                switch (activity.action) {
                  case CounterAction.increment:
                    color = Colors.green;
                    text = "User menambah ${activity.value}";
                    break;

                  case CounterAction.decrement:
                    color = Colors.red;
                    text = "User mengurangi ${activity.value}";
                    break;

                  case CounterAction.reset:
                    color = Colors.orange;
                    text = "User mereset nilai";
                    break;

                  case CounterAction.changeStep:
                    color = Colors.blue;
                    text = "User mengubah step menjadi ${activity.value}";
                    break;
                }

                // FORMAT JAM
                String jam =
                    "${activity.timestamp.hour.toString().padLeft(2, '0')}:"
                    "${activity.timestamp.minute.toString().padLeft(2, '0')}";

                text += " pada jam $jam";

                return ListTile(
                  title: Text(text, style: TextStyle(color: color)),
                );
              },
            ),
          ),
        ],
      ),

      // FAB tetap sama
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'dec',
            onPressed: () {
              setState(() => _controller.decrement());
              _showSnackBar('Counter dikurangi ${_controller.step}');
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: _confirmReset,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'inc',
            onPressed: () {
              setState(() => _controller.increment());
              _showSnackBar('Counter ditambah ${_controller.step}');
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
