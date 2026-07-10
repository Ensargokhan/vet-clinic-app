using VeterinerAPI.DTOs.Common;
using VeterinerAPI.DTOs.Reviews;

namespace VeterinerAPI.Services.Interfaces;

public interface IClinicReviewService
{
    /// <summary>
    /// Yorumu oluşturur veya mevcut yorumu günceller (kullanıcı+klinik başına tek yorum).
    /// Yalnız o klinikte tamamlanmış randevusu olan hasta sahibi çağırabilir.
    /// </summary>
    Task<int> CreateOrUpdateAsync(int userId, string role, int clinicId, ClinicReviewRequest request);

    /// <summary>Kullanıcının kendi yorumunu siler.</summary>
    Task<bool> DeleteAsync(int userId, int clinicId);

    /// <summary>Kliniğin görünür yorumları (sayfalı).</summary>
    Task<PagedResponse<ClinicReviewResponse>> GetByClinicAsync(int clinicId, int userId, int page, int pageSize);

    /// <summary>Ortalama puan, yorum sayısı ve yıldız dağılımı.</summary>
    Task<ClinicReviewSummaryResponse> GetSummaryAsync(int clinicId);

    /// <summary>Kullanıcının bu klinikteki değerlendirme durumu (buton mantığı için).</summary>
    Task<MyReviewStatusResponse> GetMyStatusAsync(int userId, string role, int clinicId);
}
