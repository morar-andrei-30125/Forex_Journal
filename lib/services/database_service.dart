import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:forex_journal_app/models/account.dart';
import 'package:forex_journal_app/models/transaction.dart';
import 'package:forex_journal_app/models/strategy.dart';
import 'package:forex_journal_app/models/user_profile.dart';

class DatabaseService {
  late Future<Isar> db;

  DatabaseService() {
    db = openIsar();
  }

  Future<Isar> openIsar() async {
    final dir = await getApplicationSupportDirectory();
    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [AccountSchema, TransactionSchema, StrategySchema, UserProfileSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }

  // --- Conturi ---
  Future<int> saveAccount(Account account) async {
    final isar = await db;
    return isar.writeTxn(() async => await isar.accounts.put(account));
  }

  Future<Account?> getAccount(int id) async {
    final isar = await db;
    return await isar.accounts.get(id);
  }

  Future<List<Account>> getAllAccounts() async {
    final isar = await db;
    return await isar.accounts.where().findAll();
  }

  Future<double> getCurrentBalance(int accountId) async {
    final isar = await db;
    final account = await isar.accounts.get(accountId);
    if (account == null) return 0.0;
    final totalProfitLoss = await isar.transactions
        .filter().accountIdEqualTo(accountId).profitLossAmountProperty().sum();
    return account.initialBalance + totalProfitLoss;
  }

  Future<void> deleteAccount(int accountId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.transactions.filter().accountIdEqualTo(accountId).deleteAll();
      await isar.accounts.delete(accountId);
    });
  }

  // --- Tranzacții ---
  Future<int> saveTransaction(Transaction transaction) async {
    final isar = await db;
    return isar.writeTxn(() async {
      final txId = await isar.transactions.put(transaction);
      await transaction.strategy.save();
      return txId;
    });
  }

  Future<List<Transaction>> getAllTransactions(int accountId) async {
    final isar = await db;
    return await isar.transactions.filter().accountIdEqualTo(accountId).sortByEntryDate().findAll(); 
  }

  Future<Transaction?> getTransaction(int id) async {
    final isar = await db;
    return await isar.transactions.get(id);
  }

  Future<void> deleteTransaction(int transactionId) async {
    final isar = await db;
    await isar.writeTxn(() async => await isar.transactions.delete(transactionId));
  }

  // --- Strategii ---
  Future<int> saveStrategy(Strategy strategy) async {
    final isar = await db;
    return isar.writeTxn(() async => await isar.strategys.put(strategy));
  }

  Future<List<Strategy>> getAllStrategies() async {
    final isar = await db;
    return await isar.strategys.where().findAll();
  }

  Future<void> deleteStrategy(int id) async {
    final isar = await db;
    await isar.writeTxn(() async => await isar.strategys.delete(id));
  }

  // --- Profil ---
  Future<UserProfile?> getUserProfile() async {
    final isar = await db;
    return await isar.userProfiles.where().findFirst();
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.userProfiles.clear(); 
      await isar.userProfiles.put(profile);
    });
  }

  // --- Reset ---
  Future<void> wipeAllData() async {
    final isar = await db;
    await isar.writeTxn(() async => await isar.clear());
  }
}