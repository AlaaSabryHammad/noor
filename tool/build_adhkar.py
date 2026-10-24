import json, sys
def load_quran(root):
    d = json.load(open(f"{root}/assets/data/quran/index.json", encoding="utf-8"))
    d["text"] = {str(n): json.load(open(f"{root}/assets/data/quran/{n:03d}.json", encoding="utf-8")) for n in range(1, 115)}
    return d

root = sys.argv[1] if len(sys.argv) > 1 else "." if len(sys.argv) > 1 else "."  # project root
Q = load_quran(root)
S = {s["number"]: s for s in Q["surahs"]}
AR_DIGITS = "٠١٢٣٤٥٦٧٨٩"

def ard(n):
    return "".join(AR_DIGITS[int(c)] for c in str(n))

def quran(s, a, b=None):
    """(ar, en, sourceAr, sourceEn) for ayah range, text straight from the dataset."""
    b = b or a
    items = Q["text"][str(s)][a - 1:b]
    ar = " ".join(i["ar"] for i in items)
    en = " ".join(i["en"] for i in items)
    rng_ar = ard(a) if a == b else f"{ard(a)}-{ard(b)}"
    rng_en = f"{a}" if a == b else f"{a}-{b}"
    return ar, en, f"سورة {S[s]['nameAr']} · الآية {rng_ar}", f"{S[s]['nameEn']} {s}:{rng_en}"

def qi(id_, s, a, b=None, repeat=1):
    ar, en, sa, se = quran(s, a, b)
    return dict(id=id_, ar=ar, en=en, sourceAr=sa, sourceEn=se, repeat=repeat)

def h(id_, ar, en, sa, se, repeat=1):
    return dict(id=id_, ar=ar, en=en, sourceAr=sa, sourceEn=se, repeat=repeat)

def sura3(prefix, repeat):
    out = []
    for i, (s, nm) in enumerate([(112, "الإخلاص"), (113, "الفلق"), (114, "الناس")]):
        it = qi(f"{prefix}{i}", s, 1, len(Q["text"][str(s)]), repeat)
        out.append(it)
    return out

data = json.load(open(f"{root}/assets/data/adhkar.json", encoding="utf-8"))
data.pop("_note", None)
data["morning"] = data["morning"][:6]  # re-runnable: keep the original six, re-append the rest

KURSI = lambda id_, repeat=1: qi(id_, 2, 255, None, repeat)

# ---------------------------------------------------------------- morning (append)
data["morning"] += [
    KURSI("m7"),
    *[dict(x, id=x["id"].replace("mm", "m8_")) for x in sura3("mm", 3)],
    h("m9", "اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ",
      "O Allah, grant me well-being in my body. O Allah, grant me well-being in my hearing. O Allah, grant me well-being in my sight. None has the right to be worshipped but You.",
      "رواه أبو داود (٥٠٩٠)", "Abu Dawud 5090", 3),
    h("m10", "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا",
      "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.",
      "رواه أبو داود (١٥٣٠) والترمذي (٣٣٨٩)", "Abu Dawud 1529 · At-Tirmidhi 3389", 3),
]

# ---------------------------------------------------------------- evening
data["evening"] = [
    KURSI("e1"),
    *[dict(x, id=x["id"].replace("ee", "e2_")) for x in sura3("ee", 3)],
    h("e3", "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَٰذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَٰذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
      "We have entered the evening and the dominion belongs to Allah, and all praise is for Allah. None has the right to be worshipped but Allah alone, without partner; His is the dominion and His is the praise, and He is over all things capable. My Lord, I ask You for the good of this night and what follows it, and seek refuge in You from the evil of this night and what follows it. My Lord, I seek refuge in You from laziness and the misery of old age; from punishment in the Fire and punishment in the grave.",
      "رواه مسلم (٢٧٢٣)", "Muslim 2723"),
    h("e4", "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ",
      "O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the final return.",
      "رواه الترمذي (٣٣٩١)", "At-Tirmidhi 3391"),
    h("e5", "اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَٰهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ",
      "O Allah, I have entered the evening calling You, the bearers of Your Throne, Your angels and all Your creation to witness that You are Allah, none has the right to be worshipped but You alone, without partner, and that Muhammad is Your servant and Messenger.",
      "رواه أبو داود (٥٠٦٩)", "Abu Dawud 5069", 4),
    h("e6", "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
      "In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, the All-Knowing.",
      "رواه أبو داود (٥٠٨٨) والترمذي (٣٣٨٨)", "Abu Dawud 5088 · At-Tirmidhi 3388", 3),
    h("e7", "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
      "I seek refuge in the perfect words of Allah from the evil of what He has created.",
      "رواه مسلم (٢٧٠٩)", "Muslim 2709", 3),
    h("e8", "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
      "Glory is to Allah and praise is to Him.",
      "رواه مسلم (٢٦٩٢)", "Muslim 2692", 100),
]

