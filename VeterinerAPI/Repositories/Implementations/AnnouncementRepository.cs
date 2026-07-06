using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class AnnouncementRepository : Repository<Announcement>, IAnnouncementRepository
{
    public AnnouncementRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Announcement>> GetActiveByClinicAsync(int clinicId)
    {
        return await _dbSet
            .Where(a => a.ClinicId == clinicId && a.IsActive)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync();
    }
}
