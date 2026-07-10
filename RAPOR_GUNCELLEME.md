# Rapor Güncelleme — `müh_tasarım_final.docx`

Bu dosya, raporun güncellenmesi gereken bölümlerini **Word'e yapıştırılmaya hazır** biçimde içerir.
Her başlık altında önce *neyin neden değiştiği*, sonra **yeni metin** verilmiştir.
Başlık numaraları raporun mevcut yapısıyla birebir eşleşir.

> Not: **ÖZET** ve **ABSTRACT** en sona bırakılmıştır — gövdeyi özetledikleri için en son yazılmaları doğrudur.

---

## SİMGELER VE KISALTMALAR

**Neden değişiyor:** Raporun gövdesinde kullanılan ancak listede bulunmayan kısaltmalar var
(NLP → 3.1.5'te, DSS → 5.1'de geçiyor). Güncellenen bölümlerde ayrıca LLM, RAG, DTO, EF gibi
terimler kullanılacak. Liste alfabetik sırada tutulmuştur.

### Yeni metin

**Kısaltmalar**

```
API   : Application Programming Interface (Uygulama Programlama Arayüzü)
CRUD  : Create, Read, Update, Delete (Oluştur, Oku, Güncelle, Sil)
DSS   : Decision Support System (Karar Destek Sistemi)
DTO   : Data Transfer Object (Veri Taşıma Nesnesi)
EF    : Entity Framework
ER    : Entity-Relationship (Varlık-İlişki)
FCM   : Firebase Cloud Messaging
HTTP  : Hypertext Transfer Protocol
JSON  : JavaScript Object Notation
JWT   : JSON Web Token
LLM   : Large Language Model (Büyük Dil Modeli)
NLP   : Natural Language Processing (Doğal Dil İşleme)
ORM   : Object-Relational Mapping (Nesne-İlişkisel Eşleme)
RAG   : Retrieval-Augmented Generation (Erişim ile Zenginleştirilmiş Üretim)
REST  : Representational State Transfer
SDK   : Software Development Kit (Yazılım Geliştirme Kiti)
TOCTOU: Time-of-Check to Time-of-Use (Kontrol Anı ile Kullanım Anı Arası Yarış Durumu)
UI/UX : User Interface / User Experience (Kullanıcı Arayüzü / Kullanıcı Deneyimi)
XSS   : Cross-Site Scripting (Siteler Arası Betik Çalıştırma)
```

---

## 1.2.3. Yapay Zekâ Destekli Ön Teşhis Modülü

**Neden değişiyor:**
1. Rapor **OpenAI API** diyor; proje **Google Gemini** (`gemini-2.5-flash`) ile gerçeklendi.
2. Rapor modülün "eliminasyon mantığı"yla çalışacağını söylüyor; gerçekte **çok turlu sohbet** (her turda
   1–2 soru) yürütülüyor ve sonunda **yapılandırılmış anamnez raporu** üretiliyor.
3. Rapor modülü bir *hedef* olarak anlatıyor; modül **tamamlandı**, bu yüzden dil hedeften gerçekleşene çekildi.
4. Raporun tanımlamadığı iki gerçek çıktı eklendi: **aciliyet seviyesi sınıflandırması** ve raporun
   **randevuya bağlanarak hekimin paneline düşmesi**.

### Yeni metin

Projenin en yenilikçi bileşeni, hasta sahibinin kliniğe gelmeden önce evcil hayvanının durumunu
yapılandırılmış biçimde aktarmasını sağlayan yapay zekâ destekli ön teşhis modülüdür. Modül, Google'ın
büyük dil modeli (LLM) ailesinden **Gemini** servisi üzerine inşa edilmiştir.

Modül, tek seferlik bir form doldurma mantığıyla değil, **çok turlu bir sohbet** akışıyla çalışmaktadır.
Yapay zekâ asistanı her turda en fazla bir veya iki soru sorarak; ana şikâyeti, belirtinin başlangıç
zamanını, şiddetini ve seyrini, hayvanın iştah, su tüketimi, dışkılama ve enerji düzeyi gibi genel durum
göstergelerini sırayla öğrenmektedir. Böylece hasta sahibinin tıbbi terminolojiye hâkim olmasına gerek
kalmadan, hekimin ihtiyaç duyduğu anamnez bilgisi adım adım toplanmaktadır.

Sohbet başlatılırken hayvanın veri tabanındaki kayıtlı bilgileri (adı, türü, ırkı, yaşı, kilosu, cinsiyeti
ve aşı geçmişi) sistem talimatına otomatik olarak yerleştirilmektedir. Bu sayede kullanıcı, sistemde zaten
kayıtlı olan bilgileri tekrar girmek zorunda kalmamakta; yapay zekâ ise vakayı hayvanın tıbbi geçmişi
bağlamında değerlendirebilmektedir.

Modülün tasarımında **klinik güvenlik** ilkesi esas alınmıştır. Asistan, hiçbir koşulda kesin teşhis koymamakta
ve ilaç önermemektedir; görevi yalnızca bilgi toplamak ve bunu hekime aktarmaktır. Nefes darlığı, yoğun
kanama, bilinç kaybı veya zehirlenme şüphesi gibi durumlar tespit edildiğinde kullanıcı, sohbet sırasında
en yakın veteriner kliniğine vakit kaybetmeden başvurması yönünde uyarılmaktadır. Ayrıca kullanıcının
sohbeti amacı dışına çekme girişimleri sistem talimatı düzeyinde engellenmiştir.

Yeterli bilgi toplandığında kullanıcı ön raporu oluşturmakta ve yapay zekâ, sohbet dökümünü üç alandan oluşan
**yapılandırılmış bir çıktıya** dönüştürmektedir:

- **Belirti özeti:** Şikâyetin bir iki cümlelik özeti; randevu sebebi alanına otomatik olarak aktarılır.
- **Ön rapor (anamnez):** Hekime yönelik, başlıklandırılmış ayrıntılı değerlendirme metni.
- **Aciliyet seviyesi:** Vakanın *düşük*, *orta*, *yüksek* veya *acil* olarak sınıflandırılması.

Bu çıktının serbest metin yerine makine tarafından güvenilir biçimde okunabilen bir şemaya oturtulması,
özellikle aciliyet seviyesinin arayüzde tutarlı bir görsel uyarıya (renk kodlu rozet) dönüştürülebilmesi
açısından kritik önemdedir.

Üretilen ön rapor, oluşturulan randevu kaydıyla ilişkilendirilmektedir. Böylece hasta sahibi raporu kendi
randevu detayında görüntüleyebilmekte; **ilgili veteriner hekim ise muayeneden önce randevu listesi üzerinden
rapora erişebilmektedir.** Bu akış, hekimin vakayı önceden değerlendirmesine ve teşhis sürecine bir adım önde
başlamasına imkân tanımakta, dolayısıyla fiziksel muayene süresini kısaltmaktadır. Modül, randevu alma akışının
isteğe bağlı bir adımı olarak konumlandırılmış; ön muayene yapmak istemeyen kullanıcıların bu adımı atlayarak
randevularını tamamlayabilmesi sağlanmıştır.

---

## 1.2.4. Klinik Değerlendirme ve Kalite Kontrol Sistemi

**Neden değişiyor:**
1. Gelecek zaman ("oluşturulacaktır") → modül **tamamlandı**, geçmiş zamana çekildi.
2. ⚠️ Mevcut metin *"ilgili kliniği **ve hekimi** puanlayıp"* diyor. Sistemde **yalnızca klinik** puanlanmaktadır
   (hekim puanlaması kapsam dışı bırakıldı) → ifade düzeltildi.
3. Modülün ayırt edici tasarım kararları (tamamlanmış randevu şartı, klinik başına tek yorum, gizlenememe)
   eklendi — jüri "sahte yorumu nasıl engelliyorsunuz?" diye sorduğunda cevabı metinde olsun.

