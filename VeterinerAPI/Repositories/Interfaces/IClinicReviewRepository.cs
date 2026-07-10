using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IClinicReviewRepository : IRepository<ClinicReview>
{
    /// <summary>Bir kullanıcının bir kliniğe yazdığı tek yorum (yoksa null).</summary>
    Task<ClinicReview?> GetByClinicAndUserAsync(int clinicId, int userId);

    /// <summary>Kliniğin görünür yorumları, en yeniden eskiye, sayfalı.</summary>
    Task<(IEnumerable<ClinicReview> Items, int TotalCount)> GetByClinicPagedAsync(int clinicId, int page, int pageSize);

    /// <summary>Yıldız dağılımı: puan (1–5) → o puanı veren yorum sayısı.</summary>
    Task<Dictionary<int, int>> GetRatingDistributionAsync(int clinicId);
}
