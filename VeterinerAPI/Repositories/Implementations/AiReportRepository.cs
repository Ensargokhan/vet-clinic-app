using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class AiReportRepository : Repository<AiReport>, IAiReportRepository
{
    public AiReportRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<AiReport?> GetByAppointmentAsync(int appointmentId)
    {
        return await _dbSet
            .Where(r => r.AppointmentId == appointmentId)
            .OrderByDescending(r => r.CreatedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<IEnumerable<AiReport>> GetByAnimalAsync(int animalId)
    {
        return await _dbSet
            .Where(r => r.AnimalId == animalId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();
    }
}