### Yeni metin

Kullanıcıların aldıkları hizmet sonrasında ilgili kliniği puanlayıp yorum bırakabilmelerini sağlayan bir
şeffaflık modülü geliştirilmiştir. Bu modül, bir yandan diğer hayvan sahiplerine doğru klinik tercihinde
rehberlik ederken, diğer yandan kliniklerin kendi hizmet kalitelerini ölçebilmesine olanak tanımaktadır.

Değerlendirmelerin güvenilirliğini sağlamak amacıyla üç tasarım kararı alınmıştır. Birincisi, **yorum hakkı
hizmet almış olma şartına bağlanmıştır**: yalnızca ilgili klinikte durumu "tamamlandı" olarak işaretlenmiş
en az bir randevusu bulunan hasta sahibi değerlendirme yapabilmektedir. Bu şart, hekim veya klinik yöneticisi
randevuyu tamamlandı olarak işaretlediğinde doğar ve sahte yorum girişimlerini engeller. İkincisi, bir
kullanıcı bir kliniğe **yalnızca tek bir değerlendirme** yapabilir; bu kural veri tabanı düzeyinde tekil bir
kısıtla güvence altına alınmıştır. Kullanıcı dilediği zaman değerlendirmesini güncelleyebilir veya silebilir.
Üçüncüsü, **değerlendirmeler klinikler tarafından gizlenemez**; yalnızca yorumu yazan kullanıcı kendi yorumunu
kaldırabilir. Böylece kliniklerin olumsuz yorumları saklayarak ortalama puanlarını manipüle etmesinin önüne
geçilmiştir.

Klinik puanı, o kliniğe ait görünür değerlendirmelerin ortalaması olarak anlık hesaplanmakta; hem klinik
listesinde hem de klinik detay sayfasında yıldız gösterimi, ortalama ve değerlendirme sayısıyla birlikte
sunulmaktadır. Klinik detayında ayrıca yıldız dağılımı ve son yorumlar görüntülenebilmekte, tüm yorumlara
ayrı bir ekrandan sayfalı olarak erişilebilmektedir. Yeni bir değerlendirme yapıldığında ilgili klinik
yöneticisine anlık bildirim iletilmektedir.

---

## 1.2.5. Mesajlaşma ve Klinik Duyuruları *(YENİ BAŞLIK)*

**Neden ekleniyor:** Bu iki modül projede gerçeklendi ancak raporda hiç geçmiyor. Rapor 1.1'de
"hekim ile hasta sahibi arasındaki iletişimi dijital ortama taşımak" problemini tanımlıyor; bu başlık
o problemin doğrudan çözümüdür. 1.2.4'ten sonra eklenmelidir.

### Yeni metin

Klinik ile hasta sahibi arasındaki iletişimin telefon trafiğinden ve anlık mesajlaşma uygulamalarından
kurumsal bir zemine taşınması amaçlanmıştır. Bu doğrultuda iki tamamlayıcı modül geliştirilmiştir.

**Hekim–Hasta Sahibi Mesajlaşması:** Hasta sahipleri, muayene öncesi veya sonrasında oluşan soruları için
uygulama içinden doğrudan veteriner hekime yazılı olarak ulaşabilmektedir. Kötüye kullanımı önlemek amacıyla
mesajlaşma yetkisi rastgele değil, **randevu ilişkisine** bağlanmıştır: bir hasta sahibi yalnızca daha önce
randevu aldığı hekimle, bir hekim de yalnızca kendisinden randevu almış hasta sahipleriyle yazışabilmektedir.
Okunmamış mesaj sayısı uygulamanın gezinme çubuğunda bir rozetle gösterilmekte, yeni mesaj geldiğinde alıcıya
anlık bildirim iletilmektedir.

**Klinik Duyuruları:** Klinik yöneticileri, çalışma saatlerindeki değişiklik, tatil dönemleri veya kampanya
gibi bilgileri tek noktadan yayımlayabilmektedir. Bir duyuru oluşturulduğunda, o klinikte randevusu bulunan
tüm hasta sahiplerine otomatik olarak bildirim gönderilmekte; duyuru ayrıca kliniğin detay sayfasında
listelenmektedir. Böylece kliniğin tüm hasta kitlesine ulaşması tek bir işlemle mümkün hâle gelmektedir.

---

## 1.3. Projenin Özgün Değeri

**Neden değişiyor:**
1. Yapay zekâ modülü artık bir *hedef* değil, **çalışan bir bileşen**; dil buna göre güncellendi.
2. **OpenAI → Gemini** düzeltmesi.
3. `Clean Architecture` ifadesi projenin gerçek mimarisini yansıtmıyor. Proje **katmanlı bir mimari**
   (Denetleyici → Servis → Depo → EF Core) kullanıyor; iddia buna göre doğru ama iddiasız biçimde yazıldı.
4. Rapordaki "on binlerce hastayı kaldırabilecek ölçeklenebilirlik" gibi **ölçülmemiş** iddialar,
   savunulabilir ifadelerle değiştirildi (jüride "nasıl ölçtünüz?" sorusuna açık kapı bırakmamak için).
5. Gerçekten ayrıştırıcı olan somut özellikler (aciliyet sınıflandırması, yapılandırılmış çıktı,
   raporun hekim paneline düşmesi, üç rollü yapı) öne çıkarıldı.

### Yeni metin

Bu proje, pazarda var olan ve genellikle tek yönlü hizmet sunan mevcut veteriner uygulamalarından, sunduğu
bütünleşik hizmet modeli ve yenilikçi özellikleri sayesinde açıkça ayrışmaktadır. Piyasadaki çözümlerin büyük
bir çoğunluğu ya kliniklerin kendi iç idari süreçlerine odaklanıp hasta sahibini denklemin dışında bırakmakta
ya da yalnızca hasta sahibine yönelik basit hatırlatıcılar sunmaktadır. Geliştirilen bu platform ise hekim
bazlı randevu seçimi, dinamik aşı takibi, hekim–hasta sahibi mesajlaşması, klinik duyuruları ve yapay zekâ
destekli ön teşhis gibi çok boyutlu servisleri tek bir mimaride birleştirmektedir.

Projenin asıl özgün değeri, entegre edilen **yapay zekâ destekli ön teşhis modülünde** yatmaktadır. Bu modül,
uygulamayı pasif bir kayıt defteri olmaktan çıkarıp aktif bir sağlık asistanına dönüştürmektedir. Evcil hayvan
sahibinin gündelik dille aktardığı belirtilerin (örneğin *"köpeğim üç gündür kusuyor ve iştahsız"*) çok turlu
bir sohbet aracılığıyla derinleştirilmesi ve ardından veteriner hekimlik pratiğine uygun, **yapılandırılmış bir
anamnez raporuna** dönüştürülmesi, hekimin muayeneye hazırlıklı başlamasını sağlamaktadır.

Modülün literatürdeki benzerlerinden ayrıldığı iki nokta bulunmaktadır. Birincisi, çıktının serbest metin
olarak değil; belirti özeti, ayrıntılı anamnez ve **aciliyet seviyesi** alanlarından oluşan makine tarafından
okunabilir bir şema olarak üretilmesidir. Bu sayede acil vakalar arayüzde otomatik olarak vurgulanabilmektedir.
İkincisi, üretilen raporun havada kalmayıp doğrudan **ilgili randevuya bağlanması** ve muayeneden önce hekimin
paneline düşmesidir; yani modül, bir demo işlevi görmenin ötesinde klinik iş akışının içine yerleştirilmiştir.

