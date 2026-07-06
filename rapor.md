# MÜHENDİSLİK TASARIMI DERSİ ARA SINAV RAPOR FORMU

## A. GENEL BİLGİLER

| Alan | Bilgi |
| :--- | :--- |
| **Proje Adı** | Yapay Zekâ Destekli Veteriner Klinik Mobil Uygulaması |
| **Öğrenci Adı Soyadı** | Ensar Gökhan |
| **Öğrenci Numarası** | 203311019 |
| **Danışman / Öğretim Elemanı** | Doç.Dr. İlker Ali ÖZKAN |

## B. PROJE ÖZETİ
Bu proje, veteriner kliniklerinin hasta yönetim süreçlerini dijitalleştirerek evcil hayvan sahipleri ve klinikler arasındaki iletişimi güçlendirmeyi hedefleyen yapay zekâ destekli bir mobil uygulama geliştirmeyi amaçlamaktadır. Mevcut veteriner kliniklerinde randevu alma, hasta takibi ve klinik iş akışı yönetimi büyük ölçüde manuel yürütülmektedir. Bu durum hem hasta sahipleri hem de klinik personeli için zaman kaybına ve verimsizliğe yol açmaktadır.

Uygulama, mobil randevu alma, hekim bazlı randevu seçimi, aşı takibi ve hatırlatma bildirimleri, klinik değerlendirme/yorum sistemi ile yapay zekâ destekli ön teşhis modülleri gibi temel özellikler sunacaktır. Ön teşhis modülünde hasta sahipleri, kliniğe gelmeden önce eliminasyon mantığına dayalı soruları yanıtlayarak yapay zekâ tarafından oluşturulan bir ön teşhis raporu alacaktır. Bu rapor veteriner hekime hastayı değerlendirme sürecinde önemli bir alt yapı sunacak ve muayene sürelerini kısaltacaktır.

Uygulama Flutter ile geliştirilecek olup iOS ve Android platformlarında çalışacaktır. Sunucu tarafında C# ve .NET (ASP.NET Core Web API) ile MySQL kullanılacak; bildirim sistemi için Firebase Cloud Messaging, kimlik doğrulama için Firebase Authentication ve yapay zekâ hizmetleri için OpenAI API entegre edilecektir. Proje sonunda; kliniklerin dijital dönüşümüne katkı sağlayan, hasta memnuniyetini artıran ve veteriner hekimlerin iş yükünü azaltan işlevsel bir mobil uygulama teslim edilmesi hedeflenmektedir.

## C. ANAHTAR KELİMELER
Mobil Uygulama, Veteriner Klinik Yönetimi, Yapay Zekâ Destekli Ön Teşhis, Süreç Takibi

## D. ÖZGÜN DEĞER
Bu proje, mevcut veteriner randevu ve hasta takip uygulamalarından birkaç temel özellikte ayrılmaktadır. Piyasadaki mevcut çözümlerin büyük çoğunluğu yalnızca randevu almaya odaklanırken; bu uygulama yapay zekâ destekli ön teşhis, hekim bazlı randevu seçimi, aşı takibi ve klinik değerlendirme gibi birden fazla katma değerli hizmeti tek bir platformda bir araya getirmektedir.

Özellikle yapay zekâ destekli ön teşhis modülü, Türkiye’deki veteriner klinik uygulamaları arasında nadir rastlanan bir yeniliktir. Hasta sahibinin kliniğe gelmeden önce hayvanının belirtilerini sisteme girmesi ve otomatik oluşturulan raporun veteriner hekime iletilmesi; muayene sürelerini kısaltmakta, hekim iş yükünü azaltmakta ve tanı doğruluğunu artırmaktadır. Klinik değerlendirme ve yorum sistemi ise hasta sahiplerine doğru klinik tercihinde yol gösterirken kliniklere hizmet kalitelerini iyileştirme fırsatı sunmaktadır.

Tüm bu özellikler bir arada değerlendirildiğinde, proje veteriner klinik ekosisteminde bütünleşik dijital dönüşüme katkı sağlayan, ölçeklenebilir ve genişletilebilir bir yapı sunmaktadır.

