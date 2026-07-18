using VeterinerAPI.DTOs.Appointments;
using VeterinerAPI.Helpers;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class AppointmentService : IAppointmentService
{
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IAnimalRepository _animalRepository;
    private readonly IVetRepository _vetRepository;
    private readonly IVetService _vetService;
    private readonly INotificationService _notificationService;

    public AppointmentService(
        IAppointmentRepository appointmentRepository,
        IAnimalRepository animalRepository,
        IVetRepository vetRepository,
        IVetService vetService,
        INotificationService notificationService)
    {
        _appointmentRepository = appointmentRepository;
        _animalRepository = animalRepository;
        _vetRepository = vetRepository;
        _vetService = vetService;
        _notificationService = notificationService;
    }

    public async Task<IEnumerable<AppointmentResponse>> GetAppointmentsByUserAsync(int userId)
    {
        var appointments = await _appointmentRepository.GetAppointmentsByUserAsync(userId);
        return appointments.Select(a => new AppointmentResponse
        {
            Id = a.Id,
            AnimalId = a.AnimalId,
            AnimalName = a.Animal?.Name,
            VetId = a.VetId,
            VetName = a.Vet?.User.FullName,
            ClinicId = a.ClinicId,
            AppointmentDate = a.AppointmentDate,
            DurationMinutes = a.DurationMinutes,
            Status = a.Status,
            Reason = a.Reason,
            Notes = a.Notes,
            CancellationReason = a.CancellationReason
        });
    }

    public async Task<AppointmentResponse?> GetAppointmentByIdAsync(int id, int userId)
    {
        var a = await _appointmentRepository.GetAppointmentWithDetailsAsync(id);
        if (a == null || a.OwnerId != userId) return null;

        return new AppointmentResponse
        {
            Id = a.Id,
            AnimalId = a.AnimalId,
            AnimalName = a.Animal?.Name ?? "",
            VetId = a.VetId,
            VetName = a.Vet?.User?.FullName ?? "",
            ClinicId = a.ClinicId,
            AppointmentDate = a.AppointmentDate,
            DurationMinutes = a.DurationMinutes,
            Status = a.Status,
            Reason = a.Reason,
            Notes = a.Notes,
            CancellationReason = a.CancellationReason
        };
    }

    public async Task<int> CreateAppointmentAsync(AppointmentRequest request, int userId)
    {
        // Hayvan kullanıcının mı kontrolü
        var animal = await _animalRepository.GetByIdAsync(request.AnimalId);
        if (animal == null || !animal.IsActive || animal.OwnerId != userId)
        {
            throw new UnauthorizedAccessException("Geçersiz hayvan ID veya erişim yetkiniz yok.");
        }

        // Geçmiş tarihe randevu alınamaz
        if (request.AppointmentDate <= DateTime.UtcNow)
        {
            throw new InvalidOperationException("Geçmiş bir tarih veya saat için randevu oluşturulamaz.");
        }

        // Müsait slot kontrolü
        var dateOnly = request.AppointmentDate.Date;
        var availableSlots = await _vetService.GetAvailableSlotsAsync(request.VetId, dateOnly);

        var isSlotAvailable = availableSlots.Any(s => s.Time == request.AppointmentDate.TimeOfDay && s.IsAvailable);
        if (!isSlotAvailable)
        {
            throw new Exception("Seçilen saat hekimin takvimine göre müsait değil.");
        }

        var vet = await _vetRepository.GetByIdAsync(request.VetId);
        if (vet == null)
            throw new Exception("Hekim bulunamadı.");

        // Yarış (TOCTOU) koruması: kayıttan hemen önce aynı hekim+tarih+saat için
        // aktif (iptal edilmemiş) bir randevu oluşmuş mu son kez kontrol et.
        var sameDayAppointments = await _appointmentRepository.GetAppointmentsByVetAndDateAsync(request.VetId, dateOnly);
        if (sameDayAppointments.Any(a => a.AppointmentDate.TimeOfDay == request.AppointmentDate.TimeOfDay))
        {
            throw new InvalidOperationException("Bu saat az önce başka bir randevu tarafından alındı. Lütfen farklı bir saat seçin.");
        }

        var appointment = new Appointment
        {
            AnimalId = request.AnimalId,
            OwnerId = userId,
            VetId = request.VetId,
            ClinicId = vet.ClinicId,
            AppointmentDate = request.AppointmentDate,
            DurationMinutes = 30, // Default
            Status = "pending",
            Reason = InputSanitizer.Sanitize(request.Reason)
        };

        await _appointmentRepository.AddAsync(appointment);
        await _appointmentRepository.SaveChangesAsync();

        // Hekime "yeni randevu talebi" bildirimi
        var dateStr = appointment.AppointmentDate.ToString("dd.MM.yyyy HH:mm");
        await _notificationService.NotifyAsync(
            vet.UserId,
            "Yeni randevu talebi",
            $"{animal.Name} için {dateStr} tarihine yeni bir randevu talebi var.",
            "appointment_created",
            appointment.Id);

        return appointment.Id;
    }

    public async Task<bool> CancelAppointmentAsync(int id, int userId, string? reason)
    {
        var appointment = await _appointmentRepository.GetByIdAsync(id);
        if (appointment == null || appointment.OwnerId != userId)
        {
            return false;
        }

        // Merkezi kural: yalnız pending/confirmed iptal edilebilir ve randevuya
        // 2 saatten fazla süre kalmış olmalı (AppointmentStatusRules tek kaynak).
        AppointmentStatusRules.EnsureOwnerCancellable(
            appointment.Status, appointment.AppointmentDate, DateTime.UtcNow);

        var sanitizedReason = InputSanitizer.Sanitize(reason);
        appointment.Status = "cancelled";
        appointment.CancellationReason =
            string.IsNullOrWhiteSpace(sanitizedReason) ? null : sanitizedReason;
        _appointmentRepository.Update(appointment);
        await _appointmentRepository.SaveChangesAsync();

        // Hekime "randevu iptal edildi" bildirimi (gerekçe varsa eklenir)
        var vet = await _vetRepository.GetByIdAsync(appointment.VetId);
        if (vet != null)
        {
            var dateStr = appointment.AppointmentDate.ToString("dd.MM.yyyy HH:mm");
            var body = $"{dateStr} tarihli bir randevu hasta sahibi tarafından iptal edildi.";
            if (appointment.CancellationReason != null)
            {
                body += $" Gerekçe: {appointment.CancellationReason}";
            }

            await _notificationService.NotifyAsync(
                vet.UserId,
                "Randevu iptal edildi",
                body,
                "appointment_status",
                appointment.Id);
        }

        return true;
    }
}