Tüm bu özellikler yazılım mühendisliği standartlarına uygun olarak tasarlanmıştır. Sunucu tarafında ASP.NET Core
Web API üzerinde, sorumlulukların **Denetleyici (Controller) – Servis – Depo (Repository)** katmanlarına ayrıldığı
bir mimari benimsenmiş; iş mantığı servis katmanında toplanarak veri erişim ayrıntılarından ve dış servislerden
(Firebase, Gemini) yalıtılmıştır. Bu modüler yapı, kodun test edilebilirliğini artırmakta ve yeni özelliklerin
mevcut yapıyı bozmadan eklenmesini mümkün kılmaktadır. Nitekim mesajlaşma, duyuru ve yapay zekâ modülleri,
çekirdek randevu akışına dokunulmadan sisteme dâhil edilebilmiştir.

İstemci tarafında Google'ın Flutter teknolojisi kullanılarak tek kod tabanı üzerinden akıcı ve kullanıcı dostu
bir deneyim sunulmuş; token tabanlı bir tasarım sistemi ile açık ve koyu tema desteği sağlanmıştır. Sistem, üç
farklı kullanıcı rolünü (hasta sahibi, veteriner hekim, klinik yöneticisi) ve her rol için ayrı bir uygulama
akışını desteklemektedir. Veri güvenliği; Firebase Authentication tabanlı kimlik doğrulama, sunucu katmanındaki
yetkilendirme denetimleri, istek sınırlandırma (rate limiting) politikaları ve kullanıcı girdilerinin
temizlenmesi (XSS koruması) ile katmanlı biçimde ele alınmıştır. Bu modern teknolojik altyapı, projeyi sıradan
bir akademik prototipin ötesine taşıyarak sahada kullanılabilir bir ürün adayı hâline getirmektedir.

---

## 3.1.5. Yapay Zekâ Entegrasyonu: Google Gemini API

**Neden değişiyor:** Bölümün tamamı OpenAI'ı anlatıyor; proje **Google Gemini** ile gerçeklendi.
Ayrıca mevcut metin tek cümlelik ve teknik içerikten yoksun; entegrasyonun *nasıl* yapıldığı
(REST, JSON şema zorlaması, rol eşlemesi, hata yönetimi) bir mühendislik tasarımı raporunda yer almalıdır.

> ⚠️ **Başlık adı da değişiyor:** İçindekiler'de `3.1.5. Yapay Zekâ Entegrasyonu: OpenAI API` →
> `3.1.5. Yapay Zekâ Entegrasyonu: Google Gemini API`

### Yeni metin

Ön teşhis modülünün arkasındaki doğal dil işleme (NLP) gücünü sağlamak amacıyla Google'ın büyük dil modeli
servisi **Gemini** tercih edilmiştir. Modellerden, ücretsiz kullanım katmanında yeterli kota sunan ve düşük
gecikmeyle yanıt üreten `gemini-2.5-flash` seçilmiştir.

Entegrasyon, üçüncü parti bir SDK bağımlılığı eklemek yerine doğrudan servisin **REST arayüzü** üzerinden,
.NET'in `HttpClient` altyapısı kullanılarak gerçekleştirilmiştir. Bu tercih; projeye dış bağımlılık eklememesi,
istek gövdesi üzerinde tam denetim sağlaması ve API anahtarının yapılandırma dosyasından yönetilmesine imkân
tanıması nedeniyle yapılmıştır. Yapay zekâ istemcisi, uygulamanın geri kalanından bir arayüz (`IGeminiClient`)
ardında soyutlanmıştır; böylece ileride farklı bir sağlayıcıya geçilmesi hâlinde iş mantığı katmanında değişiklik
gerekmeyecektir.

İstemci iki farklı modda çalışmaktadır:

**Sohbet modu:** Sistem talimatı (hayvanın bilgileri ve asistanın davranış kuralları) ile o ana kadarki tüm
sohbet geçmişi servise iletilerek bir sonraki soru üretilir. Uygulamanın veri tabanında `assistant` olarak
saklanan roller, servisin beklediği `model` rolüne eşlenmektedir.

**Rapor modu:** Sohbet dökümü, çıktının biçimini garanti altına almak amacıyla bir **JSON şeması**
(`responseSchema`) ile birlikte gönderilir. Şema; `reportContent`, `symptomsSummary` ve yalnızca
*low / medium / high / emergency* değerlerini alabilen `urgencyLevel` alanlarını zorunlu kılar. Bu yaklaşım,
modelin serbest metin üretip ardından bunun ayrıştırılmaya çalışılması yerine, doğrudan işlenebilir bir nesne
döndürmesini sağlayarak aciliyet seviyesinin güvenilir biçimde okunmasını mümkün kılmaktadır. Gelen değer yine de
sunucu tarafında bilinen kümeye göre doğrulanmakta, beklenmedik bir değer gelmesi hâlinde güvenli varsayılana
(`medium`) çekilmektedir.

Dış servise bağımlı her çağrıda olduğu gibi hata yönetimi ayrıca ele alınmıştır. Ağ hatası, zaman aşımı, geçersiz
API anahtarı veya kota aşımı (HTTP 429) durumlarında ham hata kullanıcıya yansıtılmamakta; bunun yerine anlaşılır
bir Türkçe mesaj döndürülmekte ve teknik ayrıntı sunucu günlüklerine yazılmaktadır.

---

## 3.1.6. Güvenlik ve Servis Kalitesi Önlemleri *(YENİ BAŞLIK)*

**Neden ekleniyor:** Projede uygulanan güvenlik katmanları (özel kimlik doğrulama işleyicisi, merkezî hata
yönetimi, istek sınırlandırma, girdi temizleme, güvenlik başlıkları) raporda hiç anlatılmıyor; oysa bunlar
4.2.3'te "kanıtlanmıştır" denen iddiaların dayanağıdır. `3.1.5`'ten sonra eklenmelidir.

### Yeni metin

Sistemin güvenliği tek bir noktaya bırakılmamış, birbirini tamamlayan katmanlarla ele alınmıştır.

**Kimlik doğrulama ve yetkilendirme:** Mobil istemci her isteğe Firebase'den aldığı kimlik jetonunu (ID token)
eklemektedir. Sunucu tarafında yazılan özel bir kimlik doğrulama işleyicisi bu jetonu Firebase Admin SDK ile
doğrulamakta; ardından bir ara katman (middleware), jetondaki kimliği yerel veri tabanındaki kullanıcı kaydıyla
eşleştirerek isteğin bağlamına kullanıcı numarasını ve rolünü yerleştirmektedir. Rol denetimleri servis katmanında,
işlemin doğasına uygun biçimde yapılmaktadır: örneğin bir hasta sahibi yalnızca kendi hayvanı için işlem
yapabilmekte, bir hekim ise yalnızca kendisinden randevu almış hayvanların kayıtlarına erişebilmektedir.

**Merkezî hata yönetimi:** Uygulamanın en dış katmanında konumlanan bir ara katman, servislerden fırlatılan
istisnaları anlamlı HTTP durum kodlarına eşlemektedir (yetkisiz erişim → 403, kayıt bulunamadı → 404, geçersiz
istek → 400, beklenmeyen hata → 500). Böylece hata ayrıntıları istemciye sızmadan, tutarlı bir yanıt biçimi
korunmaktadır.

**İstek sınırlandırma (Rate limiting):** Kötüye kullanımı ve maliyet aşımını önlemek amacıyla dört ayrı politika
tanımlanmıştır: tüm uç noktalar için dakikada 60 istek; kayıt/giriş işlemleri için kaba kuvvet saldırılarına karşı
10 dakikada 5 istek; randevu oluşturma için takvim istismarına karşı dakikada 5 istek; yapay zekâ uç noktaları
için servis kotasını korumak amacıyla 5 dakikada 20 istek. Sınır aşıldığında istemciye `Retry-After` başlığıyla
birlikte 429 yanıtı dönülmektedir.

