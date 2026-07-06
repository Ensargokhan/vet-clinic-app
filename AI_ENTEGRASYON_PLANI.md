# 🐾 Veteriner Yapay Zeka Asistanı — Uygulama Planı

## Amaç

Mevcut Veteriner Klinik uygulamasına bir **Yapay Zeka Ön Muayene Asistanı** entegre etmek. Bu asistan:
- Hayvan sahibine ön elemeli sorular soracak (sohbet formatında)
- Aldığı cevapları analiz edip **veteriner hekim için bir ön rapor (anamnez)** oluşturacak
- Kullanıcıya doğrudan teşhis **koymayacak**, amacı hekimin işini kolaylaştırmak

**Kullanılacak Model:** Google Gemini (ücretsiz katman — Gemini 2.0 Flash veya 1.5 Flash)

---

## Mimari Genel Bakış

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│  📱 Flutter App  │ ──── │  🖥️ C# Backend  │ ──── │  🤖 Gemini API  │
│  (Mobil Uygulama)│      │  (ASP.NET Core)  │      │  (Google AI)     │
└─────────────────┘      └────────┬─────────┘      └─────────────────┘
                                  │
                          ┌───────┴────────┐
                          │   🗄️ MySQL DB  │
                          │  (EF Core 9)    │
                          └────────────────┘
