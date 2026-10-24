"""Builds assets/data/khutab.json: Friday sermons (khutab) in Arabic and English.

The sermons were written for this app. Every Quranic quotation is copied from
assets/data/quran (Tanzil Uthmani text + Saheeh International), never typed by
hand; excerpts are cut by exact substring and the script stops if one does not
match. Hadith are quoted with their collection and number. Have the texts
reviewed by a qualified scholar before a public release.

  python -I tool/build_khutab.py .
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from quran_quote import H, P, Quran  # noqa: E402

root = sys.argv[1] if len(sys.argv) > 1 else "."
A = Quran(root).A


# ── Shared openings and endings (khutbat al-hajah, Abu Dawud 2118; Muslim 867) ──

OPENING = [
    P(
        "إنَّ الحمدَ للهِ، نحمدُه ونستعينُه ونستغفرُه، ونعوذُ باللهِ من شرورِ أنفسِنا ومن سيئاتِ أعمالِنا، مَن يهدِه اللهُ فلا مُضِلَّ له، ومَن يُضلِلْ فلا هاديَ له، وأشهدُ أن لا إلهَ إلا اللهُ وحدَه لا شريكَ له، وأشهدُ أنَّ محمدًا عبدُه ورسولُه، صلّى اللهُ عليه وعلى آلِه وصحبِه وسلَّم تسليمًا كثيرًا.",
        "All praise is for Allah. We praise Him, seek His help and ask His forgiveness, and we seek refuge in Allah from the evil of our souls and the wrongs of our deeds. Whomever Allah guides, none can lead astray; whomever He leaves astray, none can guide. I bear witness that there is no god but Allah alone, without partner, and that Muhammad is His servant and Messenger; may Allah send abundant blessings and peace upon him, his family and his Companions.",
    ),
    A(3, 102),
    P(
        "أمّا بعدُ: فإنَّ خيرَ الحديثِ كتابُ الله، وخيرَ الهديِ هديُ محمدٍ ﷺ، وشرَّ الأمورِ محدثاتُها، وكلَّ بدعةٍ ضلالة.",
        "To proceed: the best speech is the Book of Allah, the best guidance is the guidance of Muhammad ﷺ, the worst of matters are those newly invented, and every innovation is misguidance.",
    ),
]

CLOSE_FIRST = P(
    "أقولُ قولي هذا، وأستغفرُ اللهَ العظيمَ لي ولكم ولسائرِ المسلمين من كلِّ ذنب، فاستغفروه إنه هو الغفورُ الرحيم.",
    "I say these words and ask Allah the Almighty to forgive me, you and all Muslims every sin; so ask Him for forgiveness, for He is the Most Forgiving, the Most Merciful.",
)

OPEN_SECOND = P(
    "الحمدُ للهِ ربِّ العالمين، والصلاةُ والسلامُ على نبيِّنا محمدٍ وعلى آلِه وصحبِه أجمعين. أمّا بعدُ، فيا عبادَ الله:",
    "All praise is for Allah, Lord of the worlds, and blessings and peace be upon our Prophet Muhammad, his family and all his Companions. To proceed, O servants of Allah:",
)


def closing(dua_ar, dua_en):
    return [
        P("ثمَّ صلّوا وسلّموا على مَن أمركم اللهُ بالصلاةِ والسلامِ عليه، فقال سبحانه:", "Then send blessings and peace upon the one Allah commanded you to bless, for He said:"),
        A(33, 56),
        P(
            "اللهمَّ صلِّ وسلِّم وبارِك على نبيِّنا محمدٍ وعلى آلِه وصحبِه أجمعين. " + dua_ar + " اللهمَّ أعِزَّ الإسلامَ والمسلمين، واغفرْ للمؤمنين والمؤمنات، الأحياءِ منهم والأموات، ربَّنا آتِنا في الدنيا حسنةً وفي الآخرةِ حسنةً وقِنا عذابَ النار.",
            "O Allah, send blessings, peace and grace upon our Prophet Muhammad, his family and all his Companions. " + dua_en + " O Allah, honour Islam and the Muslims, and forgive the believing men and women, the living and the dead. Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.",
        ),
        P("عبادَ الله:", "Servants of Allah:"),
        A(16, 90),
        P("فاذكروا اللهَ العظيمَ يذكرْكم، واشكروه على نعمِه يزدْكم، ولَذِكرُ اللهِ أكبر، واللهُ يعلمُ ما تصنعون.", "Remember Allah the Almighty and He will remember you; thank Him for His blessings and He will increase you. The remembrance of Allah is greater, and Allah knows what you do."),
    ]


def khutba(id, cat, title, summary, first, second, dua):
    return {
        "id": id,
        "cat": cat,
        "titleAr": title[0],
        "titleEn": title[1],
        "summaryAr": summary[0],
        "summaryEn": summary[1],
        "parts": [
            {"titleAr": "الخطبة الأولى", "titleEn": "First khutbah", "blocks": OPENING + first + [CLOSE_FIRST]},
            {"titleAr": "الخطبة الثانية", "titleEn": "Second khutbah", "blocks": [OPEN_SECOND] + second + closing(*dua)},
        ],
    }


CATEGORIES = [
    {"id": "faith", "ar": "العقيدة والإيمان", "en": "Faith"},
    {"id": "worship", "ar": "العبادات", "en": "Worship"},
    {"id": "character", "ar": "الأخلاق والمعاملات", "en": "Character"},
    {"id": "family", "ar": "الأسرة والمجتمع", "en": "Family & society"},
    {"id": "heart", "ar": "الرقائق والتزكية", "en": "Heart & soul"},
    {"id": "seasons", "ar": "المواسم والمناسبات", "en": "Seasons"},
    {"id": "prophetic", "ar": "خطب نبوية", "en": "Prophetic sermons"},
]

KHUTAB = [
    khutba(
        "taqwa", "faith",
        ("التقوى خيرُ الزاد", "Taqwa: the best provision"),
        ("ما التقوى، وكيف نعيشها في يومنا، وما ثمراتها في الدنيا والآخرة.", "What taqwa is, how to live it day to day, and its fruits in this life and the next."),
        [
            P(
                "عبادَ الله: أوصيكم ونفسي بتقوى الله؛ فهي وصيّةُ اللهِ للأوّلين والآخرين، وهي أن تجعلَ بينك وبين ما يُغضِبُ اللهَ وقايةً، بفعلِ ما أمر واجتنابِ ما نهى، رجاءَ رحمتِه وخوفَ عذابِه. وليست التقوى كلماتٍ تُقال، بل هي حياةُ قلبٍ يراقبُ ربَّه في السرِّ والعلن.",
                "Servants of Allah: I counsel you and myself to have taqwa of Allah, the counsel He gave to the first and the last. Taqwa is to place a shield between yourself and what angers Allah, by doing what He commands and avoiding what He forbids, hoping for His mercy and fearing His punishment. It is not words that are spoken but a living heart that is mindful of its Lord in private and in public.",
            ),
            A(2, 197, ar_from="وَتَزَوَّدُوا۟", en_from="And take provisions"),
            P(
                "والتقوى مفتاحُ الفرَج وسببُ الرزق؛ فمَن ضاقت عليه أبوابُ الدنيا فليطرقْ بابَ التقوى، فإنَّ اللهَ تكفّل لأهلِها بالمخرجِ من كلِّ ضيق، والرزقِ من حيث لا يحتسبون.",
                "Taqwa is the key to relief and a cause of provision. Whoever finds the doors of this world closed, let him knock at the door of taqwa, for Allah has promised its people a way out of every hardship and provision from where they do not expect.",
            ),
            A(65, 2, 3, ar_from="وَمَن يَتَّقِ", en_from="And whoever fears Allah"),
            P(
                "وقد جمع النبيُّ ﷺ معنى التقوى في وصيّةٍ جامعةٍ لمعاذٍ وأبي ذرٍّ رضي الله عنهما، فقال:",
                "The Prophet ﷺ summed up taqwa in a comprehensive piece of advice to Mu‘adh and Abu Dharr, may Allah be pleased with them:",
            ),
            H("«اتقِ اللهَ حيثما كنتَ، وأتبِعِ السيئةَ الحسنةَ تمحُها، وخالِقِ الناسَ بخُلُقٍ حسن»", "“Fear Allah wherever you are, follow a bad deed with a good one and it will wipe it out, and treat people with good character.”", "رواه الترمذي (1987) وقال: حسن صحيح", "at-Tirmidhi 1987 (hasan sahih)"),
        ],
        [
            P(
                "اعلموا أنَّ التقوى تظهرُ في التفاصيل: في صلاةٍ تُؤدّى في وقتها، وفي لسانٍ يُمسَكُ عن الغيبة، وفي مالٍ يُكسَبُ من حلال، وفي عينٍ تُغَضُّ عن الحرام، وفي معاملةٍ لا غشَّ فيها. ومَن أراد أن يعرفَ مقامَ التقوى من قلبِه فلينظرْ إلى حالِه إذا خلا بنفسِه.",
                "Know that taqwa shows in the details: a prayer offered on time, a tongue held back from backbiting, wealth earned lawfully, eyes lowered from what is forbidden, and dealings free of deceit. Whoever wants to know the place of taqwa in his heart, let him look at how he behaves when he is alone.",
            ),
            A(49, 13, ar_from="إِنَّ أَكْرَمَكُمْ", en_from="Indeed, the most noble"),
        ],
        ("اللهمَّ آتِ نفوسَنا تقواها، وزكِّها أنت خيرُ مَن زكّاها، أنت وليُّها ومولاها.", "O Allah, grant our souls their taqwa and purify them, for You are the best to purify them; You are their Guardian and Master."),
    ),
    khutba(
        "salah", "worship",
        ("الصلاةُ عمادُ الدين", "Prayer, the pillar of the religion"),
        ("مكانة الصلاة، وأثرها في الأخلاق، وكيف نحافظ عليها ونخشع فيها.", "The standing of prayer, its effect on character, and how to guard it and pray with humility."),
        [
            P(
                "عبادَ الله: إنَّ أعظمَ ما افترضه اللهُ على عبادِه بعد التوحيد الصلاة، فُرِضت من فوقِ سبعِ سماوات ليلةَ المعراج، وهي الصلةُ بين العبدِ وربِّه، يقفُ فيها المؤمنُ بين يدي مولاه خمسَ مراتٍ في اليوم، فيخرجُ منها خفيفًا مطمئنًّا.",
                "Servants of Allah: after tawhid, the greatest obligation Allah placed upon His servants is prayer. It was prescribed above the seven heavens on the night of the Ascension. It is the bond between the servant and his Lord: five times a day the believer stands before his Master and leaves lighter and at peace.",
            ),
            A(29, 45),
            P(
                "والصلاةُ أوّلُ ما يُنظَرُ فيه من عملِ العبد يومَ القيامة، فإن صلحت صلح سائرُ عمله، وإن فسدت فسد سائرُ عمله، قال رسولُ الله ﷺ:",
                "Prayer is the first of a servant’s deeds to be examined on the Day of Resurrection: if it is sound, the rest of his deeds are sound, and if it is corrupt, the rest are corrupt. The Messenger of Allah ﷺ said:",
            ),
            H("«إنَّ أوّلَ ما يُحاسَبُ به العبدُ يومَ القيامةِ من عملِه صلاتُه، فإن صلَحت فقد أفلحَ وأنجح، وإن فسَدت فقد خابَ وخسِر»", "“The first of his deeds for which a servant will be held to account on the Day of Resurrection is his prayer. If it is sound, he has succeeded and prospered; if it is corrupt, he has failed and lost.”", "رواه الترمذي (413) والنسائي (465)", "at-Tirmidhi 413, an-Nasa’i 465"),
            P(
                "وهي طُهرةٌ متجدّدة؛ يغسلُ اللهُ بها الخطايا كما يغسلُ الماءُ الدرن، فقد ضرب النبيُّ ﷺ لذلك مثلًا فقال:",
                "It is a purification renewed throughout the day; Allah washes away sins by it as water washes away dirt. The Prophet ﷺ gave an example of this:",
            ),
            H("«أرأيتم لو أنَّ نهرًا ببابِ أحدِكم يغتسلُ منه كلَّ يومٍ خمسَ مرات، هل يبقى من درنِه شيء؟» قالوا: لا يبقى من درنِه شيء، قال: «فذلك مثلُ الصلواتِ الخمس، يمحو اللهُ بهنَّ الخطايا»", "“Tell me, if there were a river at the door of one of you in which he bathed five times a day, would any dirt remain on him?” They said: “No dirt would remain.” He said: “That is the likeness of the five prayers: by them Allah wipes out sins.”", "متفق عليه: البخاري (528) ومسلم (667)", "al-Bukhari 528, Muslim 667"),
        ],
        [
            P(
                "حافظوا على الصلاةِ في أوقاتِها مع الجماعة، وأقبلوا عليها بقلوبِكم؛ فإنَّ روحَ الصلاةِ الخشوع. تهيّؤوا لها قبل دخولِ وقتها، وأحسنوا الوضوء، وتدبّروا ما تقرؤون، واطمئنّوا في الركوعِ والسجود، وعلّموها أبناءَكم بالقدوةِ قبل الكلمة.",
                "Guard the prayers in their times and in congregation, and turn to them with your hearts, for the soul of prayer is humility. Prepare for it before its time comes, perfect your wudu, reflect on what you recite, be still in bowing and prostration, and teach it to your children by example before words.",
            ),
            A(23, 1, 2),
        ],
        ("اللهمَّ اجعلنا مقيمي الصلاةِ ومن ذرياتِنا، ربَّنا وتقبّلْ دعاء.", "O Allah, make us and our descendants steadfast in prayer; our Lord, accept our supplication."),
    ),
    khutba(
        "parents", "family",
        ("بِرُّ الوالدين", "Kindness to parents"),
        ("حقّ الوالدين بعد حقّ الله، وصور البرّ في حياتهما وبعد موتهما.", "The right of parents after the right of Allah, and ways to honour them in life and after death."),
        [
            P(
                "عبادَ الله: لقد قرن اللهُ حقَّ الوالدين بحقِّه، وجعل الإحسانَ إليهما بعد عبادتِه، لأنهما سببُ وجودِك بعد الله، حملتك أمُّك وهنًا على وهن، وسهِر أبوك وكدَح لتكبرَ في عافية.",
                "Servants of Allah: Allah joined the right of parents to His own right and placed kindness to them right after worshipping Him, for after Allah they are the reason you exist. Your mother carried you in weakness upon weakness, and your father stayed up and toiled so you could grow up in health.",
            ),
            A(17, 23, 24),
            P(
                "والأمُّ أحقُّ الناسِ بحسنِ الصحبة، ثلاثَ مراتٍ قبل الأب، لعِظَمِ ما لاقت من الحملِ والوضعِ والرضاع:",
                "The mother is the most deserving of good companionship, three times before the father, because of the great hardship of pregnancy, birth and nursing:",
            ),
            H("جاء رجلٌ إلى رسولِ الله ﷺ فقال: يا رسولَ الله، مَن أحقُّ الناسِ بحُسنِ صحابتي؟ قال: «أمُّك» قال: ثم مَن؟ قال: «أمُّك» قال: ثم مَن؟ قال: «أمُّك» قال: ثم مَن؟ قال: «أبوك»", "A man came to the Messenger of Allah ﷺ and said: “O Messenger of Allah, who most deserves my good companionship?” He said: “Your mother.” He asked: “Then who?” He said: “Your mother.” He asked: “Then who?” He said: “Your mother.” He asked: “Then who?” He said: “Your father.”", "متفق عليه: البخاري (5971) ومسلم (2548)", "al-Bukhari 5971, Muslim 2548"),
            A(31, 14),
        ],
        [
            P(
                "ومن البرِّ: لينُ الكلام، وخفضُ الصوت، وسرعةُ الإجابة، وقضاءُ الحاجة قبل أن تُطلب، والإنفاقُ عليهما، وإدخالُ السرورِ عليهما، وألّا تُشعرَهما بثِقَلِ خدمتِهما. فإذا رحلا فالبرُّ باقٍ: بالدعاءِ لهما، والاستغفارِ لهما، وإنفاذِ عهدِهما، وصلةِ أرحامِهما، وإكرامِ أصدقائِهما.",
                "Kindness to them includes gentle words, a lowered voice, answering quickly, meeting their needs before they ask, spending on them, bringing them joy, and never letting them feel that serving them is a burden. When they pass away, kindness continues: praying for them, seeking forgiveness for them, fulfilling their promises, keeping ties with their relatives and honouring their friends.",
            ),
            H("«رَغِمَ أنفُه، ثم رَغِمَ أنفُه، ثم رَغِمَ أنفُه» قيل: مَن يا رسولَ الله؟ قال: «مَن أدرك أبويه عند الكِبَر، أحدَهما أو كليهما، فلم يدخلِ الجنة»", "“May his nose be rubbed in dust, then may his nose be rubbed in dust, then may his nose be rubbed in dust.” It was said: “Who, O Messenger of Allah?” He said: “The one whose parents, one or both, reach old age with him, and yet he does not enter Paradise.”", "رواه مسلم (2551)", "Muslim 2551"),
        ],
        ("اللهمَّ اغفرْ لوالدينا وارحمهما كما ربَّيانا صغارًا، واجزِهما عنّا خيرَ الجزاء.", "O Allah, forgive our parents and have mercy on them as they raised us when we were small, and reward them for us with the best reward."),
    ),
    khutba(
        "character", "character",
        ("حُسنُ الخلق", "Good character"),
        ("منزلة الأخلاق في الإسلام، وأثقل ما يوضع في الميزان، وكيف نكتسب الخلق الحسن.", "The place of character in Islam, the heaviest thing on the scale, and how good character is acquired."),
        [
            P(
                "عبادَ الله: إنَّ الدينَ ليس عبادةً بين العبدِ وربِّه فحسب، بل هو أيضًا خُلُقٌ يظهرُ في البيتِ والسوقِ والطريق. وقد أثنى اللهُ على نبيِّه ﷺ بأعظمِ ما يُثنى به على بشر:",
                "Servants of Allah: religion is not only worship between a servant and his Lord; it is also character that shows at home, in the market and on the road. Allah praised His Prophet ﷺ with the greatest praise given to any human being:",
            ),
            A(68, 4),
            H("«ما شيءٌ أثقلُ في ميزانِ المؤمنِ يومَ القيامةِ من خُلُقٍ حسن»", "“Nothing is heavier on the believer’s scale on the Day of Resurrection than good character.”", "رواه الترمذي (2002) وأبو داود (4799)", "at-Tirmidhi 2002, Abu Dawud 4799"),
            P(
                "وحسنُ الخلقِ طريقٌ قريبٌ إلى قربِ النبيِّ ﷺ في الجنة، فقد قال:",
                "Good character is a short path to being near the Prophet ﷺ in Paradise, for he said:",
            ),
            H("«إنَّ مِن أحبِّكم إليَّ وأقربِكم مني مجلسًا يومَ القيامةِ أحاسنَكم أخلاقًا»", "“Among the most beloved of you to me and the nearest to me in seating on the Day of Resurrection are those of you with the best character.”", "رواه الترمذي (2018)", "at-Tirmidhi 2018"),
            A(3, 133, 134),
        ],
        [
            P(
                "والخلقُ الحسنُ يُكتسَبُ بالمجاهدةِ والتعوّد: بكظمِ الغيظ حين يثور، والعفوِ حين تقدر، والكلمةِ الطيبة، والابتسامةِ في وجهِ أخيك، والوفاءِ بالوعد، والصبرِ على أذى الناس. وأولى الناسِ بحسنِ خلقِك أهلُ بيتِك، فلا يكنْ أحدُنا لطيفًا مع الغرباءِ قاسيًا مع أقربِ الناسِ إليه.",
                "Good character is acquired by striving and habit: swallowing anger when it rises, forgiving when you are able, a kind word, a smile in your brother’s face, keeping promises, and patience with people’s harm. The people most entitled to your good character are those in your home; let none of us be gentle with strangers and harsh with those closest to him.",
            ),
        ],
        ("اللهمَّ اهدِنا لأحسنِ الأخلاقِ لا يهدي لأحسنِها إلا أنت، واصرفْ عنّا سيّئَها لا يصرفُ عنّا سيّئَها إلا أنت.", "O Allah, guide us to the best of character, for none guides to the best of it but You, and turn away from us its worst, for none turns it away but You."),
    ),
    khutba(
        "time", "heart",
        ("العمرُ رأسُ المال", "Life is your capital"),
        ("قيمة الوقت، والسؤال عن العمر يوم القيامة، وكيف نستثمر أيامنا.", "The value of time, the questioning about one’s life, and how to invest our days."),
        [
            P(
                "عبادَ الله: أقسم اللهُ بالعصرِ، وهو الزمن، ليُنبّهَنا إلى أنَّ أعمارَنا هي رأسُ مالِنا، وأنَّ كلَّ يومٍ يمضي لا يعود، وأنَّ الخاسرَ مَن ضيّع أيامَه فيما لا ينفعه.",
                "Servants of Allah: Allah swore by time to remind us that our lives are our capital, that every day that passes never returns, and that the loser is the one who wastes his days on what does not benefit him.",
            ),
            A(103, 1, 3),
            H("«نعمتانِ مغبونٌ فيهما كثيرٌ من الناس: الصحةُ والفراغ»", "“There are two blessings in which many people are cheated: health and free time.”", "رواه البخاري (6412)", "al-Bukhari 6412"),
            P(
                "وسيُسألُ كلُّ واحدٍ منّا عن عمرِه: فيمَ قضاه؟ وعن شبابِه: فيمَ أبلاه؟",
                "Each of us will be asked about his life: how did he spend it? And about his youth: how did he use it?",
            ),
            H("«لا تزولُ قدما عبدٍ يومَ القيامةِ حتى يُسألَ عن عمرِه فيمَ أفناه، وعن علمِه فيمَ فعل، وعن مالِه من أين اكتسبه وفيمَ أنفقه، وعن جسمِه فيمَ أبلاه»", "“The feet of a servant will not move on the Day of Resurrection until he is asked about his life and how he spent it, his knowledge and what he did with it, his wealth and how he earned it and spent it, and his body and how he used it.”", "رواه الترمذي (2417) وقال: حسن صحيح", "at-Tirmidhi 2417 (hasan sahih)"),
        ],
        [
            P(
                "فاجعلوا لأنفسِكم وِردًا من القرآنِ لا تتركونه، وذكرًا في الصباحِ والمساء، ووقتًا لأهلِكم، ووقتًا للعلمِ النافع، واحذروا لصوصَ الوقتِ التي تسرقُ الساعاتِ دون أن نشعر. واعلموا أنَّ النيّةَ الصالحةَ تحوِّلُ العادةَ عبادة: فالعملُ والنومُ والأكلُ إذا نُوي بها التقوّي على طاعةِ اللهِ كُتب لك أجرُها.",
                "Set yourselves a daily portion of the Quran that you never abandon, remembrance in the morning and evening, time for your family and time for beneficial knowledge, and beware of the thieves of time that steal hours without our noticing. Know that a good intention turns habit into worship: work, sleep and food, when intended as strength for obeying Allah, are recorded for you as reward.",
            ),
            A(23, 115),
        ],
        ("اللهمَّ بارِكْ لنا في أعمارِنا وأوقاتِنا، واجعلْ خيرَ أيامِنا يومَ نلقاك.", "O Allah, bless our lives and our time, and make the best of our days the day we meet You."),
    ),
    khutba(
        "honesty", "character",
        ("الصدقُ والأمانة", "Truthfulness and trustworthiness"),
        ("الصدق طريق إلى الجنة، والأمانة بمعناها الواسع، وعلامات النفاق التي يجب الحذر منها.", "Truthfulness as a road to Paradise, trust in its broad sense, and the signs of hypocrisy to guard against."),
        [
            P(
                "عبادَ الله: الصدقُ خُلُقُ الأنبياء، وزينةُ المؤمنين، به تُبنى الثقة، وتصلحُ المعاملات، ويطمئنُّ القلب. وقد أمر اللهُ المؤمنين أن يكونوا مع الصادقين:",
                "Servants of Allah: truthfulness is the character of the prophets and the adornment of the believers. By it trust is built, dealings are set right and the heart finds peace. Allah commanded the believers to be with the truthful:",
            ),
            A(9, 119),
            H("«عليكم بالصدق، فإنَّ الصدقَ يهدي إلى البِرّ، وإنَّ البِرَّ يهدي إلى الجنة، وما يزالُ الرجلُ يصدُقُ ويتحرّى الصدقَ حتى يُكتبَ عند اللهِ صِدِّيقًا، وإياكم والكذب، فإنَّ الكذبَ يهدي إلى الفجور، وإنَّ الفجورَ يهدي إلى النار، وما يزالُ الرجلُ يكذبُ ويتحرّى الكذبَ حتى يُكتبَ عند اللهِ كذّابًا»", "“Hold to truthfulness, for truthfulness leads to righteousness and righteousness leads to Paradise. A man keeps speaking the truth and striving for it until he is recorded with Allah as truthful. Beware of lying, for lying leads to wickedness and wickedness leads to the Fire. A man keeps lying and striving for it until he is recorded with Allah as a liar.”", "رواه مسلم (2607)", "Muslim 2607"),
            P(
                "والأمانةُ أوسعُ ممّا يظنُّ كثيرٌ من الناس: فالوظيفةُ أمانة، والوقتُ أمانة، والكلمةُ أمانة، والأسرارُ أمانة، والأولادُ أمانة، وصوتُك في الشهادةِ والمشورةِ أمانة.",
                "Trust is broader than many people think: your job is a trust, your time is a trust, your word is a trust, secrets are a trust, children are a trust, and your voice in testimony and counsel is a trust.",
            ),
            A(4, 58),
        ],
        [
            P(
                "واحذروا خصالَ النفاق، فإنها تتسلّلُ إلى القلبِ من باب التهاون: كذبةٌ صغيرةٌ في البيع، ووعدٌ يُخلَف بلا عذر، وأمانةٌ يُفرَّط فيها. فقد قال النبيُّ ﷺ:",
                "Beware of the traits of hypocrisy, for they creep into the heart through carelessness: a small lie in a sale, a promise broken without excuse, a trust neglected. The Prophet ﷺ said:",
            ),
            H("«آيةُ المنافقِ ثلاث: إذا حدّث كذب، وإذا وعد أخلف، وإذا اؤتُمن خان»", "“The signs of a hypocrite are three: when he speaks he lies, when he promises he breaks it, and when he is trusted he betrays.”", "متفق عليه: البخاري (33) ومسلم (59)", "al-Bukhari 33, Muslim 59"),
        ],
        ("اللهمَّ طهِّرْ قلوبَنا من النفاق، وألسنتَنا من الكذب، وأعمالَنا من الرياء.", "O Allah, purify our hearts from hypocrisy, our tongues from lies and our deeds from showing off."),
    ),
    khutba(
        "repentance", "heart",
        ("بابُ التوبةِ مفتوح", "The door of repentance is open"),
        ("سعة رحمة الله، وشروط التوبة الصادقة، وألّا يقنط أحدٌ من رحمة ربّه.", "The vastness of Allah’s mercy, the conditions of sincere repentance, and why no one should despair."),
        [
            P(
                "عبادَ الله: ما من أحدٍ إلا وله ذنوب، والعبرةُ ليست بألّا تذنب، فذلك للملائكة، ولكنْ بأن ترجعَ إلى ربِّك كلما زلّت قدمُك. ولقد فتح اللهُ للمذنبين بابًا لا يُغلَق حتى تطلعَ الشمسُ من مغربِها.",
                "Servants of Allah: there is no one without sins. What matters is not that you never sin, which is for the angels, but that you return to your Lord every time your foot slips. Allah has opened for sinners a door that does not close until the sun rises from the west.",
            ),
            A(39, 53),
            H("«إنَّ اللهَ عزَّ وجلَّ يبسُطُ يدَه بالليلِ ليتوبَ مسيءُ النهار، ويبسُطُ يدَه بالنهارِ ليتوبَ مسيءُ الليل، حتى تطلُعَ الشمسُ من مغربِها»", "“Allah, Mighty and Majestic, stretches out His hand at night so that the one who sinned by day may repent, and stretches out His hand by day so that the one who sinned by night may repent, until the sun rises from the west.”", "رواه مسلم (2759)", "Muslim 2759"),
            H("«كلُّ ابنِ آدمَ خطّاء، وخيرُ الخطّائين التوّابون»", "“Every son of Adam errs, and the best of those who err are those who repent.”", "رواه الترمذي (2499) وابن ماجه (4251)", "at-Tirmidhi 2499, Ibn Majah 4251"),
        ],
        [
            P(
                "والتوبةُ الصادقة: إقلاعٌ عن الذنب، وندمٌ على ما فات، وعزمٌ ألّا يعود، فإن كان الذنبُ في حقِّ آدميٍّ فلا بدَّ من ردِّ الحقِّ إلى صاحبِه أو استحلالِه. ولا تؤخّروا التوبةَ إلى غد، فلا يدري أحدُنا هل يُدرِكُ الغد. وأتبعوا السيئاتِ بالحسنات، وأكثروا من الاستغفار، فإنَّ اللهَ يفرحُ بتوبةِ عبدِه.",
                "Sincere repentance is to stop the sin, regret what has passed and resolve not to return. If the sin concerns another person’s right, it must be returned to them or their pardon sought. Do not delay repentance until tomorrow, for none of us knows whether he will see tomorrow. Follow bad deeds with good ones and seek forgiveness often, for Allah rejoices at His servant’s repentance.",
            ),
            A(3, 135),
        ],
        ("اللهمَّ تُبْ علينا توبةً نصوحًا، واغفرْ لنا ما قدّمنا وما أخّرنا، وما أسررنا وما أعلنّا.", "O Allah, accept from us sincere repentance, and forgive us what we have done before and after, in secret and in public."),
    ),
    khutba(
        "family", "family",
        ("الأسرةُ أمانة", "The family is a trust"),
        ("مسؤولية الوالدين، والمودّة والرحمة بين الزوجين، وتربية الأبناء على الإيمان.", "The responsibility of parents, love and mercy between spouses, and raising children in faith."),
        [
            P(
                "عبادَ الله: الأسرةُ هي اللبنةُ الأولى في بناءِ المجتمع، إن صلحت صلح، وإن فسدت فسد. وقد جعل اللهُ بين الزوجين مودّةً ورحمة، وجعل البيتَ سكنًا لا ساحةَ نزاع.",
                "Servants of Allah: the family is the first building block of society; if it is sound, society is sound, and if it is corrupt, society is corrupt. Allah placed love and mercy between spouses and made the home a place of tranquillity, not a battlefield.",
            ),
            A(30, 21),
            H("«كلُّكم راعٍ وكلُّكم مسؤولٌ عن رعيّتِه: الإمامُ راعٍ ومسؤولٌ عن رعيّتِه، والرجلُ راعٍ في أهلِه وهو مسؤولٌ عن رعيّتِه، والمرأةُ راعيةٌ في بيتِ زوجِها ومسؤولةٌ عن رعيّتِها»", "“Each of you is a shepherd and each of you is responsible for his flock. The ruler is a shepherd and responsible for his flock; a man is a shepherd over his family and responsible for his flock; a woman is a shepherd in her husband’s house and responsible for her flock.”", "متفق عليه: البخاري (893) ومسلم (1829)", "al-Bukhari 893, Muslim 1829"),
            A(66, 6),
        ],
        [
            P(
                "ومن حمايةِ الأهلِ: أن نعلّمَهم دينَهم، ونكونَ لهم قدوة، ونصاحبَ أبناءَنا ونسمعَ منهم، ونعرفَ أصدقاءَهم وما يشاهدون، وأن نعدلَ بينهم، وأن نجعلَ للبيتِ نصيبًا من الصلاةِ والقرآنِ والذكر. وخيرُ الناسِ أحسنُهم معاملةً لأهلِه:",
                "Protecting our families means teaching them their religion, being an example for them, befriending our children and listening to them, knowing their friends and what they watch, being fair among them, and giving the home its share of prayer, Quran and remembrance. The best of people are those who treat their families best:",
            ),
            H("«خيرُكم خيرُكم لأهلِه، وأنا خيرُكم لأهلي»", "“The best of you are those who are best to their families, and I am the best of you to my family.”", "رواه الترمذي (3895)", "at-Tirmidhi 3895"),
        ],
        ("ربَّنا هبْ لنا من أزواجِنا وذرياتِنا قرّةَ أعين، واجعلنا للمتقين إمامًا.", "Our Lord, grant us from our spouses and children comfort to our eyes, and make us leaders for the righteous."),
    ),
    khutba(
        "brotherhood", "family",
        ("الأخوّةُ الإيمانية", "Brotherhood in faith"),
        ("حقوق المسلم على أخيه، وآفات تهدم الأخوّة، والجسد الواحد.", "The rights Muslims owe one another, the ills that destroy brotherhood, and the one body."),
        [
            P(
                "عبادَ الله: عقد اللهُ بين المؤمنين رابطةً أقوى من رابطةِ النسبِ والوطن، هي أخوّةُ الإيمان، فجعلهم إخوةً تتكافأُ دماؤهم، ويسعى بذمّتِهم أدناهم.",
                "Servants of Allah: Allah tied the believers together with a bond stronger than lineage or homeland, the brotherhood of faith. He made them brothers whose blood is of equal worth and whose protection even the least of them may grant.",
            ),
            A(49, 10),
            A(3, 103),
            H("«مَثَلُ المؤمنين في توادِّهم وتراحمِهم وتعاطفِهم مَثَلُ الجسد، إذا اشتكى منه عضوٌ تداعى له سائرُ الجسدِ بالسهرِ والحُمّى»", "“The likeness of the believers in their love, mercy and compassion for one another is that of a body: when one part of it aches, the rest of the body responds with sleeplessness and fever.”", "رواه مسلم (2586)", "Muslim 2586"),
        ],
        [
            P(
                "وللأخوّةِ آفاتٌ تهدمها: الحسد، والغيبة، والسخرية، وسوءُ الظن، والتدابرُ والهجر. وقد جمعها النبيُّ ﷺ في وصيّةٍ واحدة:",
                "Brotherhood has ills that destroy it: envy, backbiting, mockery, suspicion, and turning away from one another. The Prophet ﷺ gathered them in a single counsel:",
            ),
            H("«لا تحاسدوا، ولا تناجشوا، ولا تباغضوا، ولا تدابروا، ولا يبعْ بعضُكم على بيعِ بعض، وكونوا عبادَ اللهِ إخوانًا، المسلمُ أخو المسلم: لا يظلِمُه ولا يخذُلُه ولا يحقِرُه»", "“Do not envy one another, do not inflate prices against one another, do not hate one another, do not turn away from one another, and do not undercut one another’s sales. Be, O servants of Allah, brothers. A Muslim is the brother of a Muslim: he does not wrong him, abandon him or look down on him.”", "رواه مسلم (2564)", "Muslim 2564"),
            P(
                "فأفشوا السلام، وعودوا المريض، وأجيبوا الدعوة، وانصحوا لبعضكم، واسعوا في قضاءِ حوائجِ إخوانِكم، وأصلحوا ذاتَ بينِكم.",
                "Spread the greeting of peace, visit the sick, accept invitations, give sincere advice to one another, work to meet your brothers’ needs, and reconcile between yourselves.",
            ),
        ],
        ("اللهمَّ ألِّفْ بين قلوبِنا، وأصلحْ ذاتَ بينِنا، ولا تجعلْ في قلوبِنا غِلًّا للذين آمنوا.", "O Allah, join our hearts, reconcile between us, and put no rancour in our hearts towards those who believe."),
    ),
    khutba(
        "ramadan", "seasons",
        ("استقبالُ رمضان", "Welcoming Ramadan"),
        ("فضل شهر رمضان، وكيف نستعدّ له، وما يفوّت على الصائم أجره.", "The virtue of Ramadan, how to prepare for it, and what robs the fasting person of reward."),
        [
            P(
                "عبادَ الله: أظلّكم شهرٌ عظيم، شهرُ القرآنِ والصيامِ والقيام، تُفتَحُ فيه أبوابُ الخير، ويتنافسُ فيه المتنافسون. فطوبى لمَن أدركه فاغتنمه، وخسارةٌ لمَن أدركه ثم خرج منه كما دخل.",
                "Servants of Allah: a great month is upon you, the month of the Quran, fasting and night prayer, in which the doors of good are opened and those who compete, compete. Glad tidings to whoever reaches it and makes the most of it, and loss to whoever reaches it and leaves it as he entered.",
            ),
            A(2, 183),
            H("«إذا جاء رمضانُ فُتِّحت أبوابُ الجنة، وغُلِّقت أبوابُ النار، وصُفِّدت الشياطين»", "“When Ramadan comes, the gates of Paradise are opened, the gates of the Fire are closed, and the devils are chained.”", "متفق عليه: البخاري (1899) ومسلم (1079)", "al-Bukhari 1899, Muslim 1079"),
            H("«مَن صام رمضانَ إيمانًا واحتسابًا غُفِر له ما تقدّم من ذنبِه»", "“Whoever fasts Ramadan out of faith and hoping for reward will have his past sins forgiven.”", "متفق عليه: البخاري (38) ومسلم (760)", "al-Bukhari 38, Muslim 760"),
            A(2, 185, ar_to="وَٱلْفُرْقَانِ", en_to="criterion."),
        ],
        [
            P(
                "استعدّوا لرمضانَ بالتوبة، وتصفيةِ القلوب، وقضاءِ ما فات من الصيام، وتنظيمِ الأوقات: وِردٌ يوميٌّ من القرآن، ومحافظةٌ على التراويح، وصدقةٌ ولو قليلة، وتفطيرُ صائم. واحذروا ما يذهبُ بأجرِ الصيام من قولِ الزورِ والعملِ به، والغضبِ والجدال، وضياعِ الليالي أمام الشاشات.",
                "Prepare for Ramadan with repentance, cleansing the heart, making up missed fasts and organising your time: a daily portion of Quran, keeping to tarawih, charity even if small, and feeding a fasting person. Beware of what takes away the reward of fasting: false speech and acting on it, anger and argument, and nights lost in front of screens.",
            ),
        ],
        ("اللهمَّ بلِّغنا رمضان، وأعِنّا فيه على الصيامِ والقيام، وتقبّلْه منّا.", "O Allah, let us reach Ramadan, help us in it to fast and pray at night, and accept it from us."),
    ),
    khutba(
        "dhulhijjah", "seasons",
        ("عشرُ ذي الحجة", "The ten days of Dhul-Hijjah"),
        ("أفضل أيام الدنيا، والأعمال المستحبّة فيها، وصيام عرفة والأضحية.", "The best days of the year, the deeds recommended in them, fasting Arafah and the sacrifice."),
        [
            P(
                "عبادَ الله: أقسم اللهُ بليالٍ عشر، وهي عشرُ ذي الحجةِ عند جمهورِ المفسرين، وما أقسم بها إلا لعِظَمِ شأنِها، ففيها يومُ عرفة، ويومُ النحر، وتجتمعُ فيها أمّهاتُ العبادة: الصلاةُ والصيامُ والصدقةُ والحج.",
                "Servants of Allah: Allah swore by ten nights, which most commentators say are the first ten of Dhul-Hijjah, and He swore by them only because of their greatness. In them are the Day of Arafah and the Day of Sacrifice, and in them the chief acts of worship meet: prayer, fasting, charity and Hajj.",
            ),
            A(89, 1, 2),
            H("«ما مِن أيامٍ العملُ الصالحُ فيها أحبُّ إلى اللهِ من هذه الأيام» يعني أيامَ العشر، قالوا: يا رسولَ الله، ولا الجهادُ في سبيلِ الله؟ قال: «ولا الجهادُ في سبيلِ الله، إلا رجلٌ خرج بنفسِه ومالِه فلم يرجعْ من ذلك بشيء»", "“There are no days in which righteous deeds are more beloved to Allah than these days,” meaning the ten days. They said: “O Messenger of Allah, not even jihad in the path of Allah?” He said: “Not even jihad in the path of Allah, except a man who went out with his life and his wealth and returned with nothing of it.”", "رواه أبو داود (2438)، وأصله في البخاري (969)", "Abu Dawud 2438; its origin is in al-Bukhari 969"),
            A(22, 28),
        ],
        [
            P(
                "فأكثروا فيها من التكبيرِ والتهليلِ والتحميد، وصوموا ما تيسّر منها، وخصّوا يومَ عرفةَ بالصيامِ لغيرِ الحاج، وتصدّقوا، وصِلوا أرحامَكم، ومَن أراد أن يضحّيَ فليُمسكْ عن شعرِه وأظفارِه من دخولِ العشر حتى يذبح.",
                "Increase in them in saying Allahu akbar, la ilaha illallah and alhamdulillah; fast what you can of them, especially the Day of Arafah for those not on Hajj; give charity and keep family ties. Whoever intends to offer a sacrifice should not cut his hair or nails from the start of the ten until he has slaughtered.",
            ),
            H("«صيامُ يومِ عرفة، أحتسبُ على اللهِ أن يكفِّرَ السنةَ التي قبلَه والسنةَ التي بعدَه»", "“Fasting the Day of Arafah, I hope from Allah that it will expiate the year before it and the year after it.”", "رواه مسلم (1162)", "Muslim 1162"),
        ],
        ("اللهمَّ وفّقنا لاغتنامِ هذه الأيام، وتقبّلْ من الحجاجِ حجَّهم، ومنّا صالحَ أعمالِنا.", "O Allah, help us to make the most of these days, accept the pilgrims’ Hajj, and accept our good deeds."),
    ),
    khutba(
        "mercy", "character",
        ("الرحمةُ بالخلق", "Mercy towards creation"),
        ("نبيّ الرحمة، والرحمة بالضعفاء والصغار والحيوان، والإحسان في كل شيء.", "The Prophet of mercy, mercy to the weak, the young and animals, and excellence in everything."),
        [
            P(
                "عبادَ الله: الرحمةُ صفةٌ من صفاتِ اللهِ الذي وسعت رحمتُه كلَّ شيء، وقد أرسل نبيَّه ﷺ رحمةً للعالمين، فكان رحيمًا بالكبيرِ والصغير، والقريبِ والبعيد، بل وبالحيوانِ والجماد.",
                "Servants of Allah: mercy is an attribute of Allah, whose mercy encompasses all things. He sent His Prophet ﷺ as a mercy to the worlds, and he was merciful to old and young, near and far, and even to animals and inanimate things.",
            ),
            A(21, 107),
            A(3, 159, ar_to="مِنْ حَوْلِكَ", en_to="from about you."),
            H("«الراحمون يرحمُهم الرحمن، ارحموا مَن في الأرضِ يرحمْكم مَن في السماء»", "“The merciful are shown mercy by the Most Merciful. Be merciful to those on earth, and the One above the heavens will be merciful to you.”", "رواه أبو داود (4941) والترمذي (1924)", "Abu Dawud 4941, at-Tirmidhi 1924"),
        ],
        [
            P(
                "فارحموا آباءَكم إذا كبِروا، وأبناءَكم إذا أخطؤوا، والعاملين تحت أيديكم، والمرضى والفقراءَ والأيتام، وحتى الحيوانَ الذي سخّره اللهُ لكم. واعلموا أنَّ الإحسانَ مطلوبٌ في كلِّ عمل، حتى في أدقِّ الأمور:",
                "Be merciful to your parents when they grow old, to your children when they err, to those who work under you, to the sick, the poor and orphans, and even to the animals Allah has made subservient to you. Know that excellence is required in every deed, even the smallest matters:",
            ),
            H("«إنَّ اللهَ كتب الإحسانَ على كلِّ شيء»", "“Allah has prescribed excellence in everything.”", "رواه مسلم (1955)", "Muslim 1955"),
        ],
        ("اللهمَّ ارزقنا قلوبًا رحيمة، وارحمنا برحمتِك التي وسعت كلَّ شيء.", "O Allah, grant us merciful hearts, and have mercy on us with Your mercy that encompasses all things."),
    ),
    khutba(
        "patience", "heart",
        ("الصبرُ والرضا", "Patience and contentment"),
        ("أنواع الصبر، وكيف يكون أمر المؤمن كله خيرًا، وتكفير الذنوب بالمصائب.", "The kinds of patience, how all of a believer’s affairs are good, and hardship as expiation."),
        [
            P(
                "عبادَ الله: الدنيا دارُ ابتلاء، لا تصفو لأحد، يتقلّبُ فيها الإنسانُ بين نعمةٍ تستوجبُ الشكر، ومصيبةٍ تستوجبُ الصبر. والصبرُ ثلاثة: صبرٌ على طاعةِ الله، وصبرٌ عن معصيتِه، وصبرٌ على أقدارِه المؤلمة.",
                "Servants of Allah: this world is a place of testing that is never pure for anyone. A person moves in it between a blessing that calls for gratitude and a calamity that calls for patience. Patience is of three kinds: patience in obeying Allah, patience in staying away from disobeying Him, and patience with His painful decrees.",
            ),
            A(2, 155, 157),
            A(39, 10, ar_from="إِنَّمَا يُوَفَّى", en_from="Indeed, the patient"),
            H("«عجبًا لأمرِ المؤمن، إنَّ أمرَه كلَّه خير، وليس ذاك لأحدٍ إلا للمؤمن: إن أصابته سرّاءُ شكر فكان خيرًا له، وإن أصابته ضرّاءُ صبر فكان خيرًا له»", "“How wonderful is the affair of the believer! All of his affairs are good, and that is for no one but the believer: if something good happens to him he is grateful and that is good for him, and if something harmful befalls him he is patient and that is good for him.”", "رواه مسلم (2999)", "Muslim 2999"),
        ],
        [
            P(
                "ومن رحمةِ اللهِ أنَّ ما يصيبُ المؤمنَ من ألمٍ لا يضيع، بل يُكفِّرُ اللهُ به خطاياه ويرفعُ درجته. فإذا نزل بك البلاء فقل: إنّا للهِ وإنّا إليه راجعون، واستعنْ بالصلاة، وأحسنِ الظنَّ بربِّك، واعلمْ أنَّ مع العسرِ يسرًا.",
                "Of Allah’s mercy is that no pain that strikes a believer is wasted; by it Allah expiates his sins and raises his rank. When trial comes, say: “To Allah we belong and to Him we return”, seek help through prayer, think well of your Lord, and know that with hardship comes ease.",
            ),
            H("«ما يصيبُ المسلمَ من نَصَبٍ ولا وَصَبٍ ولا همٍّ ولا حَزَنٍ ولا أذًى ولا غمٍّ، حتى الشوكةِ يُشاكُها، إلا كفّر اللهُ بها من خطاياه»", "“No fatigue, illness, worry, sorrow, harm or distress befalls a Muslim, not even a thorn that pricks him, except that Allah expiates some of his sins by it.”", "متفق عليه: البخاري (5641) ومسلم (2573)", "al-Bukhari 5641, Muslim 2573"),
        ],
        ("اللهمَّ أفرغْ علينا صبرًا، وارزقنا الرضا بقضائِك، والشكرَ على نعمائِك.", "O Allah, pour patience upon us, grant us contentment with Your decree and gratitude for Your blessings."),
    ),
    khutba(
        "gratitude", "faith",
        ("شكرُ النعم", "Gratitude for blessings"),
        ("نعم الله التي لا تُحصى، وكيف يكون الشكر بالقلب واللسان والجوارح، وسبب زيادة النعم.", "Allah’s countless blessings, gratitude with heart, tongue and limbs, and how blessings increase."),
        [
            P(
                "عبادَ الله: تأمّلوا في نعمِ اللهِ عليكم: نعمةِ الإسلام، ونعمةِ العافية، ونعمةِ الأمن، ونعمةِ الطعامِ والشرابِ والمسكن، ونعمِ السمعِ والبصرِ والعقل، وهي أكثرُ من أن تُعَدّ.",
                "Servants of Allah: reflect on Allah’s blessings upon you: Islam, health, safety, food, drink and shelter, hearing, sight and intellect; they are more than can be counted.",
            ),
            A(16, 18),
            A(14, 7),
            H("«مَن أصبح منكم آمنًا في سِربِه، معافًى في جسدِه، عنده قوتُ يومِه، فكأنما حِيزت له الدنيا»", "“Whoever among you wakes up secure in his home, healthy in his body and with his food for the day, it is as if the whole world has been gathered for him.”", "رواه الترمذي (2346) وابن ماجه (4141)", "at-Tirmidhi 2346, Ibn Majah 4141"),
        ],
        [
            P(
                "والشكرُ يكونُ بالقلب: اعترافًا بأنَّ النعمةَ من الله، وباللسان: حمدًا وثناءً وتحدّثًا بنعمته، وبالجوارح: باستعمالِ النعمةِ في طاعتِه لا في معصيتِه. ومن أعظمِ ما يُعينُ على الشكرِ أن ينظرَ المرءُ في أمرِ الدنيا إلى مَن هو دونه:",
                "Gratitude is with the heart, by acknowledging that every blessing is from Allah; with the tongue, by praise and speaking of His favour; and with the limbs, by using blessings in obedience to Him and not in disobedience. One of the greatest aids to gratitude is to look, in worldly matters, at those who have less:",
            ),
            H("«انظروا إلى مَن هو أسفلَ منكم، ولا تنظروا إلى مَن هو فوقَكم، فهو أجدرُ ألّا تزدروا نعمةَ اللهِ عليكم»", "“Look at those below you and do not look at those above you, for that is more likely to keep you from belittling Allah’s blessing upon you.”", "رواه مسلم (2963)", "Muslim 2963"),
            A(2, 152),
        ],
        ("اللهمَّ أعِنّا على ذكرِك وشكرِك وحسنِ عبادتِك، ولا تجعلنا من الغافلين.", "O Allah, help us to remember You, thank You and worship You well, and do not make us among the heedless."),
    ),
    khutba(
        "jumuah", "worship",
        ("يومُ الجمعة", "The day of Jumu‘ah"),
        ("خير يوم طلعت عليه الشمس، وآداب الجمعة وسننها، وساعة الإجابة.", "The best day the sun rises on, the etiquette and sunnahs of Friday, and the hour of response."),
        [
            P(
                "عبادَ الله: هدى اللهُ هذه الأمّةَ ليومِ الجمعة، وجعله عيدًا أسبوعيًّا تجتمعُ فيه القلوبُ قبل الأبدان، وتتجدّدُ فيه الصلةُ بالله، ويتعلّمُ فيه الناسُ دينَهم.",
                "Servants of Allah: Allah guided this nation to the day of Jumu‘ah and made it a weekly celebration in which hearts gather before bodies, the bond with Allah is renewed and people learn their religion.",
            ),
            A(62, 9, 10),
            H("«خيرُ يومٍ طلعت عليه الشمسُ يومُ الجمعة: فيه خُلِق آدم، وفيه أُدخِل الجنة، وفيه أُخرِج منها، ولا تقومُ الساعةُ إلا في يومِ الجمعة»", "“The best day on which the sun has risen is Friday: on it Adam was created, on it he was admitted to Paradise, on it he was expelled from it, and the Hour will not be established except on Friday.”", "رواه مسلم (854)", "Muslim 854"),
        ],
        [
            P(
                "ومن سننِ الجمعة: الاغتسال، والتطيّب، ولبسُ أحسنِ الثياب، والتبكيرُ إلى المسجد، والإنصاتُ للخطبة، وقراءةُ سورةِ الكهف، وتحرّي ساعةِ الإجابةِ آخرَ ساعةٍ بعد العصر، والإكثارُ من الصلاةِ على النبيِّ ﷺ:",
                "Among the sunnahs of Friday are bathing, wearing perfume and one’s best clothes, going early to the mosque, listening attentively to the khutbah, reading Surat al-Kahf, seeking the hour of response in the last hour after Asr, and sending abundant blessings upon the Prophet ﷺ:",
            ),
            H("«إنَّ مِن أفضلِ أيامِكم يومَ الجمعة، فيه خُلِق آدم، وفيه قُبِض، وفيه النفخة، وفيه الصعقة، فأكثِروا عليَّ من الصلاةِ فيه، فإنَّ صلاتَكم معروضةٌ عليّ»", "“Among the best of your days is Friday: on it Adam was created, on it he died, on it the Horn will be blown and on it all will swoon. So send abundant blessings upon me on it, for your blessings are presented to me.”", "رواه أبو داود (1047)", "Abu Dawud 1047"),
        ],
        ("اللهمَّ اجعلنا ممّن يستمعون القولَ فيتّبعون أحسنَه، ووفّقنا لساعةِ الإجابة.", "O Allah, make us among those who listen to speech and follow the best of it, and grant us the hour of response."),
    ),
]

# The Farewell Sermon is presented as narrated excerpts with context, not as a template sermon.
FAREWELL = {
    "id": "farewell",
    "cat": "prophetic",
    "titleAr": "خطبةُ حجّةِ الوداع",
    "titleEn": "The Farewell Sermon",
    "summaryAr": "مقتطفات صحيحة من خطبة النبي ﷺ في حجة الوداع سنة ١٠هـ، مع المصادر.",
    "summaryEn": "Authentic excerpts of the Prophet’s ﷺ sermon at the Farewell Pilgrimage in 10 AH, with sources.",
    "parts": [
        {
            "titleAr": "المناسبة",
            "titleEn": "Context",
            "blocks": [
                P(
                    "في السنةِ العاشرةِ من الهجرة حجَّ النبيُّ ﷺ حجّتَه الوحيدة، وشهدها جمعٌ عظيمٌ من المسلمين، فخطبهم يومَ عرفةَ ببطنِ الوادي خطبةً جامعةً قرّر فيها أصولَ الإسلامِ وحقوقَ الإنسان، وودّعهم فيها، فسُمّيت حجّةَ الوداع. ونزل في ذلك اليوم قولُه تعالى:",
                    "In the tenth year after the Hijrah the Prophet ﷺ performed his only Hajj, attended by a great multitude of Muslims. On the Day of Arafah, in the valley, he delivered a comprehensive sermon setting out the foundations of Islam and the rights of people, and bade them farewell, so it was called the Farewell Pilgrimage. On that day Allah revealed:",
                ),
                A(5, 3, ar_from="ٱلْيَوْمَ أَكْمَلْتُ", ar_to="دِينًا", en_from="This day I have perfected", en_to="as religion."),
            ],
        },
        {
            "titleAr": "من نصّ الخطبة",
            "titleEn": "From the sermon",
            "blocks": [
                H("«إنَّ دماءَكم وأموالَكم حرامٌ عليكم، كحُرمةِ يومِكم هذا، في شهرِكم هذا، في بلدِكم هذا، ألا كلُّ شيءٍ من أمرِ الجاهليةِ تحت قدميَّ موضوع»", "“Your blood and your wealth are sacred to you, as sacred as this day of yours, in this month of yours, in this land of yours. Behold, everything of the affairs of the Days of Ignorance is placed beneath my feet.”", "رواه مسلم (1218) من حديث جابر", "Muslim 1218, narrated by Jabir"),
                H("«فاتقوا اللهَ في النساء، فإنكم أخذتموهنَّ بأمانِ الله، واستحللتم فروجَهنَّ بكلمةِ الله»", "“Fear Allah concerning women, for you have taken them on the security of Allah and made them lawful to you by the word of Allah.”", "رواه مسلم (1218)", "Muslim 1218"),
                H("«وقد تركتُ فيكم ما لن تضلّوا بعدَه إن اعتصمتم به: كتابَ الله، وأنتم تُسألون عنّي، فما أنتم قائلون؟» قالوا: نشهدُ أنك قد بلّغتَ وأدّيتَ ونصحت، فقال بإصبعِه السبّابة يرفعُها إلى السماءِ وينكُتُها إلى الناس: «اللهمَّ اشهد، اللهمَّ اشهد» ثلاثَ مرّات", "“I have left among you that which, if you hold fast to it, you will never go astray: the Book of Allah. And you will be asked about me; what will you say?” They said: “We bear witness that you have conveyed, fulfilled and given sincere counsel.” He raised his index finger to the sky and pointed it at the people, saying: “O Allah, bear witness. O Allah, bear witness,” three times.", "رواه مسلم (1218)", "Muslim 1218"),
                H("«يا أيها الناس، ألا إنَّ ربَّكم واحد، وإنَّ أباكم واحد، ألا لا فضلَ لعربيٍّ على أعجميّ، ولا لعجميٍّ على عربيّ، ولا لأحمرَ على أسود، ولا أسودَ على أحمر، إلا بالتقوى»", "“O people, your Lord is one and your father is one. No Arab has superiority over a non-Arab, nor a non-Arab over an Arab, nor a red-skinned over a black-skinned, nor a black-skinned over a red-skinned, except by taqwa.”", "رواه أحمد (23489)", "Ahmad 23489"),
                H("«ليبلِّغِ الشاهدُ الغائب»", "“Let the one who is present convey it to the one who is absent.”", "متفق عليه: البخاري (67) ومسلم (1679)", "al-Bukhari 67, Muslim 1679"),
            ],
        },
        {
            "titleAr": "دروس وعبر",
            "titleEn": "Lessons",
            "blocks": [
                P(
                    "قرّرت الخطبةُ حرمةَ الدماءِ والأموالِ والأعراض، وأبطلت أعرافَ الجاهليةِ من الثأرِ والربا، وأوصت بالنساءِ خيرًا، وجعلت ميزانَ التفاضلِ بين الناسِ التقوى لا اللونَ ولا النسب، وربطت الأمّةَ بكتابِ ربِّها، وحمّلت كلَّ مسلمٍ أمانةَ البلاغ. وهي وصيّةُ مودِّع، فحريٌّ بكلِّ مسلمٍ أن يتدبّرها ويعملَ بها.",
                    "The sermon established the sanctity of life, property and honour, abolished the customs of the Days of Ignorance such as blood feuds and usury, enjoined good treatment of women, made taqwa, not colour or lineage, the measure of people’s worth, tied the nation to the Book of its Lord, and charged every Muslim with conveying the message. It is the counsel of one bidding farewell, and every Muslim should reflect on it and act upon it.",
                ),
            ],
        },
    ],
}

KHUTAB.append(FAREWELL)


def words(k):
    return sum(len(b["ar"].split()) for p in k["parts"] for b in p["blocks"])


ids = set()
for k in KHUTAB:
    assert k["id"] not in ids, k["id"]
    ids.add(k["id"])
    assert k["cat"] in {c["id"] for c in CATEGORIES}, k["cat"]
    for p in k["parts"]:
        for b in p["blocks"]:
            assert b["ar"] and b["en"], (k["id"], b)
    # A khutbah is delivered at roughly 100 Arabic words a minute.
    k["minutes"] = max(3, round(words(k) / 100))

out = {
    "_note": "Sermons written for NOOR. Quranic text: Tanzil Uthmani (CC BY 3.0) with Saheeh International, copied from assets/data/quran. Hadith cited by collection and number. Review by a qualified scholar is required before publication.",
    "categories": CATEGORIES,
    "khutab": KHUTAB,
}
with open(f"{root}/assets/data/khutab.json", "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
print(len(KHUTAB), "khutab", [(k["id"], k["minutes"]) for k in KHUTAB])
