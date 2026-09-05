import 'package:ardoise/services/voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
