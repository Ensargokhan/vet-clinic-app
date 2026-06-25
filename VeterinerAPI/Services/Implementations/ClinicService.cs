using VeterinerAPI.DTOs.Clinics;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;
using VeterinerAPI.DTOs.Vets;
using VeterinerAPI.Models.Entities;
using FirebaseAdmin.Auth;
using VeterinerAPI.Helpers;

namespace VeterinerAPI.Services.Implementations;

public class ClinicService : IClinicService
{
    private readonly IClinicRepository _clinicRepository;
    private readonly IUserRepository _userRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IVetRepository _vetRepository;
    private readonly VeterinerAPI.Data.AppDbContext _context;

    public ClinicService(
        IClinicRepository clinicRepository,
        IUserRepository userRepository,
        IAppointmentRepository appointmentRepository,
        IVetRepository vetRepository,
        VeterinerAPI.Data.AppDbContext context)
    {
        _clinicRepository = clinicRepository;
        _userRepository = userRepository;
        _appointmentRepository = appointmentRepository;
        _vetRepository = vetRepository;
        _context = context;
    }

    public async Task<IEnumerable<ClinicResponse>> GetAllActiveClinicsAsync()
    {
        var clinics = await _clinicRepository.GetActiveClinicsAsync();
        return clinics.Select(c => new ClinicResponse
        {
            Id = c.Id,
            Name = c.Name,
            Address = c.Address,
            City = c.City,
            District = c.District,
            Phone = c.Phone,
            LogoUrl = c.LogoUrl,
            Latitude = c.Latitude,
            Longitude = c.Longitude
        });
    }

    public async Task<VeterinerAPI.DTOs.Common.PagedResponse<ClinicResponse>> SearchClinicsAsync(ClinicSearchRequest request)
    {
        var (items, totalCount) = await _clinicRepository.SearchClinicsAsync(
            request.Search, request.City, request.District, request.Specialty, request.Page, request.PageSize);

        var totalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize);

