import 'package:shared_preferences/shared_preferences.dart';

enum CounterAction { increment, decrement, reset, changeStep }

class CounterActivity {
  final CounterAction action;
  final int? value;
  final DateTime timestamp;

  CounterActivity({required this.action, this.value, required this.timestamp});
}

class CounterController {
  CounterController({required String username}) : _username = username;

  static const String _keyLastCounter = 'last_counter';
  static const String _keyHistory = 'counter_history';

  final String _username;
  int _count = 0;
  int _langkah = 1;
  int _limit = 5;
  List<CounterActivity> _riwayat = [];
  List<String> _logEntries = [];

  int get value => _count;
  int get step => _langkah;
  int get limit => _limit;
  List<CounterActivity> get riwayat => _riwayat;
  List<String> get logEntries => _logEntries;

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _count = prefs.getInt(_keyLastCounter) ?? 0;
    _logEntries = prefs.getStringList(_keyHistory) ?? [];
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastCounter, _count);
    await prefs.setStringList(_keyHistory, _logEntries);
  }

  Future<void> increment() async {
    _count += _langkah;
    await _addAktivitas(CounterAction.increment, _langkah);
  }

  Future<void> decrement() async {
    if (_count > 0 && _count >= _langkah) {
      _count -= _langkah;
      await _addAktivitas(CounterAction.decrement, _langkah);
    }
  }

  Future<void> newStep(int step) async {
    if (step > 0 && step <= 100) {
      _langkah = step;
      await _addAktivitas(CounterAction.changeStep, step);
    }
  }

  Future<void> reset() async {
    _count = 0;
    await _addAktivitas(CounterAction.reset, 0);
  }

  Future<void> _addAktivitas(CounterAction action, int? value) async {
    final now = DateTime.now();
    _riwayat.insert(
      0,
      CounterActivity(action: action, value: value, timestamp: now),
    );

    _logEntries.insert(0, _buildLogMessage(action, value, now));
    await _persistState();
  }

  String _buildLogMessage(CounterAction action, int? value, DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final clock = "$hh:$mm";

    switch (action) {
      case CounterAction.increment:
        return "User $_username menambah +$value pada jam $clock";
      case CounterAction.decrement:
        return "User $_username mengurangi -$value pada jam $clock";
      case CounterAction.reset:
        return "User $_username mereset ke 0 pada jam $clock";
      case CounterAction.changeStep:
        return "User $_username mengubah langkah ke $value pada jam $clock";
    }
  }

  List<CounterActivity> ambilRiwayat() {
    return _riwayat.take(limit).toList();
  }
}
