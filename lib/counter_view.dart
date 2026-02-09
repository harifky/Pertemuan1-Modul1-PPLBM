import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: Versi SRP")),
      body: Column(
        children: [
          // Bagian Counter
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Total Hitungan:"),
                Text(
                  '${_controller.value}',
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 20),
                const Text("Masukkan nilai Step:"),
                TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final step = int.tryParse(value);
                      if (step != null && step > 0) {
                        _controller.newStep(step);
                      }
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ex. 1, 2, 3, ...',
                  ),
                ),
                Text(
                  'Nilai step : ${_controller.step}',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bagian Riwayat Aktivitas
          Text("Riwayat Aktivitas: ${_controller.limit} aktivitas terakhir"),
          Expanded(
            child: ListView.builder(
              itemCount: _controller.ambilRiwayat().length,
              itemBuilder: (context, index) {
                List<String> riwayat = _controller.ambilRiwayat();
                return ListTile(title: Text(riwayat[index]));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'dec',
            onPressed: () => setState(() => _controller.decrement()),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: () => setState(() => _controller.reset()),
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'inc',
            onPressed: () => setState(() => _controller.increment()),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// Expanded - Memberi space kosong untuk ListView agar bisa scroll
// ListView.builder - Membuat list yang bisa di-scroll secara dinamis
// itemCount - Jumlah item yang ditampilkan (dari ambilRiwayat())
// itemBuilder - Fungsi yang membuat setiap item
// ListTile - Widget bawaan untuk menampilkan text dengan style otomatis
