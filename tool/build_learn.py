import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import more_content as MC  # additional entries merged into the lists below

root = sys.argv[1] if len(sys.argv) > 1 else "."
NOTE = "Summaries of Quranic narratives and basic rulings. Verify against a scholar-reviewed source before release; for rulings consult qualified scholars."

def dump(name, obj):
    with open(f"{root}/assets/data/{name}.json", "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)

# ------------------------------------------------------------------ stories of the prophets
ST = [
 ("آدم", "Adam", "خلق الله آدم عليه السلام من طين وأسجد له الملائكة تكريمًا، فامتنع إبليس تكبّرًا. أسكنه الله وزوجه الجنة ونهاهما عن شجرة، فوسوس لهما الشيطان فأكلا منها، ثم تابا فتاب الله عليهما وأهبطهما إلى الأرض.",
  "Allah created Adam from clay and had the angels prostrate to him in honour; Iblis refused out of arrogance. Adam and his wife lived in Paradise and were forbidden one tree. Satan whispered to them, they ate from it, then repented and Allah accepted their repentance and sent them down to earth.",
  "البقرة ٣٠–٣٩ · الأعراف ١١–٢٥", "Al-Baqarah 30–39 · Al-A‘raf 11–25", "التوبة بعد الخطأ باب مفتوح.", "Repentance after a mistake is always open."),
 ("نوح", "Nuh (Noah)", "دعا نوح عليه السلام قومه إلى عبادة الله وحده قرابة ألف سنة إلا خمسين عامًا فلم يؤمن معه إلا قليل. أمره الله ببناء السفينة، ونجّاه ومن آمن معه من الطوفان.",
  "Nuh called his people to worship Allah alone for nine hundred and fifty years, yet only a few believed. Allah commanded him to build the ark and saved him and the believers from the flood.",
  "هود ٢٥–٤٩ · نوح", "Hud 25–49 · Nuh", "الصبر على الدعوة وعاقبة الإيمان النجاة.", "Patience in calling to Allah; salvation lies with faith."),
 ("هود وصالح", "Hud and Salih", "أرسل الله هودًا إلى قوم عاد، وصالحًا إلى ثمود، فدعوا قومهما إلى التوحيد. كذّب القومان رسولهما فأهلكهم الله، ونجّى الرسولين والمؤمنين.",
  "Allah sent Hud to ‘Ad and Salih to Thamud. Both called their people to monotheism; both peoples denied their messenger and were destroyed, while the prophets and believers were saved.",
  "هود ٥٠–٦٨ · الأعراف ٦٥–٧٩", "Hud 50–68 · Al-A‘raf 65–79", "القوة والمال لا تغني عن الحق.", "Strength and wealth cannot replace truth."),
 ("إبراهيم", "Ibrahim (Abraham)", "خليل الله إبراهيم عليه السلام تأمّل في الكون حتى عرف ربه، وحطّم أصنام قومه وألقوه في النار فجعلها الله بردًا وسلامًا عليه. ثم هاجر، ورفع مع ابنه إسماعيل قواعد الكعبة.",
  "Ibrahim, the Friend of Allah, reflected on the universe until he knew his Lord. He broke his people’s idols and was thrown into the fire, which Allah made cool and safe. He later migrated and, with his son Isma‘il, raised the foundations of the Ka‘bah.",
  "الأنبياء ٥١–٧٣ · البقرة ١٢٤–١٢٩ · الصافات ٨٣–١١١", "Al-Anbiya 51–73 · Al-Baqarah 124–129 · As-Saffat 83–111", "التوحيد والتسليم لأمر الله.", "Pure monotheism and submission to Allah."),
 ("لوط", "Lut (Lot)", "أرسل الله لوطًا إلى قومه ينهاهم عن فاحشة لم يسبقهم بها أحد، فأصرّوا وكذّبوا، فنجّاه الله وأهله إلا امرأته وأمطر عليهم حجارة.",
  "Lut was sent to a people who practised an immorality no one before them had committed. They persisted and denied him; Allah saved him and his family except his wife, and rained stones upon the people.",
  "هود ٧٧–٨٣ · الأعراف ٨٠–٨٤", "Hud 77–83 · Al-A‘raf 80–84", "الفطرة السليمة تحتاج إلى حماية.", "Sound nature must be protected."),
 ("يوسف", "Yusuf (Joseph)", "رأى يوسف رؤيا في صغره، فكاده إخوته وألقوه في الجب، ثم بيع في مصر، وصبر على فتنة وسجن، ثم مكّن الله له وصار على خزائن الأرض، وجمع الله شمله بأهله.",
  "As a child Yusuf saw a dream. His brothers plotted against him and cast him into a well; he was sold in Egypt, endured temptation and prison, and Allah gave him authority over the land’s treasuries and reunited him with his family.",
  "سورة يوسف", "Surah Yusuf (12)", "«أحسن القصص»: الصبر والعفو والثقة بتدبير الله.", "“The best of stories”: patience, forgiveness and trust in Allah’s plan."),
 ("أيوب", "Ayyub (Job)", "ابتلاه الله في جسده وماله وأهله فصبر صبرًا جميلًا ولم يشكُ إلا إلى الله، فكشف الله ضرّه وأعاد إليه أهله ومثلهم معهم.",
  "Allah tested Ayyub in his body, wealth and family. He was patient with beautiful patience, complaining only to Allah, who removed his affliction and restored his family and more.",
  "الأنبياء ٨٣–٨٤ · ص ٤١–٤٤", "Al-Anbiya 83–84 · Sad 41–44", "الصبر على البلاء ثمرته الفرج.", "Patience in hardship is followed by relief."),
 ("موسى", "Musa (Moses)", "وُلد موسى عليه السلام في زمن فرعون الذي كان يقتل أبناء بني إسرائيل، فحفظه الله وربّاه في قصر فرعون. ثم كلّمه الله وأرسله إلى فرعون وقومه، وشقّ له البحر فنجا هو ومن معه وأغرق الله فرعون.",
  "Musa was born when Pharaoh was killing the sons of Bani Isra’il; Allah protected him and he was raised in Pharaoh’s palace. Allah spoke to him and sent him to Pharaoh. The sea was parted for him, so he and his people were saved and Pharaoh was drowned.",
  "القصص ٣–٤٣ · طه ٩–٧٩", "Al-Qasas 3–43 · Ta-Ha 9–79", "الله ينصر المستضعفين بالإيمان والصبر.", "Allah supports the oppressed through faith and patience."),
 ("داود وسليمان", "Dawud and Sulayman", "آتى الله داود الزبور وألان له الحديد وسخّر معه الجبال والطير. وورث سليمان ملكه، فسخّر الله له الريح والجن، وفهّمه منطق الطير والنمل، وكان شاكرًا.",
  "Allah gave Dawud the Zabur, softened iron for him and made the mountains and birds glorify with him. Sulayman inherited his kingdom; Allah subjected the wind and jinn to him and taught him the speech of birds and ants, and he remained thankful.",
  "النمل ١٥–٤٤ · ص ١٧–٤٠", "An-Naml 15–44 · Sad 17–40", "النعمة تقتضي الشكر.", "Blessings call for gratitude."),
 ("يونس", "Yunus (Jonah)", "ذهب يونس عليه السلام مغاضبًا قبل أن يؤذن له، فالتقمه الحوت، فنادى في الظلمات بدعاء التوحيد والتوبة المذكور في سورة الأنبياء (٨٧)، فنجّاه الله.",
  "Yunus left his people in anger before being permitted, and the whale swallowed him. In the depths he called out: “There is no god but You, glory to You, I was among the wrongdoers,” and Allah saved him.",
  "الأنبياء ٨٧–٨٨ · الصافات ١٣٩–١٤٨", "Al-Anbiya 87–88 · As-Saffat 139–148", "دعاء ذي النون فرجٌ لكل كرب.", "The supplication of Dhun-Nun relieves every distress."),
 ("عيسى", "‘Isa (Jesus)", "وُلد عيسى عليه السلام من مريم العذراء بأمر الله دون أب، وتكلّم في المهد، وأيّده الله بالمعجزات بإذنه، ودعا بني إسرائيل إلى عبادة الله وحده، ورفعه الله إليه.",
  "‘Isa was born to the virgin Maryam by Allah’s command without a father and spoke in the cradle. Allah supported him with miracles by His permission; he called Bani Isra’il to worship Allah alone, and Allah raised him to Himself.",
  "مريم ١٦–٣٦ · آل عمران ٤٥–٥٩", "Maryam 16–36 · Al ‘Imran 45–59", "عبد الله ورسوله وكلمته ألقاها إلى مريم.", "The servant and messenger of Allah, His word cast to Maryam."),
]
ST += MC.STORIES_EXTRA
assert sorted(MC.STORIES_ORDER) == sorted(s[0] for s in ST), "STORIES_ORDER is out of sync with the stories"
ST.sort(key=lambda s: MC.STORIES_ORDER.index(s[0]))
dump("stories", {"_note": NOTE, "items": [dict(id=f"p{i+1}", nameAr=a, nameEn=e, bodyAr=ba, bodyEn=be, refAr=ra, refEn=re, lessonAr=la, lessonEn=le)
                                           for i, (a, e, ba, be, ra, re, la, le) in enumerate(ST)]})

# ------------------------------------------------------------------ academy (step-by-step lessons)
AC = [
 ("wudu", "الوضوء", "Wudu", "water_drop",
  [("النية", "Intention", "تنوي بقلبك رفع الحدث واستباحة الصلاة، ولا يُشرع التلفظ بها.", "Intend in your heart to purify yourself for prayer; no need to say it aloud."),
   ("التسمية", "Say Bismillah", "تقول: بسم الله.", "Say: Bismillah."),
   ("غسل الكفين", "Wash the hands", "تغسل كفيك ثلاث مرات.", "Wash both hands three times."),
   ("المضمضة والاستنشاق", "Rinse mouth and nose", "تتمضمض وتستنشق وتستنثر ثلاثًا.", "Rinse your mouth and sniff water into your nose and blow it out, three times."),
   ("غسل الوجه", "Wash the face", "تغسل وجهك كله ثلاث مرات، من منابت الشعر إلى أسفل الذقن، ومن الأذن إلى الأذن.", "Wash the whole face three times, from the hairline to the chin and ear to ear."),
   ("غسل اليدين", "Wash the arms", "تغسل يديك مع المرفقين ثلاثًا، اليمنى ثم اليسرى.", "Wash the arms up to and including the elbows, three times, right then left."),
   ("مسح الرأس والأذنين", "Wipe the head and ears", "تمسح رأسك كله مرة واحدة، ثم أذنيك.", "Wipe over the whole head once, then the ears."),
   ("غسل الرجلين", "Wash the feet", "تغسل رجليك مع الكعبين ثلاثًا، اليمنى ثم اليسرى.", "Wash the feet including the ankles, three times, right then left."),
   ("الدعاء بعد الوضوء", "Dua after wudu", "تقول: أشهد أن لا إله إلا الله وحده لا شريك له، وأشهد أن محمدًا عبده ورسوله.", "Say: I bear witness that there is no god but Allah alone, without partner, and that Muhammad is His servant and Messenger.")]),
 ("prayer", "كيف أصلي", "How to pray", "mosque",
  [("النية والاستقبال", "Intention and facing the Qibla", "تستقبل القبلة وتنوي الصلاة التي تريدها بقلبك.", "Face the Qibla and intend the prayer in your heart."),
   ("تكبيرة الإحرام", "Opening takbir", "تقول: الله أكبر، رافعًا يديك حذو منكبيك أو أذنيك.", "Say Allahu Akbar, raising the hands to the shoulders or ears."),
   ("القيام وقراءة الفاتحة", "Standing and Al-Fatihah", "تضع يدك اليمنى على اليسرى على صدرك، وتقرأ دعاء الاستفتاح ثم الفاتحة، ثم ما تيسّر من القرآن.", "Place the right hand over the left on the chest, recite the opening supplication, then Al-Fatihah, then something of the Quran."),
   ("الركوع", "Bowing (ruku‘)", "تكبّر وتركع وظهرك مستوٍ، وتقول: سبحان ربي العظيم، ثلاثًا.", "Say Allahu Akbar and bow with a straight back, saying: Subhana Rabbiyal-‘Azim, three times."),
   ("الاعتدال", "Rising", "تقول: سمع الله لمن حمده، ثم: ربنا ولك الحمد.", "Rise saying: Sami‘a Allahu liman hamidah, then: Rabbana wa lakal-hamd."),
   ("السجود", "Prostration (sujud)", "تكبّر وتسجد على سبعة أعضاء: الجبهة والأنف واليدين والركبتين وأطراف القدمين، وتقول: سبحان ربي الأعلى، ثلاثًا.", "Say Allahu Akbar and prostrate on seven points: forehead and nose, both hands, both knees and the toes, saying: Subhana Rabbiyal-A‘la, three times."),
   ("الجلوس بين السجدتين", "Sitting between prostrations", "تجلس مطمئنًا وتقول: رب اغفر لي، ثم تسجد الثانية.", "Sit calmly saying: Rabbigh-fir li, then make the second prostration."),
   ("التشهد", "The tashahhud", "في الركعة الثانية والأخيرة تجلس وتقرأ التشهد والصلاة الإبراهيمية.", "In the second and final rak‘ah, sit and recite the tashahhud and the Ibrahimi salawat."),
   ("التسليم", "The salam", "تسلّم عن يمينك ثم عن يسارك: السلام عليكم ورحمة الله.", "Give salam to the right and then to the left: As-salamu ‘alaykum wa rahmatullah."),
   ("عدد الركعات", "Number of rak‘ahs", "الفجر ٢، الظهر ٤، العصر ٤، المغرب ٣، العشاء ٤.", "Fajr 2, Dhuhr 4, ‘Asr 4, Maghrib 3, ‘Isha 4.")]),
 ("pillars", "أركان الإسلام", "Pillars of Islam", "account_balance",
  [("الشهادتان", "The testimony of faith", "شهادة أن لا إله إلا الله وأن محمدًا رسول الله.", "Testifying that there is no god but Allah and that Muhammad is His Messenger."),
   ("الصلاة", "Prayer", "إقامة الصلوات الخمس في أوقاتها.", "Establishing the five daily prayers at their times."),
   ("الزكاة", "Zakat", "إخراج جزء معلوم من المال لمستحقيه.", "Giving a set portion of wealth to those entitled."),
   ("الصوم", "Fasting", "صيام شهر رمضان من الفجر إلى المغرب.", "Fasting Ramadan from dawn to sunset."),
   ("الحج", "Hajj", "حج بيت الله الحرام لمن استطاع إليه سبيلًا.", "Pilgrimage to the Sacred House for whoever is able.")]),
 ("iman", "أركان الإيمان", "Pillars of Faith", "auto_awesome",
  [("الإيمان بالله", "Belief in Allah", "الإيمان بوجود الله وربوبيته وألوهيته وأسمائه وصفاته.", "Believing in Allah’s existence, lordship, divinity, names and attributes."),
   ("الإيمان بالملائكة", "Belief in the angels", "عباد مكرمون يطيعون الله ولا يعصونه.", "Honoured servants who obey Allah and never disobey."),
   ("الإيمان بالكتب", "Belief in the Books", "القرآن والتوراة والإنجيل والزبور وصحف إبراهيم وموسى.", "The Quran, Tawrah, Injil, Zabur and the scrolls of Ibrahim and Musa."),
   ("الإيمان بالرسل", "Belief in the Messengers", "من آدم إلى محمد ﷺ خاتم النبيين.", "From Adam to Muhammad ﷺ, the Seal of the Prophets."),
   ("الإيمان باليوم الآخر", "Belief in the Last Day", "البعث والحساب والجنة والنار.", "Resurrection, reckoning, Paradise and the Fire."),
   ("الإيمان بالقدر", "Belief in the Decree", "أن كل شيء بعلم الله وتقديره، خيره وشره.", "That everything occurs by Allah’s knowledge and decree, its good and its bad.")]),
]
AC += MC.ACADEMY_EXTRA
ACADEMY_ORDER = ["wudu", "ghusl", "tayammum", "prayer", "adhan", "sunnah", "jumuah", "eid", "janazah", "fasting", "zakat", "pillars", "iman", "quranadab", "tajweed"]
assert sorted(ACADEMY_ORDER) == sorted(c[0] for c in AC), "ACADEMY_ORDER is out of sync with the courses"
AC.sort(key=lambda c: ACADEMY_ORDER.index(c[0]))
dump("academy", {"_note": NOTE, "courses": [dict(id=i, titleAr=ta, titleEn=te, icon=ic,
                  lessons=[dict(titleAr=a, titleEn=b, bodyAr=c, bodyEn=d) for a, b, c, d in steps]) for i, ta, te, ic, steps in AC]})

# ------------------------------------------------------------------ FAQ (basics only)
FQ = [
 ("faith", "ما هي الشهادتان؟", "What is the Shahadah?", "قول: أشهد أن لا إله إلا الله وأشهد أن محمدًا رسول الله، وهي مفتاح الدخول في الإسلام وأول أركانه.", "Saying: I bear witness that there is no god but Allah and that Muhammad is the Messenger of Allah. It is the entry into Islam and its first pillar."),
 ("faith", "كم عدد أركان الإسلام وأركان الإيمان؟", "How many pillars of Islam and faith are there?", "أركان الإسلام خمسة، وأركان الإيمان ستة.", "Islam has five pillars and faith has six."),
 ("prayer", "كم عدد الصلوات المفروضة في اليوم؟", "How many prayers are obligatory each day?", "خمس صلوات: الفجر والظهر والعصر والمغرب والعشاء.", "Five: Fajr, Dhuhr, ‘Asr, Maghrib and ‘Isha."),
 ("prayer", "ما هي القبلة؟", "What is the Qibla?", "اتجاه الكعبة المشرفة في مكة المكرمة، يستقبله المسلمون في صلاتهم.", "The direction of the Ka‘bah in Makkah, which Muslims face in prayer."),
 ("prayer", "ما صلاة الجمعة؟", "What is the Friday prayer?", "صلاة تُؤدى جماعةً يوم الجمعة وقت الظهر وتسبقها خطبتان، وهي واجبة على الرجال المقيمين المكلفين.", "A congregational prayer held on Friday at midday preceded by two sermons; it is obligatory on resident adult men."),
 ("fasting", "متى يبدأ الصيام وينتهي؟", "When does the fast begin and end?", "يبدأ من طلوع الفجر الصادق وينتهي بغروب الشمس، مع الامتناع عن الطعام والشراب والمفطرات.", "From true dawn until sunset, abstaining from food, drink and other things that break the fast."),
 ("fasting", "ما هي ليلة القدر؟", "What is Laylat al-Qadr?", "ليلة نزل فيها القرآن وهي خير من ألف شهر، وتُلتمس في الوتر من العشر الأواخر من رمضان.", "The night in which the Quran was revealed, better than a thousand months, sought in the odd nights of the last ten of Ramadan."),
 ("zakat", "ما مقدار الزكاة؟", "How much is zakat?", "ربع العشر، أي ٢٫٥٪ من المال الذي بلغ النصاب وحال عليه الحول.", "One-fortieth, i.e. 2.5% of wealth that reaches the nisab and has been held for a lunar year."),
 ("zakat", "ما هو النصاب؟", "What is the nisab?", "ما يعادل ٨٥ غرامًا من الذهب أو ٥٩٥ غرامًا من الفضة، ويختلف تقديره باختلاف الأسعار.", "The equivalent of 85 grams of gold or 595 grams of silver; its value changes with prices."),
 ("zakat", "ما زكاة الفطر؟", "What is Zakat al-Fitr?", "صدقة تُخرج في آخر رمضان عن كل فرد، طعامًا يقتاته أهل البلد، وتُؤدى قبل صلاة العيد.", "A charity given at the end of Ramadan for each person, in staple food, paid before the Eid prayer."),
 ("hajj", "على من يجب الحج؟", "Upon whom is Hajj obligatory?", "على المسلم البالغ العاقل المستطيع ماديًا وبدنيًا، مرة واحدة في العمر.", "On every adult sane Muslim who is financially and physically able, once in a lifetime."),
 ("hajj", "ما الفرق بين الحج والعمرة؟", "What is the difference between Hajj and ‘Umrah?", "الحج له وقت محدد في ذي الحجة ومناسك في منى وعرفة ومزدلفة، أما العمرة فتجوز في أي وقت وهي الإحرام والطواف والسعي والحلق أو التقصير.", "Hajj has a fixed time in Dhul-Hijjah with rites at Mina, ‘Arafah and Muzdalifah; ‘Umrah can be done any time and consists of ihram, tawaf, sa‘i and shaving or trimming."),
]
FC = {"faith": ("الإيمان", "Faith"), "prayer": ("الصلاة", "Prayer"), "fasting": ("الصيام", "Fasting"), "zakat": ("الزكاة", "Zakat"), "hajj": ("الحج", "Hajj")}
FC.update(MC.FAQ_CATEGORIES_EXTRA)
FQ += MC.FAQ_EXTRA
FC = {k: FC[k] for k in MC.FAQ_ORDER}
FQ.sort(key=lambda f: MC.FAQ_ORDER.index(f[0]))  # stable: keeps the written order inside each category
dump("faq", {"_note": NOTE, "categories": {k: {"ar": v[0], "en": v[1]} for k, v in FC.items()},
             "items": [dict(id=f"f{i+1}", cat=c, qAr=qa, qEn=qe, aAr=aa, aEn=ae) for i, (c, qa, qe, aa, ae) in enumerate(FQ)]})

# ------------------------------------------------------------------ Hajj and Umrah guide
HJ = [
 ("umrah", "الإحرام", "Ihram", "تغتسل وتلبس ثياب الإحرام وتنوي العمرة من الميقات، وتكثر من التلبية: لبيك اللهم لبيك، لبيك لا شريك لك لبيك، إن الحمد والنعمة لك والملك، لا شريك لك.", "Bathe, wear the ihram garments and make the intention for ‘Umrah at the miqat, repeating the talbiyah: Labbayk Allahumma labbayk, labbayk la sharika laka labbayk, innal-hamda wan-ni‘mata laka wal-mulk, la sharika lak."),
 ("umrah", "الطواف", "Tawaf", "تطوف بالكعبة سبعة أشواط تبدأ من الحجر الأسود وتجعل الكعبة عن يسارك.", "Circle the Ka‘bah seven times starting at the Black Stone, keeping the Ka‘bah on your left."),
 ("umrah", "ركعتا الطواف", "Two rak‘ahs after tawaf", "تصلي ركعتين خلف مقام إبراهيم إن تيسّر، ثم تشرب من ماء زمزم.", "Pray two rak‘ahs behind the Station of Ibrahim if possible, then drink Zamzam water."),
 ("umrah", "السعي", "Sa‘i", "تسعى بين الصفا والمروة سبعة أشواط، تبدأ بالصفا وتنتهي بالمروة.", "Walk between Safa and Marwah seven times, beginning at Safa and ending at Marwah."),
 ("umrah", "الحلق أو التقصير", "Shaving or trimming", "يحلق الرجل رأسه أو يقصّر، وتقصّر المرأة قدر أنملة، فتنتهي العمرة.", "Men shave or trim the hair; women trim a fingertip’s length. The ‘Umrah is complete."),
 ("hajj", "٨ ذو الحجة · يوم التروية", "8 Dhul-Hijjah · Tarwiyah", "تحرم بالحج وتذهب إلى منى، وتصلي فيها الظهر والعصر والمغرب والعشاء والفجر قصرًا دون جمع.", "Enter ihram for Hajj and go to Mina, praying each prayer there shortened but not combined."),
 ("hajj", "٩ ذو الحجة · يوم عرفة", "9 Dhul-Hijjah · ‘Arafah", "الوقوف بعرفة هو ركن الحج الأعظم: «الحج عرفة». تجمع الظهر والعصر جمع تقديم وتكثر من الدعاء حتى الغروب.", "Standing at ‘Arafah is the essence of Hajj: “Hajj is ‘Arafah.” Combine Dhuhr and ‘Asr and supplicate until sunset."),
 ("hajj", "ليلة العاشر · مزدلفة", "Night of the 10th · Muzdalifah", "تنفر بعد الغروب إلى مزدلفة فتجمع المغرب والعشاء وتبيت بها، وتلتقط الحصى.", "Leave ‘Arafah after sunset for Muzdalifah, combine Maghrib and ‘Isha, spend the night and collect pebbles."),
 ("hajj", "١٠ ذو الحجة · يوم النحر", "10 Dhul-Hijjah · Eid day", "ترمي جمرة العقبة بسبع حصيات، ثم تنحر هديك، ثم تحلق أو تقصّر، ثم تطوف طواف الإفاضة وتسعى.", "Stone Jamrat al-‘Aqabah with seven pebbles, offer your sacrifice, shave or trim, then perform Tawaf al-Ifadah and sa‘i."),
 ("hajj", "١١–١٣ ذو الحجة · أيام التشريق", "11–13 Dhul-Hijjah · Tashriq", "تبيت بمنى وترمي الجمرات الثلاث كل يوم بعد الزوال، كل واحدة بسبع حصيات.", "Stay at Mina and stone the three jamarat each day after midday, seven pebbles each."),
 ("hajj", "طواف الوداع", "Farewell tawaf", "إذا أردت مغادرة مكة تطوف طواف الوداع ليكون آخر عهدك بالبيت.", "Before leaving Makkah, perform the farewell tawaf so that the House is your last stop."),
]
HJ += MC.HAJJ_GUIDE
dump("hajj", {"_note": NOTE, "steps": [dict(kind=k, titleAr=a, titleEn=b, bodyAr=c, bodyEn=d) for k, a, b, c, d in HJ]})

# ------------------------------------------------------------------ Kids quiz
KQ = [
 ("كم عدد أركان الإسلام؟", "How many pillars does Islam have?", [("٣", "3"), ("٥", "5"), ("٧", "7")], 1),
 ("ما هو كتاب المسلمين المقدس؟", "What is the holy book of Muslims?", [("القرآن الكريم", "The Quran"), ("الإنجيل", "The Injil"), ("الزبور", "The Zabur")], 0),
 ("كم صلاة نصلي في اليوم والليلة؟", "How many prayers do we pray each day?", [("٣", "3"), ("٤", "4"), ("٥", "5")], 2),
 ("في أي شهر نصوم؟", "In which month do we fast?", [("رمضان", "Ramadan"), ("شوال", "Shawwal"), ("رجب", "Rajab")], 0),
 ("ما اسم آخر الأنبياء؟", "Who is the last Prophet?", [("موسى عليه السلام", "Musa"), ("محمد ﷺ", "Muhammad ﷺ"), ("عيسى عليه السلام", "‘Isa")], 1),
 ("إلى أين نتجه في الصلاة؟", "Which direction do we face in prayer?", [("الكعبة في مكة", "The Ka‘bah in Makkah"), ("الشمال", "North"), ("المسجد الأقصى", "Al-Aqsa")], 0),
 ("ماذا نقول قبل الأكل؟", "What do we say before eating?", [("الحمد لله", "Alhamdulillah"), ("بسم الله", "Bismillah"), ("سبحان الله", "SubhanAllah")], 1),
 ("كم عدد سور القرآن الكريم؟", "How many surahs are in the Quran?", [("١١٤", "114"), ("٩٩", "99"), ("٣٠", "30")], 0),
 ("ما أول سورة في المصحف؟", "What is the first surah in the Quran?", [("البقرة", "Al-Baqarah"), ("الفاتحة", "Al-Fatihah"), ("الإخلاص", "Al-Ikhlas")], 1),
 ("ماذا نقول عند العطاس؟", "What do we say after sneezing?", [("الحمد لله", "Alhamdulillah"), ("بسم الله", "Bismillah"), ("الله أكبر", "Allahu Akbar")], 0),
]
KM = [
 ("السلام", "Salam", "نبدأ لقاءنا بقول: السلام عليكم", "We greet with: As-salamu ‘alaykum"),
 ("الصدق", "Honesty", "المسلم صادق ولا يكذب", "A Muslim is truthful and does not lie"),
 ("بر الوالدين", "Kindness to parents", "نحسن إلى والدينا ونطيعهما بالمعروف", "We are kind to our parents and obey them in what is good"),
 ("النظافة", "Cleanliness", "النظافة من الإيمان", "Cleanliness is part of faith"),
 ("مساعدة الآخرين", "Helping others", "نبتسم ونساعد من يحتاج مساعدتنا", "We smile and help those in need"),
]
KQ += MC.KIDS_QUIZ_EXTRA
KM += MC.KIDS_MANNERS_EXTRA
dump("kids", {"_note": NOTE, "quiz": [dict(qAr=a, qEn=b, options=[dict(ar=x, en=y) for x, y in o], answer=ans) for a, b, o, ans in KQ],
              "manners": [dict(titleAr=a, titleEn=b, bodyAr=c, bodyEn=d) for a, b, c, d in KM]})
print(len(ST), len(AC), len(FQ), len(HJ), len(KQ))
