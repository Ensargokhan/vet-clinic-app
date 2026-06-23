using FirebaseAdmin.Auth;
using VeterinerAPI.DTOs.Auth;
using VeterinerAPI.Helpers;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly IClinicRepository _clinicRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IAnimalRepository _animalRepository;
    private readonly IVetRepository _vetRepository;

    public AuthService(
        IUserRepository userRepository, 
        IClinicRepository clinicRepository,
        IAppointmentRepository appointmentRepository,
        IAnimalRepository animalRepository,
        IVetRepository vetRepository)
    {
        _userRepository = userRepository;
        _clinicRepository = clinicRepository;
        _appointmentRepository = appointmentRepository;
        _animalRepository = animalRepository;
        _vetRepository = vetRepository;
    }

    public async Task<User> RegisterUserAsync(string firebaseUid, RegisterRequest request)
    {
        // 1. Bu FirebaseUid ile zaten kayıtlı mı?
        var existingByUid = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (existingByUid != null)
        {
            return existingByUid; // Zaten kayıtlı, mevcut kullanıcıyı döndür
        }

        // 2. Bu e-posta ile zaten kayıtlı mı? (Firebase hesabı silinip tekrar oluşturulmuş olabilir)
        var existingByEmail = await _userRepository.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (existingByEmail != null)
        {
            existingByEmail.FirebaseUid = firebaseUid;
            existingByEmail.FullName = InputSanitizer.Sanitize(request.FullName)!;
            existingByEmail.Phone = InputSanitizer.Sanitize(request.Phone);
            existingByEmail.UpdatedAt = DateTime.UtcNow;

            _userRepository.Update(existingByEmail);
            await _userRepository.SaveChangesAsync();
            return existingByEmail;
        }

        // 3. Yeni kullanıcı oluştur
        var user = new User
        {
            FirebaseUid = firebaseUid,
            FullName = InputSanitizer.Sanitize(request.FullName)!,
            Email = request.Email,
            Phone = InputSanitizer.Sanitize(request.Phone),
            Role = request.Role ?? "owner"
        };

        await _userRepository.AddAsync(user);
        await _userRepository.SaveChangesAsync();

        return user;
    }

    public async Task<User> RegisterClinicAsync(string firebaseUid, RegisterClinicRequest request)
    {
        // 1. Bu FirebaseUid ile veya e-posta ile zaten kayıtlı mı?
        var existingByUid = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (existingByUid != null)
            return existingByUid;

        var existingByEmail = await _userRepository.FirstOrDefaultAsync(u => u.Email == request.AdminEmail);
        if (existingByEmail != null)
            throw new Exception("Bu e-posta ile zaten bir kayıt mevcut.");

        // 2. Admin Kullanıcısını (clinic_admin) oluştur
        var adminUser = new User
        {
            FirebaseUid = firebaseUid,
            FullName = InputSanitizer.Sanitize(request.AdminFullName)!,
            Email = request.AdminEmail,
            Phone = InputSanitizer.Sanitize(request.AdminPhone),
            Role = "clinic_admin"
        };

        await _userRepository.AddAsync(adminUser);
        await _userRepository.SaveChangesAsync(); // Admin user kaydedildi, Id'si alındı

        // 3. Kliniği oluştur ve admin'e bağla
        var clinic = new Clinic
        {
            Name = InputSanitizer.Sanitize(request.ClinicName)!,
            Email = request.ClinicEmail,
            Phone = InputSanitizer.Sanitize(request.ClinicPhone)!,
            City = InputSanitizer.Sanitize(request.ClinicCity)!,
            District = InputSanitizer.Sanitize(request.ClinicDistrict)!,
            Address = InputSanitizer.Sanitize(request.ClinicAddress)!,
            AdminUserId = adminUser.Id // FK bağlantısı
        };

        await _clinicRepository.AddAsync(clinic);
        await _clinicRepository.SaveChangesAsync();

        return adminUser;
    }

    public async Task<User?> GetUserByFirebaseUidAsync(string firebaseUid)
    {
        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (user != null && !user.IsActive)
            throw new Exception("Hesabınız sistem yöneticisi veya klinik tarafından pasife alınmıştır.");
        return user;
    }

    public async Task<User?> GetUserProfileAsync(string firebaseUid)
    {
        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (user != null && !user.IsActive)
            throw new Exception("Hesabınız sistem yöneticisi veya klinik tarafından pasife alınmıştır.");
        return user;
    }

    public async Task<User> UpdateProfileAsync(string firebaseUid, UpdateProfileRequest request)
    {
        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (user == null)
        {
            throw new Exception("Kullanıcı bulunamadı.");
        }
        if (!user.IsActive)
        {
            throw new Exception("Hesabınız sistem yöneticisi veya klinik tarafından pasife alınmıştır.");
        }

        user.FullName = InputSanitizer.Sanitize(request.FullName)!;
        user.Phone = InputSanitizer.Sanitize(request.Phone);
        user.UpdatedAt = DateTime.UtcNow;

        _userRepository.Update(user);
        await _userRepository.SaveChangesAsync();

        return user;
    }

    public async Task<string?> UpdateProfilePhotoAsync(string firebaseUid, string photoUrl)
    {
        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (user == null) throw new Exception("Kullanıcı bulunamadı.");
        if (!user.IsActive) throw new Exception("Hesabınız sistem yöneticisi veya klinik tarafından pasife alınmıştır.");

        var oldPhotoUrl = user.ProfilePhoto;
        user.ProfilePhoto = photoUrl;
        user.UpdatedAt = DateTime.UtcNow;

        _userRepository.Update(user);
        await _userRepository.SaveChangesAsync();

        return oldPhotoUrl;
    }

    public async Task DeactivateUserAccountAsync(string firebaseUid)
    {
        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (user == null)
            throw new Exception("Kullanıcı bulunamadı.");

        // 1. Soft Delete User & Anonymize
        user.IsActive = false;
        user.FullName = "Silinmiş Kullanıcı";
        user.Email = $"deleted_{Guid.NewGuid().ToString("N")[..8]}@deleted.com";
        user.Phone = null;
        user.UpdatedAt = DateTime.UtcNow;
        _userRepository.Update(user);

        // 2. Cascade Soft Delete and Cancel Appointments
        if (user.Role == "clinic_admin")
        {
            var clinic = await _clinicRepository.FirstOrDefaultAsync(c => c.AdminUserId == user.Id);
            if (clinic != null)
            {
                clinic.IsActive = false;
                clinic.UpdatedAt = DateTime.UtcNow;
                _clinicRepository.Update(clinic);

                // Cancel future pending/confirmed appointments for this clinic
                var pendingAppointments = await _appointmentRepository.FindAsync(a => 
                    a.ClinicId == clinic.Id && 
                    (a.Status == "pending" || a.Status == "confirmed") && 
                    a.AppointmentDate > DateTime.UtcNow);

                foreach (var appt in pendingAppointments)
                {
                    appt.Status = "cancelled";
                    appt.Notes = "Klinik hesabı kapatıldığı için iptal edildi.";
                    appt.UpdatedAt = DateTime.UtcNow;
                    _appointmentRepository.Update(appt);
                }
            }
        }
        else if (user.Role == "owner")
        {
            // Cancel future pending/confirmed appointments for this owner
            var pendingAppointments = await _appointmentRepository.FindAsync(a => 
                a.OwnerId == user.Id && 
                (a.Status == "pending" || a.Status == "confirmed") && 
                a.AppointmentDate > DateTime.UtcNow);

            foreach (var appt in pendingAppointments)
            {
                appt.Status = "cancelled";
                appt.Notes = "Kullanıcı hesabı kapatıldığı için iptal edildi.";
                appt.UpdatedAt = DateTime.UtcNow;
                _appointmentRepository.Update(appt);
            }

            // Deactivate animals owned by this user
            var animals = await _animalRepository.FindAsync(a => a.OwnerId == user.Id && a.IsActive);
            foreach (var animal in animals)
            {
                animal.IsActive = false;
                animal.UpdatedAt = DateTime.UtcNow;
                _animalRepository.Update(animal);
            }
        }
        else if (user.Role == "vet")
        {
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == user.Id);
            if (vet != null)
            {
                vet.IsActive = false;
                _vetRepository.Update(vet);

                // Cancel future pending/confirmed appointments for this vet
                var pendingAppointments = await _appointmentRepository.FindAsync(a => 
                    a.VetId == vet.Id && 
                    (a.Status == "pending" || a.Status == "confirmed") && 
                    a.AppointmentDate > DateTime.UtcNow);

                foreach (var appt in pendingAppointments)
                {
                    appt.Status = "cancelled";
                    appt.UpdatedAt = DateTime.UtcNow;
                    _appointmentRepository.Update(appt);
                }
            }
        }

        // Save DB Changes first
        await _userRepository.SaveChangesAsync();

        // 3. Delete from Firebase
        await FirebaseAuth.DefaultInstance.DeleteUserAsync(firebaseUid);
    }

    public async Task<object> GetUserStatsAsync(string firebaseUid)
    {
        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (user == null) throw new Exception("Kullanıcı bulunamadı.");

        int totalAnimals = 0;
        int totalAppointments = 0;
        double? rating = null;

        if (user.Role == "owner")
        {
            var animals = await _animalRepository.FindAsync(a => a.OwnerId == user.Id && a.IsActive);
            totalAnimals = animals.Count();

            var appointments = await _appointmentRepository.FindAsync(a => a.OwnerId == user.Id);
            totalAppointments = appointments.Count();
        }
        else if (user.Role == "vet")
        {
            var appointments = await _appointmentRepository.FindAsync(a => a.VetId == user.Id);
            totalAppointments = appointments.Count();
        }
        else if (user.Role == "clinic_admin")
        {
            var clinic = await _clinicRepository.FirstOrDefaultAsync(c => c.AdminUserId == user.Id);
            if (clinic != null)
            {
                var appointments = await _appointmentRepository.FindAsync(a => a.ClinicId == clinic.Id);
                totalAppointments = appointments.Count();
                // Optionally implement clinic rating if there's a property
            }
        }

        return new
        {
            totalAnimals,
            totalAppointments,
            rating
        };
    }
}
