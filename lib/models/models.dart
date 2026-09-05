// Modèles de données d'Ardoise.
// Stockés dans Hive sous forme de Map pour rester simples et sans codegen.

enum TransactionType { credit, payment }

enum PaymentMethod { cash, mobileMoney, other }

class Client {
  final String id;
  String name;
  String phone;
  String note;
  final DateTime createdAt;
  int colorIndex;

  /// Date à laquelle le client a promis de rembourser (optionnelle).
  DateTime? promiseDate;

  Client({
    required this.id,
    required this.name,
    this.phone = '',
    this.note = '',
    required this.createdAt,
    this.colorIndex = 0,
    this.promiseDate,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'colorIndex': colorIndex,
    'promiseDate': promiseDate?.millisecondsSinceEpoch,
  };

  factory Client.fromMap(Map<dynamic, dynamic> m) => Client(
    id: m['id'] as String,
    name: (m['name'] as String?) ?? '',
    phone: (m['phone'] as String?) ?? '',
    note: (m['note'] as String?) ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    ),
    colorIndex: (m['colorIndex'] as int?) ?? 0,
    promiseDate: m['promiseDate'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(m['promiseDate'] as int),
  );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class Transaction {
  final String id;
  final String clientId;
  final TransactionType type;
  final int amount; // en FCFA (entier)
  final String label; // ex: "Riz", "Huile"
  final PaymentMethod? method;
  final DateTime date;
  final bool viaVoice;

  Transaction({
    required this.id,
    required this.clientId,
    required this.type,
    required this.amount,
    this.label = '',
    this.method,
    required this.date,
    this.viaVoice = false,
  });

  bool get isCredit => type == TransactionType.credit;

  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'type': type.index,
    'amount': amount,
    'label': label,
    'method': method?.index,
    'date': date.millisecondsSinceEpoch,
    'viaVoice': viaVoice,
  };

  factory Transaction.fromMap(Map<dynamic, dynamic> m) => Transaction(
    id: m['id'] as String,
    clientId: m['clientId'] as String,
    type: TransactionType.values[(m['type'] as int?) ?? 0],
    amount: (m['amount'] as num?)?.toInt() ?? 0,
    label: (m['label'] as String?) ?? '',
    method: m['method'] == null
        ? null
        : PaymentMethod.values[(m['method'] as int)],
    date: DateTime.fromMillisecondsSinceEpoch(
      (m['date'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    ),
    viaVoice: (m['viaVoice'] as bool?) ?? false,
  );
}

class ShopProfile {
  String ownerName;
  String shopName;
  String phone;
  int reminderDays; // rappel après X jours sans paiement

  ShopProfile({
    this.ownerName = '',
    this.shopName = '',
    this.phone = '',
    this.reminderDays = 7,
  });

  Map<String, dynamic> toMap() => {
    'ownerName': ownerName,
    'shopName': shopName,
    'phone': phone,
    'reminderDays': reminderDays,
  };

  factory ShopProfile.fromMap(Map<dynamic, dynamic>? m) {
    if (m == null) return ShopProfile();
    return ShopProfile(
      ownerName: (m['ownerName'] as String?) ?? '',
      shopName: (m['shopName'] as String?) ?? '',
      phone: (m['phone'] as String?) ?? '',
      reminderDays: (m['reminderDays'] as int?) ?? 7,
    );
  }
}
