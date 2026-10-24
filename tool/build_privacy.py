"""Builds the privacy policy from one source of truth.

  assets/data/privacy.json     read by the in-app screen (Settings > Privacy)
  site/privacy/index.html      the public page the app stores ask for (Firebase Hosting, see firebase.json)

Usage:  python -X utf8 tool/build_privacy.py . --email you@example.com [--name "Your name"]

The contact details are required by the App Store and Google Play. They are not stored in this repository: pass
them on the command line when building, or the contact section is left out and a warning is printed.
Update UPDATED and the text whenever the app starts collecting something new (see docs/RELEASE.md).
"""
import argparse
import html
import json
import os

UPDATED = "2026-10-24"

# (id, titleAr, titleEn, [paragraphAr...], [paragraphEn...])
SECTIONS = [
    ("summary", "ملخص", "Summary",
     ["نور يعمل دون حساب، ولا يحتوي على إعلانات ولا أدوات تحليلات سلوكية أو تتبّع، ولا نبيع بياناتك.",
      "تبقى معظم بياناتك على جهازك وحده. توضّح هذه الصفحة ما يُحفظ، وما قد يخرج من جهازك، وكيف تتحكم فيه."],
     ["NOOR works without an account, has no ads and no behavioural analytics or tracking tools, and we do not sell your data.",
      "Most of your data stays on your device. This page explains what is stored, what can leave your device, and how you control it."]),
    ("device", "ما يبقى على جهازك", "What stays on your device",
     ["اللغة والمظهر وحجم الخط وتعديل التاريخ الهجري، وموضع القراءة والعلامات والمحفوظات، وعدّادات الأذكار والتسبيح، وخطة العبادة اليومية وتتبّع رمضان، وإعدادات حساب المواقيت والمدينة المختارة.",
      "تُحفظ هذه البيانات محليًا على جهازك ولا نصل إليها، وتُحذف بمسح بيانات التطبيق أو إلغاء تثبيته."],
     ["Language, theme, text size and Hijri adjustment; your reading position, bookmarks and saved items; adhkar and tasbeeh counters; your daily worship plan and Ramadan tracker; prayer-time settings and the city you chose.",
      "This data is stored locally on your device, we cannot access it, and it is removed by clearing the app’s data or uninstalling the app."]),
    ("location", "الموقع", "Location",
     ["إذا سمحت بالوصول إلى الموقع تُحسب مواقيت الصلاة واتجاه القبلة على جهازك نفسه. لا يُرسل موقعك إلينا ولا يُخزَّن على أي خادم لدينا. يمكنك أيضًا اختيار مدينة يدويًا دون منح إذن الموقع.",
      "عند الضغط على «مساجد قريبة» يفتح التطبيق رابط بحث في تطبيق الخرائط أو المتصفح (خرائط Google) متضمنًا إحداثيات موقعك، فتخضع للخدمة التي تفتح الرابط ولسياستها."],
     ["If you allow location access, prayer times and the Qibla direction are calculated on your device. Your location is not sent to us and is not stored on any server of ours. You can also pick a city manually without granting location permission.",
      "When you tap “Nearby mosques” the app opens a search link in your maps app or browser (Google Maps) that contains your coordinates, so that service and its policy apply to that request."]),
    ("account", "الحساب (اختياري)", "Account (optional)",
     ["الحساب اختياري. إذا أنشأت حسابًا أو سجّلت الدخول (بالبريد وكلمة المرور أو Google أو Apple أو كزائر) فالمصادقة تتم عبر خدمة Firebase Authentication من Google.",
      "البيانات المعالَجة: عنوان بريدك، والاسم وصورة الملف الشخصي إن وفّرها مزوّد الدخول، ومعرّف مستخدم فريد، وطريقة الدخول وأوقاته. الدخول كزائر ينشئ معرّفًا مجهولًا دون بيانات شخصية.",
      "نستخدم هذه البيانات لتسجيل دخولك فقط، ولا نطّلع على كلمة مرورك لأنها تُعالج لدى Firebase. لا نحفظ حاليًا قراءتك أو علاماتك على خوادم، فحذف الحساب يزيل سجل الحساب نفسه.",
      "تحذف حسابك متى شئت من: الإعدادات ← حسابي ← حذف الحساب."],
     ["An account is optional. If you create an account or sign in (with e-mail and password, Google, Apple, or as a guest), authentication is provided by Google’s Firebase Authentication.",
      "Data processed: your e-mail address, your name and profile photo if the sign-in provider supplies them, a unique user ID, and the sign-in method and times. Guest sign-in creates an anonymous ID with no personal data.",
      "We use this data only to sign you in, and we never see your password because Firebase handles it. We do not currently store your reading or bookmarks on a server, so deleting your account removes the account record itself.",
      "You can delete your account at any time from Settings → My account → Delete account."]),
    ("crash", "تقارير الأعطال (اختيارية)", "Crash reports (optional)",
     ["تقارير الأعطال اختيارية ومتوقفة حتى توافق. إن وافقت تجمع خدمة Firebase Crashlytics من Google معلومات تشخيصية عند تعطّل التطبيق: تتبّع الأخطاء، وطراز الجهاز، ونسخة النظام، ونسخة التطبيق، ومعرّف تثبيت.",
      "نستخدمها لإصلاح الأعطال فقط. لا يُرسل شيء قبل موافقتك، ويمكنك الرجوع عنها في أي وقت من: الإعدادات ← الخصوصية."],
     ["Crash reports are optional and off until you agree. If you do, Google’s Firebase Crashlytics collects diagnostic information when the app fails: error traces, device model, OS version, app version and an installation identifier.",
      "We use it only to fix crashes. Nothing is sent before you agree, and you can withdraw at any time in Settings → Privacy."]),
    ("network", "المحتوى من الإنترنت", "Content fetched from the internet",
     ["تُبثّ التلاوة آية بآية من الموقع everyayah.com، وتُجلب نصوص كتب الحديث غير المضمّنة في التطبيق من شبكة jsDelivr (مشروع hadith-api). كأي موقع، تتلقى هذه الخوادم عنوان IP الخاص بك والملف المطلوب.",
      "نص القرآن والأذكار والخطوط مضمّنة في التطبيق وتعمل دون اتصال."],
     ["Recitation is streamed ayah by ayah from everyayah.com, and hadith book texts that are not bundled are fetched from the jsDelivr network (the hadith-api project). Like any website, these servers receive your IP address and the file you request.",
      "The Quran text, adhkar and fonts are bundled with the app and work offline."]),
    ("notifications", "الإشعارات", "Notifications",
     ["تذكيرات الصلاة تُجدول محليًا على جهازك. لا نستخدم خادم إشعارات ولا نجمع رمز الإشعارات الخاص بجهازك."],
     ["Prayer reminders are scheduled locally on your device. We do not run a push-notification server and we do not collect your device’s notification token."]),
    ("never", "ما لا نفعله", "What we do not do",
     ["لا إعلانات.", "لا أدوات تحليلات سلوكية أو إعلانية.", "لا نبيع بياناتك ولا نشاركها لأغراض إعلانية.", "لا نبني ملفًا تعريفيًا عنك."],
     ["No ads.", "No behavioural or advertising analytics.", "We do not sell your data or share it for advertising.", "We do not build a profile about you."]),
    ("rights", "حقوقك", "Your rights and choices",
     ["لك الحق في الوصول إلى بيانات حسابك وتصحيحها وحذفها، وفي الاعتراض على معالجتها أو تقييدها وطلب نقلها، وفي تقديم شكوى إلى جهة حماية البيانات في بلدك. الحذف متاح مباشرة من التطبيق، ولباقي الطلبات تواصل معنا.",
      "الأساس القانوني للمعالجة: تنفيذ طلبك بإنشاء حساب، وموافقتك على تقارير الأعطال.",
      "يمكنك سحب أذونات الموقع والإشعارات في أي وقت من إعدادات جهازك."],
     ["You have the right to access, correct and delete your account data, to object to or restrict its processing, to ask for it to be transferred, and to complain to the data-protection authority in your country. Deletion is available directly in the app; for other requests, contact us.",
      "Legal basis: carrying out your request to create an account, and your consent for crash reports.",
      "You can withdraw location and notification permissions at any time in your device settings."]),
    ("children", "الأطفال", "Children",
     ["إنشاء الحساب لمن بلغ ١٣ عامًا فأكثر (أو سنّ الموافقة الرقمية في بلدك). يعمل ركن الأطفال دون حساب ولا يجمع أي بيانات."],
     ["Creating an account is for people aged 13 or over (or the age of digital consent in your country). The Kids corner works without an account and collects no data."]),
    ("transfers", "الأمان ونقل البيانات", "Security and data transfers",
     ["تنتقل بياناتك إلى خدمات Google عبر اتصال مشفّر (HTTPS). تعالج Google بيانات Firebase في عدة دول منها الولايات المتحدة."],
     ["Your data travels to Google’s services over an encrypted (HTTPS) connection. Google processes Firebase data in several countries, including the United States."]),
    ("changes", "التعديلات", "Changes to this policy",
     ["ننشر أي تعديل على هذه السياسة هنا ونحدّث تاريخ آخر تحديث."],
     ["We publish any change to this policy here and update the date above."]),
]