**Girdi temizleme ve HTTP güvenlik başlıkları:** Kullanıcıdan alınan tüm serbest metinler (randevu sebebi, mesaj
gövdesi, aşı notu vb.) veri tabanına yazılmadan önce zararlı HTML etiketlerinden, olay işleyicilerinden ve
tehlikeli protokollerden arındırılmakta; böylece siteler arası betik çalıştırma (XSS) riski azaltılmaktadır.
Ayrıca tüm yanıtlara `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy` gibi güvenlik
başlıkları eklenmekte ve sunucu bilgisini açık eden başlıklar kaldırılmaktadır.

---

## 3.2. Sistem Mimarisi ve Veri Tabanı Tasarımı

**Neden değişiyor:**
1. `Clean Architecture` iddiası projenin gerçek yapısını yansıtmıyor → **katmanlı mimari** olarak doğru anlatıldı.
2. **Kritik hata:** "Randevu çakışmaları **katı veritabanı kısıtlamaları** ile kontrol altına alınmıştır" iddiası
   doğru değil. Projede bu amaçla bir veritabanı kısıtı **yok**; kontrol uygulama katmanındadır (gerekçesiyle
   birlikte aşağıda anlatıldı). Bu, jürinin şemayı açıp doğrulayabileceği türden bir iddia olduğu için düzeltilmesi
   zorunludur.
3. Veri modeli 6 tablodan **15 tabloya** çıktı; yeni varlıklar (bildirim, mesajlaşma, duyuru, yapay zekâ) eklendi.

### Yeni metin

Projenin sürdürülebilir ve genişletilebilir olması adına, sorumlulukların net biçimde ayrıldığı **katmanlı bir
mimari** benimsenmiştir. İstemciden gelen istek sırasıyla şu katmanlardan geçmektedir:

**Denetleyici (Controller)** katmanı yalnızca isteği karşılar, doğrular ve yanıtı biçimlendirir; iş mantığı
içermez. **Servis (Service)** katmanı tüm iş kurallarını, yetkilendirme denetimlerini ve dış servis çağrılarını
(Firebase, Gemini) barındırır. **Depo (Repository)** katmanı veri erişimini soyutlar; genel bir temel depo
sınıfı ile varlığa özgü depolar birlikte kullanılır. En altta ise Entity Framework Core aracılığıyla MySQL
veri tabanına erişilir. Tüm servis ve depolar bağımlılık enjeksiyonu ile yönetilmektedir.

Bu ayrım sayesinde iş mantığı, veri erişim ayrıntılarından ve dış servis istemcilerinden yalıtılmıştır. Nitekim
yapay zekâ istemcisi bir arayüz ardında soyutlandığı için, servis katmanı hangi sağlayıcının kullanıldığını
bilmemektedir. Ayrıca sunucu, zamana bağlı işleri yürüten üç **arka plan servisi** çalıştırmaktadır: randevu
durumlarını güncelleyen, yaklaşan randevuları hatırlatan ve aşı zamanı gelen hayvanların sahiplerini uyaran
servisler (ayrıntı için bkz. 4.2.4).

Veri tabanı tasarımında Varlık-İlişki (ER) prensipleri merkeze alınarak normalizasyon kurallarına uyulmuştur.
Sistem, birbiriyle ilişkili **on beş tablodan** oluşmaktadır. Şemanın kalbinde Kullanıcılar (Users) ve Klinikler
(Clinics) tabloları yer alır. Bir kullanıcı; hasta sahibi, veteriner hekim veya klinik yöneticisi rollerinden
birine sahiptir. Her hasta sahibi birden fazla Hayvan (Animals) kaydına sahip olabilmekte; bu hayvanlar üzerinden
Randevular (Appointments) ve Aşılar (Vaccines) tablolarına ilişkisel bağlar kurulmaktadır. Klinikler tablosu ise
kendi altında birden fazla Veteriner Hekim (Vets) ve bu hekimlere ait Çalışma Takvimleri (VetSchedules)
barındırmaktadır. Bunlara ek olarak Bildirimler (Notifications), Konuşmalar (Conversations), Mesajlar (Messages),
Duyurular (Announcements), Klinik Değerlendirmeleri (ClinicReviews) ve yapay zekâ modülüne ait üç tablo
(AiChatSessions, AiChatMessages, AiReports) şemayı tamamlamaktadır.

Randevu oluşturma işlemi, Hayvan, Veteriner Hekim ve Çalışma Takvimi tablolarının kesişiminde gerçekleşmektedir.
Hekimin uygun saat aralıkları, çalışma takviminde tanımlı gün, başlangıç/bitiş saati ve randevu süresi (varsayılan
30 dakika) bilgilerinden üretilmekte; halihazırda dolu olan saatler bu kümeden çıkarılmaktadır. İptal edilmiş
randevular dolu sayılmadığından, iptal durumunda ilgili saat otomatik olarak yeniden kullanılabilir hâle gelir.

Aynı hekime aynı saat için eşzamanlı gelen taleplerin engellenmesi, **uygulama katmanında** ele alınmıştır. Bunun
nedeni, kullanılan MySQL sürümünün koşullu (filtreli) tekil dizin tanımlamayı desteklememesi ve "yalnızca iptal
edilmemiş randevular için saat benzersiz olsun" kuralının bir veritabanı kısıtıyla ifade edilememesidir. Bu
sebeple çakışma denetimi iki aşamalı olarak kurgulanmıştır: talep önce hekimin takvimine ve müsait saat listesine
karşı doğrulanır; kayıt işleminden hemen önce ise, iki isteğin arasındaki kontrol–kullanım yarışını (TOCTOU)
kapatmak amacıyla aynı hekim ve saat için aktif bir randevu oluşup oluşmadığı son kez sınanır. Çakışma tespit
edilmesi hâlinde işlem iptal edilerek kullanıcıya saatin az önce dolduğunu bildiren açıklayıcı bir hata mesajı
döndürülür.

---

## 4.1.3. Akıllı Randevu Akışı

**Neden değişiyor:** Akış artık **beş adımlı**; araya isteğe bağlı "Ön Muayene" adımı girdi ve randevu
durumları bir **durum makinesiyle** yönetiliyor. Mevcut metin üç adımlı eski akışı anlatıyor.

### Yeni metin

Kullanıcı bir kliniği seçtikten sonra randevu oluşturma süreci, ilerleme göstergesiyle desteklenen beş adımlı
bir akış hâlinde yürütülmektedir.

İlk adımda kullanıcı, seçtiği klinikte görev yapan veteriner hekimleri uzmanlık alanlarıyla birlikte
görüntüleyerek tercihini yapar. İkinci adımda, seçilen hekimin veri tabanındaki çalışma takvimine göre üretilen
ve halihazırda dolu olmayan tarih–saat aralıkları listelenir; dolu saatler pasif olarak gösterilir. Üçüncü adımda
hasta sahibi, randevunun hangi evcil hayvanı için alındığını seçer ve dilerse şikâyetini serbest metin olarak
girer.

Dördüncü adım, **isteğe bağlı yapay zekâ ön muayenesidir.** Kullanıcı bu adımda ön muayeneyi başlatarak asistanla
sohbet edebilir; sohbet sonunda üretilen ön rapor bu adıma bir özet kartı ve renk kodlu aciliyet rozeti olarak
döner ve belirti özeti otomatik olarak randevu sebebi alanına aktarılır. Ön muayene yapmak istemeyen kullanıcılar
bu adımı doğrudan geçebilir. Son adımda tüm bilgiler bir özet ekranında gösterilir ve randevu onaylanır; ön rapor
oluşturulmuşsa kayıt tamamlandıktan sonra ilgili randevuya bağlanır.

