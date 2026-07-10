# Klinik Değerlendirme (Yorum & Puan) Modülü — Diğer Cihaz Kurulum & Test

Modülün kodu yazıldı ve `dotnet build` ile **0 hatayla derlendi**; `AddClinicReviewConstraints`
migration'ı **DB'ye bağlanmadan** üretildi. Aşağıdakiler DB/cihaz gerektiren, burada yapılamayan işler.

## 0. Ne eklendi?

**Kurallar (kararlaştırıldı):**
- Yorum hakkı: yalnız o klinikte **`completed`** durumunda en az bir randevusu olan **hasta sahibi**.
- Kullanıcı+klinik başına **tek yorum** (düzenlenebilir/silinebilir) — DB'de tekil indeksle garanti.
- Yalnız **klinik** puanlanır (hekim puanı yok).
- Yorumu **kimse gizleyemez**; yalnız sahibi siler.

**Backend (yeni):** `Controllers/ClinicReviewsController.cs` · `Services/{Interfaces/IClinicReviewService,
Implementations/ClinicReviewService}.cs` · `Repositories/{Interfaces/IClinicReviewRepository,
Implementations/ClinicReviewRepository}.cs` · `DTOs/Reviews/…` · migration `AddClinicReviewConstraints`

**Backend (değişen):** `Models/Entities/ClinicReview.cs` (`updated_at`) · `Data/AppDbContext.cs`
(tekil indeks) · `Repositories/Implementations/ClinicRepository.cs` (`Include(Reviews)`) ·
`Services/Implementations/ClinicService.cs` (puan hesabı tek yardımcıya çıkarıldı, klinik detayına eklendi) ·
`DTOs/Clinics/ClinicDetailResponse.cs` · `Program.cs`

**Frontend (yeni):** `features/reviews/` → 3 model, `star_rating`, `rating_summary`, `review_tile`,
`write_review_sheet`, `clinic_reviews_screen`

**Frontend (değişen):** `clinic_detail_screen` (puan + değerlendirme bölümü) · `appointments_screen` +
`appointment_detail_screen` ("Değerlendir" butonu) · `appointment_model` (`clinicId`/`clinicName`) ·
`app_router` (`/clinics/:id/reviews`) · `notifications_screen` + `fcm_service` (`new_review`)

**API uçları** (hepsi `[Authorize]`):

| Metot | Yol | Açıklama |
|------|-----|----------|
| GET | `/api/clinics/{clinicId}/reviews?page=1&pageSize=10` | Sayfalı yorum listesi |
| GET | `/api/clinics/{clinicId}/reviews/summary` | Ortalama + adet + yıldız dağılımı |
| GET | `/api/clinics/{clinicId}/reviews/me` | `canReview` + kendi yorumu |
| POST | `/api/clinics/{clinicId}/reviews` | Oluştur **veya** güncelle (upsert) |
| DELETE | `/api/clinics/{clinicId}/reviews/me` | Kendi yorumunu sil |

---

## 1. Migration'ı uygula

```bash
cd VeterinerAPI
dotnet ef database update      # veya: dotnet run (DbSeeder MigrateAsync çağırıyor)
```

Doğrula (MySQL):
```sql
SHOW INDEX FROM clinic_reviews WHERE Key_name LIKE '%clinic_id_user_id%';
-- Non_unique = 0 olmalı (tekil indeks)
DESCRIBE clinic_reviews;   -- updated_at kolonu görünmeli
```

> ⚠️ Tabloda aynı `(clinic_id, user_id)` için **mükerrer satır varsa** tekil indeks eklenemez ve migration
> hata verir. Seed veri yorum üretmiyor; tablo boşsa sorun çıkmaz. Sorun olursa mükerrerleri temizle:
> ```sql
> DELETE r1 FROM clinic_reviews r1
> JOIN clinic_reviews r2
>   ON r1.clinic_id = r2.clinic_id AND r1.user_id = r2.user_id AND r1.id > r2.id;
> ```

---

## 2. Backend testi (Postman)

Header: `Authorization: Bearer <FIREBASE_ID_TOKEN>`

1. **Yetkisiz deneme:** Tamamlanmış randevusu **olmayan** bir owner ile
   `POST /api/clinics/1/reviews` `{"rating":5,"comment":"Harika"}` → **403**
   ("Bu kliniği değerlendirebilmek için tamamlanmış bir randevunuz olmalıdır.")

