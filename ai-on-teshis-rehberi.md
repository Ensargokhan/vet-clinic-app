# Yapay Zekâ Destekli Ön Teşhis — Uygulama Rehberi

> **Bu bir kılavuz/rapordur; kod değil.** Kedi & Köpek odaklı, **LLM + RAG** yaklaşımı, **Google Gemini**
> sağlayıcısı baz alınarak hazırlanmıştır. Amaç: rapor.md'deki "yapay zekâ destekli ön teşhis" hedefini
> nasıl gerçekleştireceğine dair somut yol haritası.

---

## 0. TL;DR (en kritik 3 nokta)

1. **LLM bağlamak ≠ model eğitmek.** Gemini gibi bir LLM zaten milyonlarca veteriner metniyle eğitilmiş
   gelir. Sen sıfırdan model eğitmeyeceksin. Veri setinin işi **eğitim değil**; **(a) bilgi tabanı (RAG),
   (b) semptom taksonomisi + few-shot örnek, (c) değerlendirme (test) seti** olmak.
2. **Öneri mimari:** Yapılandırılmış semptom soru akışı → RAG (güvenilir veteriner kaynaklarından ilgili
   bilgiyi çek) → Gemini'ye "yalnız bu kaynaklara dayan" talimatı + **JSON şeması** → hekime iletilecek
   yapılandırılmış ön teşhis raporu. RAG, halüsinasyonu azaltır ve "kaynaklı/sorumlu AI" olarak bitirme
   savunmanda güçlü bir **özgün değer** sağlar.
3. **Bu bir teşhis değil, ön-triyajdır.** Sistemin tek işi: *olası durumlar + aciliyet seviyesi +
   yönlendirme*. Sorumluluk/etik bölümü (§8) bu projede en az kod kadar önemli.

---

## 1. Üç Yol ve Neden RAG?

| Yaklaşım | Ne yapar | Veri setinin rolü | Artı / Eksi |
|---|---|---|---|
| **A. Saf Prompt (LLM)** | Sadece Gemini'ye iyi bir sistem promptu + semptomlar | Few-shot örnek | En hızlı; ama kaynaksız, halüsinasyon riski, "neye dayandı?" belirsiz |
| **B. RAG + LLM ⭐** | LLM'i kürating edilmiş veteriner bilgi tabanıyla besleyerek yanıtlatmak | **Bilgi tabanı** (embed edilir) + değerlendirme | Kaynaklı, güncellenebilir, savunması güçlü; kurulum orta |
| **C. Klasik ML** | Semptom→hastalık sınıflandırıcı (RandomForest vb.) eğitmek | **Eğitim verisi** | "Gerçek ML" ama kedi-köpek için veri kalitesi zayıf, dar; LLM raporu ayrı iş |

**Seçim: B (RAG + LLM).** Kedi-köpek semptom-hastalık açık veri setleri hem küçük hem gürültülü (çoğu
çiftlik hayvanı ağırlıklı) — bu yüzden C tek başına zayıf kalır. LLM'in zengin bilgisini **RAG ile
sınırlandırıp kaynağa bağlamak** en dengeli yoldur. (İstersen ileride C'yi "ikinci görüş" olarak
ekleyebilirsin — opsiyonel, zorunlu değil.)

---

## 2. Ön Teşhis Akışının Mantığı (rapor.md'deki "eliminasyon soru-cevap")

```
1) Bağlam (üründe zaten var): tür, ırk, yaş, kilo, cinsiyet  → Animal kaydından otomatik
2) Ana şikâyet seçimi: kusma / ishal / kaşıntı / topallık / iştahsızlık / göz-kulak akıntısı ...
3) Eliminasyon soruları (adaptif): "Ne zamandır?", "Kanlı mı?", "Ateş?", "Başka belirti?"
4) Kırmızı-bayrak taraması: nefes güçlüğü, şiddetli kanama, zehir teması, şişkin/gergin karın (GDV),
   idrar yapamama, bilinç kaybı  → varsa "ACİL: derhal kliniğe" ve akışı kısa kes
5) RAG + Gemini → yapılandırılmış rapor (olası durumlar, aciliyet, evde ne yap/yapma, hekime not)
6) Rapor DB'ye kaydedilir + (opsiyonel) randevuya iliştirilir → hekim randevu öncesi görür
```