Oluşturulan randevular, geçişleri tek bir noktadan denetlenen bir **durum makinesi** ile yönetilmektedir. Randevu
`beklemede` durumunda oluşur; hekim veya klinik yöneticisi tarafından `onaylandı` ya da `iptal edildi` durumuna
alınabilir. Onaylanmış bir randevu ise `tamamlandı`, `gelinmedi` veya `iptal edildi` durumlarına geçebilir. Bu
dört durum sonlanmış kabul edilir ve üzerlerinden yeni bir geçiş yapılamaz. Tarihi geçtiği hâlde işleme
alınmamış randevular ise arka plan servisi tarafından `süresi doldu` durumuna çekilir. Geçerli geçişlerin tek bir
kural kümesinde toplanması, aynı iş kuralının hekim ve klinik yöneticisi uçlarında tutarlı biçimde uygulanmasını
güvence altına almaktadır.

---

## 4.1.5. Yapay Zekâ Ön Teşhis Modülü

**Neden değişiyor:** Mevcut metin "arayüz prototipleri tasarlanmıştır… kodlama ve test süreçleri devam
etmektedir" diyor. Modül **tamamlandı ve uçtan uca çalışıyor.** Bu, raporun en kritik güncellemesidir.

### Yeni metin

Uygulamanın en yenilikçi bölümü olan yapay zekâ ön teşhis modülü, tasarımdan uçtan uca çalışan bir bileşene
dönüştürülmüştür. Modüle, randevu alma akışının dördüncü adımından erişilmektedir.

Kullanıcı ön muayeneyi başlattığında, öncelikle asistanın teşhis koymadığını ve veteriner hekim muayenesinin
yerine geçmediğini belirten bir bilgilendirme onayı gösterilir. Onayın ardından tam ekran bir sohbet arayüzü
açılır. Asistanın açılış mesajı, servis kotasını gereksiz yere tüketmemek amacıyla yapay zekâya
başvurulmadan üretilir. Kullanıcı yanıt yazdıkça istekler sunucuya iletilir; yanıt beklenirken arayüzde bir
"yazıyor" göstergesi sunularak kullanıcıya geri bildirim verilir.

Yeterli bilgi toplandığında kullanıcı "Ön Raporu Hazırla" işlemini tetikler. Sunucu, sohbet dökümünü yapay zekâ
servisine ileterek yapılandırılmış raporu üretir, veri tabanına kaydeder ve oturumu tamamlanmış olarak işaretler.
Aynı oturum için işlemin tekrarlanması hâlinde yeni bir çağrı yapılmaz; mevcut rapor döndürülerek hem kota hem
tutarlılık korunur.

Üretilen rapor kullanıcıya aciliyet rozeti, belirti özeti ve ayrıntılı anamnez metni olarak sunulur. Randevu
onaylandıktan sonra rapor ilgili randevuyla ilişkilendirilir. Bu noktadan itibaren rapora iki taraf da
erişebilmektedir: hasta sahibi kendi randevu detay ekranından, **ilgili veteriner hekim ise randevu listesindeki
kart üzerinden.** Erişim yetkisi sunucu tarafında denetlenmekte; raporu yalnızca randevunun sahibi ile randevunun
atandığı hekim görüntüleyebilmektedir.

---

## 4.1.6. Mesajlaşma ve Bildirim Merkezi *(YENİ BAŞLIK)*

**Neden ekleniyor:** Gerçeklendi ancak raporda yok. `4.1.5`'ten sonra eklenmelidir.

### Yeni metin

Hasta sahipleri ve veteriner hekimler, uygulamanın gezinme çubuğundaki Mesajlar sekmesi üzerinden yazışabilmektedir.
Ekranda kullanıcının yazışabileceği kişiler (aralarında randevu ilişkisi bulunanlar) listelenmekte, her konuşma için
son mesaj önizlemesi ve okunmamış mesaj sayısı gösterilmektedir. Konuşma ekranı açıldığında karşı tarafın gönderdiği
mesajlar otomatik olarak okundu işaretlenir.

Bildirim merkezinde ise kullanıcıya iletilen tüm bildirimler türlerine göre ayırt edici ikonlarla listelenmektedir:
randevu oluşturma, randevu durumu değişikliği, randevu hatırlatması, aşı hatırlatması, yeni mesaj ve klinik duyurusu.
Okunmamış bildirimler görsel olarak vurgulanmakta ve toplu biçimde okundu işaretlenebilmektedir. Bildirimler yalnızca
uygulama içinde tutulmamakta, Firebase Cloud Messaging aracılığıyla cihaza anlık bildirim olarak da iletilmektedir;
kullanıcı bildirime dokunduğunda uygulamanın ilgili ekranına yönlendirilir.

---

## 4.1.7. Veteriner Hekim ve Klinik Yöneticisi Panelleri *(YENİ BAŞLIK)*

**Neden ekleniyor:** Sistem üç rollü; rapor yalnızca hasta sahibi arayüzünü anlatıyor. `4.1.6`'dan sonra eklenmelidir.

### Yeni metin

Uygulama, kullanıcının rolüne göre farklı bir ana ekrana yönlendirme yapmaktadır.

**Veteriner hekim paneli**, hekimin günlük iş akışına odaklanmıştır. Randevular ekranı; bugünkü, yaklaşan ve geçmiş
randevuları ayrı sekmelerde sunar. Hekim, bir randevuyu onaylayabilir, tamamlandı ya da gelinmedi olarak
işaretleyebilir ve muayene notu ekleyebilir; izin verilen geçişler durum makinesi tarafından belirlendiğinden
arayüzde yalnızca geçerli eylemler gösterilir. Hekim ayrıca randevu kartı üzerinden hayvanın aşı geçmişine ve varsa
yapay zekâ ön raporuna erişebilir, kendi çalışma takvimini ve profil bilgilerini düzenleyebilir.

**Klinik yöneticisi paneli**, kliniğin kurumsal yönetimine ayrılmıştır. Yönetici; kliniğin profil bilgilerini
güncelleyebilir, bünyesindeki hekimleri görüntüleyebilir, kliniğe gelen randevuların durumunu değiştirebilir ve
kliniğin tüm hasta kitlesine ulaşan duyurular yayımlayabilir.

---

## 4.2.2. Randevu Çakışma Kontrolü

**Neden değişiyor:** ⚠️ Mevcut metin **gerçeğe aykırı**. "İşlem (transaction) kilitleri ve veritabanı kısıtlamaları"
kullanıldığı yazıyor; projede bunların **hiçbiri yok**. Jüri kaynak kodu veya şemayı incelerse doğrulanamaz.
Aşağıdaki metin, uygulanan gerçek mekanizmayı ve bu tasarım tercihinin **gerekçesini** anlatmaktadır — ki bu,
yanlış iddiadan hem daha dürüst hem de mühendislik açısından daha güçlüdür.

### Yeni metin

Aynı hekime aynı saat dilimi için eşzamanlı gelen randevu talepleri, sunucu tarafında iki aşamalı bir denetimle
engellenmektedir.

Birinci aşamada gelen talep, hekimin çalışma takviminden üretilen müsait saat kümesine karşı doğrulanır; takvim
dışında veya halihazırda dolu bir saat için gelen istek reddedilir. İkinci aşamada, veri tabanına yazma işleminden
hemen önce aynı hekim ve saat için aktif bir randevu oluşup oluşmadığı son kez sınanır. Bu ikinci denetim,
doğrulama anı ile kayıt anı arasında başka bir isteğin araya girmesiyle oluşabilecek kontrol–kullanım yarışını
(TOCTOU) kapatmayı amaçlamaktadır. Çakışma tespit edildiğinde işlem sonlandırılmakta ve kullanıcıya saatin az önce
başka bir randevu tarafından alındığını bildiren açıklayıcı bir hata mesajı anında döndürülmektedir.