def contact_section(email, name):
    who_ar = f"{name}: " if name else ""
    who_en = f"{name}: " if name else ""
    return ("contact", "التواصل", "Contact",
            [f"للأسئلة أو طلبات الخصوصية: {who_ar}{email}"],
            [f"For questions or privacy requests: {who_en}{email}"])


def page(sections, email):
    def block(lang, direction, title, updated_label, idx):
        out = [f'<section id="{lang}" lang="{lang}" dir="{direction}">', f"<h1>{html.escape(title)}</h1>",
               f'<p class="meta">{updated_label}: {UPDATED}</p>']
        for s in sections:
            out.append(f"<h2>{html.escape(s[idx])}</h2>")
            paras = s[3] if lang == "ar" else s[4]
            if s[0] == "never":
                out.append("<ul>" + "".join(f"<li>{html.escape(p)}</li>" for p in paras) + "</ul>")
            else:
                out.extend(f"<p>{html.escape(p)}</p>" for p in paras)
        out.append("</section>")
        return "\n".join(out)

    return f"""<!doctype html>
<html lang="ar">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>NOOR | نور — Privacy Policy · سياسة الخصوصية</title>
<style>
  :root {{ color-scheme: light dark; --bg:#faf9f5; --fg:#18231f; --muted:#5d6a64; --line:#e4e1d6; --accent:#0b6e5a; }}
  @media (prefers-color-scheme: dark) {{ :root {{ --bg:#0f1714; --fg:#e8efe9; --muted:#9aa8a0; --line:#25322c; --accent:#5cc9ac; }} }}
  body {{ margin:0; background:var(--bg); color:var(--fg); font:16px/1.85 system-ui, "Segoe UI", Tahoma, sans-serif; }}
  main {{ max-width:46rem; margin:0 auto; padding:1.5rem 1.25rem 4rem; }}
  nav {{ display:flex; gap:.75rem; justify-content:center; padding:.5rem 0 1rem; }}
  nav a {{ color:var(--accent); text-decoration:none; border:1px solid var(--line); border-radius:99px; padding:.25rem 1rem; }}
  h1 {{ font-size:1.6rem; margin:.5rem 0 0; }} h2 {{ font-size:1.15rem; margin:2rem 0 .25rem; color:var(--accent); }}
  .meta {{ color:var(--muted); margin:.25rem 0 0; }}
  section + section {{ border-top:1px solid var(--line); margin-top:3rem; padding-top:1rem; }}
  body:has(#en:target) #ar {{ display:none; }} body:has(#en:target) section + section {{ border-top:0; margin-top:0; padding-top:0; }}
  body:has(#ar:target) #en {{ display:none; }}
</style>
</head>
<body>
<main>
<nav><a href="#ar">العربية</a><a href="#en">English</a></nav>
{block("ar", "rtl", "سياسة الخصوصية — نور", "آخر تحديث", 1)}
{block("en", "ltr", "Privacy Policy — NOOR", "Last updated", 2)}
</main>
</body>
</html>
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root", nargs="?", default=".")
    ap.add_argument("--email", default=os.environ.get("NOOR_PRIVACY_EMAIL", ""))
    ap.add_argument("--name", default=os.environ.get("NOOR_PRIVACY_NAME", ""))
    a = ap.parse_args()

    sections = list(SECTIONS)
    if a.email:
        sections.append(contact_section(a.email.strip(), a.name.strip()))
    else:
        print("WARNING: no --email given, so the contact section is missing. App stores require a privacy contact: rebuild with --email before publishing.")

    os.makedirs(f"{a.root}/site/privacy", exist_ok=True)
    with open(f"{a.root}/assets/data/privacy.json", "w", encoding="utf-8") as f:
        json.dump({"updated": UPDATED, "sections": [dict(id=i, titleAr=ta, titleEn=te, ar=pa, en=pe) for i, ta, te, pa, pe in sections]}, f, ensure_ascii=False, indent=1)
    with open(f"{a.root}/site/privacy/index.html", "w", encoding="utf-8") as f:
        f.write(page(sections, a.email))
    print(len(sections), "sections")


if __name__ == "__main__":
    main()
