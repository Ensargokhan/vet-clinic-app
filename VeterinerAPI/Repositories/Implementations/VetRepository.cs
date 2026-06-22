using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class VetRepository : Repository<Vet>, IVetRepository
{
    public VetRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<Vet?> GetVetWithScheduleAsync(int vetId, byte dayOfWeek)
    {
        var vet = await _dbSet
            .Include(v => v.Schedules)
            .FirstOrDefaultAsync(v => v.Id == vetId && v.IsActive);

        if (vet != null && vet.Schedules != null)
        {
            vet.Schedules = vet.Schedules.Where(s => s.DayOfWeek == dayOfWeek && s.IsActive).ToList();
        }

        return vet;
    }

    public async Task<IEnumerable<VetSchedule>> GetVetSchedulesAsync(int vetId)
    {
        return await _context.VetSchedules
            .Where(s => s.VetId == vetId && s.IsActive)
            .OrderBy(s => s.DayOfWeek)
            .ToListAsync();
    }
}
