# ESCAPE Window AI V2

**Kişiselleştirilmiş Erken Risk ve Mikro-Müdahale Sistemi**

ESCAPE Window AI, 18–24 yaş üniversite çağındaki kullanıcıların problemli akıllı telefon ve sosyal medya kullanımına doğru gelişebilecek öz-düzenleme kaybını erken aşamada değerlendirmek için geliştirilen Android-first, açıklanabilir ve privacy-by-design bir Flutter MVP'sidir.

> **Durum: MVP v0.1.0 — gerçek Android cihazda uçtan uca doğrulandı.**  
> Klinik tanı veya tedavi sistemi değildir; davranışsal ve bağlamsal risk göstergelerini değerlendirir.

## Neden ESCAPE?

Sadece “bugün kaç saat telefona baktın?” demek yeterli değil. ESCAPE, kullanıcının kendi geçmişini kişisel baseline olarak ele alır; süreklilik, hedef aşımı ve hassas saat kullanımı gibi sinyalleri birlikte değerlendirir ve gerektiğinde düşük yoğunluklu bir müdahale penceresi açar.

## Çalışan MVP Akışı

```text
Açık rıza
→ Android Usage Access
→ Takip edilecek uygulamaların seçimi
→ 14 tamamlanmış günlük UsageStats verisi
→ DailyFeatureSnapshot
→ Personal Baseline
→ DERM
→ Risk + Confidence + Explanation
→ ESCAPE Window
→ Mikro-müdahale
→ Kullanıcı yanıtı
→ Geçmiş ve eğilim
```

## Doğrulanmış Durum

03–04.09.2026 fiziksel Android cihaz testlerinde:

- Usage Access izin akışı çalıştı.
- Geçmiş UsageStats olayları gerçek cihazdan okundu.
- 14 günlük baseline/değerlendirme penceresi işlendi.
- Açıklanabilir risk ve güven çıktısı üretildi.
- ESCAPE mikro-müdahalesi kullanıcıya sunuldu ve kabul akışı çalıştı.
- Geçmiş/eğilim ekranı gerçek günlük metrikleri gösterdi.
- Android event parçalanmasının şişirdiği oturum sayıları 30 saniyelik aynı-paket normalizasyonuyla düzeltildi.
- Instagram'daki yinelenen foreground olayının süreyi +88/+129 dakika şişirebildiği kök neden testiyle bulundu ve regresyon testiyle sabitlendi.
- Kullanıcıya dönük final ekrandan tüm UsageStats debug/tanılama alanları kaldırıldı.

Ayrıntılı mühendislik kaydı: `docs/real-device-validation-2026-09-03.md`.

## CI / Kalite Kapısı

PR doğrulama zinciri:

```text
flutter pub get
→ flutter analyze
→ flutter test
→ flutter build apk --debug
→ APK artifact
```

Final MVP değişiklikleri bu zincirden başarıyla geçti ve `main` dalına alındı. UsageStats duration pairing ve session normalization için ayrı regresyon testleri bulunur.

## Mimari

```text
Android UsageStats
      ↓
DailyFeatureSnapshot
      ↓
Feature Engine
      ↓
Baseline Engine (PBD)
      ↓
DERM (BPI + SRFI + CVL + Safety)
      ↓
Risk + Confidence + Explanation
      ↓
ESCAPE Window
      ↓
Micro Intervention
      ↓
Outcome Tracking
```

### DERM

DERM (**Davranışsal Erken Risk Modeli**) açıklanabilir erken-risk değerlendirme motorudur.

- **BPI — Behavioral Persistence Index:** risk örüntüsünün zamansal sürekliliği
- **SRFI — Self-Regulation Failure Index:** kullanıcının kendi sınırlarının tekrar eden ihlali
- **CVL — Contextual Vulnerability Level:** gece kullanımı gibi bağlamsal hassasiyet göstergeleri
- **PBD — Personal Baseline Deviation:** bağımsız risk bileşeni değil, kişiselleştirme/kalibrasyon katmanı

İlk MVP ağırlıkları klinik olarak doğrulanmış kabul edilmez. Sistem doğrulanmamış bir “AI teşhis skoru” yerine sürümlenebilir ve açıklanabilir karar mantığı kullanır.

## Privacy-by-Design

- Kullanıcı açık rıza vermeden UsageStats okunmaz.
- Yalnızca uygulama paketi, foreground/background olay tipi ve zaman damgası işlenir.
- Mesaj içeriği, fotoğraf, mikrofon, kişi listesi, tuş vuruşu veya özel iletişim içeriği okunmaz.
- Kullanıcı değerlendirmeye dahil edilecek uygulamaları kendisi seçer.
- Local-first ve veri minimizasyonu yaklaşımı izlenir.

## Risk ve Sistem Durumları

**Risk:** `LOW`, `WATCH`, `ELEVATED`, `INSUFFICIENT_DATA`

**ESCAPE Window:** `CLOSED`, `OBSERVING`, `ACTIVE`, `COOLDOWN`

**Baseline:** `CALIBRATING`, `STABLE`, `FROZEN`, `RECALIBRATING`

## 2–3 Dakikalık Demo Senaryosu

1. **0:00–0:20 — Problem:** ESCAPE'in yalnızca ekran süresini değil, kişisel davranış örüntüsünü değerlendirdiğini anlat.
2. **0:20–0:45 — Rıza ve veri:** Usage Access ve kullanıcının takip edeceği uygulamaları kendisinin seçtiğini göster.
3. **0:45–1:20 — Risk:** Dashboard'da risk, güven ve açıklanabilir nedenleri göster; DERM'in tanı koymadığını belirt.
4. **1:20–1:50 — Müdahale:** ESCAPE Window'u aç ve önerilen mikro-müdahalenin neden tetiklendiğini göster.
5. **1:50–2:15 — Sonuç:** Müdahaleyi kabul et ve outcome tracking akışını göster.
6. **2:15–2:40 — Kanıt:** Geçmiş/eğilim ekranında gerçek UsageStats günlük metriklerini göster.
7. **2:40–3:00 — Teknik kapanış:** Gerçek cihaz doğrulaması, CI, regresyon testleri ve privacy-by-design yaklaşımını özetle.

## Proje Yapısı

```text
lib/
├── core/
├── data/
├── features/
├── baseline/
├── derm/
├── escape/
├── hybrid/
├── interventions/
├── privacy/
└── ui/
android/
└── app/src/main/
test/
├── baseline/
├── derm/
├── escape/
├── features/
└── scenarios/
docs/
└── real-device-validation-2026-09-03.md
```

## MVP Kapsam Dışı

Chatbot, sosyal ağ, oyunlaştırma, ebeveyn/kurum paneli, klinik teşhis, serbest GenAI psikolojik tavsiyesi, çoklu bağımlılık türleri ve doğrulanmamış ML modeli ilk MVP kapsamına dahil değildir.

## Sürüm

`0.1.0+1` — gerçek cihazda doğrulanmış ilk çalışan MVP.

Bir sonraki ürün aşaması; kontrollü pilot veri toplama, DERM eşik/ağırlık kalibrasyonu, UX iyileştirmeleri ve araştırma protokolüdür.
