enum CounterAction { increment, decrement, reset, changeStep }

class CounterActivity {
  final CounterAction action;
  final int? value;
  final DateTime timestamp;

  CounterActivity({required this.action, this.value, required this.timestamp});
}

class CounterController {
  int _count = 0;
  int _langkah = 1;
  int _limit = 5;
  List<CounterActivity> _riwayat = [];

  int get value => _count;
  int get step => _langkah;
  int get limit => _limit;
  List<CounterActivity> get riwayat => _riwayat;

  void increment() {
    _count += _langkah;
    _addAktivitas(CounterAction.increment, _langkah);
  }

  void decrement() {
    if (_count > 0 && _count >= _langkah) {
      _count -= _langkah;
      _addAktivitas(CounterAction.decrement, _langkah);
    }
  }

  void newStep(int step) {
    if (step > 0 && step <= 100) {
      _langkah = step;
      _addAktivitas(CounterAction.changeStep, step);
    }
  }

  void reset() {
    _count = 0;
    _addAktivitas(CounterAction.reset, 0);
  }

  void _addAktivitas(CounterAction action, int? value) {
    _riwayat.insert(
      0,
      CounterActivity(action: action, value: value, timestamp: DateTime.now()),
    );
  }

  List<CounterActivity> ambilRiwayat() {
    return _riwayat.take(limit).toList();
  }
}
