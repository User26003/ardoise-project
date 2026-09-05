import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/ardoise_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  /// Mode "première ouverture" : plein écran, pas de bouton retour.
  final bool onboarding;
  const SettingsScreen({super.key, this.onboarding = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _owner;
  late final TextEditingController _shop;
  late final TextEditingController _phone;
  late int _reminderDays;

  @override
  void initState() {
    super.initState();
    final p = context.read<ArdoiseProvider>().profile;
    _owner = TextEditingController(text: p.ownerName);
    _shop = TextEditingController(text: p.shopName);
    _phone = TextEditingController(text: p.phone);
    _reminderDays = p.reminderDays;
  }

  @override
  void dispose() {
    _owner.dispose();
    _shop.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final p = context.read<ArdoiseProvider>();
    await p.saveProfile(ShopProfile(
      ownerName: _owner.text.trim(),
      shopName: _shop.text.trim(),
      phone: _phone.text.trim(),
      reminderDays: _reminderDays,
    ));
    if (!mounted) return;
    if (widget.onboarding) return; // le parent bascule sur l'accueil
    Navigator.pop(context);
    showToast(context, 'Profil enregistré', color: AppColors.green);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArdoiseProvider>();
    return Scaffold(
      body: Column(
        children: [
          WaxHeader(
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 26),
            child: Row(
              children: [
                if (!widget.onboarding)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  )
                else
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.onboarding ? 'Bienvenue sur Ardoise' : 'Ma boutique',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.onboarding)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Votre carnet de crédit, sans cahier ni oubli.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.onboarding) ...[
                  const _Tip(
                    icon: Icons.mic_rounded,
                    title: 'Parlez, on note',
                    text: 'Dites « Codjo, riz, 500 » et c\'est sur l\'ardoise.',
                  ),
                  const _Tip(
                    icon: Icons.sms_outlined,
                    title: 'Rappels SMS',
                    text: 'Un bouton pour rappeler poliment à vos clients.',
                  ),
                  const _Tip(
                    icon: Icons.wifi_off_rounded,
                    title: '100 % hors ligne',
                    text: 'Tout reste sur votre téléphone, même sans réseau.',
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _owner,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Votre nom (ex. Mama Afi)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _shop,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la boutique',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro Mobile Money (MTN / Moov / Celtiis)',
                    helperText: 'Ajouté dans les SMS de rappel pour faciliter le paiement',
                    prefixIcon: Icon(Icons.phone_iphone),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Considérer un client en retard après',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [3, 7, 14, 30].map((d) {
                    final sel = _reminderDays == d;
                    return ChoiceChip(
                      label: Text('$d jours'),
                      selected: sel,
                      selectedColor: AppColors.orange,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : AppColors.ink),
                      onSelected: (_) => setState(() => _reminderDays = d),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(widget.onboarding ? 'Commencer' : 'Enregistrer'),
                ),
                if (!widget.onboarding) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.inkSoft),
                    title: const Text('À propos'),
                    subtitle: Text(
                        'Ardoise v1.0 · ${p.clients.length} clients · ${p.transactions.length} opérations'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppColors.lateRed),
                    title: const Text('Effacer toutes les données',
                        style: TextStyle(color: AppColors.lateRed)),
                    subtitle: const Text('Clients et opérations (irréversible)'),
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Tout effacer ?'),
                          content: const Text(
                              'Tous les clients et toutes les opérations seront supprimés définitivement.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler')),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.lateRed,
                                  minimumSize: const Size(0, 44)),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Effacer'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<ArdoiseProvider>().clearAllData();
                        if (context.mounted) {
                          showToast(context, 'Données effacées');
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Tip({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.deepOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(text,
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
