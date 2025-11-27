// fisier: lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forex_journal_app/models/account.dart';
import 'package:forex_journal_app/models/transaction.dart' as model; 
import 'package:forex_journal_app/models/strategy.dart';
import 'package:forex_journal_app/models/user_profile.dart';
import 'package:forex_journal_app/models/post.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  DocumentReference get _userDoc {
    if (_userId == null) throw Exception("Utilizator neautentificat");
    return _db.collection('users').doc(_userId);
  }

  Future<void> get db async {}

  // ==========================================================================
  // --- ZONA ADMIN (COMPLETĂ) ---
  // ==========================================================================

  // 1. Verifică strict dacă ești ADMIN
  Future<bool> isAdmin() async {
    if (_userId == null) return false;
    try {
      final doc = await _userDoc.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin';
      }
    } catch (e) {}
    return false;
  }

 // 2. Ia lista cu TOȚI userii (Versiune Curată)
  Future<List<Map<String, dynamic>>> getAllUsersForAdmin() async {
    try {
      final userSnapshot = await _db.collection('users').get();
      
      final futures = userSnapshot.docs.map((doc) async {
        final userData = doc.data();
        final uid = doc.id;
        
        String displayName = '';
        String displayEmail = userData['email'] ?? '';

        // Încercare de recuperare nume din profil
        try {
          final profileCollection = await _db.collection('users').doc(uid).collection('profile').get();
          if (profileCollection.docs.isNotEmpty) {
            final pData = profileCollection.docs.first.data();
            final first = pData['firstName'] ?? pData['prenume'] ?? '';
            final last = pData['lastName'] ?? pData['nume'] ?? '';
            
            if (first.toString().isNotEmpty || last.toString().isNotEmpty) {
              displayName = "$first $last".trim();
            }
          }
        } catch (e) {
          // ignore
        }

        // LOGICA DE "FALLBACK" PENTRU EMAIL
        if (displayEmail.isEmpty) {
          // Dacă e chiar contul meu (adminul logat), știu sigur care e mailul meu
          if (uid == _auth.currentUser?.uid) {
            displayEmail = _auth.currentUser?.email ?? 'Emailul Tău';
            // Opțional: Îl și salvăm în DB ca să nu mai apară problema pe viitor
            await _db.collection('users').doc(uid).update({'email': displayEmail});
          } else {
            displayEmail = 'Utilizator App'; // Text curat, nu eroare
          }
        }

        // Dacă nici numele nu e setat, punem un placeholder
        if (displayName.isEmpty) {
          displayName = 'Trader Anonim';
        }

        return {
          'uid': uid,
          'email': displayEmail, 
          'role': userData['role'] ?? 'student',
          'name': displayName,
        };
      });

      return await Future.wait(futures);
    } catch (e) {
      print("Eroare admin fetch: $e");
      return [];
    }
  }

  // 3. Schimbă rolul
  Future<void> updateUserRole(String targetUserId, String newRole) async {
    await _db.collection('users').doc(targetUserId).update({'role': newRole});
  }

  // 4. Trimite Email de Resetare Parolă (ACȚIUNE ADMIN) - LIPSEA
  Future<void> adminResetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 5. Șterge datele utilizatorului (ACȚIUNE ADMIN) - LIPSEA
  Future<void> adminDeleteUserData(String targetUid) async {
    await _db.collection('users').doc(targetUid).delete();
  }

  // ==========================================================================
  // --- ZONA PUBLICĂ (TEACHING) ---
  // ==========================================================================

  Future<bool> isTeacher() async {
    if (_userId == null) return false;
    try {
      final doc = await _userDoc.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'teacher' || data['role'] == 'admin';
      }
    } catch (e) {}
    return false;
  }

  Stream<List<Post>> getPostsStream() {
    return _db.collection('teaching_hub').orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Post.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addPost(Post post) async { await _db.collection('teaching_hub').add(post.toMap()); }
  Future<void> deletePost(String id) async { await _db.collection('teaching_hub').doc(id).delete(); }

  // ==========================================================================
  // --- ZONA PRIVATĂ (CONTURI, TRANZACȚII) ---
  // ==========================================================================

  // --- Conturi ---
  Future<String> saveAccount(Account account) async {
    final collection = _userDoc.collection('accounts');
    if (account.id.isEmpty) {
      final docRef = await collection.add(account.toMap());
      return docRef.id;
    } else {
      await collection.doc(account.id).update(account.toMap());
      return account.id;
    }
  }

  Future<Account?> getAccount(String id) async {
    final doc = await _userDoc.collection('accounts').doc(id).get();
    if (doc.exists) return Account.fromMap(doc.data()!, doc.id);
    return null;
  }

  Future<List<Account>> getAllAccounts() async {
    if (_userId == null) return [];
    final snapshot = await _userDoc.collection('accounts').get();
    return snapshot.docs.map((doc) => Account.fromMap(doc.data(), doc.id)).toList();
  }

  Future<double> getCurrentBalance(String accountId) async {
    final account = await getAccount(accountId);
    if (account == null) return 0.0;
    final transactions = await getAllTransactions(accountId);
    final totalProfit = transactions.fold(0.0, (sum, t) => sum + t.profitLossAmount);
    return account.initialBalance + totalProfit;
  }

  Future<void> deleteAccount(String accountId) async {
    final txSnapshot = await _userDoc.collection('transactions').where('accountId', isEqualTo: accountId).get();
    final batch = _db.batch();
    for (var doc in txSnapshot.docs) { batch.delete(doc.reference); }
    batch.delete(_userDoc.collection('accounts').doc(accountId));
    await batch.commit();
  }

  // --- Tranzacții ---
  Future<void> saveTransaction(model.Transaction transaction) async {
    final collection = _userDoc.collection('transactions');
    if (transaction.id.isEmpty) {
      await collection.add(transaction.toMap());
    } else {
      await collection.doc(transaction.id).update(transaction.toMap());
    }
  }

  Future<List<model.Transaction>> getAllTransactions(String accountId) async {
    if (_userId == null) return [];
    final snapshot = await _userDoc.collection('transactions').where('accountId', isEqualTo: accountId).orderBy('entryDate', descending: true).get();
    return snapshot.docs.map((doc) => model.Transaction.fromMap(doc.data(), doc.id)).toList();
  }

  Future<model.Transaction?> getTransaction(String id) async {
    final doc = await _userDoc.collection('transactions').doc(id).get();
    if (doc.exists) return model.Transaction.fromMap(doc.data()!, doc.id);
    return null;
  }

  Future<void> deleteTransaction(String transactionId) async { await _userDoc.collection('transactions').doc(transactionId).delete(); }

  // --- Strategii ---
  Future<void> saveStrategy(Strategy strategy) async {
    final collection = _userDoc.collection('strategies');
    if (strategy.id.isEmpty) await collection.add(strategy.toMap()); else await collection.doc(strategy.id).update(strategy.toMap());
  }

  Future<List<Strategy>> getAllStrategies() async {
    if (_userId == null) return [];
    final snapshot = await _userDoc.collection('strategies').get();
    return snapshot.docs.map((doc) => Strategy.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> deleteStrategy(String id) async { await _userDoc.collection('strategies').doc(id).delete(); }

  // --- Profil ---
  Future<UserProfile?> getUserProfile() async {
    if (_userId == null) return null;
    final doc = await _userDoc.collection('profile').doc('main_profile').get();
    if (doc.exists) return UserProfile.fromMap(doc.data()!, doc.id);
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _userDoc.collection('profile').doc('main_profile').set(profile.toMap());
  }

  Future<void> wipeAllData() async {}
}