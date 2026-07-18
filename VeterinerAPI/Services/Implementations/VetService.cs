using Microsoft.EntityFrameworkCore;
using VeterinerAPI.DTOs.Vets;
using VeterinerAPI.Helpers;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class VetService : IVetService
{
    private readonly IVetRepository _vetRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IUserRepository _userRepository;
    private readonly VeterinerAPI.Data.AppDbContext _context;
    private readonly INotificationService _notificationService;

    public VetService(
        IVetRepository vetRepository,
        IAppointmentRepository appointmentRepository,
        IUserRepository userRepository,
        VeterinerAPI.Data.AppDbContext context,
        INotificationService notificationService)
    {
        _vetRepository = vetRepository;
        _appointmentRepository = appointmentRepository;
        _userRepository = userRepository;
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<IEnumerable<VetScheduleResponse>> GetVetScheduleAsync(int vetId)
    {
        var schedules = await _vetRepository.GetVetSchedulesAsync(vetId);
        return schedules.Select(s => new VetScheduleResponse
        {
            Id = s.Id,
            DayOfWeek = s.DayOfWeek,
            StartTime = s.StartTime,
            EndTime = s.EndTime,
            SlotDuration = s.SlotDuration
        });
    }

    public async Task<IEnumerable<AvailableSlotResponse>> GetAvailableSlotsAsync(int vetId, DateTime date)
    {
        byte dayOfWeek = (byte)date.DayOfWeek;
        Console.WriteLine($"[DEBUG] GetAvailableSlotsAsync called for VetId: {vetId}, Date: {date:yyyy-MM-dd}, DayOfWeek: {dayOfWeek}");
        
        var schedules = await _vetRepository.GetVetSchedulesAsync(vetId);
        var schedule = schedules.FirstOrDefault(s => s.DayOfWeek == dayOfWeek);

        if (schedule == null)
        {
            Console.WriteLine("[DEBUG] No schedules found for this day.");
            return new List<AvailableSlotResponse>();
        }

        Console.WriteLine($"[DEBUG] Schedule found: Start {schedule.StartTime}, End {schedule.EndTime}, SlotDuration {schedule.SlotDuration}");

        var appointments = await _appointmentRepository.GetAppointmentsByVetAndDateAsync(vetId, date);
        var takenTimes = appointments.Select(a => a.AppointmentDate.TimeOfDay).ToList();

        var availableSlots = new List<AvailableSlotResponse>();
        var currentSlot = schedule.StartTime;

        while (currentSlot < schedule.EndTime)
        {
            availableSlots.Add(new AvailableSlotResponse
            {
                Time = currentSlot,
                IsAvailable = !takenTimes.Contains(currentSlot)
            });

            currentSlot = currentSlot.Add(TimeSpan.FromMinutes(schedule.SlotDuration));
        }

        Console.WriteLine($"[DEBUG] Returning {availableSlots.Count} available slots.");
        return availableSlots;
    }

    private async Task<VeterinerAPI.Models.Entities.Vet> GetVetAsync(string firebaseUid)
    {
        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid);
        if (user == null || user.Role != "vet")
            throw new UnauthorizedAccessException("Bu işlem için yetkiniz yok.");

        var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == user.Id);
        if (vet == null)
            throw new Exception("Hekim profili bulunamadı.");

        return vet;
    }

    public async Task<VetDashboardResponse?> GetVetDashboardAsync(string firebaseUid)
    {
        var vet = await GetVetAsync(firebaseUid);
        var clinic = await _context.Clinics.FindAsync(vet.ClinicId);
        
        var appointments = await _appointmentRepository.GetAppointmentsByVetIdAsync(vet.Id);
        var todayCount = appointments.Count(a => a.AppointmentDate.Date == DateTime.UtcNow.Date);
        var pendingCount = appointments.Count(a => a.Status == "pending");
        var totalCount = appointments.Count();

        var upcoming = appointments
            .Where(a => a.AppointmentDate > DateTime.UtcNow)
            .OrderBy(a => a.AppointmentDate)
            .Take(5)
            .Select(a => new VetUpcomingAppointmentDto
            {
                Id = a.Id,
                AnimalName = a.Animal.Name,
                OwnerName = a.Owner.FullName,
                AppointmentDate = a.AppointmentDate,
                Status = a.Status,
                Reason = a.Reason
            }).ToList();

        var user = await _userRepository.GetByIdAsync(vet.UserId);

        return new VetDashboardResponse
        {
            VetId = vet.Id,
            FullName = user?.FullName ?? "",
            Title = vet.Title,
            Specialty = vet.Specialty,
            ProfilePhoto = vet.ProfilePhoto,
            ClinicName = clinic?.Name ?? "Bilinmiyor",
            TodayAppointmentCount = todayCount,
            PendingAppointmentCount = pendingCount,
            TotalAppointmentCount = totalCount,
            UpcomingAppointments = upcoming
        };
    }

    public async Task<IEnumerable<VeterinerAPI.DTOs.Appointments.AppointmentResponse>> GetVetAppointmentsAsync(string firebaseUid)
    {
        var vet = await GetVetAsync(firebaseUid);
        var appointments = await _appointmentRepository.GetAppointmentsByVetIdAsync(vet.Id);
        
        return appointments.Select(a => new VeterinerAPI.DTOs.Appointments.AppointmentResponse
        {
            Id = a.Id,
            AnimalId = a.AnimalId,
            AnimalName = a.Animal.Name,
            ClinicId = a.ClinicId,
            ClinicName = a.Clinic.Name,
            VetId = a.VetId,
            VetName = a.Vet.User.FullName,
            AppointmentDate = a.AppointmentDate,
            DurationMinutes = a.DurationMinutes,
            Status = a.Status,
            Reason = a.Reason,
            Notes = a.Notes,
            CancellationReason = a.CancellationReason
        });
    }

    public async Task<bool> UpdateAppointmentStatusAsync(string firebaseUid, int appointmentId, string newStatus, string? notes)
    {
        var vet = await GetVetAsync(firebaseUid);
        var appointment = await _appointmentRepository.GetByIdAsync(appointmentId);
        
        if (appointment == null || appointment.VetId != vet.Id)
            throw new Exception("Randevu bulunamadı veya yetkiniz yok.");

        // Durum geçiş kuralları (tek kaynak: AppointmentStatusRules)
        AppointmentStatusRules.EnsureTransition(appointment.Status, newStatus);
        appointment.Status = newStatus;
        if (notes != null) appointment.Notes = InputSanitizer.Sanitize(notes);

        _appointmentRepository.Update(appointment);
        try
        {
            await _appointmentRepository.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            // Status bir eşzamanlılık token'ı: aynı anda hekim ve klinik yöneticisi
            // güncellediyse ikinci yazan buraya düşer — "son yazan kazanır" engellenir.
            throw new InvalidOperationException(
                "Randevu az önce başka bir kullanıcı tarafından güncellendi. Lütfen sayfayı yenileyip tekrar deneyin.");
        }

        // Randevu sahibine durum bildirimi (yalnız başarılı kayıttan sonra — çift bildirim olmaz)
        await NotifyOwnerStatusAsync(appointment, newStatus);
        return true;
    }

    // Randevu sahibine "durumunuz güncellendi" bildirimi (hekim ve klinik ortak kullanır mantığı; burada hekim tarafı)
    private async Task NotifyOwnerStatusAsync(VeterinerAPI.Models.Entities.Appointment appointment, string newStatus)
    {
        var label = AppointmentStatusRules.ToTurkishLabel(newStatus);
        var dateStr = appointment.AppointmentDate.ToString("dd.MM.yyyy HH:mm");
        await _notificationService.NotifyAsync(
            appointment.OwnerId,
            "Randevu durumu güncellendi",
            $"{dateStr} tarihli randevunuz: {label}.",
            "appointment_status",
            appointment.Id);
    }

    public async Task<IEnumerable<VetScheduleResponse>> GetMyScheduleAsync(string firebaseUid)
    {
        var vet = await GetVetAsync(firebaseUid);
        return await GetVetScheduleAsync(vet.Id);
    }

    public async Task<bool> UpdateMyScheduleAsync(string firebaseUid, List<UpdateVetScheduleRequest> schedules)
    {
        var vet = await GetVetAsync(firebaseUid);
        
        var existingSchedules = await _vetRepository.GetVetSchedulesAsync(vet.Id);
        
        foreach (var req in schedules)
        {
            // Sadece o gün çalışılıyorsa saat aralığı mantıklı olmalı (bitiş > başlangıç)
            if (req.IsActive && req.EndTime <= req.StartTime)
                throw new Exception("Çalışma bitiş saati, başlangıç saatinden sonra olmalıdır.");

            var existing = existingSchedules.FirstOrDefault(s => s.DayOfWeek == req.DayOfWeek);
            if (existing != null)
            {
                existing.StartTime = req.StartTime;
                existing.EndTime = req.EndTime;
                existing.SlotDuration = req.SlotDuration;
                existing.IsActive = req.IsActive;
            }
            else
            {
                _context.VetSchedules.Add(new VeterinerAPI.Models.Entities.VetSchedule
                {
                    VetId = vet.Id,
                    DayOfWeek = req.DayOfWeek,
                    StartTime = req.StartTime,
                    EndTime = req.EndTime,
                    SlotDuration = req.SlotDuration,
                    IsActive = req.IsActive
                });
            }
        }
        
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<VetResponse?> GetVetProfileAsync(string firebaseUid)
    {
        var vet = await GetVetAsync(firebaseUid);
        var user = await _userRepository.GetByIdAsync(vet.UserId);
        
        return new VetResponse
        {
            Id = vet.Id,
            FullName = user?.FullName ?? "",
            Title = vet.Title,
            Specialty = vet.Specialty,
            ProfilePhoto = vet.ProfilePhoto,
            Bio = vet.Bio
        };
    }

    public async Task<VetResponse?> UpdateVetProfileAsync(string firebaseUid, UpdateVetProfileRequest request)
    {
        var vet = await GetVetAsync(firebaseUid);
        var user = await _userRepository.GetByIdAsync(vet.UserId);
        
        if (request.Title != null) vet.Title = InputSanitizer.Sanitize(request.Title);
        if (request.Specialty != null) vet.Specialty = InputSanitizer.Sanitize(request.Specialty);
        if (request.Bio != null) vet.Bio = InputSanitizer.Sanitize(request.Bio);
        
        if (request.Phone != null && user != null)
        {
            user.Phone = InputSanitizer.Sanitize(request.Phone);
            _userRepository.Update(user);
        }
        
        _vetRepository.Update(vet);
        await _context.SaveChangesAsync();
        
        return await GetVetProfileAsync(firebaseUid);
    }

    public async Task<string?> UpdateVetProfilePhotoAsync(string firebaseUid, string photoUrl)
    {
        var vet = await GetVetAsync(firebaseUid);
        
        var oldPhotoUrl = vet.ProfilePhoto;
        vet.ProfilePhoto = photoUrl;
        vet.UpdatedAt = DateTime.UtcNow;

        _vetRepository.Update(vet);
        await _context.SaveChangesAsync();

        return oldPhotoUrl;
    }
}