        return new VeterinerAPI.DTOs.Common.PagedResponse<ClinicResponse>
        {
            Items = items.Select(c => new ClinicResponse
            {
                Id = c.Id,
                Name = c.Name,
                Address = c.Address,
                City = c.City,
                District = c.District,
                Phone = c.Phone,
                LogoUrl = c.LogoUrl,
                Latitude = c.Latitude,
                Longitude = c.Longitude,
                Specialties = c.Vets
                    .Where(v => v.IsActive && v.Specialty != null)
                    .Select(v => v.Specialty!)
                    .Distinct()
                    .ToList(),
                ReviewCount = c.Reviews.Count(r => r.IsVisible),
                Rating = c.Reviews.Any(r => r.IsVisible)
                    ? Math.Round(c.Reviews.Where(r => r.IsVisible).Average(r => r.Rating), 1)
                    : (double?)null
            }).ToList(),
            Page = request.Page,
            PageSize = request.PageSize,
            TotalCount = totalCount,
            TotalPages = totalPages,
            HasPrevious = request.Page > 1,
            HasNext = request.Page < totalPages
        };
    }

    public async Task<ClinicDetailResponse?> GetClinicDetailsAsync(int clinicId)
    {
        var clinic = await _clinicRepository.GetClinicWithVetsAsync(clinicId);
        if (clinic == null) return null;

        return new ClinicDetailResponse
        {
            Id = clinic.Id,
            Name = clinic.Name,
            Address = clinic.Address,
            City = clinic.City,
            District = clinic.District,
            Phone = clinic.Phone,
            Email = clinic.Email,
            Description = clinic.Description,
            LogoUrl = clinic.LogoUrl,
            Latitude = clinic.Latitude,
            Longitude = clinic.Longitude,
            Vets = clinic.Vets.Where(v => v.IsActive).Select(v => new VeterinerAPI.DTOs.Vets.VetResponse
            {
                Id = v.Id,
                FullName = v.User.FullName,
                Title = v.Title,
                Specialty = v.Specialty,
                ProfilePhoto = v.ProfilePhoto
            }).ToList()
        };
    }

    private async Task<Clinic> GetAdminClinicAsync(string firebaseUid)
    {
        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (user == null || user.Role != "clinic_admin")
            throw new UnauthorizedAccessException("Bu işlem için yetkiniz yok.");

        var clinic = await _clinicRepository.GetClinicByAdminUserIdAsync(user.Id);
        if (clinic == null)
            throw new Exception("Size ait bir klinik bulunamadı.");
            
        return clinic;
    }

    public async Task<ClinicDashboardResponse?> GetClinicDashboardAsync(string firebaseUid)
    {
        var clinic = await GetAdminClinicAsync(firebaseUid);
        var clinicWithDetails = await _clinicRepository.GetClinicWithDetailsAsync(clinic.Id);
        if (clinicWithDetails == null) return null;

        var todayCount = await _appointmentRepository.GetTodayAppointmentCountByClinicAsync(clinic.Id);
        var pendingCount = await _appointmentRepository.GetPendingAppointmentCountByClinicAsync(clinic.Id);
        
        var upcoming = clinicWithDetails.Appointments
            .Where(a => a.AppointmentDate > DateTime.UtcNow && a.Status != "cancelled")
            .OrderBy(a => a.AppointmentDate)
            .Take(5)
            .Select(a => new UpcomingAppointmentDto
            {
                Id = a.Id,
                AnimalName = a.Animal.Name,
                OwnerName = a.Owner.FullName,
                VetName = a.Vet.User.FullName,
                AppointmentDate = a.AppointmentDate,
                Status = a.Status,
                Reason = a.Reason
            }).ToList();

        return new ClinicDashboardResponse
        {
            ClinicId = clinic.Id,
            ClinicName = clinic.Name,
            AdminName = clinic.AdminUser.FullName,
            TodayAppointmentCount = todayCount,
            PendingAppointmentCount = pendingCount,
            ActiveVetCount = clinicWithDetails.Vets.Count(v => v.IsActive),
            UpcomingAppointments = upcoming
        };
    }

    public async Task<ClinicDetailResponse?> GetMyClinicAsync(string firebaseUid)
    {
        var clinic = await GetAdminClinicAsync(firebaseUid);
        return await GetClinicDetailsAsync(clinic.Id);
    }

    public async Task<ClinicDetailResponse?> UpdateMyClinicAsync(string firebaseUid, UpdateClinicRequest request)
    {
        var clinic = await GetAdminClinicAsync(firebaseUid);
        
        if (request.Name != null) clinic.Name = InputSanitizer.Sanitize(request.Name)!;
        if (request.Phone != null) clinic.Phone = InputSanitizer.Sanitize(request.Phone)!;
        if (request.Email != null) clinic.Email = request.Email;
        if (request.City != null) clinic.City = InputSanitizer.Sanitize(request.City)!;
        if (request.District != null) clinic.District = InputSanitizer.Sanitize(request.District)!;
        if (request.Address != null) clinic.Address = InputSanitizer.Sanitize(request.Address)!;
        if (request.Description != null) clinic.Description = InputSanitizer.Sanitize(request.Description);
        
        clinic.UpdatedAt = DateTime.UtcNow;
        _clinicRepository.Update(clinic);
        await _clinicRepository.SaveChangesAsync();
        
        return await GetClinicDetailsAsync(clinic.Id);
    }

    public async Task<string?> UpdateClinicLogoAsync(string firebaseUid, string logoUrl)
    {
        var clinic = await GetAdminClinicAsync(firebaseUid);
        
        var oldLogoUrl = clinic.LogoUrl;
        clinic.LogoUrl = logoUrl;
        clinic.UpdatedAt = DateTime.UtcNow;

        _clinicRepository.Update(clinic);
        await _clinicRepository.SaveChangesAsync();

        return oldLogoUrl;
    }

    public async Task<object> AddVetToClinicAsync(string firebaseUid, AddVetToClinicRequest request)
    {
        var clinic = await GetAdminClinicAsync(firebaseUid);
        
        // 1. Check if email already exists
        var existingUser = await _userRepository.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (existingUser != null)
        {
            if (existingUser.IsActive)
            {
                throw new Exception("Bu e-posta adresiyle aktif bir kullanıcı zaten mevcut.");
            }
            else
            {
                // Pasif kullanıcı var ama e-postası zaten anonimleştirilmiş olmalıydı.
                // Güvenlik katmanı: Burada da anonimleştir.
                existingUser.Email = $"deleted_{Guid.NewGuid().ToString("N")[..8]}@deleted.com";
                existingUser.FirebaseUid = $"deleted_{Guid.NewGuid().ToString("N")[..8]}";
                _userRepository.Update(existingUser);
                await _userRepository.SaveChangesAsync();
            }
        }

        // 1.5 Create Firebase User
        var firebaseUserArgs = new FirebaseAdmin.Auth.UserRecordArgs
        {
            Email = request.Email,
            Password = request.Password,
            DisplayName = request.FullName,
            Disabled = false
        };
        var firebaseUser = await FirebaseAdmin.Auth.FirebaseAuth.DefaultInstance.CreateUserAsync(firebaseUserArgs);

        // 2. Create User in Database
        var newUser = new VeterinerAPI.Models.Entities.User
        {
            FirebaseUid = firebaseUser.Uid,
            FullName = InputSanitizer.Sanitize(request.FullName)!,
            Email = request.Email,
            Phone = InputSanitizer.Sanitize(request.Phone),
            Role = "vet",
            IsActive = true
        };
        await _userRepository.AddAsync(newUser);
        await _userRepository.SaveChangesAsync();

        // 3. Create Vet Profile
        var vet = new VeterinerAPI.Models.Entities.Vet
        {
            UserId = newUser.Id,
            ClinicId = clinic.Id,
            Title = InputSanitizer.Sanitize(request.Title),
            Specialty = InputSanitizer.Sanitize(request.Specialty),
            Bio = InputSanitizer.Sanitize(request.Bio),
            IsActive = true
        };
        await _vetRepository.AddAsync(vet);
        await _vetRepository.SaveChangesAsync();

        // 4. Create Default VetSchedules (Monday to Friday, 09:00 - 17:00, 30 min slots)
        for (byte day = 1; day <= 5; day++) // 1: Monday ... 5: Friday
        {
            _context.VetSchedules.Add(new VeterinerAPI.Models.Entities.VetSchedule
            {
                VetId = vet.Id,
                DayOfWeek = day,
                StartTime = new TimeSpan(9, 0, 0), // 09:00
                EndTime = new TimeSpan(17, 0, 0),  // 17:00
                SlotDuration = 30,
                IsActive = true
            });
        }
        await _context.SaveChangesAsync();

        return new { Message = "Hekim eklendi. Lütfen mobil uygulamadan hekim hesabıyla (bu e-posta ile) kayıt olmasını isteyin." };
    }

    public async Task<object> RemoveVetFromClinicAsync(string firebaseUid, int vetId)
    {
        var clinic = await GetAdminClinicAsync(firebaseUid);
        
        var vet = await _vetRepository.FirstOrDefaultAsync(v => v.Id == vetId && v.ClinicId == clinic.Id);
        if (vet == null)
            throw new Exception("Kliniğinize ait böyle bir hekim bulunamadı.");

        // Soft delete Vet
        vet.IsActive = false;
        vet.UpdatedAt = DateTime.UtcNow;
        _vetRepository.Update(vet);

        // Soft delete associated User if necessary, but just deactivating the Vet profile is usually enough for the Clinic's scope.
        // We will deactivate the user entirely so they cannot login as vet.
        var user = await _userRepository.GetByIdAsync(vet.UserId);
        if (user != null)
        {
            var oldFirebaseUid = user.FirebaseUid;

            user.IsActive = false;
            user.UpdatedAt = DateTime.UtcNow;
            user.Email = $"deleted_{Guid.NewGuid().ToString("N")[..8]}@deleted.com";
            user.FirebaseUid = $"deleted_{Guid.NewGuid().ToString("N")[..8]}";
            user.Phone = null;
            _userRepository.Update(user);

            // Cancel future pending/confirmed appointments for this vet
            var pendingAppointments = await _appointmentRepository.FindAsync(a => 
                a.VetId == vet.Id && 
                (a.Status == "pending" || a.Status == "confirmed") && 
                a.AppointmentDate > DateTime.UtcNow);

            foreach (var appt in pendingAppointments)
            {
                appt.Status = "cancelled";
                appt.Notes = "Hekim klinikten ayrıldığı için iptal edildi.";
                appt.UpdatedAt = DateTime.UtcNow;
                _appointmentRepository.Update(appt);
            }

            await _vetRepository.SaveChangesAsync(); // Saves both Vet, User and Appointments due to shared DbContext

            try
            {
                await FirebaseAuth.DefaultInstance.DeleteUserAsync(oldFirebaseUid);
            }
            catch (FirebaseAuthException)
            {
                // Firebase'de zaten silinmişse veya bulunamazsa sessizce devam et
            }
        }

        return new { Message = "Hekim başarıyla silindi (pasife alındı)." };
    }

    public async Task<IEnumerable<object>> GetClinicAppointmentsAsync(string firebaseUid)
    {
        var clinic = await GetAdminClinicAsync(firebaseUid);
        var appointments = await _appointmentRepository.GetAppointmentsByClinicIdAsync(clinic.Id);
        
        return appointments.Select(a => new
        {
            Id = a.Id,
            AnimalName = a.Animal.Name,
            OwnerName = a.Owner.FullName,
            VetName = a.Vet.User.FullName,
            AppointmentDate = a.AppointmentDate,
            Status = a.Status,
            Reason = a.Reason
        });
    }

    public async Task<bool> UpdateClinicAppointmentStatusAsync(string firebaseUid, int appointmentId, string newStatus, string? notes)
    {
        var clinic = await GetAdminClinicAsync(firebaseUid);
        var appointment = await _appointmentRepository.GetByIdAsync(appointmentId);
        
        if (appointment == null || appointment.ClinicId != clinic.Id)
            throw new Exception("Randevu bulunamadı veya yetkiniz yok.");

        // Durum geçiş kuralları (hekim ile aynı kurallar)
        AppointmentStatusRules.EnsureTransition(appointment.Status, newStatus);
        appointment.Status = newStatus;
        if (notes != null) appointment.Notes = InputSanitizer.Sanitize(notes);
        
        _appointmentRepository.Update(appointment);
        await _appointmentRepository.SaveChangesAsync();
        return true;
    }
}
