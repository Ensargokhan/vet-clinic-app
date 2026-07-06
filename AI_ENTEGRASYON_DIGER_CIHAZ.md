# AI Ön Muayene Asistanı — Diğer Cihaz Kurulum & Test Rehberi (Faz 1 / Backend)

Bu doküman, **backend AI kodu yazıldıktan sonra** DB'nin ve Gemini API anahtarının bulunduğu
cihazda (senin makinen) yapılacak **canlı adımları** içerir. Buradaki (Claude) tarafta backend
kodu yazıldı ve `dotnet build` ile **0 hatayla derlendi**, `AddAiAssistant` migration'ı **DB'ye
bağlanmadan** üretildi. Aşağıdakiler DB/anahtar gerektiren, burada yapılamayan işler.

> **Not:** Frontend (Flutter) kodları **Faz 2**'de yazılacak. Bu doküman Faz 2 sonunda
> `flutter` adımlarıyla genişletilecek. Şimdilik backend'i canlıya alıp Postman ile test ediyoruz.

---

## 0. Bu turda backend'de ne eklendi? (özet)

**Yeni tablolar (migration `AddAiAssistant`):** `ai_chat_sessions`, `ai_chat_messages`, `ai_reports`.

**Yeni kod:**
- `Models/Entities/AiChatSession.cs`, `AiChatMessage.cs`, `AiReport.cs`
- `Services/Ai/GeminiOptions.cs`, `IGeminiClient.cs`, `GeminiClient.cs` (REST, HttpClient)
- `Services/Interfaces/IAiAssistantService.cs`, `Services/Implementations/AiAssistantService.cs`
- `Repositories/{Interfaces,Implementations}/AiChatSession|AiChatMessage|AiReport…`
- `Controllers/AiAssistantController.cs` (`/api/ai/...`)
- `DTOs/AI/…`
- `Data/AppDbContext.cs` (3 DbSet + FK/index), `Program.cs` (DI + HttpClient + `AiPolicy`), `appsettings.example.json`

**API uçları** (hepsi `[Authorize]`, Firebase Bearer token ister):
| Metot | Yol | Açıklama | Rate limit |
|------|-----|----------|-----------|
| POST | `/api/ai/start-session` | Oturum başlat (body: `{ "animalId": 1 }`) | GeneralPolicy |
| POST | `/api/ai/sessions/{id}/chat` | Mesaj gönder (body: `{ "message": "..." }`) | **AiPolicy** |
| GET | `/api/ai/sessions/{id}/messages` | Sohbeti getir | GeneralPolicy |
| POST | `/api/ai/sessions/{id}/finalize` | Ön rapor üret | **AiPolicy** |
| POST | `/api/ai/reports/{reportId}/attach/{appointmentId}` | Raporu randevuya bağla | GeneralPolicy |
| GET | `/api/ai/reports/by-appointment/{appointmentId}` | Randevunun raporunu getir (owner/vet) | GeneralPolicy |

`AiPolicy`: 5 dakikada 20 istek (Gemini kotasını/maliyeti korur).

---

## 1. Gemini API anahtarı alma (Google AI Studio)

1. https://aistudio.google.com adresine Google hesabınla gir.
2. Sol menüden **"Get API key"** (veya **"API keys"**) → **"Create API key"**.
3. Anahtarı bir projeye bağla (yoksa yeni proje oluştur) → oluşan `AIza...` anahtarını **kopyala**.
4. **Ücretsiz katman** yeterli: `gemini-2.5-flash` günde ~250 istek, dakikada ~10 istek.
   - Kotayı çok aşarsan alternatif: `gemini-2.5-flash-lite` (günde ~1000 istek). Model adını
     `appsettings.json`'da `GeminiAI:Model` ile değiştir.
5. ⚠️ **Gizlilik uyarısı:** Ücretsiz katmanda gönderilen veriler Google tarafından model
   iyileştirmede kullanılabilir. Demo/bitirme için uygun; gerçek klinik verisinde ücretli katman/veri
   koruması gerekir. (Detay: `ai-on-teshis-rehberi.md`.)

---

## 2. `appsettings.json`'a anahtarı ekle (gitignored)

