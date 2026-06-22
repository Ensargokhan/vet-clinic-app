# Deploy Kontrol Listesi (Deploy Checklist)

Her canlıya (production) çıkıştan önce aşağıdaki adımları kontrol edin:

## 🔐 1. Çevre Değişkenleri (Environment Variables)
- [ ] `.env` ve `appsettings.json` dosyalarındaki gizli bilgiler Git'e commit EDİLMEMİŞ.
- [ ] Tüm secret'lar (DB parolası, API key'ler) hosting platformunun (Azure, AWS, Vercel vs.) kendi panelinde tanımlanmış.
- [ ] Boş şablon olan `.env.example` veya `appsettings.example.json` güncel.

## 🚦 2. Güvenlik ve Ağ (Security & Network)
- [ ] `appsettings.Production.json` içinde veritabanı bağlantı metninde (connection string) doğru public/private adres kullanılmış.
- [ ] Veritabanı doğrudan internete açık DEĞİL (private network arkasında).
- [ ] API URL'leri HTTPS olarak ayarlanmış (Flutter tarafında `baseUrl`).
- [ ] CORS sadece izin verilen kaynaklarla (mobil uygulama veya frontend) kısıtlanmış (`Program.cs` içinde `Cors:AllowedOrigins` ayarlanmış).
- [ ] Tüm dışarıya açık API uç noktalarında Rate Limiting (Hız Sınırlandırma) devrede.

## 🧹 3. Yapılandırma ve Loglama (Config & Logging)
- [ ] ASP.NET Core `ASPNETCORE_ENVIRONMENT` değişkeni `Production` olarak ayarlı.
- [ ] Debug modu kapalı, Swagger/OpenAPI sadece Development ortamında açık.
- [ ] Loglama mekanizmasında hassas bilgiler (kullanıcı şifresi, kredi kartı vb.) maskelenmiş.
- [ ] `GlobalExceptionMiddleware` düzgün çalışıyor ve `500 Internal Server Error` durumunda kullanıcılara stack trace sızdırılmıyor.

## 🛠️ 4. Veritabanı (Database)
- [ ] Bekleyen son EF Core migration'ları canlı veritabanına başarıyla uygulandı (`dotnet ef database update`).
- [ ] Gereksiz "dummy" (örnek) test verileri canlı sistemden temizlendi.

## 📱 5. İstemci (Frontend / Flutter)
- [ ] `DioClient` içindeki `baseUrl`, backend'in production URL'i ile güncellendi.
- [ ] Uygulama release (üretim) modunda build alındı (`flutter build apk --release` veya `flutter build ipa`).
- [ ] `firebase_options.dart` dosyasındaki key'ler (publishable) kontrol edildi.
