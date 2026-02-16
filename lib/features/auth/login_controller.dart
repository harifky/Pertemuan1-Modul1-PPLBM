class LoginController {
  // Database sederhana (Hardcoded) untuk banyak user
  final Map<String, String> _users = {
    "admin": "123",
    "user": "123",
    "guest": "123",
  };

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  bool login(String username, String password) {
    return _users[username] == password;
  }
}
