import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ardoise_provider.dart';
import '../services/sms_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/common.dart';
import 'client_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenStats;
  const HomeScreen({super.key, required this.onOpenStats});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArdoiseProvider>();
    final items = p.filteredSummaries;
    final upcoming = p.upcomingPromises;
    final hp = R.hPad(context);
    final wide = R.isWide(context);

    return Column(
      children: [
        _Header(onOpenStats: onOpenStats),
        Expanded(
          child: MaxWidth(
            max: wide ? 900 : R.maxContentWidth,
            child: items.isEmpty && upcoming.isEmpty
                ? _emptyForFilter(p)
                : CustomScrollView(
                    slivers: [
                      if (upcoming.isNotEmpty && p.filter == ClientFilter.all)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hp, 12, hp, 0),
                          sliver: SliverToBoxAdapter(
                            child: _PromiseBanner(items: upcoming),
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hp, 10, hp, 130),
                        sliver: wide
                            ? SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 440,
                                      mainAxisExtent: 84,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => ClientCard(
                                    summary: items[i],
                                    isLate: p.isLate(items[i]),
                                  ),
                                  childCount: items.length,
                                ),
                              )
                            : SliverList.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) => ClientCard(
                                  summary: items[i],
                                  isLate: p.isLate(items[i]),
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _emptyForFilter(ArdoiseProvider p) {
    switch (p.filter) {
      case ClientFilter.today:
        return const EmptyState(
          icon: Icons.today_rounded,
          title: "Rien aujourd'hui",
          message: "Aucun crédit ni paiement noté aujourd'hui.",
        );
      case ClientFilter.late:
        return const EmptyState(
          icon: Icons.celebration_rounded,
          title: 'Aucun retard',
          message: 'Tous vos clients sont dans les délais. Bravo !',
        );
      case ClientFilter.paid:
        return const EmptyState(
          icon: Icons.check_circle_outline,
          title: 'Personne à zéro',
          message: "Aucun client n'a encore soldé son ardoise.",
        );
      case ClientFilter.all:
        return EmptyState(
          icon: Icons.people_outline,
          title: p.search.isNotEmpty ? 'Aucun résultat' : 'Aucun client',
          message: p.search.isNotEmpty
              ? 'Essayez un autre nom.'
              : 'Appuyez sur le micro et dites :\n« Codjo, riz, 500 »',
        );
    }
  }
}

/// Bannière "promesses de remboursement aujourd'hui / demain".
class _PromiseBanner extends StatelessWidget {
  final List<ClientSummary> items;
  const _PromiseBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    final today = items.where((s) => s.daysToPromise == 0).toList();
    final tomorrow = items.where((s) => s.daysToPromise == 1).toList();
    String text;
    if (today.isNotEmpty && tomorrow.isNotEmpty) {
      text =
          "${_names(today)} ${today.length > 1 ? 'ont' : 'a'} promis de payer aujourd'hui · ${_names(tomorrow)} demain";
    } else if (today.isNotEmpty) {
      text =
          "${_names(today)} ${today.length > 1 ? 'ont' : 'a'} promis de payer aujourd'hui";
    } else {
      text =
          '${_names(tomorrow)} ${tomorrow.length > 1 ? 'ont' : 'a'} promis de payer demain';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: Color(0xFFB57400)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF6B4500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _names(List<ClientSummary> l) =>
      l.map((s) => s.client.name).join(', ');
}

class _Header extends StatelessWidget {
  final VoidCallback onOpenStats;
  const _Header({required this.onOpenStats});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArdoiseProvider>();
    final profile = p.profile;
    final owner = profile.ownerName.isEmpty ? 'Boutiquier' : profile.ownerName;
    final shop = profile.shopName.isEmpty ? 'Ma boutique' : profile.shopName;
    final compact = R.isCompact(context);
    final short = R.isShort(context);
    final hp = R.hPad(context);

    return WaxHeader(
      padding: EdgeInsets.fromLTRB(hp, short ? 4 : 8, hp, short ? 12 : 18),
      child: MaxWidth(
        max: R.isWide(context) ? 900 : R.maxContentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Profil (style 1) -----
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openSettings(context),
                  child: Container(
                    width: compact ? 42 : 48,
                    height: compact ? 42 : 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      owner.isNotEmpty ? owner[0].toUpperCase() : 'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Fmt.greeting()}, $owner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: R.sp(context, 18),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              shop,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: short ? 10 : 16),
            // ----- Total dehors -----
            GestureDetector(
              onTap: onOpenStats,
              child: Container(
                padding: EdgeInsets.all(compact ? 14 : 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL DEHORS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${Fmt.number(p.totalOutstanding)} FCFA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: R.sp(context, 34),
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.debtorsCount == 0
                                ? 'Personne ne vous doit rien'
                                : 'chez ${p.debtorsCount} ${p.debtorsCount > 1 ? 'personnes' : 'personne'}'
                                      '${p.lateCount > 0 ? ' · ${p.lateCount} en retard' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: short ? 10 : 14),
            // ----- Recherche + Filtres (côte à côte sur écran large) -----
            LayoutBuilder(
              builder: (context, c) {
                final search = TextField(
                  onChanged: p.setSearch,
                  style: const TextStyle(color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Chercher un client…',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.inkSoft,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );
                final filters = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip('Tous', ClientFilter.all, p.clients.length),
                      const SizedBox(width: 8),
                      _FilterChip("Aujourd'hui", ClientFilter.today, null),
                      const SizedBox(width: 8),
                      _FilterChip(
                        'En retard',
                        ClientFilter.late,
                        p.lateCount,
                        badgeColor: AppColors.lateRed,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip('Payé', ClientFilter.paid, null),
                    ],
                  ),
                );
                if (c.maxWidth >= 620) {
                  return Row(
                    children: [
                      Expanded(flex: 2, child: search),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: filters),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [search, const SizedBox(height: 12), filters],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final ClientFilter value;
  final int? count;
  final Color? badgeColor;
  const _FilterChip(this.label, this.value, this.count, {this.badgeColor});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArdoiseProvider>();
    final selected = p.filter == value;
    return GestureDetector(
      onTap: () => p.setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.deepOrange : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color:
                      badgeColor ??
                      (selected ? AppColors.orange : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: badgeColor != null
                        ? Colors.white
                        : (selected ? Colors.white : AppColors.deepOrange),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carte client : avatar coloré, nom + DATE à côté, promesse, montant, rappel.
class ClientCard extends StatelessWidget {
  final ClientSummary summary;
  final bool isLate;
  const ClientCard({super.key, required this.summary, required this.isLate});

  @override
  Widget build(BuildContext context) {
    final c = summary.client;
    final balance = summary.balance;
    final settled = balance <= 0;
    final compact = R.isCompact(context);
    final promise = summary.promiseDate;
    final hasPromise = promise != null && !settled;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: c.id)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 14,
            12,
            compact ? 8 : 12,
            12,
          ),
          child: Row(
            children: [
              ClientAvatar(client: c, size: compact ? 42 : 50),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom + date (Wrap pour passer à la ligne si trop étroit)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: R.sp(context, 16),
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        _DateBadge(
                          icon: isLate && !hasPromise
                              ? Icons.warning_amber_rounded
                              : Icons.schedule,
                          text: Fmt.relativeDate(summary.lastActivity),
                          color: isLate && !hasPromise
                              ? AppColors.lateRed
                              : AppColors.inkSoft,
                          bg: isLate && !hasPromise
                              ? AppColors.lateRed.withValues(alpha: 0.12)
                              : AppColors.cream,
                        ),
                        if (hasPromise)
                          _DateBadge(
                            icon: isLate
                                ? Icons.warning_amber_rounded
                                : Icons.event_available_rounded,
                            text: Fmt.promiseLabel(promise),
                            color: isLate
                                ? AppColors.lateRed
                                : const Color(0xFFB57400),
                            bg: isLate
                                ? AppColors.lateRed.withValues(alpha: 0.12)
                                : AppColors.amber.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    settled ? 'Soldé' : Fmt.fcfa(balance),
                    style: TextStyle(
                      fontSize: R.sp(context, 16),
                      fontWeight: FontWeight.w900,
                      color: settled
                          ? AppColors.green
                          : (isLate ? AppColors.lateRed : AppColors.deepOrange),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!settled)
                    _ReminderButton(summary: summary)
                  else
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 20,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final c = summary.client;
    final parts = <String>[];
    if (c.phone.isNotEmpty) parts.add(c.phone);
    if (summary.lastPaymentDate != null) {
      parts.add(
        'Payé ${Fmt.relativeDate(summary.lastPaymentDate).toLowerCase()}',
      );
    } else if (summary.balance > 0) {
      parts.add('Aucun paiement');
    }
    return parts.isEmpty ? 'Pas de téléphone' : parts.join(' · ');
  }
}

class _DateBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;
  const _DateBadge({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderButton extends StatelessWidget {
  final ClientSummary summary;
  const _ReminderButton({required this.summary});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ArdoiseProvider>();
    final hasPhone = summary.client.phone.trim().isNotEmpty;
    return GestureDetector(
      onTap: () async {
        if (!hasPhone) {
          showToast(
            context,
            'Ajoutez un numéro pour envoyer un rappel.',
            color: AppColors.lateRed,
          );
          return;
        }
        final ok = await SmsService.sendReminder(
          client: summary.client,
          balance: summary.balance,
          profile: p.profile,
        );
        if (!ok && context.mounted) {
          showToast(context, "Impossible d'ouvrir l'application SMS.");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: hasPhone
              ? AppColors.teal.withValues(alpha: 0.14)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sms_outlined,
              size: 13,
              color: hasPhone ? AppColors.teal : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Rappel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: hasPhone ? AppColors.teal : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
