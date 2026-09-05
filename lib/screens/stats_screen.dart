import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ardoise_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'client_detail_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArdoiseProvider>();
    final top = p.topDebtors;
    final labels = p.topLabels;
    final days = p.last7Days;
    final maxDay = days.fold<int>(
        1, (m, d) => math.max(m, math.max(d.$2, d.$3)));

    return Column(
      children: [
        WaxHeader(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistiques',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                p.debtorsCount == 0
                    ? 'Personne ne vous doit rien !'
                    : 'Tu as ${Fmt.fcfa(p.totalOutstanding)} dehors chez ${p.debtorsCount} ${p.debtorsCount > 1 ? 'personnes' : 'personne'}.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (p.lateCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⚠ ${p.lateCount} en retard · ${Fmt.fcfa(p.lateAmount)}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  StatTile(
                    label: "Crédits aujourd'hui",
                    value: Fmt.fcfa(p.todayCredited),
                    icon: Icons.add_shopping_cart,
                    color: AppColors.deepOrange,
                  ),
                  StatTile(
                    label: "Encaissé aujourd'hui",
                    value: Fmt.fcfa(p.todayPaid),
                    icon: Icons.savings_outlined,
                    color: AppColors.green,
                  ),
                  StatTile(
                    label: 'Crédits ce mois',
                    value: Fmt.fcfa(p.monthCredited),
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.purple,
                  ),
                  StatTile(
                    label: 'Encaissé ce mois',
                    value: Fmt.fcfa(p.monthPaid),
                    icon: Icons.trending_up,
                    color: AppColors.teal,
                  ),
                ],
              ),
              const SectionTitle('7 derniers jours'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 130,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: days.map((d) {
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          _bar(d.$2, maxDay,
                                              AppColors.deepOrange),
                                          const SizedBox(width: 3),
                                          _bar(d.$3, maxDay, AppColors.green),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      Fmt.dayLabel(d.$1).replaceAll('.', ''),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.inkSoft,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legend(AppColors.deepOrange, 'Crédits'),
                          const SizedBox(width: 16),
                          _legend(AppColors.green, 'Paiements'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SectionTitle('Mode de paiement'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _MethodBar(
                      cash: p.cashTotal, momo: p.mobileMoneyTotal),
                ),
              ),
              if (top.isNotEmpty) ...[
                const SectionTitle('Plus grosses ardoises'),
                Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < top.length; i++)
                        ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ClientDetailScreen(
                                    clientId: top[i].client.id)),
                          ),
                          leading: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ClientAvatar(client: top[i].client, size: 42),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.ink,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          title: Text(top[i].client.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'Depuis ${Fmt.relativeDate(top[i].lastActivity).toLowerCase()}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: Text(
                            Fmt.fcfa(top[i].balance),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: p.isLate(top[i])
                                  ? AppColors.lateRed
                                  : AppColors.deepOrange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (labels.isNotEmpty) ...[
                const SectionTitle('Articles les plus pris à crédit'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: labels.map((l) {
                        final ratio = l.$2 / labels.first.$2;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(l.$1,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700))),
                                  Text(Fmt.fcfa(l.$2),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.inkSoft)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  backgroundColor: AppColors.cream,
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(int value, int max, Color color) {
    final h = max == 0 ? 0.0 : (value / max);
    return Expanded(
      child: Tooltip(
        message: Fmt.fcfa(value),
        child: FractionallySizedBox(
          heightFactor: value == 0 ? 0.04 : h.clamp(0.06, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: value == 0 ? color.withValues(alpha: 0.25) : color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
        ],
      );
}

class _MethodBar extends StatelessWidget {
  final int cash;
  final int momo;
  const _MethodBar({required this.cash, required this.momo});

  @override
  Widget build(BuildContext context) {
    final total = cash + momo;
    final cashRatio = total == 0 ? 0.5 : cash / total;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 18,
            child: Row(
              children: [
                Expanded(
                  flex: (cashRatio * 1000).round().clamp(1, 1000),
                  child: Container(color: AppColors.green),
                ),
                Expanded(
                  flex: ((1 - cashRatio) * 1000).round().clamp(1, 1000),
                  child: Container(color: AppColors.amber),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _item(Icons.payments_outlined, 'Espèces', cash,
                  AppColors.green),
            ),
            Expanded(
              child: _item(Icons.phone_iphone, 'Mobile Money', momo,
                  AppColors.amber),
            ),
          ],
        ),
      ],
    );
  }

  Widget _item(IconData icon, String label, int value, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.inkSoft)),
              Text(Fmt.fcfa(value),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      );
}
