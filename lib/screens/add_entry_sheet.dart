import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/models.dart';
import '../providers/ardoise_provider.dart';
import '../services/voice_parser.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/common.dart';

/// Ouvre la feuille d'ajout. [startListening] lance directement le micro.
Future<void> showAddEntrySheet(
  BuildContext context, {
  bool startListening = false,
  String? presetClientId,
  bool presetPayment = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: R.maxContentWidth),
    builder: (_) => AddEntrySheet(
      startListening: startListening,
      presetClientId: presetClientId,
      presetPayment: presetPayment,
    ),
  );
}

class AddEntrySheet extends StatefulWidget {
  final bool startListening;
  final String? presetClientId;
  final bool presetPayment;
  const AddEntrySheet({
    super.key,
    this.startListening = false,
    this.presetClientId,
    this.presetPayment = false,
  });

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  final _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;
  String _heard = '';
  String? _speechError;

  final _nameCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isPayment = false;
  PaymentMethod _method = PaymentMethod.cash;
  Client? _matchedClient;
  bool _saving = false;
  DateTime? _promiseDate;

  static const _examples = [
    '« Codjo, riz, 500 »',
    '« Afi a pris de l\'huile à 800 »',
    '« Rachid a payé 2000 »',
    '« Nadège, savon, mille deux cents »',
  ];