# ---------------------------------------------------------------- sleep
data["sleep"] = [
    KURSI("s1"),
    qi("s2", 2, 285, 286),
    h("s3", "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
      "In Your name, O Allah, I die and I live.",
      "رواه البخاري (٦٣٢٤)", "Al-Bukhari 6324"),
    h("s4", "اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ",
      "O Allah, I submit myself to You, entrust my affairs to You, turn my face to You, and rely on You, out of hope and fear of You. There is no refuge and no escape from You except to You. I believe in Your Book which You revealed and in Your Prophet whom You sent.",
      "رواه البخاري (٦٣١٣) ومسلم (٢٧١٠)", "Al-Bukhari 6313 · Muslim 2710"),
    h("s5", "سُبْحَانَ اللَّهِ",
      "Glory is to Allah.",
      "رواه البخاري (٣١١٣) ومسلم (٢٧٢٧)", "Al-Bukhari 3113 · Muslim 2727", 33),
    h("s6", "الْحَمْدُ لِلَّهِ",
      "All praise is for Allah.",
      "رواه البخاري (٣١١٣) ومسلم (٢٧٢٧)", "Al-Bukhari 3113 · Muslim 2727", 33),
    h("s7", "اللَّهُ أَكْبَرُ",
      "Allah is the Greatest.",
      "رواه البخاري (٣١١٣) ومسلم (٢٧٢٧)", "Al-Bukhari 3113 · Muslim 2727", 34),
    *[dict(x, id=x["id"].replace("ss", "s8_")) for x in sura3("ss", 3)],
    h("s9", "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ",
      "O Allah, protect me from Your punishment on the day You resurrect Your servants.",
      "رواه أبو داود (٥٠٤٥) والترمذي (٣٣٩٨)", "Abu Dawud 5045 · At-Tirmidhi 3398", 3),
]

# ---------------------------------------------------------------- waking
data["waking"] = [
    h("w1", "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
      "All praise is for Allah who gave us life after having taken it from us, and to Him is the resurrection.",
      "رواه البخاري (٦٣١٢)", "Al-Bukhari 6312"),
    h("w2", "الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لِي بِذِكْرِهِ",
      "All praise is for Allah who gave me well-being in my body, returned my soul to me, and permitted me to remember Him.",
      "رواه الترمذي (٣٤٠١)", "At-Tirmidhi 3401"),
    qi("w3", 3, 190, 191),
]

