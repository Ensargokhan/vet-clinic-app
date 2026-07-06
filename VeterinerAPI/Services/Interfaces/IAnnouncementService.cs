using VeterinerAPI.DTOs.Announcements;

namespace VeterinerAPI.Services.Interfaces;

public interface IAnnouncementService
{
    /// <summary>Klinik duyurusu oluşturur ve klinikte randevusu olan sahiplere bildirim yollar. Duyuru id döner.</summary>
    Task<int> CreateAsync(int userId, string role, AnnouncementRequest request);

    Task<IEnumerable<AnnouncementResponse>> GetMyClinicAnnouncementsAsync(int userId, string role);

    Task<bool> DeleteAsync(int id, int userId, string role);

    /// <summary>Bir kliniğin aktif duyuruları (owner görünümü).</summary>
    Task<IEnumerable<AnnouncementResponse>> GetByClinicAsync(int clinicId);
}
