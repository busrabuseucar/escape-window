# İşletim ve sürüm doğrulama — Android davranış verisi MVP

Son inceleme: **16 Ekim 2026**. Bu belge kurulum, veri akışı, sürüm kapıları, geri dönüş ve doğrulama kapsamını birlikte kaydeder. Bir yayın adresinin açılması, tüm üretim koşullarının tamamlandığı anlamına gelmez.

## Sürüm kanıtı

- Denetlenen uygulama commit’i: `0385f1abc9f590af2e90d639d16dfc5811a0a120`.
- [Bu commit için başarılı CI kaydı](https://github.com/busrabuseucar/escape-window/actions/runs/38900322262).
- Doğrulanan otomatik kapsam: Flutter analiz + test + debug APK.
- Testlerin gerçek servis, veri veya donanım yerine taklit kullandığı noktalar aşağıda açıkça ayrılmıştır.

## Kurulum ve çalışma

Depo kökünde, README’deki çalışma zamanı sürümüyle:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Veri akışı: Açık rıza → Android UsageStats → tamamlanmış günler → kişisel baseline → DERM ve mikro müdahale.

Yapılandırma: Flutter 3.47.7; Android Java 17. Fiziksel cihazda Usage Access ve izlenen uygulama seçimi gerekir. Debug APK mağaza sürümü değildir.

## Yayın ve geri dönüş

1. Temiz checkout ve kilitli bağımlılıklarla yukarıdaki kontrolleri çalıştır. İlgili CI başarısını commit SHA ile eşleştir.
2. Yayın paketine yalnızca çalışma zamanı dosyalarını koy. Secret, ham kullanıcı verisi, yerel veritabanı ve kişisel hazırlık notları pakete girmemeli.
3. Hedef proje, kaynak commit, ortam ve yayın sürümünü kaydet. Önceki çalışan sürüm kimliğini geri dönüş için koru.
4. Yayından sonra ana kullanıcı akışını, hata durumunu ve varsa kalıcılığı doğrula. Sunucu hatası/yanlış sonuçta yeni yazmaları durdur; önceki doğrulanmış yayını geri al.
5. Şema değiştiyse yalnızca kodu geri almak yeterli değildir. Yedekten ayrı ortamda doğrulama yapmadan canlı veri üzerine yazma.

## Veri saklama ve kurtarma

Yerel kullanım geçmişi kişisel veridir. Hata raporlarına ham uygulama geçmişini ekleme. Uygulama silme/veri temizleme kayıp yaratabilir; eski sürüme dönmeden yerel şema uyumluluğunu doğrula.

## Gerçek servis, model ve cihaz doğrulaması

03–04 Eylül cihaz kaydı önceki revizyon içindir. Ekim commitinde fiziksel telefon regresyonu, izin kaldırma/yeniden verme, gün sınırı ve 14 günlük baseline yeniden doğrulanmalı. Klinik etkililik veya tanı iddiası yok.

## Yayın sonrası gözlem

Önce küçük ve sentetik girdilerle temel akışı kontrol et. Beklenmeyen hata, boş ekran, yanlış hesap, yetkisiz erişim veya veri kaybında tarih, uygulama commit’i, ortam ve yeniden üretme adımlarını kaydet; kişisel veri ve secret ekleme. Statik araçlarda tarayıcı konsolu/ağ hatalarını; backend bulunan projelerde durum kodu, gecikme ve hata oranını incele. Bu belgede sürekli izleme veya otomatik geri dönüş kurulmuş olduğu iddia edilmez.

## Kabul kaydı

Her yeni sürümün kaydı; test komutu/sonucu, kaynak SHA, yayın sürümü, gerçek servis/model sürümü, cihaz/işletim sistemi, veri kümesi özeti ve geri dönüş denemesini içermeli. Erişim veya fiziksel donanım yoksa ilgili satır **çalıştırılmadı** olarak tutulur; otomatik test başarısı yerine geçirilmez.
