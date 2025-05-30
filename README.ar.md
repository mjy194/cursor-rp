# cursor-rp

[简体中文](README.md) | [English](README.en.md) | [Русский](README.ru.md) | [Français](README.fr.md) | [Español](README.es.md)

## مقدمة
وكيل عكسي محلي. المقدمة موجزة، عن قصد.

## التثبيت
1. قم بتنزيل modifier و ccursor من https://github.com/wisdgod/cursor-rp/releases
2. أعد تسميتهما بالأسماء القياسية وضعهما في نفس الدليل

## الإعداد والاستخدام
باستخدام المنفذ 3000 و .local كمثال:

### 1. تصحيح Cursor
1. افتح Cursor، نفذ الأمر `Open User Settings` وسجل مسار ملف الإعدادات
2. أغلق Cursor، طبق التصحيح (يجب إعادة التنفيذ بعد كل تحديث):
   ```bash
   /path/to/modifier --cursor-path /path/to/cursor --port 3000 --suffix .local local
   ```

**ملاحظات خاصة**:
- مستخدمو Windows: لا يلزم اهتمام خاص
- مستخدمو macOS: التوقيع اليدوي مطلوب بسبب SIP (مثل Windows إذا تم تعطيل SIP)
- مستخدمو Linux: يحتاج إلى التعامل مع تنسيق AppImage
- النصوص المرجعية: [macos.sh](macos.sh) | [linux.sh](linux.sh) (PR مرحب بها)

### 2. إعداد Hosts
إذا كنت تستخدم المعامل `--skip-hosts`، أضف يدويًا سجلات المضيفين هذه:
```
127.0.0.1 api2.cursor.sh.local api3.cursor.sh.local repo42.cursor.sh.local api4.cursor.sh.local us-asia.gcpp.cursor.sh.local us-eu.gcpp.cursor.sh.local us-only.gcpp.cursor.sh.local
```

### 3. بدء الخدمة
```bash
/path/to/ccursor
```

## تفاصيل الإعداد
في `config.toml`، قم بتعليق أو حذف المعلمات غير المعروفة، **لا تتركها فارغة**.

عند الترحيل من الإصدار 0.1.x، قم بإنشاء قالب التكوين باستخدام:
```bash
/path/to/ccursor /path/to/settings.json
```

### الإعداد الأساسي
| العنصر | الوصف | النوع | مطلوب | القيمة الافتراضية | الإصدار المدعوم |
|--------|--------|-------|--------|-------------------|-----------------|
| `check-updates` | التحقق من التحديثات عند بدء التشغيل | bool | ❌ | false | 0.2.0+ |
| `github-token` | رمز وصول GitHub | string | ❌ | "" | 0.2.0+ |
| `usage-statistics` | إحصائيات استخدام النموذج | bool | ❌ | true | 0.2.1+ |
| `current-override` | معرف التجاوز النشط | string | ✅ | - | 0.2.0+ |

### إعداد الخدمة (`service-config`)
| العنصر | الوصف | النوع | مطلوب | القيمة الافتراضية | الإصدار المدعوم |
|--------|--------|-------|--------|-------------------|-----------------|
| `port` | منفذ استماع الخدمة | u16 | ✅ | - | جميع الإصدارات |
| `lock-updates` | قفل التحديثات | bool | ✅ | false | جميع الإصدارات |
| `domain-suffix` | لاحقة النطاق | string | ✅ | - | جميع الإصدارات |
| `proxy` | إعداد خادم الوكيل | string | ❌ | "" | 0.2.0+ |
| `dns-resolver` | محلل DNS (gai/hickory) | string | ❌ | "gai" | 0.2.0+ |
| `fake-email` | إعداد البريد الإلكتروني الوهمي | object | ❌ | {email="",sign-up-type="unknown",enable=false} | 0.2.0+ |
| `service-addr` | إعداد عنوان الخدمة | object | ❌ | {mode="local",suffix=".example.com",port=8080} | 0.2.0+ |

### إعداد التجاوزات (`overrides`)
| العنصر | الوصف | النوع | مطلوب | القيمة الافتراضية | الإصدار المدعوم |
|--------|--------|-------|--------|-------------------|-----------------|
| `token` | رمز مصادقة JWT | string | ❌ | - | جميع الإصدارات |
| `traceparent` | الحفاظ على معرف التتبع | bool | ❌ | false | 0.2.0+ |
| `client-key` | تجزئة مفتاح العميل | string | ❌ | - | 0.2.0+ |
| `checksum` | مجموع التحقق المجمع | string | ❌ | - | 0.2.0+ |
| `client-version` | رقم إصدار العميل | string | ❌ | - | 0.2.0+ |
| `timezone` | معرف المنطقة الزمنية IANA | string | ❌ | - | جميع الإصدارات |
| `ghost-mode` | إعدادات الوضع الخفي | bool | ❌ | true | 0.2.0+ |
| `session-id` | معرف الجلسة الفريد | string | ❌ | - | 0.2.0+ |

**ملاحظات خاصة**:
- العناصر المميزة بـ "0.2.0+" لم تكن موجودة في 0.1.x، لكن العناصر المميزة بـ "جميع الإصدارات" قد لا تكون متكافئة تمامًا
- يمكن تعليق أو حذف عناصر الإعداد ذات القيم الافتراضية لتجنب المشاكل المحتملة

## الواجهات الداخلية
الواجهات تحت `/internal/` يتم التحكم فيها بواسطة الملفات في دليل internal (يعيد index.html عندما لا يوجد الملف)، باستثناء:

1. **TokenUpdate**
   تحديث current-override في وقت التشغيل:
   ```bash
   curl http://127.0.0.1:3000/internal/TokenUpdate?key=${KEY_NAME}
   ```

2. **ConfigUpdate**
   تفعيل إعادة التحميل بعد تحديث ملف الإعداد

3. **GetUsage**
   الحصول على إحصائيات استخدام النموذج

---

*إخلاء المسؤولية مضمن في EULA. قد يتوقف المشروع عن الصيانة في أي وقت.*

Feel free!