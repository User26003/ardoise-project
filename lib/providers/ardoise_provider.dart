import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/storage_service.dart';

class ClientSummary {
  final Client client;
  final int balance; // dette actuelle
  final DateTime? lastCreditDate;
  final DateTime? lastPaymentDate;
  final DateTime? lastActivity;
  final int totalCredited;
  final int totalPaid;

  ClientSummary({
    required this.client,
    required this.balance,
    this.lastCreditDate,
    this.lastPaymentDate,
    this.lastActivity,
    this.totalCredited = 0,
    this.totalPaid = 0,
  });

  /// Nombre de jours depuis la dernière activité (crédit ou paiement).
  int get daysSinceActivity => lastActivity == null
      ? 0
      : DateTime.now().difference(lastActivity!).inDays;
}

enum ClientFilter { all, today, late, paid }

class ArdoiseProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<Client> _clients = [];
  List<Transaction> _transactions = [];
  ShopProfile _profile = ShopProfile();
  ClientFilter filter = ClientFilter.all;
  String search = '';

  ArdoiseProvider(this._storage);

  ShopProfile get profile => _profile;
  List<Client> get clients => _clients;
  List<Transaction> get transactions => _transactions;
  bool get onboardingDone => _storage.onboardingDone;

  Future<void> load() async {
    _clients = _storage.getClients();
    _transactions = _storage.getTransactions();
    _profile = _storage.getProfile();
    if (!_storage.demoSeeded && _clients.isEmpty) {
      await _seedDemo();
      await _storage.setDemoSeeded();
    }
    notifyListeners();
  }

  // ---------- Profil ----------
  Future<void> saveProfile(ShopProfile p) async {
    _profile = p;
    await _storage.saveProfile(p);
    await _storage.setOnboardingDone();
    notifyListeners();
  }

  // ---------- Clients ----------
  Client? clientById(String id) {
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Recherche tolérante (insensible à la casse et aux accents).
  Client? findClientByName(String name) {
    final n = _normalize(name);
    if (n.isEmpty) return null;
    for (final c in _clients) {
      if (_normalize(c.name) == n) return c;
    }
    for (final c in _clients) {
      final cn = _normalize(c.name);
      if (cn.startsWith(n) || n.startsWith(cn) || cn.contains(n)) return c;
    }
    return null;
  }

  Future<Client> addClient(String name, {String phone = ''}) async {
    final c = Client(
      id: _uuid.v4(),
      name: name.trim(),
      phone: phone.trim(),
      createdAt: DateTime.now(),
      colorIndex: _clients.length % 8,
    );
    _clients.add(c);
    await _storage.saveClient(c);
    notifyListeners();
    return c;
  }

  Future<void> updateClient(Client c) async {
    await _storage.saveClient(c);
    final i = _clients.indexWhere((e) => e.id == c.id);
    if (i >= 0) _clients[i] = c;
    notifyListeners();
  }

  Future<void> deleteClient(String id) async {
    await _storage.deleteClient(id);
    _clients.removeWhere((c) => c.id == id);
    _transactions.removeWhere((t) => t.clientId == id);
    notifyListeners();
  }

  // ---------- Transactions ----------
  Future<Transaction> addCredit(String clientId, int amount,
      {String label = '', bool viaVoice = false, DateTime? date}) async {
    final t = Transaction(
      id: _uuid.v4(),
      clientId: clientId,
      type: TransactionType.credit,
      amount: amount,
      label: label.trim(),
      date: date ?? DateTime.now(),
      viaVoice: viaVoice,
    );
    _transactions.add(t);
    await _storage.saveTransaction(t);
    notifyListeners();
    return t;
  }

  Future<Transaction> addPayment(String clientId, int amount,
      {PaymentMethod method = PaymentMethod.cash, DateTime? date}) async {
    final t = Transaction(
      id: _uuid.v4(),
      clientId: clientId,
      type: TransactionType.payment,
      amount: amount,
      method: method,
      label: method == PaymentMethod.mobileMoney ? 'Mobile Money' : 'Espèces',
      date: date ?? DateTime.now(),
    );
    _transactions.add(t);
    await _storage.saveTransaction(t);
    notifyListeners();
    return t;
  }

  Future<void> deleteTransaction(String id) async {
    await _storage.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<Transaction> transactionsOf(String clientId) {
    final list = _transactions.where((t) => t.clientId == clientId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ---------- Résumés ----------
  ClientSummary summaryOf(Client c) {
    int credited = 0, paid = 0;
    DateTime? lastCredit, lastPayment, last;
    for (final t in _transactions) {
      if (t.clientId != c.id) continue;
      if (t.isCredit) {
        credited += t.amount;
        if (lastCredit == null || t.date.isAfter(lastCredit)) lastCredit = t.date;
      } else {
        paid += t.amount;
        if (lastPayment == null || t.date.isAfter(lastPayment)) {
          lastPayment = t.date;
        }
      }
      if (last == null || t.date.isAfter(last)) last = t.date;
    }
    return ClientSummary(
      client: c,
      balance: credited - paid,
      lastCreditDate: lastCredit,
      lastPaymentDate: lastPayment,
      lastActivity: last,
      totalCredited: credited,
      totalPaid: paid,
    );
  }

  List<ClientSummary> get allSummaries {
    final list = _clients.map(summaryOf).toList();
    list.sort((a, b) {
      final la = a.lastActivity ?? a.client.createdAt;
      final lb = b.lastActivity ?? b.client.createdAt;
      return lb.compareTo(la);
    });
    return list;
  }

  bool isLate(ClientSummary s) =>
      s.balance > 0 && s.daysSinceActivity >= _profile.reminderDays;

  List<ClientSummary> get filteredSummaries {
    final today = DateTime.now();
    Iterable<ClientSummary> list = allSummaries;
    switch (filter) {
      case ClientFilter.all:
        break;
      case ClientFilter.today:
        list = list.where((s) =>
            s.lastActivity != null &&
            s.lastActivity!.year == today.year &&
            s.lastActivity!.month == today.month &&
            s.lastActivity!.day == today.day);
        break;
      case ClientFilter.late:
        list = list.where(isLate);
        break;
      case ClientFilter.paid:
        list = list.where((s) => s.balance <= 0);
        break;
    }
    if (search.trim().isNotEmpty) {
      final q = _normalize(search);
      list = list.where((s) =>
          _normalize(s.client.name).contains(q) ||
          s.client.phone.contains(search.trim()));
    }
    return list.toList();
  }

  void setFilter(ClientFilter f) {
    filter = f;
    notifyListeners();
  }

  void setSearch(String q) {
    search = q;
    notifyListeners();
  }

  // ---------- Statistiques ----------
  int get totalOutstanding =>
      allSummaries.fold(0, (sum, s) => sum + (s.balance > 0 ? s.balance : 0));

  int get debtorsCount => allSummaries.where((s) => s.balance > 0).length;

  int get lateCount => allSummaries.where(isLate).length;

  int get lateAmount =>
      allSummaries.where(isLate).fold(0, (sum, s) => sum + s.balance);

  int creditedBetween(DateTime from, DateTime to) => _transactions
      .where((t) => t.isCredit && !t.date.isBefore(from) && t.date.isBefore(to))
      .fold(0, (s, t) => s + t.amount);

  int paidBetween(DateTime from, DateTime to) => _transactions
      .where(
          (t) => !t.isCredit && !t.date.isBefore(from) && t.date.isBefore(to))
      .fold(0, (s, t) => s + t.amount);

  int get todayCredited {
    final d = DateTime.now();
    final start = DateTime(d.year, d.month, d.day);
    return creditedBetween(start, start.add(const Duration(days: 1)));
  }

  int get todayPaid {
    final d = DateTime.now();
    final start = DateTime(d.year, d.month, d.day);
    return paidBetween(start, start.add(const Duration(days: 1)));
  }

  int get monthCredited {
    final d = DateTime.now();
    return creditedBetween(
        DateTime(d.year, d.month, 1), DateTime(d.year, d.month + 1, 1));
  }

  int get monthPaid {
    final d = DateTime.now();
    return paidBetween(
        DateTime(d.year, d.month, 1), DateTime(d.year, d.month + 1, 1));
  }

  int get mobileMoneyTotal => _transactions
      .where((t) => !t.isCredit && t.method == PaymentMethod.mobileMoney)
      .fold(0, (s, t) => s + t.amount);

  int get cashTotal => _transactions
      .where((t) => !t.isCredit && t.method != PaymentMethod.mobileMoney)
      .fold(0, (s, t) => s + t.amount);

  /// Sept derniers jours: [(jour, crédits, paiements)]
  List<(DateTime, int, int)> get last7Days {
    final now = DateTime.now();
    final res = <(DateTime, int, int)>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final next = day.add(const Duration(days: 1));
      res.add((day, creditedBetween(day, next), paidBetween(day, next)));
    }
    return res;
  }

  List<ClientSummary> get topDebtors {
    final list = allSummaries.where((s) => s.balance > 0).toList();
    list.sort((a, b) => b.balance.compareTo(a.balance));
    return list.take(5).toList();
  }

  /// Articles les plus vendus à crédit.
  List<(String, int)> get topLabels {
    final map = <String, int>{};
    for (final t in _transactions) {
      if (t.isCredit && t.label.isNotEmpty) {
        final k = t.label.trim();
        final key = k.isEmpty
            ? k
            : k.substring(0, 1).toUpperCase() + k.substring(1).toLowerCase();
        map[key] = (map[key] ?? 0) + t.amount;
      }
    }
    final list = map.entries.map((e) => (e.key, e.value)).toList();
    list.sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(5).toList();
  }

  Future<void> clearAllData() async {
    await _storage.clearAll();
    _clients = [];
    _transactions = [];
    notifyListeners();
  }

  // ---------- Utilitaires ----------
  static String _normalize(String s) {
    const from = 'àáâäãåçèéêëìíîïñòóôöõùúûüýÿ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyy';
    var r = s.toLowerCase().trim();
    for (int i = 0; i < from.length; i++) {
      r = r.replaceAll(from[i], to[i]);
    }
    return r;
  }

  // ---------- Données de démonstration ----------
  Future<void> _seedDemo() async {
    final now = DateTime.now();
    final demo = [
      ('Codjo', '97 12 34 56', [
        (5, 'Riz', 1500, true),
        (3, 'Huile', 800, true),
        (1, 'Sucre', 500, true),
      ], <(int, int)>[(2, 1000)]),
      ('Afi', '96 45 67 89', [
        (12, 'Savon', 700, true),
        (9, 'Tomate', 1200, false),
      ], <(int, int)>[]),
      ('Sènan', '95 22 33 44', [
        (0, 'Pain', 300, true),
        (0, 'Lait', 900, false),
      ], <(int, int)>[]),
      ('Rachid', '61 78 90 12', [
        (20, 'Gaz', 6500, false),
      ], <(int, int)>[(15, 3000)]),
      ('Nadège', '97 88 77 66', [
        (4, 'Farine', 2000, true),
        (2, 'Oeufs', 1500, true),
      ], <(int, int)>[(1, 3500)]),
      ('Kossi', '99 11 22 33', [
        (8, 'Spaghetti', 1100, true),
        (6, 'Sardine', 1300, false),
        (2, 'Riz', 2500, true),
      ], <(int, int)>[(5, 1000)]),
    ];

    for (int i = 0; i < demo.length; i++) {
      final (name, phone, credits, payments) = demo[i];
      final c = Client(
        id: _uuid.v4(),
        name: name,
        phone: phone,
        createdAt: now.subtract(const Duration(days: 30)),
        colorIndex: i % 8,
      );
      _clients.add(c);
      await _storage.saveClient(c);
      for (final (daysAgo, label, amount, voice) in credits) {
        final t = Transaction(
          id: _uuid.v4(),
          clientId: c.id,
          type: TransactionType.credit,
          amount: amount,
          label: label,
          date: now.subtract(Duration(days: daysAgo, hours: 2)),
          viaVoice: voice,
        );
        _transactions.add(t);
        await _storage.saveTransaction(t);
      }
      for (final (daysAgo, amount) in payments) {
        final t = Transaction(
          id: _uuid.v4(),
          clientId: c.id,
          type: TransactionType.payment,
          amount: amount,
          method: daysAgo.isEven ? PaymentMethod.mobileMoney : PaymentMethod.cash,
          label: daysAgo.isEven ? 'Mobile Money' : 'Espèces',
          date: now.subtract(Duration(days: daysAgo, hours: 1)),
        );
        _transactions.add(t);
        await _storage.saveTransaction(t);
      }
    }
  }
}
