# Test Kılavuzu — Bildirim & Hatırlatma & Aşı & Mesajlaşma & Duyuru

> Bu dosya, projeyi **başka bir cihaza** taşıdıktan sonra elle test etmen içindir. Sırayla uygula.
> Kod, Flutter SDK'sı olmayan bir makinede yazıldı → burada `flutter analyze` ile derleme kontrolü ilk iştir.

---

## 0. Hazırlık

1. **Emülatör:** Android Studio'da **Play Store'lu** bir emülatör aç (uygulama çekmecesinde **Play Store**
   ikonu görünmeli). Push bildirim (FCM) yalnız Google Play Services'li emülatörde çalışır.
2. **Frontend bağımlılıkları:**
   ```bash
   cd VeterinerApp
   flutter pub get
   ```
   Sürüm çakışması hatası alırsan (firebase_messaging / flutter_local_notifications):
   ```bash
   flutter pub add firebase_messaging flutter_local_notifications
   ```
3. **Statik analiz:** `flutter analyze` — **çıkan uyarı/hataları not al** (blind yazıldığı için 1-2 küçük
   düzeltme çıkabilir; bana iletebilirsin).
4. **Backend:**
   ```bash
   cd VeterinerAPI
   dotnet run
   ```
   Migration'lar açılışta otomatik uygulanır (`DbSeeder.MigrateAsync`). `firebase-adminsdk.json` dosyasının
   `VeterinerAPI/` kökünde olduğundan emin ol (auth için zaten gerekli).
5. **Çalıştır:** `cd VeterinerApp && flutter run`.

> İpucu: İki farklı rolü aynı anda test etmek için biri emülatör, biri `flutter run -d` ile ikinci bir cihaz
> kullanabilir ya da aynı emülatörde çıkış yapıp diğer hesapla girebilirsin.

---

## 1. Bildirim Altyapısı (Faz 1)

| # | Test | Beklenen |
|---|------|----------|
| T1 | Bir hesapla giriş yap | DB'de `users.fcm_token` alanı dolmalı (veya backend konsol logu). |
| T2 | Uygulamayı ilk açış | Bildirim izni sorulmalı (Android 13+), **İzin Ver**. |
| T3 | Owner randevu alır | Randevunun hekimi (vet) ve klinik hesabında: zil rozeti +1, bildirim merkezinde **"Yeni randevu talebi"**. |
| T4 | Vet/klinik randevuyu onaylar/iptal/tamamlar/gelmedi | Randevu **sahibine** "Randevu durumu güncellendi" bildirimi. |
| T5 | Owner randevuyu iptal eder | Hekime **"Randevu iptal edildi"** bildirimi. |
| T6 | Bildirim merkezini aç | Liste görünür; okunmamışlar vurgulu; bir bildirime dokun → okundu olur; **"Tümünü okundu yap"** çalışır; zil rozeti güncellenir. |
| T7 | Uygulama **arka planda/kapalıyken** bildirim gelmesi | Sistem bildirim banner'ı düşer. **Önplandayken** → uygulama içi banner (local notification). |
| T8 | Gelen bildirime dokun | Uygulama açılıp **Bildirimler** ekranına gider. |
| T9 | Çıkış yap (logout) | `users.fcm_token` NULL olur. Sonra farklı bir hesapla gir → önceki kullanıcının bildirimleri bu cihaza **gelmemeli**. |

---

## 2. Hatırlatmalar (Faz 2)