Bu kuralın bir veritabanı kısıtı yerine uygulama katmanında gerçeklenmesi bilinçli bir tasarım tercihidir. Aranan
kural "yalnızca iptal edilmemiş randevular için hekim–saat ikilisi benzersiz olsun" biçiminde koşulludur; ancak
kullanılan MySQL sürümü koşullu (filtreli) tekil dizin tanımlamayı desteklememektedir. Kısıtın koşulsuz biçimde
tanımlanması, iptal edilmiş bir randevunun saatinin yeniden kullanılmasını engelleyeceğinden iş kuralına aykırı
düşecektir. Ayrıca bu tasarım, iptal edilen randevunun saatinin herhangi bir ek işleme gerek kalmadan otomatik
olarak yeniden müsait hâle gelmesini sağlamaktadır.

---

## 4.2.3. Veri Bütünlüğü ve Güvenlik

**Neden değişiyor:** Mevcut metin doğru ama eksik; projede uygulanan istek sınırlandırma, girdi temizleme ve
merkezî hata yönetimi bu bölümde somutlaştırılmalıdır.

### Yeni metin

Firebase üzerinden alınan kimlik jetonlarının her API isteğinde doğrulanması test edilmiş; jeton taşımayan veya
geçersiz jeton taşıyan isteklerin sunucu katmanında 401 (Unauthorized) koduyla reddedildiği doğrulanmıştır. Kimliği
doğrulanmış ancak yetkisi olmayan isteklerin (örneğin bir kullanıcının başkasına ait hayvanın kaydına erişme
girişimi) 403 (Forbidden) koduyla engellendiği ayrıca sınanmıştır.

İlişkisel veri tabanındaki yabancı anahtar mimarisi sayesinde yetim (orphan) veri oluşumunun önüne geçilmiştir.
Silme davranışları varlığın doğasına göre belirlenmiştir: bir konuşma silindiğinde mesajları da silinirken, geçmiş
kayıtların korunması gereken ilişkilerde silme kısıtlanmış; randevusu silinen bir yapay zekâ raporunun ise raporu
kaybetmeden yalnızca randevu bağının kopması sağlanmıştır.

Kötüye kullanıma karşı, uç noktalara istek sınırlandırma politikaları uygulanmıştır. Kayıt ve giriş uçlarında kaba
kuvvet denemelerinin, randevu oluşturma ucunda takvim istismarının ve yapay zekâ uçlarında servis kotasının
tüketilmesinin, sınır aşıldığında dönen 429 yanıtıyla engellendiği doğrulanmıştır. Ayrıca kullanıcıdan alınan tüm
serbest metinler veri tabanına yazılmadan önce zararlı içerikten arındırılmakta ve sunucudan dönen hata yanıtları
merkezî bir ara katman tarafından biçimlendirilerek iç hata ayrıntılarının istemciye sızması önlenmektedir.

---

## 4.2.4. Arka Plan Görevleri ve Zamanlanmış İşler *(YENİ BAŞLIK)*

**Neden ekleniyor:** Üç arka plan servisi gerçeklendi; rapor bunlardan hiç söz etmiyor. Oysa 1.2.1 ve 1.2.2'de
vaat edilen "otomatik hatırlatma" işlevini fiilen bu servisler yerine getirmektedir. `4.2.3`'ten sonra eklenmelidir.

### Yeni metin

Kullanıcı etkileşimi gerektirmeyen, zamana bağlı işlerin yürütülmesi için sunucu üzerinde üç arka plan servisi
çalıştırılmaktadır.

**Randevu durumu güncelleme servisi**, on beş dakikada bir çalışarak tarihi geçtiği hâlde hâlâ beklemede olan
randevuları `süresi doldu` durumuna çeker. Böylece hekim panelindeki listeler gerçek durumu yansıtır.

**Randevu hatırlatma servisi**, otuz dakikada bir çalışarak önümüzdeki yirmi dört saat içinde randevusu bulunan
hasta sahiplerine bir kez hatırlatma bildirimi gönderir.

**Aşı hatırlatma servisi**, on iki saatte bir çalışarak sonraki aşı tarihi üç gün içinde olan hayvanların
sahiplerine bildirim iletir; böylece koruyucu hekimlik süreçleri desteklenir.

Her iki hatırlatma servisi de ilgili kayıt üzerinde bir "gönderildi" işareti tutmaktadır. Bu sayede servis her
tetiklendiğinde aynı kullanıcıya tekrar bildirim gönderilmesi önlenmekte ve işlemin tekrarlanabilirliği (idempotency)
sağlanmaktadır.

---

## 4.2.5. Yapay Zekâ Servisinin Güvenilirliği ve Maliyet Yönetimi *(YENİ BAŞLIK)*

**Neden ekleniyor:** Dış bir yapay zekâ servisine bağımlılık, raporun tartışması gereken mühendislik
kısıtlarını (kota, gecikme, hata, biçim güvenilirliği) beraberinde getirir. `4.2.4`'ten sonra eklenmelidir.

### Yeni metin

Dış bir yapay zekâ servisine bağımlılık, sistemin tasarımında ayrıca ele alınması gereken kısıtlar doğurmuştur.

**Biçim güvenilirliği:** Büyük dil modellerinin serbest metin üretme eğilimi, çıktının program tarafından
ayrıştırılmasını kırılgan kılmaktadır. Bu risk, rapor üretiminde servise bir JSON şeması dayatılarak ortadan
kaldırılmıştır. Buna rağmen dönen aciliyet değeri sunucu tarafında bilinen kümeye karşı yeniden doğrulanmakta,
beklenmedik bir değer alınması hâlinde güvenli varsayılana çekilmektedir.

**Kota ve maliyet:** Kullanılan ücretsiz katmanın günlük ve dakikalık istek sınırları bulunmaktadır. Bu nedenle
yapay zekâ uçlarına ayrı bir istek sınırlandırma politikası uygulanmış; sohbetin açılış mesajı yapay zekâya
başvurulmadan üretilmiş; tamamlanmış bir oturum için rapor yeniden istendiğinde yeni bir servis çağrısı yapılmayıp
kayıtlı rapor döndürülmüştür. Bu üç önlem birlikte, kullanıcı başına düşen çağrı sayısını gözle görülür biçimde
azaltmaktadır.

**Hata ve gecikme yönetimi:** Ağ hatası, zaman aşımı ve kota aşımı senaryolarında ham hata istemciye
yansıtılmamakta; kullanıcıya anlaşılır bir mesaj gösterilirken teknik ayrıntı sunucu günlüklerine yazılmaktadır.
Yanıt beklenirken arayüzde bir yükleniyor göstergesi sunulduğundan, servisin doğası gereği saniyeler sürebilen
yanıt süresi kullanıcı deneyimini bozmamaktadır.

**Gizlilik:** Sohbet içeriğinin üçüncü taraf bir servise iletildiği göz önünde bulundurulmalıdır. Sisteme, hayvanın
sağlık durumu dışında kişisel veri gönderilmemekte; kullanıcı, sohbet başlamadan önce modülün niteliği hakkında
bilgilendirilmektedir.

---

## 5.1. Sonuçlar

**Neden değişiyor:** Mevcut metin yapay zekâ modülünü "arayüz ve mimari tasarımları tamamlanmış, ilerleyen
fazlarda entegre edilecek" diye anlatıyor — modül **tamamlandı**. Ayrıca "Clean Architecture" ve ölçülmemiş
ölçeklenebilirlik iddiaları düzeltildi; gerçekleştirilen ancak sayılmayan modüller eklendi.

### Yeni metin

Bu proje kapsamında, geleneksel yöntemlerle yürütülen veteriner hekimliği klinik süreçlerini modern, dijital ve
akıllı bir ekosisteme dönüştürmeyi hedefleyen "Yapay Zekâ Destekli Veteriner Klinik Mobil Uygulaması" başarıyla
geliştirilmiştir. Proje sonucunda elde edilen temel kazanımlar şunlardır:

Kliniklerin randevu ve hasta kayıt süreçleri dijitalleştirilmiş; hekim bazlı randevu seçimi, çalışma takviminden
üretilen müsaitlik denetimi ve altı durumlu bir randevu yaşam döngüsü ile idari iş yükü azaltılmıştır.