`VeterinerAPI/appsettings.json` (git'e girmez) dosyasına `GeminiAI` bölümünü ekle. Şablon
`appsettings.example.json` içinde hazır:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "server=localhost;database=vetdb;user=root;password=SENIN_SIFREN"
  },
  "GeminiAI": {
    "ApiKey": "AIza...SENIN_ANAHTARIN",
    "Model": "gemini-2.5-flash",
    "BaseUrl": "https://generativelanguage.googleapis.com"
  }
}
```

> `ApiKey` boş bırakılırsa uçlar **500** döner ("AI servisi yapılandırılmamış.") — kod bilinçli
> olarak boş anahtarda Gemini'ye çıkmaz.

---

## 3. Migration'ı canlı DB'ye uygula

`AddAiAssistant` migration dosyaları **zaten üretildi** (`Migrations/*_AddAiAssistant.cs`). Sadece
uygulaman gerekiyor:

```bash
cd VeterinerAPI
dotnet ef database update      # 3 yeni tabloyu oluşturur
# veya sadece
dotnet run                     # DbSeeder içindeki MigrateAsync bekleyen migration'ları uygular
```

Doğrula (MySQL):
```sql
SHOW TABLES LIKE 'ai_%';
-- ai_chat_sessions, ai_chat_messages, ai_reports görünmeli
```

---

## 4. Gemini REST şeması (canlı test edemediğim için debug referansı)

`GeminiClient` şu isteği atıyor:

```
POST {BaseUrl}/v1beta/models/{Model}:generateContent?key={ApiKey}
Content-Type: application/json
```

**Sohbet cevabı (chat) gövdesi:**
```json
{
  "systemInstruction": { "parts": [ { "text": "Sen bir veteriner ... asistanısın ..." } ] },
  "contents": [
    { "role": "user",  "parts": [ { "text": "Köpeğim kusuyor" } ] },
    { "role": "model", "parts": [ { "text": "Ne zamandır sürüyor?" } ] }
  ],
  "generationConfig": { "temperature": 0.4 }
}
```
> Not: DB'de rol `assistant`; Gemini'ye giderken **`model`** olarak eşlenir (`GeminiClient.MapRole`).

**Rapor (finalize) gövdesi** — JSON şema zorlanır:
```json
{
  "systemInstruction": { "parts": [ { "text": "... yapılandırılmış anamnez üret ..." } ] },
  "contents": [ { "role": "user", "parts": [ { "text": "SOHBET GEÇMİŞİ: ..." } ] } ],
  "generationConfig": {
    "temperature": 0.2,
    "responseMimeType": "application/json",
    "responseSchema": {
      "type": "OBJECT",
      "properties": {
        "reportContent":   { "type": "STRING" },
        "symptomsSummary": { "type": "STRING" },
        "urgencyLevel":    { "type": "STRING", "enum": ["low","medium","high","emergency"] }
      },
      "required": ["reportContent","symptomsSummary","urgencyLevel"]
    }
  }
}
```

**Başarılı yanıt** (kod `candidates[0].content.parts[*].text` birleştirir):
```json
{ "candidates": [ { "content": { "parts": [ { "text": "..." } ], "role": "model" } } ] }
```

**Anahtarı doğrudan curl ile test** (kod devreye girmeden Gemini'nin çalıştığını gör):
```bash
curl -s -X POST \
 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIza...ANAHTAR" \
 -H "Content-Type: application/json" \
 -d '{"contents":[{"role":"user","parts":[{"text":"Merhaba, tek cümle yanıt ver."}]}]}'
```
> 200 + `candidates` gelirse anahtar/kotanız çalışıyor demektir. 400/403 → anahtar/model adı;
> 429 → kota (bekle veya `flash-lite`'a geç).

---

## 5. Backend API testi (Postman / curl)

Ön koşul: geçerli bir Firebase kullanıcısıyla giriş yapıp **ID token** al (mevcut login akışı).
Tüm isteklere header: `Authorization: Bearer <FIREBASE_ID_TOKEN>`.
Ayrıca elinde, **kendi hayvanın** olan bir `animalId` ve (attach testi için) sana ait bir `appointmentId` olsun.

**Akış:**
1. **Oturum başlat**
   ```
   POST /api/ai/start-session
   { "animalId": 1 }
   ```
   → `data.sessionId` ve açılış mesajını not al. (Açılış mesajı hardcode'dur; Gemini çağrılmaz.)

2. **Mesajlaş** (birkaç kez — Gemini burada devreye girer)
   ```
   POST /api/ai/sessions/{sessionId}/chat
   { "message": "Köpeğim dün akşamdan beri kusuyor ve hiçbir şey yemiyor." }
   ```
   → `data.content` içinde asistanın sorusu gelmeli.

3. **Ön rapor üret**
   ```
   POST /api/ai/sessions/{sessionId}/finalize
   ```
   → `data.reportContent`, `data.symptomsSummary`, `data.urgencyLevel` (low/medium/high/emergency)
     ve `data.id` (reportId).

4. **Raporu randevuya bağla**
   ```
   POST /api/ai/reports/{reportId}/attach/{appointmentId}
   ```
   → başarı mesajı. (Rapor ile randevunun **aynı hayvana** ait olması gerekir, aksi halde 400.)

5. **Hekim/owner rapora ulaşsın**
   ```
   GET /api/ai/reports/by-appointment/{appointmentId}
   ```
   → owner (randevu sahibi) veya ilgili hekim raporu görebilmeli; yetkisiz → 403.

**Acil senaryo denemesi:** chat'te "köpeğim kan kusuyor, nefes alamıyor" gibi bir mesaj gönder →
finalize'de `urgencyLevel` **`emergency`/`high`** dönmeli ve rapor buna dikkat çekmeli.

---

## 6. Olası sorunlar ve çözümleri

| Belirti | Olası neden | Çözüm |
|--------|-------------|-------|
| 500 "AI servisi yapılandırılmamış." | `GeminiAI:ApiKey` boş | `appsettings.json`'a anahtarı ekle, yeniden başlat |
| 500 "AI şu an yanıt veremiyor." | Yanlış model adı / 400 / ağ | Model adını (`gemini-2.5-flash`) ve curl testini (madde 4) kontrol et |
| 429 (Gemini) log'da | Ücretsiz kota aşıldı | Bekle veya `Model`'i `gemini-2.5-flash-lite` yap |
| "AI raporu okunamadı." | Finalize JSON parse hatası | Log'daki ham metni gör; `responseSchema` desteği için model adı 2.5+ olmalı |
| 429 (bizim API) | `AiPolicy` limiti (20/5dk) | Normal; bekle. Gerekirse `Program.cs`'te limiti artır |
| `by-appointment` 404 | Rapor henüz randevuya bağlanmadı | Önce madde 4 (attach) çalıştır |
| `by-appointment` 403 | Owner/hekim eşleşmiyor | Doğru kullanıcı token'ı ve randevu kullan |
| migration DB'ye gitmedi | `database update` çalıştırılmadı | Madde 3 |

---

## 7. Faz 2 — Frontend (yazıldı, canlı test bekliyor)

Frontend kodu **yazıldı**. Bu makinede Flutter SDK varsa aşağıdaki adımlarla çalıştırıp test et.

### 7.1 Eklenen/değişen dosyalar
**Yeni:** `features/ai_assistant/data/models/{ai_chat_message_model,ai_report_model}.dart` ·
`features/ai_assistant/presentation/screens/ai_chat_screen.dart` ·
`features/ai_assistant/presentation/widgets/ai_report_view.dart` · `core/utils/ai_urgency.dart`
**Değişen:** `appointments/.../create_appointment_screen.dart` (5. adım "Ön Muayene" + attach) ·
`core/router/app_router.dart` (`/ai-chat`) · `appointments/.../appointment_detail_screen.dart` (owner rapor bölümü) ·
`vet_panel/.../vet_appointments_screen.dart` (hekim "AI Ön Rapor" butonu).

### 7.2 Çalıştırma
```bash
cd VeterinerApp
flutter pub get
flutter analyze        # 0 hata bekleriz (uyarılar olabilir)
flutter run            # emülatör/cihaz
```
> **Fiziksel cihaz notu:** `core/network/dio_client.dart` içindeki `baseUrl`
> `http://10.0.2.2:5295/api` yalnız Android emülatörü içindir. Gerçek telefonda makinenin
> **LAN IP**'siyle değiştir (ör. `http://192.168.1.34:5295/api`). Aynı şekilde
> `create_appointment_screen.dart`'taki `_imgBase` de gerekiyorsa güncellenir.

### 7.3 Uçtan uca senaryo (owner + vet)
1. **Owner** ile giriş → **Randevu Al** akışı: Hekim → Tarih/Saat → Hayvan → **Ön Muayene** adımı.
2. Ön Muayene adımında **"Ön Muayeneyi Başlat"** → yasal uyarı → **Anladım, Başla**.
3. AI ile sohbet et (birkaç mesaj). Asistan sırayla soru sormalı, "yazıyor…" görünmeli.
4. **"Ön Raporu Hazırla"** → adıma dön: aciliyet rozeti + belirti özeti kartı gelmeli ve
   "Belirti özeti randevu sebebine eklendi" yazmalı (randevu sebebi otomatik dolar).
5. **Devam Et → Özet**'te "AI Ön Rapor: Hazırlandı — Aciliyet: …" satırı görünmeli → **Randevuyu Onayla**.
6. **Owner** → Randevularım → o randevunun **detayında** "AI Ön Muayene Raporu" kartı (tam rapor) görünmeli.
7. **Vet** (randevunun hekimi) ile giriş → Randevularım → ilgili kart → **"AI Ön Rapor"** butonu →
   alttan açılan sayfada raporun tamamı görünmeli. (Rapor bağlı değilse "Bu randevuya bağlı ön rapor yok.")

### 7.4 Acil senaryo
Sohbette **"köpeğim kan kusuyor ve nefes alamıyor"** benzeri bir mesaj → rapor rozeti
**ACİL (emergency)** veya **Yüksek (high)** gelmeli; sohbette de acil uyarısı çıkmalı.

### 7.5 Olası sorunlar
| Belirti | Neden | Çözüm |
|--------|-------|-------|
| Ön Muayene adımında "başlatılamadı" | Backend/anahtar sorunu | §6 tablosu (Gemini key/kota) |
| Rapor detayda/hekimde görünmüyor | attach çalışmadı | Randevu oluşturma yanıtında `data.appointmentId` var mı? Owner ile hayvan aynı mı? |
| "AI Ön Rapor" 404 | Rapor o randevuya bağlanmadı | Önce owner akışında ön muayene tamamlanıp randevu onaylanmalı |
| İstek yanıtı gelmiyor (fiziksel cihaz) | `baseUrl` emülatör IP'si | §7.2 LAN IP notu |
