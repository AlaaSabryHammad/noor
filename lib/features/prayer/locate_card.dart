import 'package:flutter/material.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import 'location_sheet.dart';

/// Shown while times are for the Dammam default: nothing picked, location not allowed.
class LocateCard extends StatelessWidget {
  const LocateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return NoorCard(
      color: t.goldSoft,
      borderColor: t.goldLine,
      padding: const EdgeInsets.all(14),
      onTap: () => showLocationSheet(context),
      // Text above, button below: side by side they overflow on a narrow phone with large text.
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
          Icon(Icons.location_searching_rounded, color: t.goldText),
          Expanded(
            child: Text(
              NoorFormat.tr(context, 'المواقيت الآن للدمام افتراضيًا. حدّد موقعك لمواقيت دقيقة لمدينتك.', 'Times are for Dammam by default. Set your location for exact times in your city.'),
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
        ]),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: NoorPrimaryButton(label: NoorFormat.tr(context, 'حدّد موقعي', 'Set location'), soft: true, onPressed: () => showLocationSheet(context)),
        ),
      ]),
    );
  }
}
