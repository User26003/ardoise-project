import 'package:ardoise/models/models.dart';
import 'package:ardoise/providers/ardoise_provider.dart';
import 'package:ardoise/services/voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Retard avec date promise', () {
    ClientSummary make(DateTime? promise, int daysSince) => ClientSummary(
      client: Client(
        id: 'x',
        name: 'Test',
        createdAt: DateTime.now(),
        promiseDate: promise,
      ),
      balance: 1000,
      lastActivity: DateTime.now().subtract(Duration(days: daysSince)),
    );

    test('promesse dépassée hier = 1 jour de retard', () {
      final s = make(DateTime.now().subtract(const Duration(days: 1)), 20);
      expect(s.daysToPromise, -1);
      expect(s.lateDays(7), 1);
    });

    test("promesse aujourd'hui = pas encore en retard", () {
      final s = make(DateTime.now(), 20);
      expect(s.daysToPromise, 0);
      expect(s.lateDays(7), 0);
    });

    test('promesse future prime sur la règle des X jours', () {
      final s = make(DateTime.now().add(const Duration(days: 3)), 30);
      expect(s.lateDays(7), 0);
    });

    test('sans promesse : règle des X jours', () {
      expect(make(null, 10).lateDays(7), 3);
      expect(make(null, 3).lateDays(7), 0);
    });
  });

  group('VoiceParser', () {
    test('format virgules', () {
      final r = VoiceParser.parse('Codjo, riz, 500');
      expect(r.clientName, 'Codjo');
      expect(r.label, 'Riz');
      expect(r.amount, 500);
      expect(r.isPayment, isFalse);
    });

    test('phrase naturelle', () {
      final r = VoiceParser.parse("Afi a pris de l'huile à 800 francs");
      expect(r.clientName, 'Afi');
      expect(r.label, 'Huile');
      expect(r.amount, 800);
    });

    test('paiement', () {
      final r = VoiceParser.parse('Rachid a payé 2000');
      expect(r.clientName, 'Rachid');
      expect(r.amount, 2000);
      expect(r.isPayment, isTrue);
    });

    test('nombre en lettres', () {
      final r = VoiceParser.parse('Nadège savon mille deux cents');
      expect(r.clientName, 'Nadège');
      expect(r.label, 'Savon');
      expect(r.amount, 1200);
    });

    test('milliers avec espace', () {
      final r = VoiceParser.parse('Kossi, gaz, 6 500');
      expect(r.amount, 6500);
    });
  });
}
