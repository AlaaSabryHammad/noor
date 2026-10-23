import json, sys
def load_quran(root):
    d = json.load(open(f"{root}/assets/data/quran/index.json", encoding="utf-8"))
    d["text"] = {str(n): json.load(open(f"{root}/assets/data/quran/{n:03d}.json", encoding="utf-8")) for n in range(1, 115)}
    return d

root = sys.argv[1] if len(sys.argv) > 1 else "."

Q = load_quran(root)
AYAH_96_1 = Q["text"]["96"][0]["ar"]  # taken verbatim from the dataset

def dump(name, obj):
    with open(f"{root}/assets/data/{name}.json", "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)

NOTE = "Verify wording and numbering against a scholar-reviewed edition before release."

# ------------------------------------------------------------------ hadith
# topic: faith | character | knowledge | worship | dhikr
H = [
 ("faith", "بُنِيَ الْإِسْلَامُ عَلَىٰ خَمْسٍ: شَهَادَةِ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَأَنَّ مُحَمَّدًا رَسُولُ اللَّهِ، وَإِقَامِ الصَّلَاةِ، وَإِيتَاءِ الزَّكَاةِ، وَحَجِّ الْبَيْتِ، وَصَوْمِ رَمَضَانَ",
  "Islam is built upon five: the testimony that there is no god but Allah and that Muhammad is the Messenger of Allah, establishing the prayer, giving zakat, pilgrimage to the House, and fasting Ramadan.",
  "متفق عليه · البخاري (٨) ومسلم (١٦) · الأربعون النووية (٣)", "Agreed upon · Al-Bukhari 8, Muslim 16 · Forty Hadith an-Nawawi 3"),
 ("faith", "الدِّينُ النَّصِيحَةُ. قُلْنَا: لِمَنْ؟ قَالَ: لِلَّهِ، وَلِكِتَابِهِ، وَلِرَسُولِهِ، وَلِأَئِمَّةِ الْمُسْلِمِينَ وَعَامَّتِهِمْ",
  "Religion is sincere advice. We said: For whom? He said: For Allah, His Book, His Messenger, and the leaders of the Muslims and their common folk.",
  "رواه مسلم (٥٥) · الأربعون النووية (٧)", "Muslim 55 · Forty Hadith an-Nawawi 7"),
 ("character", "مِنْ حُسْنِ إِسْلَامِ الْمَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ",
  "Part of the excellence of a person's Islam is leaving what does not concern them.",
  "رواه الترمذي (٢٣١٧) · الأربعون النووية (١٢)", "At-Tirmidhi 2317 · Forty Hadith an-Nawawi 12"),
 ("character", "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّىٰ يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
  "None of you truly believes until he loves for his brother what he loves for himself.",
  "متفق عليه · البخاري (١٣) ومسلم (٤٥) · الأربعون النووية (١٣)", "Agreed upon · Al-Bukhari 13, Muslim 45 · Forty Hadith an-Nawawi 13"),
 ("character", "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ",
  "Whoever believes in Allah and the Last Day, let him speak good or remain silent.",
  "متفق عليه · البخاري (٦٠١٨) ومسلم (٤٧) · الأربعون النووية (١٥)", "Agreed upon · Al-Bukhari 6018, Muslim 47 · Forty Hadith an-Nawawi 15"),
 ("character", "قَالَ رَجُلٌ لِلنَّبِيِّ ﷺ: أَوْصِنِي. قَالَ: لَا تَغْضَبْ. فَرَدَّدَ مِرَارًا، قَالَ: لَا تَغْضَبْ",
  "A man said to the Prophet ﷺ: Advise me. He said: Do not become angry. The man repeated it several times, and he said: Do not become angry.",
  "رواه البخاري (٦١١٦) · الأربعون النووية (١٦)", "Al-Bukhari 6116 · Forty Hadith an-Nawawi 16"),
 ("character", "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ",
  "The strong person is not the one who overpowers others; the strong person is the one who controls himself in anger.",
  "متفق عليه · البخاري (٦١١٤) ومسلم (٢٦٠٩)", "Agreed upon · Al-Bukhari 6114, Muslim 2609"),
 ("character", "اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ",
  "Fear Allah wherever you are, follow a bad deed with a good one and it will erase it, and treat people with good character.",
  "رواه الترمذي (١٩٨٧) · الأربعون النووية (١٨)", "At-Tirmidhi 1987 · Forty Hadith an-Nawawi 18"),
 ("character", "الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ",
  "A Muslim is one from whose tongue and hand the Muslims are safe.",
  "متفق عليه · البخاري (١٠) ومسلم (٤١)", "Agreed upon · Al-Bukhari 10, Muslim 41"),
 ("character", "مَنْ لَا يَرْحَمْ لَا يُرْحَمْ",
  "Whoever does not show mercy will not be shown mercy.",
  "متفق عليه · البخاري (٥٩٩٧) ومسلم (٢٣١٨)", "Agreed upon · Al-Bukhari 5997, Muslim 2318"),
 ("character", "الرَّاحِمُونَ يَرْحَمُهُمُ الرَّحْمَٰنُ، ارْحَمُوا مَنْ فِي الْأَرْضِ يَرْحَمْكُمْ مَنْ فِي السَّمَاءِ",
  "The merciful are shown mercy by the Most Merciful. Be merciful to those on earth and the One above the heavens will be merciful to you.",
  "رواه أبو داود (٤٩٤١) والترمذي (١٩٢٤)", "Abu Dawud 4941 · At-Tirmidhi 1924"),
 ("character", "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ",
  "Your smiling in the face of your brother is charity.",
  "رواه الترمذي (١٩٥٦)", "At-Tirmidhi 1956"),
 ("character", "الْكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ",
  "A good word is charity.",
  "متفق عليه · البخاري (٢٩٨٩) ومسلم (١٠٠٩)", "Agreed upon · Al-Bukhari 2989, Muslim 1009"),
 ("faith", "إِنَّ اللَّهَ لَا يَنْظُرُ إِلَىٰ صُوَرِكُمْ وَأَمْوَالِكُمْ، وَلَٰكِنْ يَنْظُرُ إِلَىٰ قُلُوبِكُمْ وَأَعْمَالِكُمْ",
  "Allah does not look at your appearances or your wealth, but He looks at your hearts and your deeds.",
  "رواه مسلم (٢٥٦٤)", "Muslim 2564"),
 ("knowledge", "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ",
  "The best of you are those who learn the Quran and teach it.",
  "رواه البخاري (٥٠٢٧)", "Al-Bukhari 5027"),
 ("knowledge", "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ",
  "Whoever travels a path seeking knowledge, Allah makes easy for him a path to Paradise.",
  "رواه مسلم (٢٦٩٩)", "Muslim 2699"),
 ("worship", "الطُّهُورُ شَطْرُ الْإِيمَانِ",
  "Purification is half of faith.",
  "رواه مسلم (٢٢٣)", "Muslim 223"),
 ("worship", "أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ",
  "The most beloved deeds to Allah are the most consistent, even if small.",
  "متفق عليه · البخاري (٦٤٦٤) ومسلم (٧٨٣)", "Agreed upon · Al-Bukhari 6464, Muslim 783"),
 ("dhikr", "كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَٰنِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
  "Two phrases are light on the tongue, heavy on the scale, and beloved to the Most Merciful: Glory and praise to Allah; Glory to Allah the Magnificent.",
  "متفق عليه · البخاري (٦٤٠٦) ومسلم (٢٦٩٤)", "Agreed upon · Al-Bukhari 6406, Muslim 2694"),
]
TOPICS = {"faith": ("الإيمان", "Faith"), "character": ("الأخلاق", "Character"), "knowledge": ("العلم", "Knowledge"), "worship": ("العبادة", "Worship"), "dhikr": ("الذكر", "Remembrance")}
dump("hadith", {"_note": NOTE, "topics": {k: {"ar": v[0], "en": v[1]} for k, v in TOPICS.items()},
                "items": [dict(id=f"h{i+1}", topic=t, ar=a, en=e, sourceAr=sa, sourceEn=se) for i, (t, a, e, sa, se) in enumerate(H)]})

# ------------------------------------------------------------------ seerah
S = [
 ("نحو ٥٧٠م", "c. 570 CE", "مولده ﷺ", "The Birth", "وُلد النبي محمد ﷺ في مكة المكرمة في عام الفيل، يوم الاثنين من شهر ربيع الأول، في بني هاشم من قريش. تُوفي والده عبد الله قبل ولادته، فكفله جدّه عبد المطلب.",
  "Muhammad ﷺ was born in Makkah in the Year of the Elephant, on a Monday in Rabi‘ al-Awwal, among Banu Hashim of Quraysh. His father ‘Abdullah died before his birth, and his grandfather ‘Abd al-Muttalib took care of him."),
 ("نحو ٥٧٦م", "c. 576 CE", "وفاة أمه وكفالة جده وعمه", "Loss of His Mother", "تُوفيت أمه آمنة وهو في السادسة من عمره، وبعد عامين تُوفي جده عبد المطلب، فكفله عمه أبو طالب.",
  "His mother Aminah died when he was six. Two years later his grandfather died, and his uncle Abu Talib became his guardian."),
 ("نحو ٥٩٥م", "c. 595 CE", "زواجه من خديجة", "Marriage to Khadijah", "تزوّج النبي ﷺ من خديجة بنت خويلد رضي الله عنها وهو في الخامسة والعشرين، وكانت أول من آمن به.",
  "At twenty-five he married Khadijah bint Khuwaylid, may Allah be pleased with her, who was the first to believe in him."),
 ("٦١٠م", "610 CE", "نزول الوحي", "The First Revelation", "نزل عليه جبريل عليه السلام في غار حراء في شهر رمضان وهو في الأربعين، فأنزل الله عليه أولى آيات سورة العلق: ﴿" + AYAH_96_1 + "﴾.",
  "In the cave of Hira, in Ramadan and at the age of forty, Jibril (peace be upon him) came to him and the first verses of Surat al-‘Alaq were revealed: “Read in the name of your Lord who created.”"),
 ("٦١٣م", "613 CE", "الجهر بالدعوة", "The Public Call", "بعد ثلاث سنوات من الدعوة السرية أمره الله بالجهر بالدعوة، فصعد على الصفا ودعا قريشًا إلى عبادة الله وحده.",
  "After three years of secret preaching he was commanded to call openly. He climbed Mount Safa and invited Quraysh to worship Allah alone."),
 ("٦١٥م", "615 CE", "الهجرة إلى الحبشة", "Migration to Abyssinia", "اشتدّ أذى قريش للمسلمين، فأمر النبي ﷺ أصحابه بالهجرة إلى الحبشة حيث ملك عادل لا يُظلم عنده أحد.",
  "As Quraysh intensified their persecution, the Prophet ﷺ advised his companions to migrate to Abyssinia, ruled by a just king."),
 ("٦١٦–٦١٩م", "616–619 CE", "حصار شِعب أبي طالب", "The Boycott", "قاطعت قريش بني هاشم وبني المطلب نحو ثلاث سنوات في شِعب أبي طالب، حتى نُقضت الصحيفة.",
  "Quraysh boycotted Banu Hashim and Banu al-Muttalib for about three years in the valley of Abu Talib, until the pact was annulled."),
 ("٦١٩م", "619 CE", "عام الحزن", "The Year of Sorrow", "تُوفي في هذا العام عمه أبو طالب وزوجته خديجة رضي الله عنها، وبعدها خرج إلى الطائف يدعو أهلها فردّوه وآذوه.",
  "In this year his uncle Abu Talib and his wife Khadijah died. He then went to Ta’if to call its people, but they rejected and harmed him."),
 ("نحو ٦٢١م", "c. 621 CE", "الإسراء والمعراج", "The Night Journey", "أُسري بالنبي ﷺ من المسجد الحرام إلى المسجد الأقصى، ثم عُرج به إلى السماوات العُلى، وفُرضت الصلوات الخمس.",
  "He was taken by night from the Sacred Mosque to al-Aqsa, then ascended through the heavens, and the five daily prayers were prescribed."),
 ("٦٢٢م", "1 AH · 622 CE", "الهجرة إلى المدينة", "The Hijrah", "هاجر النبي ﷺ مع أبي بكر الصديق من مكة إلى المدينة المنورة، وبنى مسجده، وآخى بين المهاجرين والأنصار. ومن هذا الحدث بدأ التقويم الهجري.",
  "The Prophet ﷺ migrated with Abu Bakr from Makkah to Madinah, built his mosque and joined the Muhajirun and Ansar in brotherhood. The Hijri calendar begins with this event."),
 ("٦٢٤م", "2 AH · 624 CE", "غزوة بدر", "The Battle of Badr", "في السابع عشر من رمضان انتصر المسلمون، وهم نحو ثلاثمئة، على جيش قريش الذي يفوقهم عددًا.",
  "On the 17th of Ramadan the Muslims, about three hundred, defeated a Qurayshi army several times their size."),
 ("٦٢٥م", "3 AH · 625 CE", "غزوة أحد", "The Battle of Uhud", "وقعت عند جبل أحد قرب المدينة، وكان فيها اختبار للمسلمين بعد مخالفة الرماة موقعهم.",
  "Fought at Mount Uhud near Madinah, it became a trial for the Muslims after the archers left their position."),
 ("٦٢٧م", "5 AH · 627 CE", "غزوة الخندق", "The Battle of the Trench", "حفر المسلمون خندقًا حول المدينة بمشورة سلمان الفارسي، فردّ الله الأحزاب خائبين.",
  "The Muslims dug a trench around Madinah on the advice of Salman al-Farisi, and Allah turned the confederates back."),
 ("٦٢٨م", "6 AH · 628 CE", "صلح الحديبية", "The Treaty of Hudaybiyyah", "عقد النبي ﷺ صلحًا مع قريش لعشر سنين، وسمّاه القرآن فتحًا مبينًا، وفتح باب الدعوة على مصراعيه.",
  "The Prophet ﷺ agreed a ten-year truce with Quraysh. The Quran called it a clear victory, and it opened wide the door for the message."),
 ("٦٣٠م", "8 AH · 630 CE", "فتح مكة", "The Conquest of Makkah", "دخل النبي ﷺ مكة في رمضان في جيش كبير دون قتال يُذكر، وعفا عن أهلها، وطهّر الكعبة من الأصنام.",
  "The Prophet ﷺ entered Makkah in Ramadan with a large army and almost no fighting, forgave its people and cleansed the Ka‘bah of idols."),
 ("٦٣١م", "9 AH · 631 CE", "عام الوفود", "The Year of Delegations", "توافدت القبائل العربية إلى المدينة لإعلان إسلامها، وكانت غزوة تبوك في هذه الفترة.",
  "Arab tribes sent delegations to Madinah to embrace Islam; the expedition to Tabuk took place in this period."),
 ("٦٣٢م", "10 AH · 632 CE", "حجة الوداع", "The Farewell Pilgrimage", "حجّ النبي ﷺ بالمسلمين وخطب في عرفة خطبته الجامعة، ونزلت آية إكمال الدين (المائدة: ٣).",
  "He performed Hajj with the Muslims and delivered his comprehensive sermon at ‘Arafah, where the verse was revealed: “Today I have perfected for you your religion.”"),
 ("٦٣٢م", "11 AH · 632 CE", "وفاته ﷺ", "His Passing", "تُوفي النبي ﷺ في المدينة في الثاني عشر من ربيع الأول، ودُفن في حجرة عائشة رضي الله عنها.",
  "The Prophet ﷺ passed away in Madinah on the 12th of Rabi‘ al-Awwal and was buried in the room of ‘A’ishah, may Allah be pleased with her."),
]
dump("seerah", {"_note": "Dates are traditional approximations; scholars differ on some. " + NOTE,
                "events": [dict(yearAr=y, yearEn=ye, titleAr=ta, titleEn=te, bodyAr=ba, bodyEn=be) for y, ye, ta, te, ba, be in S]})
print(len(H), len(S))
