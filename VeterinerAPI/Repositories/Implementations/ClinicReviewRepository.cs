using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class ClinicReviewRepository : Repository<ClinicReview>, IClinicReviewRepository
{
    public ClinicReviewRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<ClinicReview?> GetByClinicAndUserAsync(int clinicId, int userId)
    {
        return await _dbSet
            .FirstOrDefaultAsync(r => r.ClinicId == clinicId && r.UserId == userId);
    }

    public async Task<(IEnumerable<ClinicReview> Items, int TotalCount)> GetByClinicPagedAsync(
        int clinicId, int page, int pageSize)
    {
        var query = _dbSet.Where(r => r.ClinicId == clinicId && r.IsVisible);

        var totalCount = await query.CountAsync();

        var items = await query
            .Include(r => r.User) // yorum sahibinin adı için
            .OrderByDescending(r => r.CreatedAt)
            .ThenByDescending(r => r.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, totalCount);
    }

    public async Task<Dictionary<int, int>> GetRatingDistributionAsync(int clinicId)
    {
        var grouped = await _dbSet
            .Where(r => r.ClinicId == clinicId && r.IsVisible)
            .GroupBy(r => r.Rating)
            .Select(g => new { Rating = g.Key, Count = g.Count() })
            .ToListAsync();

        // 1–5 arası tüm yıldızlar için anahtar bulunsun (veri yoksa 0)
        var distribution = new Dictionary<int, int>();
        for (var star = 1; star <= 5; star++) distribution[star] = 0;
        foreach (var g in grouped) distribution[g.Rating] = g.Count;

        return distribution;
    }
}
