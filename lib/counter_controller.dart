class CounterController {
  int _count = 0;
  int _langkah = 1;
  int _limit = 5;
  List<String> _riwayat = [];

  int get value => _count;
  int get step => _langkah;
  int get limit => _limit;
  List<String> get riwayat => _riwayat;

  void increment() {
    _count += _langkah; // _count = _count + _langkah;
    _addAktivitas('User menambah nilai sebesar $_langkah');
  }

  void decrement() {
    if (_count > 0 && _count >= _langkah) {
      _count -= _langkah; // _count = _count - _langkah;
      _addAktivitas('User mengurangi nilai sebesar $_langkah');
    }
  }

  void newStep(int step) {
    if (step > 0 && step <= 100) {
      _langkah = step;
      _addAktivitas('User mengubah step menjadi $step');
    }
  }

  void reset() {
    _count = 0;
    _addAktivitas('User mereset nilai ke 0');
  }

  void _addAktivitas(String aktivitas) {
    String timestamp = _ambilJamSekarang();
    String seluruhAktivias = '$aktivitas pada jam $timestamp';
    _riwayat.insert(0, seluruhAktivias);
  }

  String _ambilJamSekarang() {
    DateTime now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  List<String> ambilRiwayat() {
    return _riwayat.take(limit).toList();
  }
}