# ---------------------------------------------------------------- after prayer
data["after_prayer"] = [
    h("p1", "أَسْتَغْفِرُ اللَّهَ",
      "I seek the forgiveness of Allah.",
      "رواه مسلم (٥٩١)", "Muslim 591", 3),
    h("p2", "اللَّهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ",
      "O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of majesty and honour.",
      "رواه مسلم (٥٩١)", "Muslim 591"),
    h("p3", "لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ",
      "None has the right to be worshipped but Allah alone, without partner; His is the dominion and His is the praise, and He is over all things capable. O Allah, none can withhold what You give, none can give what You withhold, and the might of the mighty cannot benefit them against You.",
      "رواه البخاري (٨٤٤) ومسلم (٥٩٣)", "Al-Bukhari 844 · Muslim 593"),
    h("p4", "سُبْحَانَ اللَّهِ", "Glory is to Allah.", "رواه مسلم (٥٩٧)", "Muslim 597", 33),
    h("p5", "الْحَمْدُ لِلَّهِ", "All praise is for Allah.", "رواه مسلم (٥٩٧)", "Muslim 597", 33),
    h("p6", "اللَّهُ أَكْبَرُ", "Allah is the Greatest.", "رواه مسلم (٥٩٧)", "Muslim 597", 33),
    h("p7", "لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ",
      "None has the right to be worshipped but Allah alone, without partner; His is the dominion and His is the praise, and He is over all things capable.",
      "رواه مسلم (٥٩٧) — تمام المئة", "Muslim 597 — completing one hundred"),
    KURSI("p8"),
    h("p9", "اللَّهُمَّ أَعِنِّي عَلَىٰ ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ",
      "O Allah, help me to remember You, to thank You, and to worship You well.",
      "رواه أبو داود (١٥٢٢)", "Abu Dawud 1522"),
]

# ---------------------------------------------------------------- wudu
data["wudu"] = [
    h("u1", "بِسْمِ اللَّهِ",
      "In the name of Allah.",
      "عند البدء بالوضوء · رواه أبو داود (١٠١) وابن ماجه (٣٩٧)", "When starting wudu · Abu Dawud 101 · Ibn Majah 397"),
    h("u2", "أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ",
      "I bear witness that none has the right to be worshipped but Allah alone, without partner, and I bear witness that Muhammad is His servant and Messenger.",
      "بعد الوضوء · رواه مسلم (٢٣٤)", "After wudu · Muslim 234"),
    h("u3", "اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ، وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ",
      "O Allah, make me among those who repent and make me among those who purify themselves.",
      "بعد الوضوء · رواه الترمذي (٥٥)", "After wudu · At-Tirmidhi 55"),
]

# ---------------------------------------------------------------- mosque
data["mosque"] = [
    h("o1", "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ",
      "O Allah, open the gates of Your mercy for me.",
      "عند دخول المسجد · رواه مسلم (٧١٣)", "Entering the mosque · Muslim 713"),
    h("o2", "اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ",
      "O Allah, I ask You of Your bounty.",
      "عند الخروج من المسجد · رواه مسلم (٧١٣)", "Leaving the mosque · Muslim 713"),
    h("o3", "يَقُولُ مِثْلَ مَا يَقُولُ الْمُؤَذِّنُ، ثُمَّ يُصَلِّي عَلَى النَّبِيِّ ﷺ، ثُمَّ يَقُولُ: اللَّهُمَّ رَبَّ هَٰذِهِ الدَّعْوَةِ التَّامَّةِ وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ",
      "Repeat what the muezzin says, then send blessings upon the Prophet ﷺ, then say: O Allah, Lord of this perfect call and the established prayer, grant Muhammad the intercession and the favour, and raise him to the praised station You have promised him.",
      "عند سماع الأذان · رواه البخاري (٦١١، ٦١٤) ومسلم (٣٨٤)", "On hearing the adhan · Al-Bukhari 611, 614 · Muslim 384"),
]

# ---------------------------------------------------------------- travel
data["travel"] = [
    h("t1", "اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَىٰ رَبِّنَا لَمُنْقَلِبُونَ، اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَٰذَا الْبِرَّ وَالتَّقْوَىٰ، وَمِنَ الْعَمَلِ مَا تَرْضَىٰ، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَٰذَا وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ، وَالْخَلِيفَةُ فِي الْأَهْلِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ وَعْثَاءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالْأَهْلِ",
      "Allah is the Greatest (three times). Glory to Him who has subjected this to us, and we could not have subdued it, and to our Lord we shall return. O Allah, we ask You on this journey for righteousness, piety and deeds that please You. O Allah, make this journey easy for us and shorten its distance. O Allah, You are the Companion on the journey and the Guardian of the family. O Allah, I seek refuge in You from the hardship of travel, from a sorrowful sight, and from an evil return in wealth and family.",
      "رواه مسلم (١٣٤٢)", "Muslim 1342"),
    h("t2", "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
      "I seek refuge in the perfect words of Allah from the evil of what He has created.",
      "عند النزول في مكان · رواه مسلم (٢٧٠٨)", "When stopping at a place · Muslim 2708"),
    h("t3", "آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ",
      "We return, repenting, worshipping, and praising our Lord.",
      "عند العودة من السفر · رواه مسلم (١٣٤٢)", "On returning from travel · Muslim 1342"),
]

