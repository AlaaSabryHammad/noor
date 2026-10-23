import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'service_widgets.dart';

const goldNisabGrams = 85.0, silverNisabGrams = 595.0, zakatRate = 0.025;

enum NisabBasis { gold, silver }

/// Inputs of a zakat calculation. All money in the user's own currency.
class ZakatInput {
  const ZakatInput({this.cash = 0, this.goldGrams = 0, this.silverGrams = 0, this.investments = 0, this.debts = 0, this.goldPrice = 0, this.silverPrice = 0, this.basis = NisabBasis.gold});
  final double cash, goldGrams, silverGrams, investments, debts, goldPrice, silverPrice;
  final NisabBasis basis;
}

class ZakatResult {
  const ZakatResult({required this.assets, required this.net, required this.nisab, required this.due, required this.priceMissing});
  final double assets, net, nisab, due;
  final bool priceMissing;
  bool get reachesNisab => nisab > 0 && net >= nisab;
}

/// Pure calculation: 2.5% of net wealth once it reaches the nisab.
ZakatResult calculateZakat(ZakatInput i) {
  final assets = i.cash + i.investments + i.goldGrams * i.goldPrice + i.silverGrams * i.silverPrice;
  final net = (assets - i.debts).clamp(0, double.infinity).toDouble();
  final nisab = i.basis == NisabBasis.gold ? goldNisabGrams * i.goldPrice : silverNisabGrams * i.silverPrice;
  final missing = nisab <= 0 || ((i.goldGrams > 0 && i.goldPrice <= 0) || (i.silverGrams > 0 && i.silverPrice <= 0));
  final due = nisab > 0 && net >= nisab ? net * zakatRate : 0.0;
  return ZakatResult(assets: assets, net: net, nisab: nisab, due: due, priceMissing: missing);
}

/// Accepts Arabic-Indic digits and the Arabic decimal/thousands separators.
double parseAmount(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final latin = s.split('').map((c) => ar.contains(c) ? '${ar.indexOf(c)}' : c).join().replaceAll('٫', '.').replaceAll('٬', '').replaceAll(',', '');
  return double.tryParse(latin) ?? 0;
}

class ZakatScreen extends ConsumerStatefulWidget {
  const ZakatScreen({super.key});
  @override
  ConsumerState<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends ConsumerState<ZakatScreen> {
  static const _fields = ['cash', 'investments', 'goldGrams', 'silverGrams', 'debts', 'goldPrice', 'silverPrice'];
  late final Map<String, TextEditingController> _c;
  NisabBasis _basis = NisabBasis.gold;

  @override
  void initState() {
    super.initState();
    final p = ref.read(sharedPreferencesProvider);
    // Prices are remembered; the rest is entered fresh each time.
    _c = {for (final f in _fields) f: TextEditingController(text: f.endsWith('Price') ? (p.getString('zakat.$f') ?? '') : '')};
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(String k) => parseAmount(_c[k]!.text);

  ZakatInput get _input => ZakatInput(
        cash: _v('cash'),
        investments: _v('investments'),
        goldGrams: _v('goldGrams'),
        silverGrams: _v('silverGrams'),
        debts: _v('debts'),
        goldPrice: _v('goldPrice'),
        silverPrice: _v('silverPrice'),
        basis: _basis,
      );

  String _fmt(double v) => NoorFormat.digits(context, v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2));

  Widget _field(String key, String ar, String en, {String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: _c[key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫٬]'))],
          onChanged: (_) {
            if (key.endsWith('Price')) ref.read(sharedPreferencesProvider).setString('zakat.$key', _c[key]!.text);
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: NoorFormat.tr(context, ar, en),
            hintText: hint,
            filled: true,
            fillColor: context.noor.surface,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.noor.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.noor.primary, width: 1.5)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final r = calculateZakat(_input);

    return ServiceScaffold(title: l.svcZakat, children: [
      HeroSurface(
        radius: 28,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: [
          Text(NoorFormat.tr(context, 'الزكاة المستحقة', 'Zakat due'), style: const TextStyle(fontSize: 12.5, color: NoorTokens.onHeroAccent, fontWeight: FontWeight.w600)),
          // The numerals face is Latin-only, so the big figure uses Western digits.
          Directionality(textDirection: TextDirection.ltr, child: Text(r.due.toStringAsFixed(r.due == r.due.roundToDouble() ? 0 : 2), style: NoorText.numerals(size: 40))),
          Text(
            r.priceMissing
                ? NoorFormat.tr(context, 'أدخل سعر جرام الذهب (أو الفضة) لحساب النصاب.', 'Enter the gold (or silver) price per gram to work out the nisab.')
                : (r.reachesNisab
                    ? NoorFormat.tr(context, 'بلغ صافي مالك النصاب (${_fmt(r.nisab)}) فتجب الزكاة بنسبة ٢٫٥٪.', 'Your net wealth reaches the nisab (${_fmt(r.nisab)}); zakat of 2.5% is due.')
                    : NoorFormat.tr(context, 'صافي مالك (${_fmt(r.net)}) دون النصاب (${_fmt(r.nisab)}) فلا زكاة عليك الآن.', 'Your net wealth (${_fmt(r.net)}) is below the nisab (${_fmt(r.nisab)}); no zakat is due now.')),
            style: const TextStyle(color: Color(0xE6FFFFFF), height: 1.7),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      SectionTitle(NoorFormat.tr(context, 'أسعار المعادن (للجرام الواحد)', 'Metal prices (per gram)')),
      const SizedBox(height: 10),
      _field('goldPrice', 'سعر جرام الذهب', 'Gold price per gram'),
      _field('silverPrice', 'سعر جرام الفضة', 'Silver price per gram'),
      NoorSegmented<NisabBasis>(
        values: NisabBasis.values,
        labels: [NoorFormat.tr(context, 'نصاب الذهب (٨٥ غ)', 'Gold nisab (85 g)'), NoorFormat.tr(context, 'نصاب الفضة (٥٩٥ غ)', 'Silver nisab (595 g)')],
        selected: _basis,
        onChanged: (v) => setState(() => _basis = v),
      ),
      const SizedBox(height: 16),
      SectionTitle(NoorFormat.tr(context, 'أموالك', 'Your wealth')),
      const SizedBox(height: 10),
      _field('cash', 'النقد والأرصدة', 'Cash and bank balances'),
      _field('investments', 'الأسهم وعروض التجارة', 'Investments and trade goods'),
      _field('goldGrams', 'الذهب (بالجرام)', 'Gold (grams)'),
      _field('silverGrams', 'الفضة (بالجرام)', 'Silver (grams)'),
      _field('debts', 'الديون المستحقة عليك الآن', 'Debts you owe now'),
      NoorCard(
        color: t.goldSoft,
        borderColor: t.goldLine,
        padding: const EdgeInsets.all(14),
        child: Text(
          NoorFormat.tr(context, 'تجب الزكاة في المال الذي بلغ النصاب وحال عليه الحول الهجري. هذه حاسبة تقريبية؛ للتفاصيل (كالمجوهرات والعقارات والديون المؤجلة) راجع أهل العلم.', 'Zakat is due on wealth that reaches the nisab and is held for a lunar year. This is an estimate; for details (jewellery, property, deferred debts) consult a scholar.'),
          style: TextStyle(fontSize: 12.5, height: 1.7, color: t.goldText),
        ),
      ),
    ]);
  }
}