## E. AMAÇ VE HEDEFLER
Bu projenin genel amacı, veteriner kliniklerinin hasta yönetim süreçlerini dijitalleştirerek randevu, hasta takip, müşteri geri bildirimi ve ön teşhis süreçlerini hızlandıran, kullanıcı dostu bir mobil uygulama geliştirmektir. Dönem sonunda ulaşılması planlanan ölçülebilir hedefler aşağıda sıralanmıştır:

* **Hizmet Erişilebilirliği:** Hayvan sahiplerinin mobil uygulama üzerinden hızlıca randevu oluşturabilmesi ve klinik yoğunluğunun daha etkin yönetilebilmesi.
* **Randevu Takibi ve Bildirim Sistemi:** SMS veya uygulama içi bildirimlerle otomatik hatırlatmalar gönderilerek randevu kayıplarının önlenmesi.
* **Hekim Bazlı Randevu Seçimi:** Birden fazla hekimin bulunduğu kliniklerde hasta sahiplerinin tercih ettikleri hekimle randevu alabilmesi.
* **Aşı Takibi ve Hatırlatma:** Hayvanların aşı takvimlerinin sisteme kaydedilmesi ve zamanı yaklaşan aşılar için otomatik bildirim gönderilmesi.
* **Yapay Zekâ Destekli Ön Teşhis:** Hasta sahibinin kliniğe gelmeden önce doldurduğu belirtilere dayalı olarak otomatik ön teşhis raporu oluşturulması ve bu raporun veteriner hekime iletilmesi.
* **Klinik Değerlendirme ve Geri Bildirim:** Kullanıcıların klinikler hakkında yorum ve puan bırakabilmesi; kliniklerin hizmet kalitesini ölçebilmesi ve geliştirebilmesi.

## F. YÖNTEM
Proje, katmanlı bir yazılım mimarisi benimsenerek geliştirilecektir. Aşağıda kullanılacak teknolojiler ve tasarım yaklaşımları açıklanmıştır:

1. **Mobil Uygulama Geliştirme:** Flutter kullanılarak hem iOS hem Android platformlarında çalışan, tek kod tabanlı bir mobil uygulama geliştirilecektir. Dart programlama dili ile geliştirilen Flutter, hızlı geliştirme süreci, yüksek performans ve zengin kullanıcı arayüzü bileşenleri sunması nedeniyle tercih edilmiştir. Kullanıcı arayüzü tasarımında sadelik ve erişilebilirlik ön planda tutulacaktır.
2. **Backend ve API:** C# ve .NET platformu (ASP.NET Core Web API) kullanılarak RESTful servisler geliştirilecektir. Mobil uygulamanın iş mantığı, veri işlemleri ve istemci sunucu iletişimi bu katmanda yönetilecektir.
3. **Veritabanı:** MySQL ilişkisel veri tabanı kullanılacaktır. Kullanıcı bilgileri, randevu detayları, hekim ve klinik kayıtları, aşı takibi ve yorumlar ilişkisel tablolarda tutulacak; ORM katmanı aracılığıyla veri bütünlüğü ve sorgu optimizasyonu sağlanacaktır.
4. **Bildirim Sistemi:** Firebase Cloud Messaging (FCM) entegrasyonu ile randevu hatırlatmaları, aşı bildirimleri ve acil güncellemeler anlık olarak kullanıcılara iletilecektir.
5. **Yapay Zekâ Destekli Ön Teşhis:** OpenAI API entegre edilerek eliminasyon mantığına dayalı soru-cevap akışı ile otomatik ön teşhis raporu oluşturulacaktır. Raporlar veteriner hekime randevu öncesinde iletilecektir.
6. **Kimlik Doğrulama ve Güvenlik:** Firebase Authentication ile e-posta, telefon numarası veya sosyal medya hesapları üzerinden güvenli kullanıcı girişi sağlanacaktır. Kişisel ve sağlık verileri siber güvenlik önlemleriyle korunacaktır.

## G. İŞ PLANI VE DÖNEMSEL TAKVİM