2. **Randevuyu tamamla:** Hekim tokenıyla `PUT /api/vets/my-appointments/{id}/status`
   `{"status":"completed"}` (randevu `confirmed` olmalı).

3. **Yorum yaz:** Aynı owner → `POST /api/clinics/1/reviews` `{"rating":5,"comment":"Harika"}` → **200**,
   `data.reviewId` döner. Klinik yöneticisine `new_review` bildirimi düşmeli.

4. **Upsert kontrolü (kritik):** Aynı owner tekrar `POST` `{"rating":3,"comment":"Fikrim değişti"}` → **200**.
   `GET /api/clinics/1/reviews` → **tek kayıt**, `rating: 3`, `updatedAt` dolu.
   *(Yeni satır açılmadıysa tekil indeks + upsert doğru çalışıyor.)*

5. **Özet:** `GET /api/clinics/1/reviews/summary` → `rating`, `reviewCount`, `distribution` (1–5 anahtarlı).

6. **Durum:** `GET /api/clinics/1/reviews/me` → `canReview: true`, `review` dolu.

7. **Rol kontrolü:** `vet` veya `clinic_admin` tokenıyla `POST /api/clinics/1/reviews` → **403**
   ("Değerlendirmeyi yalnızca hasta sahipleri yapabilir.")

8. **Silme:** `DELETE /api/clinics/1/reviews/me` → **200**;
   `GET .../summary` → `rating: null`, `reviewCount: 0`.

9. **Puan klinik detayında:** `GET /api/clinics/1` → `rating` ve `reviewCount` alanları geliyor mu?
   *(Bu daha önce dönmüyordu; `GetClinicWithVetsAsync`'e `Include(Reviews)` eklendi.)*

10. **Doğrulama:** `POST` `{"rating":6}` → **400** (Range 1–5); `{"rating":0}` → **400**.

---

## 3. Frontend testi

```bash
cd VeterinerApp
flutter pub get
flutter analyze
flutter run
```

**Uçtan uca senaryo:**
1. Owner → Klinikler → bir kliniğe gir. Yorum yoksa **"Henüz değerlendirilmemiş."** görünmeli.
2. Hekim hesabıyla o kullanıcının randevusunu **"Tamamlandı"** yap.
3. Owner → **Randevularım → Geçmiş** sekmesi → kartta **"Değerlendir"** butonu belirmeli.
4. Butona bas → alt sayfada yıldız seç + yorum yaz → **Gönder**.
5. Klinik detayına dön → üstte **yıldız + ortalama**, altta **Değerlendirmeler** bölümü ve yorumun görünmeli.
6. **"Tümünü Gör (N)"** → `/clinics/:id/reviews` ekranı: özet + dağılım çubukları + yorum listesi.
7. Kendi yorumunda **⋮ → Düzenle** (alanlar dolu gelmeli) ve **⋮ → Sil** çalışmalı.
8. Silince ortalama ve sayı **anında** güncellenmeli.
9. Klinikler listesinde de kliniğin puanı güncellenmiş olmalı.
10. Klinik yöneticisi hesabında **bildirim merkezinde** yıldız ikonlu "Yeni değerlendirme" bildirimi.

**Beklenen kısıtlar:**
- Tamamlanmış randevusu olmayan owner'da "Değerlendir" butonu **çıkmaz**.
- Hekim/klinik yöneticisi hesabında değerlendirme butonu **çıkmaz** (`canReview: false`).
- Aynı kliniğe ikinci kez yorum yazılamaz; buton **"Değerlendirmeni Düzenle"** olur.

---

## 4. Olası sorunlar

| Belirti | Neden | Çözüm |
|--------|-------|-------|
| Migration "Duplicate entry" hatası | Tabloda mükerrer (clinic_id, user_id) | §1'deki temizleme sorgusu |
| "Değerlendir" butonu hiç çıkmıyor | Randevu `completed` değil ya da `clinicId` 0 | `GET /api/appointments` yanıtında `clinicId` dolu mu? |
| Klinik detayında puan yok | `Include(Reviews)` uygulanmamış eski derleme | Backend'i yeniden başlat |
| 403 alıyorsun ama randevun tamamlanmış | Farklı klinikte tamamlanmış olabilir | Randevunun `clinicId`'si ile yorum yazdığın klinik aynı mı? |
| Bildirim gelmiyor | Güncellemede bildirim gönderilmez (tasarım) | Yeni yorumda gelmeli; silip yeniden yaz |