Hasta sahibi ile hekim arasındaki iletişim; uygulama içi mesajlaşma, klinik duyuruları ve anlık bildirimlerle
çift yönlü hâle getirilmiştir. Randevu ve aşı hatırlatmaları, sunucu üzerinde çalışan arka plan servisleriyle
otomatikleştirilerek koruyucu hekimlik süreçleri desteklenmiştir.

Kliniklerin hizmet kalitesinin şeffaf biçimde ölçülebilmesi amacıyla, literatürde etkisi ortaya konan E-WOM
(Elektronik Ağızdan Ağıza Pazarlama) döngüsü [2] uygulamaya taşınmıştır. Değerlendirme hakkı, sahte yorumları
engellemek amacıyla **yalnızca ilgili klinikte tamamlanmış bir randevusu bulunan hasta sahiplerine**
tanınmış; her kullanıcının klinik başına yalnızca bir değerlendirme yapabilmesi veri tabanı düzeyinde tekil
bir kısıtla güvence altına alınmıştır. Değerlendirmeler kimse tarafından gizlenemez; yalnızca yorum sahibi
kendi yorumunu düzenleyebilir veya silebilir. Böylece kliniklerin puanlarını manipüle etmesi engellenmiştir.

**Projenin özgün değerini oluşturan yapay zekâ destekli ön teşhis modülü tasarım aşamasından çıkarılarak uçtan
uca çalışır hâle getirilmiş ve klinik iş akışının içine yerleştirilmiştir.** Modül, hasta sahibiyle çok turlu bir
sohbet yürüterek topladığı bilgiyi; belirti özeti, ayrıntılı anamnez ve aciliyet seviyesinden oluşan yapılandırılmış
bir rapora dönüştürmekte ve bu raporu ilgili randevuya bağlayarak muayeneden önce hekimin erişimine sunmaktadır.
Böylece hekimin anamnez alma süresini kısaltmayı hedefleyen bir karar destek sisteminin (DSS) temelleri
atılmıştır.

Sistem üç farklı kullanıcı rolünü (hasta sahibi, veteriner hekim, klinik yöneticisi) ve her rol için ayrı bir
uygulama akışını desteklemektedir. Flutter ile platform bağımsız, açık/koyu tema destekli akıcı bir arayüz
sunulurken; ASP.NET Core Web API üzerinde katmanlı mimari, kimlik doğrulama, yetkilendirme, istek sınırlandırma
ve girdi temizleme önlemleriyle veri güvenliği katmanlı biçimde sağlanmıştır.

Geliştirilen bu sistem, evcil hayvan sahipleri için yalnızca bir ajanda veya e-ticaret platformu olmaktan çıkıp
kapsamlı bir sağlık asistanına dönüşmüştür.

---

## 5.2. Öneriler

**Neden değişiyor:** ⚠️ Mevcut listedeki **"Yapay Zekâ Entegrasyonunun Tamamlanması"** maddesi artık geçersiz —
o iş bitti. **"Klinik Değerlendirme ve E-WOM Modülü"** maddesi de geçersiz — o da tamamlandı (bkz. 1.2.4, 5.1).
Yerine, projenin bugünkü durumundan doğan gerçek bir yol haritası konmalıdır.

### Yeni metin

Projenin çekirdek işlevleri tamamlanmış olup, sistemin daha da geliştirilmesi için aşağıdaki adımlar
planlanmaktadır:

**Yapay Zekâ Modülünün Alan Bilgisiyle Zenginleştirilmesi:** Mevcut modül, genel amaçlı bir dil modelinin veteriner
hekimlik bağlamına yönlendirilmesiyle çalışmaktadır. Bir sonraki aşamada, güvenilir veteriner kaynaklarından
oluşturulacak bir bilgi tabanının **RAG (Retrieval-Augmented Generation)** yöntemiyle modele bağlanması
hedeflenmektedir. Böylece asistanın soruları, ilgili türe ve belirti örüntüsüne özgü klinik kaynaklardan beslenerek
daha isabetli hâle getirilecektir.

**Çok Modlu Girdi Desteği:** Modülün yalnızca serbest metin üzerinden değil; sisteme yüklenecek tahlil sonuçları
(PDF), yara/deri lezyonu fotoğrafları veya röntgen görüntüleri üzerinden de ön analiz yapabilecek seviyeye
çıkarılması amaçlanmaktadır.

**Modülün Klinik Doğrulaması:** Ön raporun ürettiği aciliyet sınıflandırmasının, gerçek vakalar üzerinde veteriner
hekimlerin değerlendirmesiyle karşılaştırılarak ölçülmesi ve modülün duyarlılık/özgüllük başarımının raporlanması
planlanmaktadır. Bu, modülün akademik olarak savunulabilir bir karar destek aracına dönüşmesi için gereklidir.

**Topluluk (Community) Forumu:** Evcil hayvan sahiplerinin deneyimlerini paylaşabileceği, moderasyonlu bir uygulama
içi sosyal ağ modülünün geliştirilmesi.

**Ölçeklenebilirlik ve Başarım Ölçümü:** Sistemin eşzamanlı kullanıcı yükü altındaki davranışının yük testleriyle
ölçülmesi; veri tabanı sorgu başarımının ve yapay zekâ servisi yanıt sürelerinin izlenerek gerekli iyileştirmelerin
yapılması.

---

## KAYNAKLAR

**Neden değişiyor:** OpenAI yerine **Gemini** kullanıldığı için ilgili kaynak eklenmeli. Ayrıca mevcut listede
[5]'in ziyaret tarihi 2024, diğerlerininki 2026 — tutarsız. Aşağıda yalnızca **eklenecek/düzeltilecek** maddeler
verilmiştir; [1]–[4] aynen korunur.

### Eklenecek kaynak

```
[10] Google, 2026, Gemini API Documentation [online],
     https://ai.google.dev/gemini-api/docs [Ziyaret Tarihi: 6 Temmuz 2026].
```

> Metinde atıf: 3.1.5 bölümünde "…Google'ın büyük dil modeli servisi **Gemini** [10] tercih edilmiştir." biçiminde
> kullanılmalıdır. (Rapordaki kontrol listesi "kaynaklarda verilen her yayına atıfta bulunuldu mu?" diye
> sorduğundan, atıfsız kaynak bırakılmamalıdır.)

### Düzeltilecek madde

```
[5] Google, 2026, Flutter Documentation [online], https://docs.flutter.dev/
    [Ziyaret Tarihi: 8 Haziran 2026].
```
*(Yalnızca ziyaret tarihi 2024 → 2026 olarak diğerleriyle tutarlı hâle getirildi.)*

---

## EKLER

**Neden değişiyor:** Mevcut EKLER bölümünde yalnızca imzalı kontrol listesi var. Bir mühendislik tasarımı
raporunda, gövdede anlatılan mimari ve arayüzlerin görsel olarak belgelenmesi beklenir. Aşağıdakiler
**EK-2'den itibaren** eklenmelidir.

### Eklenecek ekler

**EK-2 — Sistem Mimarisi Şeması:** Mobil istemci → REST API → Servis/Depo katmanları → MySQL akışını; Firebase
(kimlik doğrulama + bildirim) ve Google Gemini dış servislerini ve üç arka plan servisini gösteren blok diyagram.