| Dönem | Planlanan Çalışmalar | Beklenen Çıktılar | Tahmini Zaman |
| :--- | :--- | :--- | :--- |
| **Bahar Dönemi** | Literatür taraması, benzer uygulamaların analizi ve sistem gereksinimlerinin belirlenmesi | Mevcut veteriner uygulamalarının karşılaştırmalı analizi ve sistem gereksinimlerinin belirlenmesi | 3 Hafta |
| **Bahar Dönemi** | Veritabanı şeması tasarımı | Kullanıcı, klinik, hekim, randevu, aşı ve yorum tablolarını kapsayan ilişkisel veritabanı şeması ve varlık-ilişki diyagramı | 4 Hafta |
| **Bahar Dönemi** | Kimlik doğrulama altyapısı | E-posta ve telefon numarası ile giriş yapılabilen, oturum yönetimi çalışan Firebase Auth entegrasyonu | 3 Hafta |
| **Bahar Dönemi** | Temel mobil arayüz ve randevu modülü | Kullanıcı profili ve hayvan bilgileri yönetimi, klinik listeleme, hekim seçimi ve randevu alma/iptal etme ekranlarını içeren prototip | 4 Hafta |
| **Güz Dönemi** | Gelişmiş mobil arayüz tasarımı | Bahar döneminde temel prototipi tamamlanan mobil arayüzün kullanıcı deneyimi iyileştirmesi | 3 Hafta |
| **Güz Dönemi** | Bildirim ve mesajlaşma altyapısı | Uygulama bildirimleri, kullanıcı-hekim mesajlaşma sistemi, randevu hatırlatmaları ve klinik duyuruları | 3 Hafta |
| **Güz Dönemi** | Yapay zekâ destekli ön teşhis modülü entegrasyonu | Yapay zekâ servisinin sisteme bağlanması, hastalıklara yönelik eleminasyonlu soru akışları ve hekime sunulacak dijital ön teşhis raporu taslağı | 6 Hafta |
| **Güz Dönemi** | Test, hata giderme ve performans iyileştirme | Uygulamanın tüm fonksiyonlarının çalışma testleri, tespit edilen hataların ayıklanması ve sistemin hızlandırılmasına yönelik çalışmalar | 2 Hafta |

## H. FİNAL SINAVINDA TESLİM EDİLECEK AŞAMA
Bahar dönemi sonunda, final sınavı kapsamında projenin aşağıdaki bileşenleri tamamlanmış ve çalışır halde teslim edilmesi planlanmaktadır:

* Kullanıcı kaydı, girişi ve profil yönetimini kapsayan kimlik doğrulama sistemi
* Klinik listeleme, hekim seçimi ve randevu alma/yönetme ekranları
* Kullanıcı ve hayvan bilgileri yönetimi ekranları
* Temel veritabanı yapısı ve ilişkisel veri modeli
* Yukarıda belirtilen fonksiyonları kapsayan, çalışır durumda mobil uygulama prototipi ve proje raporu

## I. KAYNAKLAR
1. Journal of Natural Sciences – Kabul University, “Importance of Anamnesis in Clinical Diagnosis of Cow Diseases,” 2025. [Online]. Available: https://jns.edu.af/jns/article/view/217
2. DergiPark, “Hizmet Kalitesi Algısının Tüketicilerin Pozitif E-WOM Eğilimleri Üzerindeki Etkisi,” 2022-08-31. [PDF]. Available: https://dergipark.org.tr/tr/download/article-file/1820522
3. DergiPark, “Hekime Tanı Koymada Yardımcı, Yapay Zekâ Destekli Hastalık Tespit Uzmanı,” Temmuz 2021. [PDF]. Available: https://dergipark.org.tr/en/download/article-file/1797634
4. J. Mariano, "VETGO: A Mobile Application Designed for Pet Veterinary Services," in Proc. 2024 7th Int. Conf. Computers in Management and Business (ICCMB '24), Association for Computing Machinery, 2024. https://doi.org/10.1145/3647782.3647806
5. Flutter. Available: https://flutter.dev/ (Erişim Tarihi Mar. 15, 2026).
6. .NET. Available: https://dotnet.microsoft.com/ (Erişim Tarihi Mar. 15, 2026).
7. MySQL. Available: https://www.mysql.com/ (Erişim Tarihi Mar. 18, 2026).
8. Firebase Cloud Messaging. Available: https://firebase.google.com/docs/cloud-messaging?hl=tr (Erişim Tarihi Mar. 20, 2026).
9. Firebase Authentication. Available: https://firebase.google.com/docs/auth?hl=tr (Erişim Tarihi Mar. 21, 2026).

---
**Öğrenci:** Ensar Gökhan
**İmza / Tarih:** 30.03.2026