/// Analyse une phrase dictée du type :
///   "Codjo, riz, 500"
///   "Codjo riz cinq cents"
///   "Afi a pris de l'huile à 800 francs"
///   "Rachid a payé 2000"
/// et en extrait : nom du client, article, montant, et s'il s'agit d'un paiement.
class VoiceParseResult {
  final String? clientName;
  final String? label;
  final int? amount;
  final bool isPayment;
  final String raw;

  VoiceParseResult({
    this.clientName,
    this.label,
    this.amount,
    this.isPayment = false,
    required this.raw,
  });

  bool get isComplete => clientName != null && amount != null && amount! > 0;
}

class VoiceParser {
  // Mots-clés de paiement (sans accents : le texte est normalisé avant test)
  static const _paymentWords = [
    'paye',
    'payer',
    'rembourse',
    'remboursement',
    'verse',
    'donne',
    'regle',
    'solde',
  ];

  static const _stopWords = {
    'a',
    'à',
    'pris',
    'prend',
    'pour',
    'de',
    'du',
    'des',
    'la',
    'le',
    'les',
    'l',
    'un',
    'une',
    'et',
    'francs',
    'franc',
    'fcfa',
    'f',
    'cfa',
    'chez',
    'crédit',
    'credit',
    'ardoise',
    'doit',
    'me',
    'moi',
    'sur',
    'en',
    'd',
    'note',
    'ajoute',
    'ajouter',
    'noter',
    'mets',
    'met',
  };

  static const _numberWords = <String, int>{
    'zéro': 0,
    'zero': 0,
    'un': 1,
    'une': 1,
    'deux': 2,
    'trois': 3,
    'quatre': 4,
    'cinq': 5,
    'six': 6,
    'sept': 7,
    'huit': 8,
    'neuf': 9,
    'dix': 10,
    'onze': 11,
    'douze': 12,
    'treize': 13,
    'quatorze': 14,
    'quinze': 15,
    'seize': 16,
    'vingt': 20,
    'vingts': 20,
    'trente': 30,
    'quarante': 40,
    'cinquante': 50,
    'soixante': 60,
    'cent': 100,
    'cents': 100,
    'mille': 1000,
    'mil': 1000,
    'million': 1000000,
  };

  static VoiceParseResult parse(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return VoiceParseResult(raw: raw);

    var text = raw.toLowerCase().replaceAll(RegExp(r"[’']"), ' ');

    // Paiement ? (comparaison sans accents, mot par mot)
    bool isPayment = false;
    final tokens = text.split(RegExp(r'(\s+|,|;|/)'));
    for (final tok in tokens) {
      if (tok.isNotEmpty && _paymentWords.contains(_stripAccents(tok))) {
        isPayment = true;
        text = text.replaceFirst(tok, ' ');
      }
    }

    // Montant : chiffres (avec espaces/points comme séparateurs de milliers)
    int? amount;
    final digitMatch = RegExp(
      r'(\d{1,3}(?:[ .]\d{3})+|\d+)',
    ).allMatches(text).toList();
    if (digitMatch.isNotEmpty) {
      // On prend le dernier nombre (le montant vient généralement en fin)
      final m = digitMatch.last;
      amount = int.tryParse(m.group(0)!.replaceAll(RegExp(r'[ .]'), ''));
      text = text.replaceRange(m.start, m.end, ' ');
    }

    // Découpage en segments (virgules) ou en mots
    final segments = text
        .split(RegExp(r'[,;/]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    List<String> words;
    if (segments.length >= 2) {
      // Format "nom, article, montant"
      words = segments.expand((s) => s.split(RegExp(r'\s+'))).toList();
    } else {
      words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    }

    // Montant en lettres si pas de chiffres
    if (amount == null) {
      final (value, consumed) = _parseNumberWords(words);
      if (value > 0) {
        amount = value;
        words = words.where((w) => !consumed.contains(w)).toList();
      }
    }

    // Filtrage des mots vides
    final meaningful = words
        .map((w) => w.replaceAll(RegExp(r'[^a-zàâäéèêëîïôöùûüçñ\-]'), ''))
        .where((w) => w.isNotEmpty && !_stopWords.contains(w))
        .toList();

    String? clientName;
    String? label;
    if (segments.length >= 2) {
      final segWords = segments.first
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty && !_stopWords.contains(w))
          .toList();
      clientName = segWords.isEmpty ? null : _cap(segWords.join(' '));
      if (segments.length >= 2) {
        final lbl = segments[1]
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty && !_stopWords.contains(w))
            .where((w) => !RegExp(r'^\d').hasMatch(w))
            .toList();
        if (lbl.isNotEmpty) label = _cap(lbl.join(' '));
      }
    } else if (meaningful.isNotEmpty) {
      clientName = _cap(meaningful.first);
      if (meaningful.length > 1) {
        label = _cap(meaningful.sublist(1).join(' '));
      }
    }

    if (isPayment) label = null;

    return VoiceParseResult(
      clientName: clientName,
      label: label,
      amount: amount,
      isPayment: isPayment,
      raw: raw,
    );
  }

  /// Convertit une suite de mots-nombres français en entier.
  /// Retourne (valeur, mots consommés).
  static (int, Set<String>) _parseNumberWords(List<String> words) {
    int total = 0, current = 0;
    final consumed = <String>{};
    bool found = false;
    for (final w in words) {
      final clean = w.replaceAll('-', ' ');
      final parts = clean.split(' ');
      bool anyNum = false;
      for (final p in parts) {
        final v = _numberWords[p];
        if (v == null) continue;
        anyNum = true;
        found = true;
        if (v == 100) {
          current = current == 0 ? 100 : current * 100;
        } else if (v == 1000) {
          current = current == 0 ? 1000 : current * 1000;
          total += current;
          current = 0;
        } else if (v == 1000000) {
          current = current == 0 ? 1000000 : current * 1000000;
          total += current;
          current = 0;
        } else {
          current += v;
        }
      }
      if (anyNum) consumed.add(w);
    }
    if (!found) return (0, consumed);
    return (total + current, consumed);
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _stripAccents(String s) {
    const from = 'àáâäãåçèéêëìíîïñòóôöõùúûüýÿ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyy';
    var r = s.toLowerCase();
    for (int i = 0; i < from.length; i++) {
      r = r.replaceAll(from[i], to[i]);
    }
    return r;
  }
}