**EK-3 — Varlık-İlişki (ER) Diyagramı:** On beş tabloyu ve aralarındaki ilişkileri gösteren güncel şema.
(3.2'de anlatılan yapının görsel karşılığı; jürinin en çok bakacağı ektir.)

**EK-4 — Uygulama Ekran Görüntüleri:** Aşağıdaki akışların yakalanması önerilir:
- Klinik listesi ve klinik detayı (puan gösterimi + duyurular)
- Beş adımlı randevu akışı (özellikle **Ön Muayene** adımı)
- Yapay zekâ sohbet ekranı ve üretilen ön rapor (**aciliyet rozeti görünür olacak şekilde**)
- Hekim panelinde randevu kartından ön rapora erişim
- Mesajlaşma ekranı ve bildirim merkezi
- Açık ve koyu tema karşılaştırması

**EK-5 — Örnek Ön Muayene Çıktısı:** Gerçek bir sohbet dökümü ve karşılığında üretilen yapılandırılmış rapor
(belirti özeti, anamnez, aciliyet seviyesi). Acil bir senaryonun (örn. kanamalı kusma) `emergency` olarak
sınıflandırıldığı örnek, modülün işlevselliğini somut biçimde kanıtlar.

---

## ÖZET

**Neden değişiyor:** OpenAI→Gemini; gelecek zaman → geçmiş zaman (proje tamamlandı); raporda geçmeyen modüller
(mesajlaşma, duyuru, bildirim) eklendi; klinik değerlendirme sistemi tamamlandığı için özellik listesinde
kaldı; sayfa sayısı güncellenmelidir.

> 📌 `2026, 18 Sayfa` satırındaki sayfa sayısını, güncellenmiş raporun son hâline göre düzelt.

### Yeni metin

Bu proje, veteriner kliniklerinin hasta yönetim süreçlerini dijitalleştirerek evcil hayvan sahipleri ve klinikler
arasındaki iletişimi güçlendiren yapay zekâ destekli bir mobil uygulama geliştirmeyi amaçlamıştır. Mevcut veteriner
kliniklerinde randevu alma, hasta takibi ve klinik iş akışı yönetimi büyük ölçüde manuel yürütülmekte; bu durum hem
hasta sahipleri hem de klinik personeli için zaman kaybına ve verimsizliğe yol açmaktadır.

Geliştirilen uygulama; hekim bazlı mobil randevu alma, aşı takibi ve otomatik hatırlatma bildirimleri, hekim ile
hasta sahibi arasında uygulama içi mesajlaşma, klinik duyuruları, klinik değerlendirme ve yorum sistemi ile
yapay zekâ destekli ön teşhis modülü gibi işlevleri bir arada sunmaktadır. Değerlendirme sistemi, yalnızca
ilgili klinikte tamamlanmış randevusu bulunan hasta sahiplerine yorum hakkı tanıyarak güvenilir bir E-WOM
döngüsü kurmaktadır. Ön teşhis modülünde hasta sahibi, kliniğe gelmeden önce yapay zekâ asistanıyla çok
turlu bir sohbet yürütmekte; asistan topladığı bilgiyi belirti özeti, ayrıntılı anamnez metni ve aciliyet seviyesinden
oluşan yapılandırılmış bir ön rapora dönüştürmektedir. Bu rapor, oluşturulan randevuya bağlanarak muayeneden önce
veteriner hekimin erişimine sunulmakta; hekimin vakayı önceden değerlendirmesine ve muayene süresinin kısalmasına
katkı sağlamaktadır. Sistem ayrıca hasta sahibi, veteriner hekim ve klinik yöneticisi olmak üzere üç kullanıcı
rolünü ve her rol için ayrı bir uygulama akışını desteklemektedir.

Uygulama Flutter ile geliştirilmiş olup iOS ve Android platformlarında çalışmaktadır. Sunucu tarafında C# ve .NET
(ASP.NET Core Web API) ile MySQL kullanılmış; kimlik doğrulama için Firebase Authentication, bildirim sistemi için
Firebase Cloud Messaging ve yapay zekâ hizmetleri için Google Gemini API entegre edilmiştir. Proje sonunda;
kliniklerin dijital dönüşümüne katkı sağlayan, hasta memnuniyetini artıran ve veteriner hekimlerin iş yükünü azaltan
işlevsel bir mobil uygulama geliştirilmiştir.

**Anahtar Kelimeler:** Mobil Uygulama, Veteriner Klinik Yönetimi, Yapay Zekâ Destekli Ön Teşhis, Büyük Dil Modeli,
Süreç Takibi

---

## ABSTRACT

**Neden değişiyor:** ÖZET ile birebir tutarlı olmalıdır (OpenAI→Gemini, gelecek→geçmiş zaman, yeni modüller).

> 📌 `2026, 18 Pages` satırındaki sayfa sayısını da güncelle.

### Yeni metin

This project aimed to develop an artificial intelligence-supported mobile application that digitizes the patient
management processes of veterinary clinics and strengthens communication between pet owners and clinics. In existing
veterinary clinics, appointment booking, patient tracking, and clinic workflow management are largely carried out
manually, which leads to time loss and inefficiency for both pet owners and clinic staff.

The developed application combines physician-based mobile appointment booking, vaccination tracking with automatic
reminder notifications, in-app messaging between veterinarians and pet owners, clinic announcements, a clinic
rating and review system, and an AI-supported pre-diagnosis module. The review system establishes a trustworthy
electronic word-of-mouth (E-WOM) cycle by granting review rights only to pet owners who have a completed
appointment at the given clinic. In the pre-diagnosis module, the pet owner conducts a multi-turn conversation with
an AI assistant before visiting the clinic; the assistant converts the collected information into a structured
preliminary report consisting of a symptom summary, a detailed anamnesis, and an urgency level. This report is linked
to the created appointment and made available to the veterinarian prior to the examination, enabling the physician to
assess the case in advance and helping to shorten examination times. The system also supports three user roles — pet
owner, veterinarian, and clinic administrator — each with a dedicated application flow.

The application was developed with Flutter and runs on both iOS and Android platforms. On the server side, C# and
.NET (ASP.NET Core Web API) with MySQL were used; Firebase Authentication was integrated for identity verification,
Firebase Cloud Messaging for the notification system, and the Google Gemini API for artificial intelligence services.
As a result, a functional mobile application was delivered that contributes to the digital transformation of clinics,
increases patient satisfaction, and reduces the workload of veterinarians.

**Keywords:** AI-Supported Pre-Diagnosis, Large Language Model, Mobile Application, Process Tracking, Veterinary
Clinic Management.

---

## Ek Notlar — Word'de yaparken dikkat

1. **İçindekiler (TOC):** Yeni başlıklar eklendiği için Word'de TOC'u güncellemeyi unutma
   (TOC'a sağ tık → *Alanı Güncelle* → *Tüm tabloyu güncelle*). Eklenen başlıklar:
   `1.2.5`, `3.1.6`, `4.1.6`, `4.1.7`, `4.2.4`, `4.2.5` ve `EK-2`…`EK-5`.
2. **Değişen başlık adı:** `3.1.5. Yapay Zekâ Entegrasyonu: OpenAI API` →
   `3.1.5. Yapay Zekâ Entegrasyonu: Google Gemini API`
3. **"OpenAI" kelime taraması:** Word'de `Ctrl+H` ile *OpenAI* araması yapıp hiç kalmadığından emin ol.
   Geçtiği yerler: ÖZET, ABSTRACT, 1.2.3, 3.1.5, 3.2, 4.1.5, 5.2.
4. **Sayfa sayısı:** ÖZET ve ABSTRACT sayfalarındaki `18 Sayfa` / `18 Pages` değerlerini güncelle.
5. **"hekimi puanlayıp" ifadesi:** `1.2.4`'te geçen *"kliniği **ve hekimi** puanlayıp"* düzeltildi —
   sistemde yalnızca **klinik** puanlanmaktadır. Word'de bu ifadenin başka yerde kalmadığından emin ol.
6. **5.2'den çıkarılan iki madde:** "Yapay Zekâ Entegrasyonunun Tamamlanması" ve "Klinik Değerlendirme ve
   E-WOM Modülü" — her ikisi de tamamlandığı için Öneriler'den silinip 5.1'e kazanım olarak taşındı.
   Word'deki eski 5.2 listesinde bunları **silmeyi unutma**.