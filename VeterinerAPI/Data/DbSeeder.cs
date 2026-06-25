using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Data;

public static class DbSeeder
{
    public static async Task SeedDataAsync(AppDbContext context)
    {
        // Önce migration'ları kontrol et
        await context.Database.MigrateAsync();

        // Eğer veritabanında klinik varsa zaten seed edilmiştir, atla.
        if (await context.Clinics.AnyAsync())
        {
            return;
        }

        // 1. Örnek Kullanıcılar (1 Admin/Hekim, 1 Normal Kullanıcı)
        var adminUser = new User
        {
            FirebaseUid = "dummy_admin_uid_123", // Test amaçlı sahte UID
            FullName = "Dr. Ahmet Yılmaz",
            Email = "ahmet.yilmaz@patilife.com",
            Phone = "05551234567",
            Role = "clinic_admin"
        };

        var normalUser = new User
        {
            FirebaseUid = "dummy_owner_uid_456",
            FullName = "Ensar Gökhan",
            Email = "ensar@example.com",
            Phone = "05329876543",
            Role = "owner"
        };

        context.Users.AddRange(adminUser, normalUser);
        await context.SaveChangesAsync();

        // 2. Örnek Klinik Ekleme
        var clinic = new Clinic
        {
            Name = "PatiLife Veteriner Kliniği",
            Address = "Örnek Mahallesi, Pati Sokak No: 1",
            City = "İstanbul",
            District = "Kadıköy",
            Phone = "02165554433",
            Email = "info@patilife.com",
            Description = "Sevimli dostlarınız için 7/24 hizmetinizdeyiz.",
            Latitude = 40.9902m,
            Longitude = 29.0292m,
            AdminUserId = adminUser.Id // Yeni eklenen alan
        };
        context.Clinics.Add(clinic);
        await context.SaveChangesAsync();

        // 3. Örnek Veteriner Hekim Ekleme (adminUser ile ilişkilendirilmiş)
        var vet = new Vet
        {
            UserId = adminUser.Id, // Aynı kişi hem admin hem de doktor olarak eklendi
            ClinicId = clinic.Id,
            Title = "Uzm. Vet. Hekim",
            Specialty = "Cerrahi",
            Bio = "10 yıllık tecrübesiyle sevimli dostlarımızın sağlığı için çalışmaktadır."
        };
        context.Vets.Add(vet);
        await context.SaveChangesAsync();

        // 4. Hekim Çalışma Takvimi Ekleme (Hafta içi 09:00 - 18:00)
        var schedules = new List<VetSchedule>();
        for (byte i = 1; i <= 5; i++) // 1=Salı ... (veya 1=Pazartesi vs, basitçe hafta içi)
        {
            schedules.Add(new VetSchedule
            {
                VetId = vet.Id,
                DayOfWeek = i,
                StartTime = new TimeSpan(9, 0, 0),
                EndTime = new TimeSpan(18, 0, 0),
                SlotDuration = 30
            });
        }
        context.VetSchedules.AddRange(schedules);

        // 5. Normal Kullanıcıya Evcil Hayvan Ekleme
        var animal = new Animal
        {
            OwnerId = normalUser.Id,
            Name = "Karabaş",
            Species = "dog",
            Breed = "Golden Retriever",
            Gender = "male",
            BirthDate = new DateTime(2020, 5, 10),
            Weight = 25.5m,
            MicrochipNo = "TR9876543210"
        };
        context.Animals.Add(animal);
        await context.SaveChangesAsync();

        // 6. Örnek Aşı Geçmişi
        var vaccine = new Vaccine
        {
            AnimalId = animal.Id,
            VetId = vet.Id,
            VaccineName = "Karma Aşı",
            AdministeredDate = DateTime.UtcNow.AddMonths(-6),
            NextDueDate = DateTime.UtcNow.AddMonths(6),
            BatchNumber = "KRM-2023-A"
        };
        context.Vaccines.Add(vaccine);
        await context.SaveChangesAsync();

        // Seed tamamlandı!
    }
}
