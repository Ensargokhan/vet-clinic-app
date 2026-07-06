using VeterinerAPI.DTOs.Announcements;
using VeterinerAPI.Helpers;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class AnnouncementService : IAnnouncementService
{
    private readonly IAnnouncementRepository _announcementRepository;
    private readonly IClinicRepository _clinicRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly INotificationService _notificationService;

    public AnnouncementService(
        IAnnouncementRepository announcementRepository,
        IClinicRepository clinicRepository,
        IAppointmentRepository appointmentRepository,
        INotificationService notificationService)
    {
        _announcementRepository = announcementRepository;
        _clinicRepository = clinicRepository;
        _appointmentRepository = appointmentRepository;
        _notificationService = notificationService;
    }

    public async Task<int> CreateAsync(int userId, string role, AnnouncementRequest request)
    {
        var clinic = await GetAdminClinicAsync(userId, role);

        var announcement = new Announcement
        {
            ClinicId = clinic.Id,
            Title = InputSanitizer.Sanitize(request.Title)!,
            Body = InputSanitizer.Sanitize(request.Body)!,
            IsActive = true
        };
        await _announcementRepository.AddAsync(announcement);
        await _announcementRepository.SaveChangesAsync();

        // Fan-out: klinikte (iptal olmayan) randevusu olan tüm sahiplere bildirim + push
        var ownerIds = await _appointmentRepository.GetDistinctOwnerIdsByClinicAsync(clinic.Id);
        foreach (var ownerId in ownerIds)
        {
            await _notificationService.NotifyAsync(
                ownerId,
                $"{clinic.Name} duyurusu",
                announcement.Title,
                "clinic_announcement",
                clinic.Id);
        }

        return announcement.Id;
    }

    public async Task<IEnumerable<AnnouncementResponse>> GetMyClinicAnnouncementsAsync(int userId, string role)
    {
        var clinic = await GetAdminClinicAsync(userId, role);
        var items = await _announcementRepository.GetActiveByClinicAsync(clinic.Id);
        return items.Select(Map).ToList();
    }

    public async Task<bool> DeleteAsync(int id, int userId, string role)
    {
        var clinic = await GetAdminClinicAsync(userId, role);

        var announcement = await _announcementRepository.GetByIdAsync(id);
        if (announcement == null || !announcement.IsActive) return false;
        if (announcement.ClinicId != clinic.Id)
            throw new UnauthorizedAccessException("Bu duyuruyu silme yetkiniz yok.");

        announcement.IsActive = false; // soft-delete
        _announcementRepository.Update(announcement);
        await _announcementRepository.SaveChangesAsync();
        return true;
    }

    public async Task<IEnumerable<AnnouncementResponse>> GetByClinicAsync(int clinicId)
    {
        var items = await _announcementRepository.GetActiveByClinicAsync(clinicId);
        return items.Select(Map).ToList();
    }

    private async Task<Clinic> GetAdminClinicAsync(int userId, string role)
    {
        if (role != "clinic_admin")
            throw new UnauthorizedAccessException("Bu işlem için yetkiniz yok.");

        var clinic = await _clinicRepository.GetClinicByAdminUserIdAsync(userId);
        if (clinic == null)
            throw new KeyNotFoundException("Size ait bir klinik bulunamadı.");
        return clinic;
    }

    private static AnnouncementResponse Map(Announcement a) => new()
    {
        Id = a.Id,
        ClinicId = a.ClinicId,
        Title = a.Title,
        Body = a.Body,
        CreatedAt = a.CreatedAt
    };
}
