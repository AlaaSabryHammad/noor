"""Builds assets/data/spotlights.json: seasonal "spotlights" (إضاءات).

Each spotlight gathers ayahs, hadith and short guidance around a season of
the Hijri year (Ramadan, the ten days of Dhul-Hijjah, Muharram, the white
days …) and links into the app's own sections. Outside every season the
year-round topics rotate weekly. Quranic text is copied from
assets/data/quran by tool/quran_quote.py; hadith cite collection and number.
Have the texts reviewed by a qualified scholar before a public release.

  python -I tool/build_spotlights.py .
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from quran_quote import H, P, Quran  # noqa: E402

root = sys.argv[1] if len(sys.argv) > 1 else "."
A = Quran(root).A


def act(route, ar, en):
    return {"route": route, "labelAr": ar, "labelEn": en}


def spot(id, title, summary, seasons, blocks, actions):
    """`seasons`: [month, fromDay, toDay] in the Hijri calendar (month 0 = every month); [] = year-round."""
    return {"id": id, "titleAr": title[0], "titleEn": title[1], "summaryAr": summary[0], "summaryEn": summary[1], "seasons": seasons, "blocks": blocks, "actions": actions}


# Listed by priority: the first one in season is shown on the home screen.
SPOTLIGHTS = [
    spot(
        "last-ten", ("العشر الأواخر وليلة القدر", "The last ten nights"),
        ("أفضل ليالي العام، وفيها ليلة خير من ألف شهر.", "The best nights of the year, with a night better than a thousand months."),
        [[9, 20, 30]],
        [
            P("كان النبي ﷺ يخصّ العشر الأواخر من رمضان بمزيد من الاجتهاد: يحيي الليل، ويوقظ أهله، ويعتكف في المسجد، يلتمس ليلة القدر.", "The Prophet ﷺ gave the last ten nights of Ramadan extra devotion: he spent the nights in worship, woke his family and secluded himself in the mosque, seeking Laylat al-Qadr."),
            A(97, 1, 5),
            H("«كان رسولُ الله ﷺ يجتهدُ في العشرِ الأواخرِ ما لا يجتهدُ في غيرِه»", "“The Messenger of Allah ﷺ would strive in the last ten nights more than at any other time.”", "رواه مسلم (1175)", "Muslim 1175"),
            H("«مَن قام ليلةَ القدرِ إيمانًا واحتسابًا غُفِر له ما تقدّم من ذنبِه»", "“Whoever stands in prayer on Laylat al-Qadr out of faith and hoping for reward will have his past sins forgiven.”", "متفق عليه: البخاري (1901) ومسلم (760)", "al-Bukhari 1901, Muslim 760"),
            H("قالت عائشة رضي الله عنها: يا رسولَ الله، أرأيتَ إن علمتُ أيُّ ليلةٍ ليلةُ القدر، ما أقولُ فيها؟ قال: «قولي: اللهمَّ إنك عفوٌّ تحبُّ العفوَ فاعفُ عنّي»", "‘A’ishah asked: “O Messenger of Allah, if I knew which night is Laylat al-Qadr, what should I say in it?” He said: “Say: O Allah, You are Pardoning and love to pardon, so pardon me.”", "رواه الترمذي (3513) وابن ماجه (3850)", "at-Tirmidhi 3513, Ibn Majah 3850"),
        ],
        [act("/quran/reader/97", "اقرأ سورة القدر", "Read Surat al-Qadr"), act("/ramadan", "متابعة رمضان", "Ramadan tracker"), act("/tasbeeh", "المسبحة", "Tasbeeh")],
    ),
    spot(
        "ramadan", ("شهر رمضان", "The month of Ramadan"),
        ("شهر الصيام والقيام والقرآن.", "The month of fasting, night prayer and the Quran."),
        [[9, 1, 19]],
        [
            P("رمضان موسم يتضاعف فيه الأجر، فاجعل لك فيه وردًا ثابتًا من القرآن، وحافظ على التراويح، وأكثر من الصدقة والدعاء عند الفطر.", "Ramadan is a season of multiplied reward: keep a fixed daily portion of Quran, hold on to tarawih, and give charity and make du‘a at the time of breaking the fast."),
            A(2, 183),
            H("«مَن صام رمضانَ إيمانًا واحتسابًا غُفِر له ما تقدّم من ذنبِه»", "“Whoever fasts Ramadan out of faith and hoping for reward will have his past sins forgiven.”", "متفق عليه: البخاري (38) ومسلم (760)", "al-Bukhari 38, Muslim 760"),
            H("«مَن قام رمضانَ إيمانًا واحتسابًا غُفِر له ما تقدّم من ذنبِه»", "“Whoever stands in prayer during Ramadan out of faith and hoping for reward will have his past sins forgiven.”", "متفق عليه: البخاري (37) ومسلم (759)", "al-Bukhari 37, Muslim 759"),
        ],
        [act("/ramadan", "متابعة رمضان", "Ramadan tracker"), act("/khutab/ramadan", "خطبة استقبال رمضان", "Ramadan khutbah"), act("/quran", "ختمة القرآن", "Quran khatma")],
    ),
    spot(
        "shawwal", ("ستٌّ من شوال", "Six days of Shawwal"),
        ("أتبِع رمضان بستٍّ من شوال يكن كصيام الدهر.", "Follow Ramadan with six days of Shawwal for the reward of a lifetime of fasting."),
        [[10, 1, 30]],
        [
            P("بعد العيد يُستحب صيام ستة أيام من شوال، متتابعةً أو متفرقة. ومن كان عليه قضاء من رمضان فالأولى عند كثير من العلماء أن يبدأ بالقضاء.", "After Eid it is recommended to fast six days of Shawwal, together or apart. Whoever owes days from Ramadan is advised by many scholars to make them up first."),
            H("«مَن صام رمضانَ ثم أتبعه ستًّا من شوّال كان كصيامِ الدهر»", "“Whoever fasts Ramadan and follows it with six days of Shawwal, it is as if he fasted for a lifetime.”", "رواه مسلم (1164)", "Muslim 1164"),
        ],
        [act("/qada", "متتبّع القضاء", "Make-up tracker"), act("/planner", "مخطط العبادات", "Worship planner")],
    ),
    spot(
        "dhulhijjah", ("عشر ذي الحجة ويوم عرفة", "The ten days of Dhul-Hijjah"),
        ("أحبّ الأيام إلى الله للعمل الصالح، وفيها يوم عرفة.", "The days most beloved to Allah for good deeds, with the Day of Arafah."),
        [[11, 25, 30], [12, 1, 13]],
        [
            A(89, 1, 2),
            H("«ما مِن أيامٍ العملُ الصالحُ فيها أحبُّ إلى اللهِ من هذه الأيام» يعني أيامَ العشر، قالوا: يا رسولَ الله، ولا الجهادُ في سبيلِ الله؟ قال: «ولا الجهادُ في سبيلِ الله، إلا رجلٌ خرج بنفسِه ومالِه فلم يرجعْ من ذلك بشيء»", "“There are no days in which righteous deeds are more beloved to Allah than these days,” meaning the ten days. They said: “Not even jihad in the path of Allah?” He said: “Not even jihad in the path of Allah, except a man who went out with his life and his wealth and returned with nothing of it.”", "رواه أبو داود (2438)، وأصله في البخاري (969)", "Abu Dawud 2438; its origin is in al-Bukhari 969"),
            H("«صيامُ يومِ عرفة، أحتسبُ على اللهِ أن يكفِّرَ السنةَ التي قبلَه والسنةَ التي بعدَه»", "“Fasting the Day of Arafah, I hope from Allah that it will expiate the year before it and the year after it.”", "رواه مسلم (1162)", "Muslim 1162"),
            H("«خيرُ الدعاءِ دعاءُ يومِ عرفة، وخيرُ ما قلتُ أنا والنبيّون من قبلي: لا إله إلا اللهُ وحدَه لا شريكَ له، له الملكُ وله الحمدُ وهو على كلِّ شيءٍ قدير»", "“The best supplication is the supplication of the Day of Arafah, and the best of what I and the prophets before me have said is: there is no god but Allah alone, without partner; His is the dominion and His the praise, and He has power over all things.”", "رواه الترمذي (3585)", "at-Tirmidhi 3585"),
        ],
        [act("/khutab/dhulhijjah", "خطبة عشر ذي الحجة", "Dhul-Hijjah khutbah"), act("/hajj", "دليل الحج والعمرة", "Hajj & Umrah guide"), act("/tasbeeh", "التكبير والتهليل", "Takbir and tahlil")],
    ),
    spot(
        "muharram", ("شهر الله المحرّم وعاشوراء", "Muharram and Ashura"),
        ("أفضل الصيام بعد رمضان، وصيام عاشوراء يكفّر سنة.", "The best fasting after Ramadan; fasting Ashura expiates a year."),
        [[1, 1, 10]],
        [
            P("المحرّم أول شهور السنة الهجرية وأحد الأشهر الحرم، ويُستحب الإكثار فيه من الصيام، وآكده يوم عاشوراء (العاشر)، ويُستحب أن يُصام معه التاسع.", "Muharram opens the Hijri year and is one of the sacred months. Fasting in it is encouraged, above all ‘Ashura (the tenth), together with the ninth."),
            H("«أفضلُ الصيامِ بعد رمضانَ شهرُ اللهِ المحرّم، وأفضلُ الصلاةِ بعد الفريضةِ صلاةُ الليل»", "“The best fasting after Ramadan is in Allah’s month of Muharram, and the best prayer after the obligatory prayer is the night prayer.”", "رواه مسلم (1163)", "Muslim 1163"),
            H("«صيامُ يومِ عاشوراء، أحتسبُ على اللهِ أن يكفِّرَ السنةَ التي قبلَه»", "“Fasting the day of ‘Ashura, I hope from Allah that it will expiate the year before it.”", "رواه مسلم (1162)", "Muslim 1162"),
            H("«لئن بقيتُ إلى قابلٍ لأصومنَّ التاسع»", "“If I live until next year, I will fast the ninth.”", "رواه مسلم (1134)", "Muslim 1134"),
        ],
        [act("/calendar", "التقويم الهجري", "Hijri calendar"), act("/planner", "مخطط العبادات", "Worship planner")],
    ),
    spot(
        "shaban", ("شعبان: تهيئةٌ لرمضان", "Sha‘ban: preparing for Ramadan"),
        ("شهرٌ تُرفع فيه الأعمال، وموسم لقضاء ما فات من الصيام.", "A month in which deeds are raised, and the time to make up missed fasts."),
        [[8, 1, 30]],
        [
            H("قالت عائشة رضي الله عنها: «ما رأيتُ رسولَ الله ﷺ استكمل صيامَ شهرٍ إلا رمضان، وما رأيتُه أكثرَ صيامًا منه في شعبان»", "‘A’ishah said: “I never saw the Messenger of Allah ﷺ fast a complete month except Ramadan, and I never saw him fast more in any month than in Sha‘ban.”", "متفق عليه: البخاري (1969) ومسلم (1156)", "al-Bukhari 1969, Muslim 1156"),
            H("«ذلك شهرٌ يغفلُ الناسُ عنه بين رجبٍ ورمضان، وهو شهرٌ تُرفعُ فيه الأعمالُ إلى ربِّ العالمين، فأحبُّ أن يُرفعَ عملي وأنا صائم»", "“That is a month people neglect, between Rajab and Ramadan. It is a month in which deeds are raised to the Lord of the worlds, and I love for my deeds to be raised while I am fasting.”", "رواه النسائي (2357)", "an-Nasa’i 2357"),
            H("قالت عائشة رضي الله عنها: «كان يكونُ عليَّ الصومُ من رمضان، فما أستطيعُ أن أقضيَه إلا في شعبان»", "‘A’ishah said: “I would owe fasts from Ramadan and could not make them up except in Sha‘ban.”", "متفق عليه: البخاري (1950) ومسلم (1146)", "al-Bukhari 1950, Muslim 1146"),
            P("فاقضِ ما عليك من صيام قبل دخول رمضان، وابدأ وردك من القرآن من الآن.", "Make up any fasts you owe before Ramadan arrives, and begin your daily Quran portion now."),
        ],
        [act("/qada", "متتبّع القضاء", "Make-up tracker"), act("/khutab/ramadan", "خطبة استقبال رمضان", "Ramadan khutbah"), act("/ramadan", "رمضان", "Ramadan")],
    ),
    spot(
        "sacred-months", ("الأشهر الحُرُم", "The sacred months"),
        ("ذو القعدة وذو الحجة والمحرّم ورجب: يعظُم فيها الذنب والأجر.", "Dhul-Qa‘dah, Dhul-Hijjah, Muharram and Rajab: sins and good deeds weigh more."),
        [[7, 1, 30], [11, 1, 24], [12, 14, 30], [1, 11, 30]],
        [
            A(9, 36),
            H("«إنّ الزمانَ قد استدار كهيئتِه يومَ خلق اللهُ السماواتِ والأرض، السنةُ اثنا عشرَ شهرًا، منها أربعةٌ حُرُم: ثلاثٌ متوالياتٌ: ذو القعدة وذو الحجة والمحرّم، ورجبُ مُضَرَ الذي بين جمادى وشعبان»", "“Time has come round to its form on the day Allah created the heavens and the earth. The year is twelve months, four of them sacred: three in succession — Dhul-Qa‘dah, Dhul-Hijjah and Muharram — and the Rajab of Mudar, between Jumada and Sha‘ban.”", "متفق عليه: البخاري (3197) ومسلم (1679)", "al-Bukhari 3197, Muslim 1679"),
            P("قال المفسرون في قوله تعالى: ﴿فلا تظلموا فيهن أنفسكم﴾: إن الذنب فيها أعظم، كما أن العمل الصالح فيها أعظم أجرًا. ولم يثبت في تخصيص رجب بصلاة أو صيام معيّن حديث صحيح، فيُكتفى بالطاعات المشروعة عامة.", "Commentators say of “so do not wrong yourselves during them” that sins in these months are graver, just as good deeds carry greater reward. No authentic hadith singles out Rajab for a particular prayer or fast, so the usual acts of worship suffice."),
        ],
        [act("/calendar", "التقويم الهجري", "Hijri calendar"), act("/khutab/taqwa", "خطبة التقوى", "Khutbah on taqwa")],
    ),
    spot(
        "white-days", ("الأيام البيض", "The white days"),
        ("صيام ١٣ و١٤ و١٥ من كل شهر هجري كصيام الدهر.", "Fasting the 13th, 14th and 15th of each Hijri month equals a lifetime of fasting."),
        [[0, 11, 15]],
        [
            H("«يا أبا ذرّ، إذا صمتَ من الشهرِ ثلاثةَ أيام فصُمْ ثلاثَ عشرة، وأربعَ عشرة، وخمسَ عشرة»", "“O Abu Dharr, if you fast three days of the month, fast the thirteenth, fourteenth and fifteenth.”", "رواه الترمذي (761) والنسائي (2424)", "at-Tirmidhi 761, an-Nasa’i 2424"),
            H("«صومُ ثلاثةِ أيامٍ من كلِّ شهرٍ صومُ الدهرِ كلِّه»", "“Fasting three days of every month is like fasting for a lifetime.”", "متفق عليه: البخاري (1979) ومسلم (1159)", "al-Bukhari 1979, Muslim 1159"),
            P("سُمّيت بيضًا لابيضاض لياليها بالقمر. انظر تواريخها في التقويم الهجري، وتذكّر أن تعديل اليوم الهجري متاح في الإعدادات.", "They are called white for their moonlit nights. See their dates in the Hijri calendar; the Hijri day can be adjusted in Settings."),
        ],
        [act("/calendar", "التقويم الهجري", "Hijri calendar"), act("/planner", "مخطط العبادات", "Worship planner")],
    ),
    # Year-round topics, rotating weekly when no season applies.
    spot(
        "salawat", ("الصلاة على النبي ﷺ", "Blessings on the Prophet ﷺ"),
        ("صلاةٌ واحدة يُصلّي الله عليك بها عشرًا.", "One blessing from you, ten from Allah."),
        [],
        [
            A(33, 56),
            H("«مَن صلّى عليَّ صلاةً صلّى اللهُ عليه بها عشرًا»", "“Whoever sends one blessing upon me, Allah sends ten blessings upon him.”", "رواه مسلم (408)", "Muslim 408"),
            H("«البخيلُ مَن ذُكِرتُ عنده فلم يُصلِّ عليَّ»", "“The miser is the one in whose presence I am mentioned and he does not send blessings upon me.”", "رواه الترمذي (3546)", "at-Tirmidhi 3546"),
            P("أكثِر منها يوم الجمعة وليلتها، وعند ذكره ﷺ، وفي التشهد، وبعد الأذان.", "Send them often on Friday and its night, whenever he ﷺ is mentioned, in the tashahhud and after the adhan."),
        ],
        [act("/tasbeeh", "المسبحة", "Tasbeeh"), act("/khutab/jumuah", "خطبة يوم الجمعة", "Khutbah on Friday")],
    ),
    spot(
        "istighfar", ("الاستغفار", "Seeking forgiveness"),
        ("بابٌ من الرحمة: يمحو الذنب ويجلب الرزق.", "A door of mercy: it erases sins and brings provision."),
        [],
        [
            A(71, 10, 12),
            H("«واللهِ إني لأستغفرُ اللهَ وأتوبُ إليه في اليومِ أكثرَ من سبعين مرة»", "“By Allah, I seek Allah’s forgiveness and turn to Him in repentance more than seventy times a day.”", "رواه البخاري (6307)", "al-Bukhari 6307"),
            H("«سيّدُ الاستغفارِ أن تقول: اللهمَّ أنت ربي لا إله إلا أنت، خلقتني وأنا عبدُك، وأنا على عهدِك ووعدِك ما استطعت، أعوذُ بك من شرِّ ما صنعت، أبوءُ لك بنعمتِك عليَّ، وأبوءُ لك بذنبي فاغفرْ لي، فإنه لا يغفرُ الذنوبَ إلا أنت»", "“The master of seeking forgiveness is to say: O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as far as I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You.”", "رواه البخاري (6306)", "al-Bukhari 6306"),
        ],
        [act("/tasbeeh", "المسبحة", "Tasbeeh"), act("/adhkar/session/morning", "أذكار الصباح", "Morning adhkar"), act("/khutab/repentance", "خطبة التوبة", "Khutbah on repentance")],
    ),
    spot(
        "dhikr", ("ذكر الله", "Remembering Allah"),
        ("حياة القلوب وطمأنينتها.", "The life and calm of the heart."),
        [],
        [
            A(13, 28),
            A(33, 41, 42),
            H("«مَثَلُ الذي يذكرُ ربَّه والذي لا يذكرُ ربَّه مَثَلُ الحيِّ والميّت»", "“The likeness of one who remembers his Lord and one who does not is that of the living and the dead.”", "رواه البخاري (6407)", "al-Bukhari 6407"),
            H("«كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن: سبحان اللهِ وبحمدِه، سبحان اللهِ العظيم»", "“Two phrases are light on the tongue, heavy on the scale and beloved to the Most Merciful: Glory be to Allah and praise be to Him; glory be to Allah the Almighty.”", "متفق عليه: البخاري (6406) ومسلم (2694)", "al-Bukhari 6406, Muslim 2694"),
        ],
        [act("/tasbeeh", "المسبحة", "Tasbeeh"), act("/adhkar", "الأذكار", "Adhkar"), act("/hisn", "حصن المسلم", "Hisn al-Muslim")],
    ),
]

ids = set()
for s in SPOTLIGHTS:
    assert s["id"] not in ids, s["id"]
    ids.add(s["id"])
    for b in s["blocks"]:
        assert b["ar"] and b["en"], (s["id"], b)
    for m, a, z in s["seasons"]:
        assert 0 <= m <= 12 and 1 <= a <= z <= 30, s["id"]

with open(f"{root}/assets/data/spotlights.json", "w", encoding="utf-8") as f:
    json.dump({"_note": "Seasonal spotlights written for NOOR. Quranic text copied from assets/data/quran (Tanzil, CC BY 3.0). Hadith cited by collection and number. Review by a qualified scholar is required before publication.", "spotlights": SPOTLIGHTS}, f, ensure_ascii=False, indent=1)
print(len(SPOTLIGHTS), "spotlights")
