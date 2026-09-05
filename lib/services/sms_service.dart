import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../utils/formatters.dart';

/// Envoi de rappels via l'application SMS du téléphone (Intent Android ACTION_SENDTO).
/// Fonctionne sans internet : le SMS part par le réseau GSM du boutiquier.
class SmsService {
  static String buildReminder({
    required Client client,
    required int balance,
    required ShopProfile profile,
  }) {
    final shop = profile.shopName.isNotEmpty
        ? profile.shopName
        : (profile.ownerName.isNotEmpty ? profile.ownerName : 'la boutique');
    final buffer = StringBuffer()
      ..write('Bonjour ${client.name}, ')
      ..write('petit rappel de $shop : ')
      ..write('votre ardoise est de ${Fmt.fcfa(balance)}. ')
      ..write('Merci de passer régler quand vous pouvez.');
    if (profile.phone.isNotEmpty) {
      buffer.write(' Mobile Money : ${profile.phone}');
    }
    return buffer.toString();
  }

  static Future<bool> sendReminder({
    required Client client,
    required int balance,
    required ShopProfile profile,
  }) async {
    if (client.phone.trim().isEmpty) return false;
    final body = buildReminder(client: client, balance: balance, profile: profile);
    final phone = client.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': body},
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> call(String phone) async {
    final p = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (p.isEmpty) return false;
    try {
      return await launchUrl(Uri(scheme: 'tel', path: p));
    } catch (_) {
      return false;
    }
  }
}
