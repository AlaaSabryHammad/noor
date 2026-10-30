import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'alert_sync.dart';
import 'domain/alert_models.dart';
import 'prayer_providers.dart';

/// What the system says about this app's alerts right now; read again when the app comes back to the front.
final alertHealthProvider = FutureProvider.autoDispose<AlertHealth>((ref) => ref.watch(alertDiagnosticsProvider).health());

/// Under the prayer times: the alert sound, a test alert, a check that the
/// system will really deliver the alerts, and help for phones that stop
/// background apps. Hidden where alerts are not supported.
class AlertSettingsCard extends ConsumerStatefulWidget {
  const AlertSettingsCard({super.key});
  @override
  ConsumerState<AlertSettingsCard> createState() => _AlertSettingsCardState();
}

class _AlertSettingsCardState extends ConsumerState<AlertSettingsCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(alertHealthProvider));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _test(AdhanSound sound) async {
    final l = AppLocalizations.of(context);
    final ok = await ref.read(alertDiagnosticsProvider).scheduleTest(
          sound: sound,
          title: l.adhanNotifTitle(l.dhuhr),
          body: NoorFormat.tr(context, 'تنبيه تجريبي', 'Test alert'),
          after: const Duration(seconds: 10),
        );
    if (!mounted) return;
    showNoorSnack(
      context,
      ok
          ? NoorFormat.tr(context, 'سيصلك تنبيه تجريبي بعد ١٠ ثوانٍ. يمكنك قفل الهاتف أو إغلاق التطبيق.', 'A test alert will arrive in 10 seconds. You can lock the phone or close the app.')
          : NoorFormat.tr(context, 'تعذّرت جدولة التنبيه. تحقق من إذن الإشعارات.', 'Could not schedule the alert. Check the notification permission.'),
    );
  }

  Future<void> _open(AlertSettingsPage page) async {
    await ref.read(alertDiagnosticsProvider).openSettings(page);
    // The person comes back through the lifecycle listener; also re-check now for screens that open as dialogs.
    ref.invalidate(alertHealthProvider);
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(alertHealthProvider).value;
    if (health == null || !health.supported) return const SizedBox.shrink();
    final t = context.noor;
    final sound = ref.watch(alertSoundProvider);
    final anyOn = ref.watch(prayerAlertsProvider).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: NoorCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          Row(spacing: 12, children: [
            const IconBadge(icon: Icons.notifications_active_outlined, gold: true, size: 40),
            Expanded(child: Text(NoorFormat.tr(context, 'صوت تنبيه الأذان', 'Adhan alert sound'), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))),
          ]),
          NoorSegmented<AdhanSound>(
            values: const [AdhanSound.adhan, AdhanSound.tone, AdhanSound.silent],
            labels: [NoorFormat.tr(context, 'الأذان', 'Adhan'), NoorFormat.tr(context, 'نغمة', 'Tone'), NoorFormat.tr(context, 'صامت', 'Silent')],
            selected: sound == AdhanSound.adhanSoft ? AdhanSound.adhan : sound,
            onChanged: (v) {
              // Tapping "Adhan" while it is already chosen must not undo the "follow silent mode" setting.
              if (v == AdhanSound.adhan && sound == AdhanSound.adhanSoft) return;
              ref.read(alertSoundProvider.notifier).select(v);
            },
          ),
          if (sound == AdhanSound.adhan || sound == AdhanSound.adhanSoft)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: sound == AdhanSound.adhan,
              onChanged: (loud) => ref.read(alertSoundProvider.notifier).select(loud ? AdhanSound.adhan : AdhanSound.adhanSoft),
              title: Text(NoorFormat.tr(context, 'يُسمَع حتى والهاتف على الصامت', 'Plays even when the phone is on silent'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                NoorFormat.tr(context, 'بصوت المنبّه، فارفع صوت المنبّه من إعدادات الهاتف إن كان منخفضًا.', 'Uses the alarm volume, so raise the alarm volume in the phone settings if it is low.'),
                style: TextStyle(height: 1.6, color: t.textSecondary, fontSize: 12.5),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => _test(sound),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text(NoorFormat.tr(context, 'جرّب التنبيه بعد ١٠ ثوانٍ', 'Test an alert in 10 seconds')),
          ),
          if (!health.notificationsAllowed)
            _Problem(
              text: NoorFormat.tr(context, 'الإشعارات متوقفة لنور، فلن يصلك الأذان.', 'Notifications are turned off for NOOR, so the adhan will not reach you.'),
              action: NoorFormat.tr(context, 'فتح الإعدادات', 'Open settings'),
              onTap: () => _open(AlertSettingsPage.notifications),
            ),
          if (!health.exactAlarmsAllowed)
            _Problem(
              text: NoorFormat.tr(context, 'التنبيه في الوقت بالضبط غير مسموح، وقد يتأخر الأذان دقائق.', 'Exact alarms are not allowed, so the adhan may arrive a few minutes late.'),
              action: NoorFormat.tr(context, 'السماح', 'Allow'),
              onTap: () => _open(AlertSettingsPage.exactAlarms),
            ),
          if (anyOn && health.pending == 0)
            _Problem(text: NoorFormat.tr(context, 'لا توجد تنبيهات مجدولة في النظام الآن. افتح هذه الشاشة بعد تفعيل الصلوات لتُجدول.', 'No alerts are scheduled in the system right now. Keep this screen open for a moment after turning prayers on.'))
          else if (health.pending > 0)
            Text(
              NoorFormat.tr(context, 'تنبيهات مجدولة في النظام: ${NoorFormat.digits(context, health.pending)}', 'Alerts scheduled in the system: ${health.pending}'),
              style: TextStyle(fontSize: 12.5, color: t.textSecondary),
            ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: t.primary,
              title: Text(NoorFormat.tr(context, 'لا يرنّ والتطبيق مغلق؟', 'Not ringing when the app is closed?'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              children: [
                Text(_tips(context, health.vendor), style: TextStyle(height: 1.75, color: t.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: () => _open(AlertSettingsPage.battery),
                  child: Text(NoorFormat.tr(context, 'فتح إعدادات التشغيل في الخلفية', 'Open background-launch settings')),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  static String _tips(BuildContext c, BatteryVendor v) {
    final steps = switch (v) {
      BatteryVendor.huawei || BatteryVendor.honor => NoorFormat.tr(
          c,
          'الإعدادات ← البطارية ← تشغيل التطبيقات ← نور ← أوقف «إدارة تلقائية»، ثم فعّل: التشغيل التلقائي، والتشغيل الثانوي، والتشغيل في الخلفية.',
          'Settings → Battery → App launch → NOOR → turn off “Manage automatically”, then enable Auto-launch, Secondary launch and Run in background.'),
      BatteryVendor.xiaomi => NoorFormat.tr(c, 'الأمان ← الأذونات ← التشغيل التلقائي ← فعّل نور، وفي إعدادات البطارية اختر «بلا قيود».', 'Security → Permissions → Autostart → enable NOOR, and set its battery saver to “No restrictions”.'),
      BatteryVendor.oppo => NoorFormat.tr(c, 'اسمح لنور بالتشغيل التلقائي وبالنشاط في الخلفية، ولا تقيّد استهلاكه للبطارية.', 'Allow NOOR to auto-start and run in the background, and do not restrict its battery use.'),
      BatteryVendor.vivo => NoorFormat.tr(c, 'اسمح لنور بالتشغيل التلقائي وبالعمل في الخلفية من إعدادات البطارية.', 'Allow NOOR to auto-start and to run in the background in the battery settings.'),
      BatteryVendor.samsung => NoorFormat.tr(c, 'الإعدادات ← البطارية ← حدود استخدام الخلفية، وأزل نور من «التطبيقات النائمة».', 'Settings → Battery → Background usage limits, and remove NOOR from “Sleeping apps”.'),
      BatteryVendor.other => NoorFormat.tr(c, 'اسمح لنور بالعمل في الخلفية، ولا تقيّد استهلاكه للبطارية من إعدادات الهاتف.', 'Allow NOOR to run in the background and do not restrict its battery use in the phone settings.'),
    };
    return '$steps ${NoorFormat.tr(c, 'ولا تُغلق التطبيق بالقوة من قائمة التطبيقات الأخيرة.', 'Do not force-close the app from the recent apps list.')}';
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.text, this.action, this.onTap});
  final String text;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: t.goldSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.goldLine)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: t.goldText),
          Expanded(child: Text(text, style: TextStyle(height: 1.6, color: t.goldText, fontSize: 13))),
        ]),
        if (action != null) Align(alignment: AlignmentDirectional.centerEnd, child: TextButton(onPressed: onTap, child: Text(action!))),
      ]),
    );
  }
}
