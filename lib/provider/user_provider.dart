import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  Future<void> fetchUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = Supabase.instance.client.auth.currentUser;
      _user = user;
      notifyListeners(); // <- Esto fuerza a redibujar los widgets que dependen del provider
    }
  }

  User? getUser() {
    return _user;
  }
}/*class UserProvider extends ChangeNotifier {
  User? user; // Ahora usa el User de Supabase

  void setUser(User? newUser) {
    user = newUser;
    notifyListeners();
  }

  User? getUser() {
    return user;
  }
}*/
/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  User? user;

  void setUser(newUser) {
    user = newUser;
    notifyListeners();
  }

  User? getUser() {
    return user;
  }
}*/
