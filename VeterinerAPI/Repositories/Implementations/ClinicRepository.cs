using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class ClinicRepository : Repository<Clinic>, IClinicRepository
{
    public ClinicRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Clinic>> GetActiveClinicsAsync()
    {
        return await _dbSet.Where(c => c.IsActive).ToListAsync();
    }

    public async Task<Clinic?> GetClinicWithVetsAsync(int clinicId)
    {
        var clinic = await _dbSet
            .Include(c => c.Vets)
                .ThenInclude(v => v.User)
            .FirstOrDefaultAsync(c => c.Id == clinicId && c.IsActive);

        // Do not mutate tracked lists! Let the caller filter active vets if needed.

        return clinic;
    }

    public async Task<Clinic?> GetClinicByAdminUserIdAsync(int adminUserId)
    {
        var clinic = await _dbSet
            .Include(c => c.AdminUser)
            .Include(c => c.Vets)
                .ThenInclude(v => v.User)
            .FirstOrDefaultAsync(c => c.AdminUserId == adminUserId && c.IsActive);

        // Do not mutate tracked lists! Let the caller filter active vets if needed.

        return clinic;
    }

    public async Task<Clinic?> GetClinicWithDetailsAsync(int clinicId)
    {
        var clinic = await _dbSet
            .Include(c => c.AdminUser)
            .Include(c => c.Vets)
                .ThenInclude(v => v.User)
            .Include(c => c.Appointments)
                .ThenInclude(a => a.Animal)
            .Include(c => c.Appointments)
                .ThenInclude(a => a.Owner)
            .FirstOrDefaultAsync(c => c.Id == clinicId && c.IsActive);

        // Do not mutate tracked lists! Let the caller filter active vets/appointments if needed.

        return clinic;
    }

    public async Task<(IEnumerable<Clinic> Items, int TotalCount)> SearchClinicsAsync(string? search, string? city, string? district, int page, int pageSize)
    {
        var query = _dbSet.Where(c => c.IsActive).AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(c => c.Name.Contains(search));

        if (!string.IsNullOrWhiteSpace(city))
            query = query.Where(c => c.City == city);

        if (!string.IsNullOrWhiteSpace(district))
            query = query.Where(c => c.District == district);

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, totalCount);
    }
}
