using VeterinerAPI.DTOs.AI;

namespace VeterinerAPI.Services.Interfaces;

public interface IAiAssistantService
{
    /// <summary>Yeni ön muayene oturumu başlatır (sahiplik kontrolü). Açılış mesajı hardcode.</summary>
    Task<StartSessionResponse> StartSessionAsync(int userId, int animalId);

    /// <summary>Kullanıcı mesajını işler, Gemini'den assistant cevabını üretir ve döndürür.</summary>
    Task<ChatMessageResponse> SendMessageAsync(int userId, int sessionId, string message);

    /// <summary>Oturum sohbetini mevcut haliyle döndürür (yeniden açmak için).</summary>
    Task<IEnumerable<ChatMessageResponse>> GetSessionMessagesAsync(int userId, int sessionId);

    /// <summary>Transkriptten yapılandırılmış ön rapor üretir; oturumu 'completed' yapar.</summary>
    Task<AiReportResponse> FinalizeReportAsync(int userId, int sessionId);

    /// <summary>Raporu bir randevuya bağlar (rapor sahibi == randevu sahibi doğrulanır).</summary>
    Task AttachToAppointmentAsync(int userId, int reportId, int appointmentId);

    /// <summary>Bir randevuya bağlı raporu döndürür (owner veya ilgili hekim erişebilir).</summary>
    Task<AiReportResponse?> GetReportByAppointmentAsync(int userId, string role, int appointmentId);
}
