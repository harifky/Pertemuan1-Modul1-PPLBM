import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  late final String _storageKey;
  final String username;

  LogController(this.username) {
    // Buat unique key per user
    _storageKey = 'logs_$username';
    print('🔑 [INIT] LogController untuk user: $username');
    print('   Storage key: $_storageKey');
    loadFromDisk();
  }

  void addLog(
    String title,
    String desc, {
    LogCategory category = LogCategory.pribadi,
  }) {
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );

    print('📝 [STEP 1] LogModel Object dibuat:');
    print('   Title: ${newLog.title}');
    print('   Desc: ${newLog.description}');
    print('   Date: ${newLog.date}');
    print('   Category: ${newLog.category.displayName}');

    logsNotifier.value = [...logsNotifier.value, newLog];
    saveToDisk();
  }

  void updateLog(
    int index,
    String title,
    String desc, {
    LogCategory category = LogCategory.pribadi,
  }) {
    final updatedLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );

    print('\n✏️  [UPDATE] Mengubah log di index $index:');
    print('   Baru: $title | $desc | ${category.displayName}');

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = updatedLog;

    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  void removeLog(int index) {
    print('\n🗑️  [DELETE] Menghapus log di index $index:');
    print('   Dihapus: ${logsNotifier.value[index].title}');

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeAt(index);

    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();

    print('\n📦 [STEP 2] Convert Object → Map (User: $username):');
    final mapList = logsNotifier.value.map((e) => e.toMap()).toList();
    for (var i = 0; i < mapList.length; i++) {
      print('   Log[$i]: ${mapList[i]}');
    }

    print('\n🔗 [STEP 3] Encode Map → JSON String:');
    final encodedData = jsonEncode(mapList);
    print('   JSON: $encodedData');

    print('\n💾 [STEP 4] Simpan ke SharedPreferences:');
    await prefs.setString(_storageKey, encodedData);
    print('   ✅ Berhasil disimpan dengan key: $_storageKey');
    print('   👤 User: $username');
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    print('\n🔙 [LOAD PROCESS] Membaca data dari Storage:');
    print('   Storage key: $_storageKey');
    print('   👤 User: $username');
    if (data != null) {
      print('📄 [STEP 5] Ambil JSON String dari SharedPreferences:');
      print('   JSON: $data');

      print('\n🔗 [STEP 6] Decode JSON String → List<Map>:');
      final List decoded = jsonDecode(data);
      print('   Total items: ${decoded.length}');
      for (var i = 0; i < decoded.length; i++) {
        print('   Item[$i]: ${decoded[i]}');
      }

      print('\n📝 [STEP 7] Convert Map → LogModel Object:');
      final logs = decoded.map((e) => LogModel.fromMap(e)).toList();
      for (var i = 0; i < logs.length; i++) {
        print('   Object[$i]: ${logs[i].title} | ${logs[i].description}');
      }

      logsNotifier.value = logs;
      print('\n✅ [STEP 8] Data siap dipakai di UI!');
    } else {
      print('   Tidak ada data tersimpan (pertama kali login dengan user ini)');
    }
  }
}