# ---------------------------------------------------------------- food
data["food"] = [
    h("f1", "بِسْمِ اللَّهِ",
      "In the name of Allah.",
      "قبل الطعام · رواه أبو داود (٣٧٦٧) والترمذي (١٨٥٨)", "Before eating · Abu Dawud 3767 · At-Tirmidhi 1858"),
    h("f2", "بِسْمِ اللَّهِ أَوَّلَهُ وَآخِرَهُ",
      "In the name of Allah at its beginning and at its end.",
      "إذا نسي التسمية في أوله · رواه أبو داود (٣٧٦٧) والترمذي (١٨٥٨)", "If one forgot to say it at the start · Abu Dawud 3767 · At-Tirmidhi 1858"),
    h("f3", "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَٰذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ",
      "All praise is for Allah who fed me this and provided it for me without any power or might from myself.",
      "بعد الطعام · رواه أبو داود (٤٠٢٣) والترمذي (٣٤٥٨)", "After eating · Abu Dawud 4023 · At-Tirmidhi 3458"),
    h("f4", "اللَّهُمَّ بَارِكْ لَهُمْ فِيمَا رَزَقْتَهُمْ، وَاغْفِرْ لَهُمْ وَارْحَمْهُمْ",
      "O Allah, bless them in what You have provided for them, forgive them and have mercy on them.",
      "دعاء الضيف لصاحب الطعام · رواه مسلم (٢٠٤٢)", "A guest's dua for the host · Muslim 2042"),
]

# ---------------------------------------------------------------- home
data["home"] = [
    h("h1", "بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا",
      "In the name of Allah we enter, in the name of Allah we leave, and upon our Lord we rely.",
      "عند دخول المنزل · رواه أبو داود (٥٠٩٦)", "Entering the home · Abu Dawud 5096"),
    h("h2", "بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
      "In the name of Allah, I place my trust in Allah, and there is no might and no power except with Allah.",
      "عند الخروج من المنزل · رواه أبو داود (٥٠٩٥) والترمذي (٣٤٢٦)", "Leaving the home · Abu Dawud 5095 · At-Tirmidhi 3426"),
    h("h3", "بِسْمِ اللَّهِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ",
      "In the name of Allah. O Allah, I seek refuge in You from the male and female unclean spirits.",
      "عند دخول الخلاء · رواه البخاري (١٤٢) ومسلم (٣٧٥)", "Entering the toilet · Al-Bukhari 142 · Muslim 375"),
    h("h4", "غُفْرَانَكَ",
      "I ask You for Your forgiveness.",
      "عند الخروج من الخلاء · رواه أبو داود (٣٠) والترمذي (٧)", "Leaving the toilet · Abu Dawud 30 · At-Tirmidhi 7"),
]

# ---------------------------------------------------------------- Quranic duas
def qd(id_, s, a, b, ctx_ar, ctx_en):
    """A Quranic supplication, attributed to whoever said it when that is stated by the ayah's context."""
    it = qi(id_, s, a, b)
    if ctx_ar:
        it["sourceAr"] = f"{ctx_ar} · {it['sourceAr']}"
        it["sourceEn"] = f"{ctx_en} · {it['sourceEn']}"
    return it


