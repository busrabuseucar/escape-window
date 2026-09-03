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
Usage Data
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
├── interventions/
├── privacy/
└── ui/
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

Bu zincir uçtan uca çalışmadan MVP tamamlanmış kabul edilmez.
