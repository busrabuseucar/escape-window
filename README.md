# ESCAPE Window AI V2

**Kişiselleştirilmiş Erken Risk ve Müdahale Sistemi**

ESCAPE Window AI, 18–24 yaş üniversite çağındaki kullanıcıların problemli akıllı telefon / sosyal medya kullanımına doğru gelişebilecek öz-düzenleme kaybını erken aşamada değerlendirmeyi amaçlayan, açıklanabilir ve privacy-by-design bir MVP'dir.

> Bu proje klinik tanı veya tedavi sistemi değildir. Davranışsal ve bağlamsal risk göstergelerini değerlendirir ve uygun olduğunda düşük yoğunluklu bir erken müdahale penceresi üretir.

## MVP İlkeleri

- Android-first, local-first
- Veri minimizasyonu
- Açıklanabilir kural tabanlı risk motoru
- Risk ve güven düzeyinin ayrı değerlendirilmesi
- Kişisel baseline tek başına karar vermez
- Riskli dönemler baseline'a otomatik olarak dahil edilmez
- Serbest üretken yapay zekâ ile psikolojik tavsiye üretilmez
- Klinik tanı iddiası yoktur

## Çekirdek Akış

```text
Android UsageStats / Demo Data
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

## Android UsageStats Entegrasyonu

MVP Android `UsageStatsManager` ile gerçek cihaz kullanım olaylarını okuyan bir MethodChannel katmanı içerir.

- Kullanıcı önce açık rıza verir.
- Ardından Android'in **Kullanım erişimi** ayar ekranına yönlendirilir.
- İzin verilmeden kullanım verisi okunmaz.
- Native katman yalnızca uygulama paketi, foreground/background olay tipi ve zaman damgasını Flutter tarafına iletir.
- Mesaj içeriği, fotoğraflar, mikrofon, kişiler, tuş vuruşları veya özel iletişim içeriği okunmaz.
- Flutter tarafı foreground/background olaylarını oturumlara dönüştürerek günlük toplam kullanım, seçili sosyal uygulama kullanımı, hassas saat kullanımı, takip edilen uygulama oturum sayısı ve kişisel hedef aşımını üretir.
- Oturum sayısı ve ortalama oturum süresi yalnızca kullanıcının değerlendirme için seçtiği paketler üzerinden hesaplanır; launcher/sistem foreground geçişleri bu metrikleri şişirmez.
- Bugünün eksik verisi yerine son 14 **tamamlanmış** gün kullanılır: ilk 7 gün baseline kalibrasyonu, son 7 gün mevcut değerlendirme penceresi olarak ayrılır.

İlk MVP'deki sosyal uygulama paket listesi mühendislik amaçlı başlangıç sınıflandırmasıdır; klinik bir sınıflandırma değildir. Kullanıcı değerlendirmeye dahil edilecek uygulamaları onboarding sırasında seçer.

### Gerçek cihaz doğrulaması — 03.09.2026

Android debug APK gerçek bir Android cihazda uçtan uca doğrulandı. Başarıyla test edilen zincir:

```text
APK kurulumu
→ açık rıza
→ Android Usage Access ayarına yönlendirme
→ izin dönüşünün otomatik algılanması
→ takip edilecek uygulamaların seçimi
→ geçmiş UsageStats olaylarının okunması
→ 14 tamamlanmış günlük pencerenin işlenmesi
→ DailyFeatureSnapshot
→ baseline + DERM değerlendirmesi
→ açıklanabilir risk ekranı
→ ESCAPE müdahale penceresi
→ müdahalenin kullanıcı tarafından kabul edilmesi
→ geçmiş/eğilim görünümü
```

Cihaz testinde gerçek günlük toplam ekran süresi, seçili sosyal uygulama süresi, gece kullanımı, hedef aşımı ve veri bütünlüğü alanlarının gün bazında üretildiği doğrulandı. Test sırasında tüm uygulama foreground geçişlerini sayan eski oturum metriğinin aşırı yüksek değer üretebildiği gözlendi; metrik takip edilen uygulamalarla sınırlandırılarak düzeltildi.

Ayrıntılı doğrulama kaydı için `docs/real-device-validation-2026-09-03.md` dosyasına bakın.

## DERM

DERM (Davranışsal Erken Risk Modeli) proje kapsamında geliştirilen açıklanabilir erken-risk değerlendirme motorudur.

- **BPI — Behavioral Persistence Index:** risk örüntüsünün zamansal sürekliliği
- **SRFI — Self-Regulation Failure Index:** kullanıcının kendi koyduğu sınırların tekrar eden ihlali
- **CVL — Contextual Vulnerability Level:** gece kullanımı gibi bağlamsal hassasiyet göstergeleri
- **PBD — Personal Baseline Deviation:** bağımsız risk bileşeni değil, kişiselleştirme/kalibrasyon katmanı

İlk MVP'de ağırlıklar klinik olarak doğrulanmış kabul edilmez. Model doğrulanmamış bir 'AI risk skoru' üretmek yerine açıklanabilir kurallar ve sürümlenmiş karar mantığı kullanır.

## Risk Çıktıları

- `LOW`
- `WATCH`
- `ELEVATED`
- `INSUFFICIENT_DATA`

## ESCAPE Window Durumları

- `CLOSED`
- `OBSERVING`
- `ACTIVE`
- `COOLDOWN`

## Baseline Durumları

- `CALIBRATING`
- `STABLE`
- `FROZEN`
- `RECALIBRATING`

## MVP Kapsam Dışı

Chatbot, sosyal ağ, oyunlaştırma, ebeveyn/kurum paneli, klinik teşhis, serbest GenAI psikolojik tavsiyesi, çoklu bağımlılık türleri ve doğrulanmamış ML modeli ilk MVP kapsamına dahil değildir.

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
└── scenarios/
```

## MVP Definition of Done

```text
Demo/Device Data
→ Feature Engine
→ Baseline Engine
→ DERM
→ Risk + Confidence + Explanation
→ ESCAPE Window
→ Micro Intervention
→ User Response
→ History
```

Bu zincir 03.09.2026 tarihinde gerçek Android cihaz üzerinde uçtan uca doğrulanmıştır.