# (surah, from, to, who/what — Arabic, English), in mushaf order
QURAN_DUAS = [
    (1, 5, 7, "دعاء الهداية", "The prayer for guidance"),
    (2, 127, 128, "دعاء إبراهيم وإسماعيل عليهما السلام", "Ibrahim and Isma‘il"),
    (2, 129, 129, "دعاء إبراهيم عليه السلام", "Ibrahim"),
    (2, 201, 201, "دعاء الدنيا والآخرة", "For this world and the next"),
    (2, 250, 250, "دعاء جند طالوت", "The soldiers of Talut"),
    (2, 286, 286, "خاتمة سورة البقرة", "The end of Al-Baqarah"),
    (3, 8, 8, "دعاء الراسخين في العلم", "Those firm in knowledge"),
    (3, 16, 16, "دعاء المتقين", "The God-fearing"),
    (3, 26, 27, "دعاء مالك الملك", "Owner of Sovereignty"),
    (3, 38, 38, "دعاء زكريا عليه السلام", "Zakariyya"),
    (3, 53, 53, "دعاء الحواريين", "The disciples of ‘Isa"),
    (3, 147, 147, "دعاء أتباع الأنبياء", "Followers of the prophets"),
    (3, 191, 194, "دعاء أولي الألباب", "People of understanding"),
    (4, 75, 75, "دعاء المستضعفين", "The oppressed"),
    (5, 114, 114, "دعاء عيسى عليه السلام", "‘Isa"),
    (7, 23, 23, "دعاء آدم وحواء عليهما السلام", "Adam and Hawwa"),
    (7, 47, 47, "دعاء أهل الأعراف", "The people of al-A‘raf"),
    (7, 89, 89, "دعاء شعيب عليه السلام", "Shu‘ayb"),
    (7, 126, 126, "دعاء سحرة فرعون", "Pharaoh’s magicians"),
    (7, 151, 151, "دعاء موسى عليه السلام", "Musa"),
    (9, 129, 129, "حسبي الله", "Allah is sufficient for me"),
    (10, 85, 86, "دعاء أصحاب موسى", "Those with Musa"),
    (11, 47, 47, "دعاء نوح عليه السلام", "Nuh"),
    (12, 101, 101, "دعاء يوسف عليه السلام", "Yusuf"),
    (14, 35, 36, "دعاء إبراهيم عليه السلام", "Ibrahim"),
    (14, 37, 37, "دعاء إبراهيم عليه السلام", "Ibrahim"),
    (14, 38, 38, "دعاء إبراهيم عليه السلام", "Ibrahim"),
    (14, 40, 41, "دعاء إبراهيم عليه السلام", "Ibrahim"),
    (17, 24, 24, "الدعاء للوالدين", "For one’s parents"),
    (17, 80, 80, "", ""),
    (18, 10, 10, "دعاء فتية الكهف", "The youths of the cave"),
    (20, 25, 28, "دعاء موسى عليه السلام", "Musa"),
    (20, 114, 114, "دعاء طلب العلم", "For more knowledge"),
    (21, 83, 83, "دعاء أيوب عليه السلام", "Ayyub"),
    (21, 87, 87, "دعاء يونس عليه السلام", "Yunus"),
    (21, 89, 89, "دعاء زكريا عليه السلام", "Zakariyya"),
    (23, 29, 29, "دعاء نوح عليه السلام", "Nuh"),
    (23, 97, 98, "الاستعاذة من الشياطين", "Refuge from the devils"),
    (23, 109, 109, "دعاء عباد الله المؤمنين", "The believing servants"),
    (23, 118, 118, "الاستغفار والرحمة", "Forgiveness and mercy"),
    (25, 65, 66, "دعاء عباد الرحمن", "Servants of the Most Merciful"),
    (25, 74, 74, "دعاء عباد الرحمن", "Servants of the Most Merciful"),
    (26, 83, 89, "دعاء إبراهيم عليه السلام", "Ibrahim"),
    (26, 169, 169, "دعاء لوط عليه السلام", "Lut"),
    (27, 19, 19, "دعاء سليمان عليه السلام", "Sulayman"),
    (28, 16, 16, "دعاء موسى عليه السلام", "Musa"),
    (28, 21, 21, "دعاء موسى عليه السلام", "Musa"),
    (28, 24, 24, "دعاء موسى عليه السلام", "Musa"),
    (29, 30, 30, "دعاء لوط عليه السلام", "Lut"),
    (37, 100, 100, "دعاء إبراهيم عليه السلام", "Ibrahim"),
    (38, 35, 35, "دعاء سليمان عليه السلام", "Sulayman"),
    (40, 7, 9, "دعاء الملائكة للمؤمنين", "The angels for the believers"),
    (46, 15, 15, "دعاء الشكر والبر بالوالدين", "Gratitude and kindness to parents"),
    (54, 10, 10, "دعاء نوح عليه السلام", "Nuh"),
    (59, 10, 10, "دعاء من جاؤوا بعد الصحابة", "Those who came after the Companions"),
    (60, 4, 5, "دعاء إبراهيم والذين معه", "Ibrahim and those with him"),
    (66, 8, 8, "دعاء التوبة النصوح", "Sincere repentance"),
    (66, 11, 11, "دعاء امرأة فرعون", "Pharaoh’s wife"),
    (71, 28, 28, "دعاء نوح عليه السلام", "Nuh"),
]
data["quran_duas"] = [qd(f"q{i + 1}", s, a, b, car, cen) for i, (s, a, b, car, cen) in enumerate(QURAN_DUAS)]
# ---------------------------------------------------------------- Sunnah duas
data["sunnah_duas"] = [
    h("d1", "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ",
      "O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from miserliness and cowardice, and from the burden of debt and the oppression of men.",
      "رواه البخاري (٦٣٦٩)", "Al-Bukhari 6369"),
    h("d2", "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَىٰ وَالتُّقَىٰ وَالْعَفَافَ وَالْغِنَىٰ",
      "O Allah, I ask You for guidance, piety, chastity and self-sufficiency.",
      "رواه مسلم (٢٧٢١)", "Muslim 2721"),
    h("d3", "اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الْحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ، وَاجْعَلِ الْمَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ",
      "O Allah, set right my religion which is the safeguard of my affairs, set right my worldly life in which is my livelihood, set right my hereafter to which is my return; make life an increase for me in every good, and make death a relief for me from every evil.",
      "رواه مسلم (٢٧٢٠)", "Muslim 2720"),
    h("d4", "يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَىٰ دِينِكَ",
      "O Turner of hearts, keep my heart firm upon Your religion.",
      "رواه الترمذي (٢١٤٠)", "At-Tirmidhi 2140"),
    h("d5", "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي",
      "O Allah, You are Pardoning and love to pardon, so pardon me.",
      "رواه الترمذي (٣٥١٣) وابن ماجه (٣٨٥٠)", "At-Tirmidhi 3513 · Ibn Majah 3850"),
    h("d6", "اللَّهُمَّ اغْفِرْ لِي ذَنْبِي كُلَّهُ، دِقَّهُ وَجِلَّهُ، وَأَوَّلَهُ وَآخِرَهُ، وَعَلَانِيَتَهُ وَسِرَّهُ",
      "O Allah, forgive me all my sins, small and great, first and last, open and secret.",
      "رواه مسلم (٤٨٣)", "Muslim 483"),
    h("d7", "اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي بَصَرِي نُورًا، وَفِي سَمْعِي نُورًا",
      "O Allah, place light in my heart, light in my sight and light in my hearing.",
      "رواه البخاري (٦٣١٦) ومسلم (٧٦٣)", "Al-Bukhari 6316 · Muslim 763"),
    h("d8", "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ",
      "O Allah, send prayers upon Muhammad and the family of Muhammad, as You sent prayers upon Ibrahim and the family of Ibrahim; You are indeed Praiseworthy and Glorious.",
      "الصلاة الإبراهيمية · رواه البخاري (٣٣٧٠)", "The Ibrahimi salawat · Al-Bukhari 3370"),
]

data["_note"] = "Quranic items are taken verbatim from assets/data/quran.json (Tanzil). Hadith-based adhkar are given with their primary source; verify wording and numbering against a scholar-reviewed edition (e.g. Hisn al-Muslim) before release."

with open(f"{root}/assets/data/adhkar.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=1)
print({k: len(v) for k, v in data.items() if isinstance(v, list)})
