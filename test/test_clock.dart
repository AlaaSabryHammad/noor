/// Friday 23 Oct 2026, 10:42:18 in Dammam (UTC+3) — after sunrise, before
/// Jumu‘ah — as this machine's local time. Pinned as an instant so tests read
/// the same in any time zone (CI runs in UTC); it is Friday from UTC−7 to UTC+14.
final fridayMorning = DateTime.utc(2026, 10, 23, 7, 42, 18).toLocal();
