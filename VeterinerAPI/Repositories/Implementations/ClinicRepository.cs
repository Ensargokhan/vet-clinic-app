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
            .Include(c => c.Reviews) // klinik detayında ortalama puan/adet için
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

    public async Task<(IEnumerable<Clinic> Items, int TotalCount)> SearchClinicsAsync(string? search, string? city, string? district, string? specialty, int page, int pageSize)
    {
        var query = _dbSet.Where(c => c.IsActive).AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(c =>
                c.Name.Contains(s) ||
                (c.City != null && c.City.Contains(s)) ||
                (c.District != null && c.District.Contains(s)) ||
                (c.Address != null && c.Address.Contains(s)));
        }

        if (!string.IsNullOrWhiteSpace(city))
        {
            var ct = city.Trim();
            query = query.Where(c => c.City == ct);
        }

        if (!string.IsNullOrWhiteSpace(district))
        {
            var dt = district.Trim();
            query = query.Where(c => c.District == dt);
        }

        if (!string.IsNullOrWhiteSpace(specialty))
        {
            var sp = specialty.Trim();
            query = query.Where(c => c.Vets.Any(v => v.IsActive && v.Specialty != null && v.Specialty == sp));
        }

        var totalCount = await query.CountAsync();

        var items = await query
            .Include(c => c.Vets)
            .Include(c => c.Reviews)
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, totalCount);
    }
}