Adaptiflik iki şekilde olur: **(basit)** sabit karar-ağacı soruları JSON olarak tutulur; **(gelişmiş)**
her turda Gemini "bir sonraki en ayırt edici soruyu" üretir. Bitirme için **basit + son adımda LLM**
karışımı en pratiği.

---

## 3. Mimari (senin uygulamana özel)

```
Flutter (soru akışı UI)
   │  POST /pre-diagnosis  { animalId, answers[] }
   ▼
.NET Backend  ── API anahtarı BURADA (appsettings, gitignored) ──
   │  1) RAG: answers → embedding → en yakın K bilgi kartını çek
   │  2) Prompt kur (sistem + kaynaklar + JSON şeması)
   ▼
Google Gemini API  →  JSON rapor
   │
   ▼
DB'ye kaydet (PreDiagnosis)  →  Hekime randevu detayında göster
```

**Neden backend'den çağrılmalı?** API anahtarı **asla** Flutter'a gömülmez (APK'dan sökülür). Senin
projede zaten `appsettings.json` gitignored + `firebase-adminsdk.json` deseni var — Gemini anahtarını da
aynı şekilde `appsettings.json`'a koy, backend'den çağır. Mevcut katmanlı mimariye (Controller→Service→
Repository) **yeni bir dikey dilim** olarak oturur:

- **Yeni entity `PreDiagnosis`**: `AnimalId`, `AppointmentId?`, `AnswersJson`, `AiReportJson`,
  `UrgencyLevel`, `CreatedAt`.
- **`PreDiagnosisController/Service`** + Gemini'ye REST çağrısı yapan bir `IAiClient` (HttpClient).

---

## 4. Veri Setini / Kaynağı Nereden Bulacaksın (somut)

### 4.1 Semptom-hastalık veri setleri (taksonomi + few-shot + test için)
- **Kaggle — Pet Health Symptoms Dataset** (sahibin günlük dille yazdığı gözlemler; deri, sindirim,
  parazit, kulak, hareket sorunları). Kedi-köpek için en uygunlarından. Hugging Face aynası da var.
- **Kaggle — Animal Disease Prediction** (semptom + tür/ırk/yaş/kilo → hastalık).
- **Kaggle — Animal Condition Classification** (tür + "tehlikeli mi" etiketi; aciliyet fikri için iyi).
> Bunları **eğitim için değil**, (a) standart bir semptom listesi çıkarmak, (b) few-shot örnek ve
> (c) 30-50 vaka'lık bir **değerlendirme seti** hazırlamak için kullan. Kalite değişkendir; körlemesine
> güvenme, elle temizle.

### 4.2 Otoriter bilgi tabanı (RAG'in kalbi — en değerli kaynak)
- **MSD / Merck Veterinary Manual** — 60+ yıllık, 400+ uzman, **ücretsiz tam metin** (hem profesyonel hem
  "pet-owner" sürümü). RAG bilgi kartlarının birincil kaynağı.
- **ASPCA** zehirli bitki/gıda listeleri (zehirlenme kırmızı-bayrakları için).
- **WSAVA**, üniversite veteriner "extension" siteleri, **Vetlexicon** (kısmi ücretsiz).
> **Telif uyarısı:** MSD içeriğini **toptan kopyalayıp dağıtma**. Akademik/kişisel RAG için kısa
> **özet kartlar** çıkar, kaynağı belirt, bitirme raporunda kaynakça ver. Ticari yayına almıyorsun
> (localde demo) → akademik kullanım kapsamında, ama yine de atıf yap.

---

## 5. Bulduğun Kaynakla NE Yapacaksın? (RAG, adım adım) — *asıl sorunun cevabı*

**Adım 1 — Kapsamı kilitle.** Kedi-köpekte ~**15-25 yaygın durum** seç: gastroenterit (kusma/ishal),
otitis (kulak), dermatit/pire-alerji, alt üriner sistem (özellikle erkek kedide idrar tıkanıklığı = ACİL),
konjonktivit, topallık/OA, diş, solunum, zehirlenme şüphesi, GDV (köpekte şişkin karın = ACİL)…

**Adım 2 — Bilgi kartlarını üret (RAG dokümanları).** Her durum için MSD + veri seti semptomlarından
kısa, tekdüze kartlar yaz:
```
Durum: Feline Alt Üriner Sistem Hastalığı (FLUTD)
Belirtiler: sık/ağrılı idrar, kanlı idrar, idrar yapamama, huzursuzluk...
Aciliyet: Erkek kedide idrar YAPAMAMA → ACİL (24 saatte hayati)
Evde: temiz su, stres azalt; İDRAR TIKANIKLIĞINDA bekleme
Ne zaman vete: idrar yapamıyorsa DERHAL
Kaynak: MSD Vet Manual / ...
```

**Adım 3 — Kartları aranabilir yap (embedding + vektör arama).**
- Kartları parça (chunk) → **Gemini embedding modeli** ile vektöre çevir → sakla.
- Başlangıçta basit tut: **JSON dosyası + kosinüs benzerliği** ya da SQLite. Büyürse `pgvector`/Qdrant.
- Çalışma anında: kullanıcı cevapları → sorgu embedding → en yakın **K=3-5 kart** → prompt'a koy.

**Adım 4 — Semptom taksonomisi + few-shot.** Veri setindeki semptom etiketlerinden soru akışının
kullanacağı **standart semptom listesini** çıkar; 3-5 tane "girdi → ideal rapor" **few-shot örneği** yaz.

**Adım 5 — Değerlendirme seti.** 30-50 vaka ayır ("beklenen aciliyet/ön teşhis" etiketli), modeli bununla
ölç (§9). **Eğitim/fine-tuning yok** — sadece derle, embed et, değerlendir.

---

## 6. Gemini Entegrasyonu (2026, somut)

- **Model:** `gemini-2.5-flash` (hız/kalite dengesi) veya `gemini-2.5-flash-lite` (daha yüksek kota).
  **Ücretsiz katman (2026):** Flash ~**250 istek/gün, 10 RPM**; Flash-Lite ~**1000 istek/gün, 15 RPM**;
  paylaşımlı **250K token/dk**, 1M bağlam. **Pro artık ücretli** (Nisan 2026'da free'den kalktı). Bitirme
  demosu için ücretsiz katman fazlasıyla yeter.
- **Yapılandırılmış çıktı (kilit özellik):** `responseMimeType: application/json` + `responseSchema`
  (JSON Schema alt kümesi). Böylece Gemini **her zaman** şu şemada döner:
```json
{
  "olasiDurumlar": [{ "ad": "…", "olasilik": "yüksek|orta|düşük", "kisaAciklama": "…" }],
  "aciliyetSeviyesi": "acil|24_saat|rutin|evde_izlem",
  "kirmiziBayraklar": ["…"],
  "evdeYapilabilecekler": ["…"],
  "kacinilmasiGerekenler": ["…"],
  "hekimeNot": "…",
  "sorumlulukReddi": "Bu bir ön değerlendirmedir, teşhis değildir."
}
```
- **Embedding:** RAG için Gemini embedding modeli (ücretsiz katmanda mevcut).
- **.NET tarafı:** `HttpClient` ile REST; anahtar `appsettings.json`'da (gitignored), **client'ta asla**.
- **⚠️ GİZLİLİK (rapora yaz):** Gemini **ücretsiz katmanı veri gizliliği garantisi vermez** — gönderdiğin
  girdi model iyileştirmede kullanılabilir. Bu yüzden **sahip/kişisel veriyi gönderme**; yalnız
  anonim tür/yaş/semptom gönder. Gerçek üretim için ücretli/kurumsal katman gerekir. (Demo için anonimleştir + not düş.)

---

## 7. Prompt Tasarımı (sistem promptu iskeleti)

> Sen bir veteriner **ön-triyaj asistanısın**. Görevin teşhis koymak DEĞİL; olası durumları, aciliyeti ve
> yönlendirmeyi belirtmek. **Yalnızca sana verilen KAYNAK kartlarına** dayan; kaynak dışına çıkma, emin
> değilsen "belirsiz, hekime danışın" de. Türü/yaşı dikkate al. Şu **kırmızı bayraklarda** koşulsuz "ACİL"
> de: solunum güçlüğü, kontrolsüz kanama, zehir teması, şişkin/gergin karın, idrar yapamama, bilinç kaybı,
> nöbet. Yanıtı **verilen JSON şemasına** birebir uy. Dil: Türkçe, sade, sahibi korkutmadan ama ciddiyetle.

---

## 8. Sorumluluk / Etik / Yasal (ZORUNLU — savunmada değer katar)

- **"Ön teşhis ≠ teşhis; tıbbi tavsiye değildir."** Her rapor ve akış başında görünür uyarı + kullanıcının
  onay kutusu (disclaimer). Acil durumda "doğrudan kliniğe/acil hattına".
- **İnsan döngüde:** nihai kararı **veteriner hekim** verir; sistem yalnız ona ön-bilgi sunar (rapor.md'nin
  hedefiyle birebir: "hekime randevu öncesi iletilir").
- **Güvenlik-öncelikli hata yönü:** şüphede **aciliyeti yüksek** tarafa yanıl (acil vakayı "rutin" dememek,
  tersinden daha az riskli).
- **Veri/KVKK:** kişisel veriyi anonimleştir, LLM'e gönderileni minimize et, kullanıcıdan açık onay al.
- **Halüsinasyon kontrolü:** RAG + "kaynak dışına çıkma" talimatı + düşük sıcaklık (temperature).

---

## 9. Değerlendirme (nasıl "çalışıyor" diyeceksin?)

- **Aciliyet doğruluğu** (en önemli güvenlik metriği): test setinde acil vakaların kaçını "acil" dedi
  (recall). Acil'i kaçırmak en kötü hata.
- **Makullük:** 10-15 vakayı bir veteriner hekime (danışmanına/tanıdığa) göster → "mantıklı mı?" (uzman değerlendirmesi).
- **Tutarlılık:** aynı girdiyi 3 kez sor, çıktılar tutarlı mı.
- Bunları bitirme raporuna **tablo** olarak koy — ölçülebilir hedef (rapor.md "Amaç ve Hedefler" ile uyumlu).

---

## 10. Adım Adım Yol Haritası (POC → MVP)

1. **Kapsam + bilgi kartları** (15-20 durum, MSD'den derle). *[en çok emek burada]*
2. **Gemini JSON POC** (RAG'siz): tek prompt + şema ile çalışan en basit hali. "Önce çalışsın."
3. **RAG ekle:** kartları embed et, K-en-yakın çekimi, prompt'a koy.
4. **Backend:** `PreDiagnosis` entity + `PreDiagnosisController/Service` + `IAiClient`.
5. **Flutter:** owner soru akışı ekranı; sonuç ekranı; (opsiyonel) randevuya iliştirme.
6. **Hekim görünümü:** randevu detayında "AI Ön Teşhis Raporu" bölümü (mevcut appointment_detail deseni).
7. **Değerlendirme + disclaimer + kaynakça.**

> Altın kural: **RAG'siz en basit sürümü önce bitir** (Adım 2), gösterebilir hale gel; RAG'i sonra ekle.

---

## 11. Uygulamana Özel Entegrasyon Noktaları

- **Owner:** yeni opsiyonel "Ön Teşhis" akışı (randevu öncesi). Mevcut `Animal` kaydından tür/yaş otomatik gelir.
- **Randevu bağlama:** rapor `AppointmentId`'ye iliştirilebilir → hekim randevu detayında görür (mevcut
  `appointment_detail_screen` + backend randevu servisleri deseni).
- **Backend:** Gemini anahtarı mevcut secret deseniyle (`appsettings.json` gitignored). Dikey dilim, tıpkı
  aşı/mesajlaşma modülleri gibi.

---

## 12. Kaynaklar

- Kaggle — Pet Health Symptoms Dataset: https://www.kaggle.com/datasets/yyzz1010/pet-health-symptoms-dataset
  (HF aynası: https://huggingface.co/datasets/karenwky/pet-health-symptoms-dataset )
- Kaggle — Animal Disease Prediction: https://www.kaggle.com/datasets/shijo96john/animal-disease-prediction
- Kaggle — Animal Condition Classification: https://www.kaggle.com/datasets/gracehephzibahm/animal-disease
- MSD / Merck Veterinary Manual (ücretsiz tam metin): https://www.msdvetmanual.com/
- Gemini — Yapılandırılmış çıktı (JSON Schema): https://ai.google.dev/gemini-api/docs/structured-output
- Gemini — Ücretsiz katman limitleri (2026): https://ai.google.dev/gemini-api/docs/rate-limits