  @override
  void initState() {
    super.initState();
    _isPayment = widget.presetPayment;
    if (widget.presetClientId != null) {
      final c = context.read<ArdoiseProvider>().clientById(
        widget.presetClientId!,
      );
      if (c != null) {
        _matchedClient = c;
        _nameCtrl.text = c.name;
        _promiseDate = c.promiseDate;
      }
    }
    _nameCtrl.addListener(_onNameChanged);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _speechError = _humanError(e.errorMsg);
          });
        },
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'done' || s == 'notListening') {
            setState(() => _listening = false);
          }
        },
      );
      if (!mounted) return;
      setState(() => _speechAvailable = ok);
      if (ok && widget.startListening) _startListening();
      if (!ok) {
        _speechError = 'Micro indisponible ici. Saisissez à la main.';
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
        _speechError = 'Micro indisponible ici. Saisissez à la main.';
      });
    }
  }

  String _humanError(String code) {
    if (code.contains('permission') || code.contains('denied')) {
      return "Autorisez le micro dans les paramètres du téléphone.";
    }
    if (code.contains('no_match') || code.contains('speech_timeout')) {
      return "Je n'ai rien compris. Réessayez en parlant plus près.";
    }
    if (code.contains('network')) {
      return 'Reconnaissance hors ligne indisponible. Saisissez à la main.';
    }
    return 'Erreur micro. Saisissez à la main.';
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _listening = true;
      _heard = '';
      _speechError = null;
    });
    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: 'fr_FR',
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  void _onSpeechResult(SpeechRecognitionResult r) {
    setState(() => _heard = r.recognizedWords);
    if (r.finalResult) {
      _applyParse(r.recognizedWords);
      setState(() => _listening = false);
    }
  }

  void _applyParse(String text) {
    final res = VoiceParser.parse(text);
    final p = context.read<ArdoiseProvider>();
    setState(() {
      if (res.clientName != null) {
        _nameCtrl.text = res.clientName!;
        _matchedClient = p.findClientByName(res.clientName!);
        if (_matchedClient != null) _nameCtrl.text = _matchedClient!.name;
      }
      if (res.label != null) _labelCtrl.text = res.label!;
      if (res.amount != null) _amountCtrl.text = res.amount.toString();
      _isPayment = res.isPayment;
    });
    HapticFeedback.lightImpact();
  }

  void _onNameChanged() {
    final p = context.read<ArdoiseProvider>();
    final m = p.findClientByName(_nameCtrl.text);
    if (m?.id != _matchedClient?.id) {
      setState(() {
        _matchedClient = m;
        _promiseDate = m?.promiseDate;
      });
    }
  }

  Future<void> _pickPromise() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _promiseDate != null && _promiseDate!.isAfter(now)
          ? _promiseDate!
          : now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Il paie quand ?',
      confirmText: 'Valider',
      cancelText: 'Annuler',
    );
    if (picked != null) setState(() => _promiseDate = picked);
  }

  int get _amount =>
      int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && _amount > 0;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    final p = context.read<ArdoiseProvider>();
    Client client =
        _matchedClient ??
        await p.addClient(
          _nameCtrl.text.trim(),
          phone: _phoneCtrl.text,
          promiseDate: _promiseDate,
        );
    final viaVoice = _heard.isNotEmpty;
    if (_isPayment) {
      await p.addPayment(client.id, _amount, method: _method);
      // Si l'ardoise est soldée, la promesse n'a plus d'objet.
      if (p.summaryOf(client).balance <= 0 && client.promiseDate != null) {
        await p.setPromiseDate(client.id, null);
      }
    } else {
      await p.addCredit(
        client.id,
        _amount,
        label: _labelCtrl.text,
        viaVoice: viaVoice,
      );
      if (_matchedClient != null && _promiseDate != client.promiseDate) {
        await p.setPromiseDate(client.id, _promiseDate);
      }
    }
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    Navigator.pop(context);
    showToast(
      context,
      _isPayment
          ? '${client.name} a payé ${Fmt.fcfa(_amount)}'
          : '${Fmt.fcfa(_amount)} noté sur l\'ardoise de ${client.name}',
      color: _isPayment ? AppColors.green : AppColors.deepOrange,
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _nameCtrl.dispose();
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArdoiseProvider>();
    final isNewClient =
        _matchedClient == null && _nameCtrl.text.trim().isNotEmpty;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final hp = R.hPad(context) + 4;
    final short = R.isShort(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hp, 12, hp, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ---- Type ----
            _TypeToggle(
              isPayment: _isPayment,
              onChanged: (v) => setState(() => _isPayment = v),
            ),
            SizedBox(height: short ? 10 : 18),
            // ---- Micro ----
            _MicButton(
              listening: _listening,
              available: _speechAvailable,
              small: short,
              onTap: _listening ? _stopListening : _startListening,
            ),
            const SizedBox(height: 10),
            Text(
              _listening
                  ? (_heard.isEmpty ? 'Je vous écoute…' : _heard)
                  : (_heard.isNotEmpty
                        ? 'Entendu : « $_heard »'
                        : (_speechAvailable
                              ? 'Appuyez et dites par ex. ${_examples[DateTime.now().second % _examples.length]}'
                              : (_speechError ?? 'Micro indisponible'))),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _listening ? AppColors.deepOrange : AppColors.inkSoft,
                fontWeight: _listening ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (_speechError != null && _speechAvailable) ...[
              const SizedBox(height: 4),
              Text(
                _speechError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.lateRed, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou à la main',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 14),
            // ---- Client ----
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Client',
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: _matchedClient != null
                    ? const Icon(Icons.check_circle, color: AppColors.green)
                    : (isNewClient
                          ? const Icon(
                              Icons.person_add_alt_1,
                              color: AppColors.amber,
                            )
                          : null),
                helperText: _matchedClient != null
                    ? 'Client existant · doit ${Fmt.fcfa(p.summaryOf(_matchedClient!).balance)}'
                    : (isNewClient ? 'Nouveau client — sera créé' : null),
              ),
            ),
            if (p.clients.isNotEmpty && _matchedClient == null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: p.allSummaries.take(8).map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: ClientAvatar(client: s.client, size: 22),
                        label: Text(s.client.name),
                        backgroundColor: AppColors.cream,
                        onPressed: () {
                          setState(() {
                            _matchedClient = s.client;
                            _nameCtrl.text = s.client.name;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (isNewClient) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (pour les rappels SMS)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // ---- Article (crédit) ou mode (paiement) ----
            if (!_isPayment)
              TextField(
                controller: _labelCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Article (riz, huile, savon…)',
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _MethodChip(
                      label: 'Espèces',
                      icon: Icons.payments_outlined,
                      selected: _method == PaymentMethod.cash,
                      onTap: () => setState(() => _method = PaymentMethod.cash),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MethodChip(
                      label: 'Mobile Money',
                      icon: Icons.phone_iphone,
                      selected: _method == PaymentMethod.mobileMoney,
                      onTap: () =>
                          setState(() => _method = PaymentMethod.mobileMoney),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // ---- Montant ----
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                labelText: 'Montant',
                suffixText: 'FCFA',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [100, 200, 500, 1000, 2000, 5000].map((v) {
                return ActionChip(
                  label: Text(Fmt.number(v)),
                  backgroundColor: AppColors.cream,
                  onPressed: () => setState(() {
                    _amountCtrl.text = (_amount + v).toString();
                  }),
                );
              }).toList(),
            ),
            if (!_isPayment) ...[
              const SizedBox(height: 12),
              // ---- Date promise ----
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickPromise,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _promiseDate != null
                        ? AppColors.amber.withValues(alpha: 0.18)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _promiseDate != null
                          ? AppColors.amber
                          : const Color(0xFFF1DCCB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        color: _promiseDate != null
                            ? const Color(0xFFB57400)
                            : AppColors.inkSoft,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _promiseDate == null
                              ? 'Il paie quand ? (optionnel)'
                              : 'Promet de payer le ${Fmt.shortDate(_promiseDate!)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _promiseDate != null
                                ? const Color(0xFF6B4500)
                                : AppColors.inkSoft,
                          ),
                        ),
                      ),
                      if (_promiseDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _promiseDate = null),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.inkSoft,
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.inkSoft,
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _canSave && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: _isPayment
                    ? AppColors.green
                    : AppColors.orange,
              ),
              icon: Icon(_isPayment ? Icons.check_rounded : Icons.edit_note),
              label: Text(
                _isPayment
                    ? 'Enregistrer le paiement${_amount > 0 ? ' · ${Fmt.fcfa(_amount)}' : ''}'
                    : 'Noter sur l\'ardoise${_amount > 0 ? ' · ${Fmt.fcfa(_amount)}' : ''}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool isPayment;
  final ValueChanged<bool> onChanged;
  const _TypeToggle({required this.isPayment, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _seg(
            'Crédit (doit)',
            Icons.add_shopping_cart,
            !isPayment,
            AppColors.orange,
            () => onChanged(false),
          ),
          _seg(
            'Paiement (a payé)',
            Icons.check_circle_outline,
            isPayment,
            AppColors.green,
            () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _seg(
    String label,
    IconData icon,
    bool sel,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: sel ? Colors.white : AppColors.inkSoft,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: sel ? Colors.white : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  final bool listening;
  final bool available;
  final bool small;
  final VoidCallback onTap;
  const _MicButton({
    required this.listening,
    required this.available,
    required this.onTap,
    this.small = false,
  });

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.available ? AppColors.orange : Colors.grey;
    final box = widget.small ? 84.0 : 120.0;
    final core = widget.small ? 62.0 : 84.0;
    return Center(
      child: GestureDetector(
        onTap: widget.available ? widget.onTap : null,
        child: SizedBox(
          width: box,
          height: box,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.listening)
                    for (final k in [0.0, 0.5])
                      Builder(
                        builder: (_) {
                          final t = (_ctrl.value + k) % 1.0;
                          return Container(
                            width: core - 4 + (box - core + 4) * t,
                            height: core - 4 + (box - core + 4) * t,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.deepOrange.withValues(
                                alpha: (1 - t) * 0.35,
                              ),
                            ),
                          );
                        },
                      ),
                  Container(
                    width: core,
                    height: core,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.available
                          ? AppColors.headerGradient
                          : null,
                      color: widget.available ? null : Colors.grey.shade400,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: widget.small ? 30 : 40,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.green : const Color(0xFFF1DCCB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColors.green : AppColors.inkSoft),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.green : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
