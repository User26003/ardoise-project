import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/ardoise_provider.dart';
import '../services/sms_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/common.dart';
import 'add_entry_sheet.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArdoiseProvider>();
    final client = p.clientById(clientId);
    if (client == null) {
      return const Scaffold(body: Center(child: Text('Client introuvable')));
    }
    final s = p.summaryOf(client);
    final txs = p.transactionsOf(clientId);
    final isLate = p.isLate(s);
    final lateDays = s.lateDays(p.profile.reminderDays);
    final compact = R.isCompact(context);
    final hp = R.hPad(context);

    return Scaffold(
      body: Column(
        children: [
          WaxHeader(
            padding: EdgeInsets.fromLTRB(
              8,
              4,
              12,
              R.isShort(context) ? 14 : 22,
            ),
            child: MaxWidth(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Modifier',
                        onPressed: () => _editClient(context, client),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        onPressed: () => _deleteClient(context, client),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        ClientAvatar(client: client, size: compact ? 52 : 64),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: R.sp(context, 24),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                client.phone.isEmpty
                                    ? 'Pas de numéro'
                                    : client.phone,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dernière activité : ${Fmt.relativeDate(s.lastActivity)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.balance > 0 ? 'DOIT ENCORE' : 'ARDOISE',
                                style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  s.balance > 0
                                      ? Fmt.fcfa(s.balance)
                                      : 'Soldée ✓',
                                  style: TextStyle(
                                    fontSize: R.sp(context, 28),
                                    fontWeight: FontWeight.w900,
                                    color: s.balance > 0
                                        ? (isLate
                                              ? AppColors.lateRed
                                              : AppColors.deepOrange)
                                        : AppColors.green,
                                  ),
                                ),
                              ),
                              if (isLate)
                                Text(
                                  lateDays > 0
                                      ? 'En retard de $lateDays ${lateDays > 1 ? 'jours' : 'jour'}'
                                      : 'En retard',
                                  style: const TextStyle(
                                    color: AppColors.lateRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _mini(
                              'Total pris',
                              Fmt.fcfa(s.totalCredited),
                              AppColors.deepOrange,
                            ),
                            const SizedBox(height: 6),
                            _mini(
                              'Total payé',
                              Fmt.fcfa(s.totalPaid),
                              AppColors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: MaxWidth(
              child: Column(
                children: [
                  // ---- Date promise ----
                  Padding(
                    padding: EdgeInsets.fromLTRB(hp, 14, hp, 0),
                    child: _PromiseCard(
                      client: client,
                      isLate: isLate,
                      settled: s.balance <= 0,
                      onPick: () => _pickPromise(context, client),
                      onClear: () => context
                          .read<ArdoiseProvider>()
                          .setPromiseDate(client.id, null),
                    ),
                  ),
                  // ---- Actions ----
                  Padding(
                    padding: EdgeInsets.fromLTRB(hp, 12, hp, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Action(
                            icon: Icons.add_shopping_cart,
                            label: 'Crédit',
                            color: AppColors.orange,
                            onTap: () => showAddEntrySheet(
                              context,
                              presetClientId: clientId,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Action(
                            icon: Icons.check_circle_outline,
                            label: 'Paiement',
                            color: AppColors.green,
                            onTap: () => showAddEntrySheet(
                              context,
                              presetClientId: clientId,
                              presetPayment: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Action(
                            icon: Icons.sms_outlined,
                            label: 'Rappel',
                            color: AppColors.teal,
                            enabled: client.phone.isNotEmpty && s.balance > 0,
                            onTap: () =>
                                _sendReminder(context, client, s, p.profile),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Action(
                            icon: Icons.call_outlined,
                            label: 'Appeler',
                            color: AppColors.blue,
                            enabled: client.phone.isNotEmpty,
                            onTap: () => SmsService.call(client.phone),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionTitle('Historique (${txs.length})'),
                  Expanded(
                    child: txs.isEmpty
                        ? const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Aucune opération',
                            message: 'Notez un crédit ou un paiement.',
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(hp, 0, hp, 24),
                            itemCount: txs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _TxTile(
                              tx: txs[i],
                              onDelete: () => _deleteTx(context, txs[i]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPromise(BuildContext context, Client c) async {
    final now = DateTime.now();
    final initial = c.promiseDate != null && c.promiseDate!.isAfter(now)
        ? c.promiseDate!
        : now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date promise de remboursement',
      confirmText: 'Valider',
      cancelText: 'Annuler',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.orange,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      await context.read<ArdoiseProvider>().setPromiseDate(c.id, picked);
      if (context.mounted) {
        showToast(
          context,
          '${c.name} a promis de payer le ${Fmt.shortDate(picked)}',
          color: AppColors.green,
        );
      }
    }
  }

  Widget _mini(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    ],
  );

  Future<void> _sendReminder(
    BuildContext context,
    Client c,
    ClientSummary s,
    ShopProfile profile,
  ) async {
    final msg = SmsService.buildReminder(
      client: c,
      balance: s.balance,
      profile: profile,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Envoyer un rappel SMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À ${c.name} (${c.phone})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(msg, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ouvrir SMS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await SmsService.sendReminder(
      client: c,
      balance: s.balance,
      profile: profile,
    );
    if (!ok && context.mounted) {
      showToast(context, "Impossible d'ouvrir l'application SMS ici.");
    }
  }

  Future<void> _editClient(BuildContext context, Client c) async {
    final name = TextEditingController(text: c.name);
    final phone = TextEditingController(text: c.phone);
    final note = TextEditingController(text: c.note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Note (quartier, repère…)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted && name.text.trim().isNotEmpty) {
      c.name = name.text.trim();
      c.phone = phone.text.trim();
      c.note = note.text.trim();
      await context.read<ArdoiseProvider>().updateClient(c);
    }
  }

  Future<void> _deleteClient(BuildContext context, Client c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ${c.name} ?'),
        content: const Text(
          'Toutes ses opérations seront effacées. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lateRed,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ArdoiseProvider>().deleteClient(c.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteTx(BuildContext context, Transaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette opération ?'),
        content: Text(
          '${t.isCredit ? 'Crédit' : 'Paiement'} de ${Fmt.fcfa(t.amount)} du ${Fmt.dateTime(t.date)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lateRed,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ArdoiseProvider>().deleteTransaction(t.id);
    }
  }
}

/// Carte « Date promise de remboursement ».
class _PromiseCard extends StatelessWidget {
  final Client client;
  final bool isLate;
  final bool settled;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _PromiseCard({
    required this.client,
    required this.isLate,
    required this.settled,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final d = client.promiseDate;
    final hasDate = d != null;
    final Color color = settled
        ? AppColors.green
        : (hasDate
              ? (isLate ? AppColors.lateRed : const Color(0xFFB57400))
              : AppColors.inkSoft);
    final Color bg = settled
        ? AppColors.green.withValues(alpha: 0.10)
        : (hasDate
              ? (isLate
                    ? AppColors.lateRed.withValues(alpha: 0.10)
                    : AppColors.amber.withValues(alpha: 0.18))
              : Colors.white);

    String title;
    String sub;
    if (settled) {
      title = 'Ardoise soldée';
      sub = hasDate
          ? 'Promesse du ${Fmt.shortDate(d)} tenue'
          : 'Rien à rembourser';
    } else if (hasDate) {
      title = Fmt.promiseLabel(d);
      sub = 'Rendez-vous le ${Fmt.fullDate(d)}';
    } else {
      title = 'Pas de date promise';
      sub = 'Le client a dit quand il paie ? Notez la date ici.';
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: settled ? null : onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasDate || settled
                  ? color.withValues(alpha: 0.35)
                  : const Color(0xFFF1DCCB),
            ),
          ),
          child: Row(
            children: [
              Icon(
                settled
                    ? Icons.task_alt_rounded
                    : (hasDate
                          ? (isLate
                                ? Icons.event_busy_rounded
                                : Icons.event_available_rounded)
                          : Icons.event_outlined),
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (!settled) ...[
                if (hasDate)
                  IconButton(
                    tooltip: 'Retirer la date',
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.inkSoft,
                  ),
                Icon(
                  hasDate ? Icons.edit_calendar_outlined : Icons.add,
                  color: color,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : Colors.grey;
    final compact = R.isCompact(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: c, size: compact ? 20 : 24),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onDelete;
  const _TxTile({required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final color = credit ? AppColors.deepOrange : AppColors.green;
    return Card(
      child: ListTile(
        onLongPress: onDelete,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            credit
                ? Icons.shopping_basket_outlined
                : (tx.method == PaymentMethod.mobileMoney
                      ? Icons.phone_iphone
                      : Icons.payments_outlined),
            color: color,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                credit
                    ? (tx.label.isEmpty ? 'Crédit' : tx.label)
                    : 'Paiement · ${tx.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (tx.viaVoice) ...[
              const SizedBox(width: 6),
              const Icon(Icons.mic, size: 14, color: AppColors.inkSoft),
            ],
          ],
        ),
        subtitle: Text(
          Fmt.dateTime(tx.date),
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
        trailing: Text(
          '${credit ? '+' : '−'} ${Fmt.fcfa(tx.amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}