| # | Test | Beklenen |
|---|------|----------|
| T10 | Onaylı (confirmed) bir randevunun tarihini **24 saatten yakına** ayarla (veya yaklaşan bir randevu oluşturup onayla) | `AppointmentReminderWorker` (30 dk'da bir çalışır) sahibe **bir kez** "Randevu hatırlatması" gönderir; tekrar göndermez (`ReminderSent`). |
| T11 | Bir aşıya **`NextDueDate` = bugün + 2 gün** ver (bkz. T13) | `VaccineReminderWorker` (12 saatte bir) hayvan sahibine **"Aşı hatırlatması"** gönderir (3 gün penceresi). |

> Not (timezone): Randevu saatleri yerel duvar-saati olarak saklanıyor; hatırlatma penceresi `UtcNow` ile
> hesaplandığı için tetik zamanı ~3 saat kayabilir. Demo için sorun değil (kalıcı düzeltme sonraki fazda).
> Hızlı test için worker aralıklarını geçici kısaltabilirsin (kod içi `Task.Delay`).

---

## 3. Aşı Takibi (Faz 3)

| # | Test | Beklenen |
|---|------|----------|
| T12 | Owner: bir hayvanın detayına gir | "Aşı Geçmişi" bölümü görünür. Aşı yoksa boş durum mesajı. |
| T13 | Vet: kendi randevusundaki bir hayvanın kartındaki **"Aşılar"** butonu → aşı yönetim ekranı → **"Aşı Ekle"** ile aşı ekle | Aşı kaydedilir; listeye eklenir; başarı mesajı. |
| T14 | Owner: aynı hayvanın detayına tekrar bak | Eklenen aşı listede; **hekim adı dolu** gelir (vetId bug fix); `NextDueDate` ≤ 3 gün ise **"yaklaşıyor"** rozeti. |

---

## 4. Aşı Modülü Sağlamlaştırma (Yetki + Validasyon + Kanonik Liste + Düzenle/Sil)

| # | Test | Beklenen |
|---|------|----------|
| T15 | **Kanonik liste:** Aşı ekleme formunu aç | "Aşı Adı" artık **dropdown** (liste `/vaccinenames`'ten gelir: Kuduz, Karma (DHPP)…). **"Diğer"** seçilince altında serbest metin alanı çıkar. |
| T16 | **Düzenle:** "Aşılar" ekranında bir aşının **Düzenle** butonu → alanları değiştir → kaydet | Kayıt güncellenir (PUT); liste yenilenir. Listede olmayan bir ad, düzenlemede "Diğer" alanında görünür. |
| T17 | **Sil:** "Aşılar" ekranında **Sil** → onay diyaloğu → onayla | Aşı silinir (DELETE); listeden kalkar. Owner tarafında da kaybolur. |
| T18 | **Owner salt-okunur:** Owner hayvan detayında | Aşı geçmişini **görür** ama düzenle/sil butonu **yoktur** (yalnız vet/klinik yönetir). |
| T19 | **Tarih validasyonu:** Yapılış tarihini **gelecek** yap **veya** sonraki tarihi yapılış tarihinden **önce/eşit** ver | Backend **400** döner ("Aşılanma tarihi gelecekte olamaz." / "Sonraki aşı tarihi, aşılanma tarihinden sonra olmalıdır."). |
| T20 | **Yetki (#3):** (API/Postman) Vet, **randevusu olmayan** bir `animalId`'ye `POST /vaccines` | **403** "Bu hayvana aşı ekleme yetkiniz yok." Randevusu olan hayvana → başarılı. |

---

## 5. Mesajlaşma (Owner ↔ Hekim) — Faz 4

> Ön koşul: owner ile hekim arasında **en az bir randevu** olmalı (yetki bunun üzerine kurulu). Test için
> owner bir hekimden randevu alsın.

| # | Test | Beklenen |
|---|------|----------|
| T21 | Owner: alt menüde **5. sekme "Mesajlar"** → **"Yeni Mesaj"** FAB | Ortak randevusu olan hekimler listelenir (bottom-sheet). Hekim seç → sohbet ekranı açılır. |
| T22 | Owner: mesaj yaz + gönder | Mesaj sağda (kendi balonu) görünür. Hekim hesabında: **Mesajlar sekmesinde rozet +1** + **push** ("Yeni mesaj"). |
| T23 | Hekim: bildirime/ sekmeye gir → konuşmayı aç → cevap yaz | Owner'a push gider; owner sohbeti açıkken **~6 sn içinde** yeni mesaj görünür (canlı yenileme). |
| T24 | Bir tarafta konuşma açık → karşı taraf mesaj atar | Mesaj otomatik gelir; okununca karşı tarafın **okunmamış rozeti düşer**. |
| T25 | **Yetki:** (API/Postman) `POST /conversations` ile **ortak randevusu olmayan** bir hekime konuşma başlat | **403** "Bu kişiyle mesajlaşma yetkiniz yok (ortak randevu yok)." |
| T26 | Push'a tıkla (arka planda) | Uygulama açılıp **ilgili sohbete** gider (`new_message` derin bağlantı). |

> Not: `clinic_admin` bu modelde mesajlaşma tarafı değildir → klinik panelinde "Mesajlar" sekmesi **yoktur** (bilinçli).
> Not (timezone): mesaj saatleri `UtcNow` ile saklanır; gösterim ~3 saat kayabilir (bilinen kayıt, demoda sorun değil).

---

## 6. Klinik Duyuruları — Faz 4

| # | Test | Beklenen |
|---|------|----------|
| T27 | Klinik: **Klinik sekmesi → "Duyurular"** menüsü → **"Yeni Duyuru"** → başlık+içerik → Yayınla | Duyuru listeye eklenir; "sahiplere bildirim gönderildi" mesajı. |
| T28 | Owner (klinikte randevusu olan): bildirimleri kontrol et | Zil rozeti +1 + **push** ("{Klinik} duyurusu"); bildirim merkezinde görünür (📣 ikon). |
| T29 | Owner: kliniğin **detay sayfası** | "Hakkında" ile hekimler arasında **"Duyurular"** bölümünde duyuru görünür. |
| T30 | Klinik: bir duyuruyu **Sil** (onay diyaloglu) | Duyuru listeden ve owner'ın klinik detayından kalkar. |
| T31 | **Kitle:** klinikte randevusu **olmayan** bir owner | Duyuru bildirimi **almaz** (yalnız iptal-olmayan randevusu olanlara gider). |

---

## Bilinen uyarılar / olası küçük düzeltmeler
- **pubspec sürümleri:** firebase_messaging/flutter_local_notifications sürümleri firebase_core ile
  çakışırsa `flutter pub add ...` ile çöz.
- **Blind yazım:** Flutter kodu bu makinede derlenemedi; `flutter analyze` çıktısındaki hataları bana ilet,
  hızla düzeltirim (genelde eksik import / sürüm farkı kaynaklı basit şeyler).
- **Emülatör push almıyor:** Büyük ihtimalle Play Store'suz imaj — Play Store'lu emülatör kullan.
