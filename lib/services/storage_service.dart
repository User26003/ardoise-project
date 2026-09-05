import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Couche de persistance hors ligne basée sur Hive.
class StorageService {
  static const _clientsBox = 'clients';
  static const _transactionsBox = 'transactions';
  static const _settingsBox = 'settings';

  late Box _clients;
  late Box _transactions;
  late Box _settings;

  Future<void> init() async {
    await Hive.initFlutter();
    _clients = await Hive.openBox(_clientsBox);
    _transactions = await Hive.openBox(_transactionsBox);
    _settings = await Hive.openBox(_settingsBox);
  }

  // ---------- Clients ----------
  List<Client> getClients() =>
      _clients.values.map((e) => Client.fromMap(e as Map)).toList();

  Future<void> saveClient(Client c) => _clients.put(c.id, c.toMap());

  Future<void> deleteClient(String id) async {
    await _clients.delete(id);
    final toDelete = _transactions.values
        .map((e) => Transaction.fromMap(e as Map))
        .where((t) => t.clientId == id)
        .map((t) => t.id)
        .toList();
    await _transactions.deleteAll(toDelete);
  }

  // ---------- Transactions ----------
  List<Transaction> getTransactions() =>
      _transactions.values.map((e) => Transaction.fromMap(e as Map)).toList();

  Future<void> saveTransaction(Transaction t) =>
      _transactions.put(t.id, t.toMap());

  Future<void> deleteTransaction(String id) => _transactions.delete(id);

  // ---------- Profil / réglages ----------
  ShopProfile getProfile() =>
      ShopProfile.fromMap(_settings.get('profile') as Map?);

  Future<void> saveProfile(ShopProfile p) =>
      _settings.put('profile', p.toMap());

  bool get onboardingDone =>
      (_settings.get('onboardingDone') as bool?) ?? false;
  Future<void> setOnboardingDone() => _settings.put('onboardingDone', true);

  bool get demoSeeded => (_settings.get('demoSeeded') as bool?) ?? false;
  Future<void> setDemoSeeded() => _settings.put('demoSeeded', true);

  Future<void> clearAll() async {
    await _clients.clear();
    await _transactions.clear();
  }
}
