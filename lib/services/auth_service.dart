// fisier: lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream care ascultă dacă userul e logat sau nu
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obține userul curent
  User? get currentUser => _auth.currentUser;

  // Funcție de Login
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Funcție de Înregistrare (Register)
  Future<void> register({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Funcție de Deconectare
  Future<void> logout() async {
    await _auth.signOut();
  }
}