```

### Akış:
1. Kullanıcı Flutter'dan mesaj yazar → C# Backend'e gider
2. Backend, hayvanın bilgilerini MySQL'den çeker
3. Backend, System Prompt + Hayvan Bilgisi + Sohbet Geçmişi ile Gemini API'yi çağırır
4. Gemini'ın yanıtı Backend'e döner → Sohbet geçmişi veritabanına kaydedilir
5. Yanıt Flutter'a gönderilir

> **NOT:** API anahtarı **asla** Flutter tarafında tutulmayacak. Tüm Gemini iletişimi C# Backend üzerinden gerçekleşecek.

---

## Aşama 1: Temel Altyapı (Backend - C#)

### 1.1 Veritabanı — Yeni Tablolar

Üç yeni tablo oluşturulacak:

#### `ai_chat_sessions` — Sohbet Oturumları

| Sütun | Tip | Açıklama |
|-------|-----|----------|
| `id` | int (PK) | Otomatik artan |
| `user_id` | int (FK → users) | Oturumu başlatan kullanıcı |
| `animal_id` | int (FK → animals) | Hangi hayvan için |
| `status` | string | `active`, `completed`, `expired` |
| `created_at` | datetime | Oturum başlangıcı |
| `completed_at` | datetime? | Oturum bitiş zamanı |

#### `ai_chat_messages` — Mesaj Geçmişi

| Sütun | Tip | Açıklama |
|-------|-----|----------|
| `id` | int (PK) | Otomatik artan |
| `session_id` | int (FK → ai_chat_sessions) | Hangi oturuma ait |
| `role` | string | `user` veya `assistant` |
| `content` | text | Mesaj içeriği |
| `created_at` | datetime | Gönderim zamanı |

#### `ai_reports` — Ön Raporlar (Anamnez)

| Sütun | Tip | Açıklama |
|-------|-----|----------|
| `id` | int (PK) | Otomatik artan |
| `session_id` | int (FK → ai_chat_sessions) | Hangi sohbetten üretildi |
| `animal_id` | int (FK → animals) | Hangi hayvan için |
| `user_id` | int (FK → users) | Raporu oluşturan |
| `appointment_id` | int? (FK → appointments) | Randevuya bağlanmışsa |
| `report_content` | text | Ön rapor metni (Markdown/düz metin) |
| `symptoms_summary` | text | Belirtilerin kısa özeti |
| `urgency_level` | string | `low`, `medium`, `high`, `emergency` |
| `created_at` | datetime | Oluşturulma zamanı |

---

### 1.2 Backend Dosya Yapısı — Yeni Dosyalar

Mevcut Clean Architecture yapımıza uygun olarak şu dosyalar oluşturulacak:

```
VeterinerAPI/
├── Models/Entities/
│   ├── AiChatSession.cs          [YENİ]
│   ├── AiChatMessage.cs          [YENİ]
│   └── AiReport.cs               [YENİ]
├── DTOs/AI/
│   ├── AiChatRequestDto.cs       [YENİ]
│   ├── AiChatResponseDto.cs      [YENİ]
│   ├── AiReportDto.cs            [YENİ]
│   └── AiStartSessionDto.cs      [YENİ]
├── Services/
│   ├── Interfaces/
│   │   └── IAiAssistantService.cs [YENİ]
│   └── Implementations/
│       └── AiAssistantService.cs  [YENİ]
├── Controllers/
│   └── AiAssistantController.cs   [YENİ]
├── Data/
│   └── AppDbContext.cs            [GÜNCELLE — yeni DbSet'ler]
└── Program.cs                     [GÜNCELLE — yeni service kaydı]
```

---

### 1.3 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `POST` | `/api/ai/start-session` | Yeni sohbet oturumu başlat (hayvan ID'si ile) |
| `POST` | `/api/ai/chat` | Mesaj gönder ve asistandan yanıt al |
| `POST` | `/api/ai/finalize-report` | Sohbeti bitirip ön rapor oluştur |
| `GET` | `/api/ai/reports/{animalId}` | Bir hayvana ait ön raporları listele |
| `GET` | `/api/ai/report/{reportId}` | Tek bir raporu detaylı getir |

---

### 1.4 Gemini Prompt Tasarımı (System Instruction)

Bu, tüm sistemin kalbi. Gemini'a verilecek **System Prompt** şöyle olacak:

```
Sen bir veteriner kliniği yapay zeka asistanısın. Görevin, hasta hayvanın sahibine
ön elemeli sorular sorarak hayvanın durumunu anlamak ve veteriner hekim için detaylı
bir ön rapor (anamnez) hazırlamaktır.

KURALLAR:
1. Kullanıcıya ASLA teşhis koyma veya ilaç önerme.
2. Her seferinde EN FAZLA 1-2 soru sor. Soruları basit ve anlaşılır tut.
3. Sorularını mantıksal bir sırayla sor:
   - Önce ana şikayeti öğren ("Neden endişeleniyorsunuz?")
   - Belirtinin ne zaman başladığını sor
   - Belirtinin şiddetini ve seyrini sor
   - İştah, su tüketimi, dışkılama, enerji seviyesi gibi genel durumu sor
   - Daha önce benzer bir durum yaşanıp yaşanmadığını sor
4. Yeterli bilgiyi topladığını düşündüğünde (genellikle 5-8 soru sonra)
   kullanıcıya "Yeterli bilgiyi topladım, şimdi veteriner hekiminiz için
   bir ön rapor hazırlayacağım." de.
5. Yanıtlarını Türkçe ver.
6. Sıcak, empatik ve profesyonel bir üslup kullan.
7. Acil durumları tespit edersen (nefes darlığı, kanama, bilinç kaybı vb.)
   hemen "Bu acil bir durumdur, lütfen en yakın veteriner kliniğine gidin!" uyarısı ver.

HAYVAN BİLGİLERİ:
- Adı: {animalName}
- Türü: {species}
- Irkı: {breed}
- Yaşı: {age}
- Kilosu: {weight} kg
- Cinsiyeti: {gender}
- Aşı Geçmişi: {vaccineHistory}
```

> **İPUCU:** Bu prompt, hayvanın mevcut bilgilerini (isim, tür, yaş, kilo, aşı geçmişi) veritabanımızdan çekerek dinamik olarak doldurulacak. Böylece kullanıcı bunları tekrar girmek zorunda kalmayacak.

---

### 1.5 C# Gemini SDK Entegrasyonu

`VeterinerAPI.csproj` dosyasına eklenecek NuGet paketi:

```xml
<PackageReference Include="Mscc.GenerativeAI" Version="..." />
```
> `Mscc.GenerativeAI`, Google'ın Gemini API'sine erişim sağlayan topluluk SDK'sıdır. Alternatif olarak Google'ın resmi `Google.Cloud.AIPlatform.V1` paketi de kullanılabilir.

`appsettings.json` dosyasına eklenecek ayar:

```json
{
  "GeminiAI": {
    "ApiKey": "BURAYA_API_KEY",
    "Model": "gemini-2.0-flash"
  }
}
```

> **DİKKAT:** API Key'i `appsettings.json`'a doğrudan yazmak development için uygundur. Production'da bu değer **Environment Variable** veya **User Secrets** ile yönetilmelidir. `.gitignore` dosyasına dikkat!

---

## Aşama 2: Flutter (Mobil Uygulama) Tarafı

### 2.1 Yeni Dosya Yapısı

```
VeterinerApp/lib/features/ai_assistant/
├── data/
│   ├── models/
│   │   ├── ai_chat_message_model.dart    [YENİ]
│   │   ├── ai_chat_session_model.dart    [YENİ]
│   │   └── ai_report_model.dart          [YENİ]
│   └── ai_assistant_repository.dart      [YENİ]
├── presentation/
│   ├── providers/
│   │   └── ai_assistant_provider.dart    [YENİ]
│   ├── screens/
│   │   ├── ai_chat_screen.dart           [YENİ] — Ana sohbet ekranı
│   │   └── ai_report_screen.dart         [YENİ] — Rapor görüntüleme
│   └── widgets/
│       ├── chat_bubble.dart              [YENİ]
│       ├── typing_indicator.dart         [YENİ]
│       └── urgency_badge.dart            [YENİ]
```

### 2.2 Kullanıcı Akışı (User Flow)

```
🐾 Hayvan Detay Sayfası
    │
    ▼ "Yapay Zeka Asistanı" butonuna bas
    │
🤖 Sohbet Ekranı Açılır
    │
    ▼ Asistan: "Merhaba! Boncuk için ne gibi bir endişeniz var?"
    │
    ▼ Kullanıcı: "Son 2 gündür yemek yemiyor"
    │
    ▼ Asistan: "Ne zamandan beri iştahsız? Kusma var mı?"
    │
    ▼ ... 5-8 soru-cevap ...
    │
    ▼ Asistan yeterli bilgiyi topladı
    │
📋 Ön Rapor Oluşturulur
    │
    ├── 📅 Randevu Al → Randevu ekranına git (Rapor otomatik eklenir)
    ├── 💾 Raporu Kaydet → Raporlarım'a kaydet
    └── 📤 Paylaş → Raporu hekime gönder
```

### 2.3 Ekran Tasarımı — Sohbet (Chat) Ekranı

Sohbet ekranı şu şekilde çalışacak:
- **Üstte:** Hayvanın adı ve fotoğrafı (küçük avatar)
- **Ortada:** ChatGPT benzeri sohbet balonları (kullanıcı sağda, asistan solda)
- **Asistan yazarken:** "Asistan düşünüyor..." animasyonu (typing indicator)
- **Altta:** Mesaj yazma alanı + gönder butonu
- **Sohbet bitince:** "Ön Rapor Hazırla" butonu belirir

### 2.4 Mevcut Dosyalarda Değişiklikler

| Dosya | Değişiklik |
|-------|-----------|
| `app_router.dart` | Yeni `ai-chat` ve `ai-report` route'ları |
| `animal_detail_screen.dart` | "🤖 Yapay Zeka Asistanı" butonu eklenir |
| `create_appointment_screen.dart` | Ön rapor varsa randevuya otomatik ekle |

---

## Aşama 3: Güvenlik ve Rate Limiting

| Önlem | Detay |
|-------|-------|
| **API Key Güvenliği** | Gemini API Key yalnızca backend'de tutulur, Flutter'a asla gönderilmez |
| **Rate Limiting** | Kullanıcı başına saatte max 10 AI sohbet oturumu (kötüye kullanımı önlemek için) |
| **Input Sanitization** | Kullanıcı mesajları backend'de temizlenir (injection koruması) |
| **Prompt Injection Koruması** | System prompt'taki roller sıkı tutulur, kullanıcının prompt'u manipüle etmesi engellenir |
| **Yasal Uyarı** | Sohbet başlamadan "Bu bir yapay zeka asistanıdır, teşhis koyamaz" uyarısı gösterilir |

---

## Aşama 4: İleri Seviye — RAG & Fine-Tuning (Gelecek)

Bu aşamalar, temel entegrasyon çalıştıktan sonra ele alınacak:

### 4.1 RAG (Retrieval-Augmented Generation)
- Yaygın hayvan hastalıkları, belirtileri ve tedavi yöntemlerini içeren bir bilgi bankası (vektör veritabanı) oluşturulur
- Kullanıcı bir belirti söylediğinde, önce bu bankada arama yapılır, bulunan bilgi Gemini'a ek bağlam olarak verilir
- Bu, modelin halüsinasyon görmesini engeller

### 4.2 Fine-Tuning (İnce Ayar)
- Kliniğinizde biriken gerçek vaka verileri (anonimleştirilmiş) ile Google AI Studio üzerinden model eğitilebilir
- Bu, modelin sizin kliniğinize özel konuşma kalıpları ve bilgi düzeyi kazanmasını sağlar
- Bunun için binlerce soru-cevap çifti gerekir (zamanla birikecek)

---

## ❓ Açık Sorular — Cevaplarını Bekliyorum

> Kod yazmaya başlamadan önce şu soruların cevaplarına ihtiyacım var:

### Soru 1: Hangi Hayvandan Başlasın?
Kullanıcı sohbete **Hayvan Detay Sayfası'ndan** mı başlasın (hayvan otomatik seçili), yoksa ayrı bir menüden mi?

### Soru 2: Raporun Randevuyla İlişkisi
Üretilen ön rapor:
- **(A)** Kullanıcı randevu aldığında otomatik olarak randevuya bağlansın mı?
- **(B)** Sadece kullanıcının profilinde "Raporlarım" bölümünde kalsın ve isteğe bağlı paylaşılsın mı?
- **(C)** Her ikisi de olsun mu?

### Soru 3: Veteriner Hekim Paneli
Ön rapor, veteriner hekimin panelinde görünsün mü? Yani hekim randevu detayına girince "AI Ön Raporu" sekmesi görsün mü?

### Soru 4: Gemini API Key
Google AI Studio'dan ücretsiz bir Gemini API Key'in var mı? Yoksa birlikte nasıl alacağımızı adım adım göstereyim mi?

### Soru 5: Öncelik Sırası
Önce **"Randevu Saatleri Boş Dönme"** sorununu (agents.md'deki bug) mu çözelim, yoksa doğrudan AI entegrasyonuna mı geçelim?

---

## Doğrulama Planı (Verification)

### Otomatik Testler
- Backend: `AiAssistantService` için birim testleri (mock Gemini yanıtlarıyla)
- API endpoint'leri için integration testleri

### Manuel Test
1. Flutter'da sohbet ekranını açıp bir hayvan için ön muayene başlatma
2. Gemini'ın mantıklı ve sıralı sorular sorduğunu doğrulama
3. Sohbet sonunda üretilen ön raporun eksiksiz ve okunabilir olduğunu kontrol etme
4. Ön raporun veritabanına kaydedildiğini doğrulama
5. Acil durum tespitinin çalıştığını test etme (örn: "kedim kan kusuyor" senaryosu)
