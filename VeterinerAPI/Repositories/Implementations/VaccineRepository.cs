using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class VaccineRepository : Repository<Vaccine>, IVaccineRepository
{
    public VaccineRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Vaccine>> GetVaccinesByAnimalAsync(int animalId)
    {
        return await _dbSet
            .Include(v => v.Vet)
                .ThenInclude(v => v!.User) // Hekimin isim bilgisi User tablosunda
            .Where(v => v.AnimalId == animalId)
            .OrderByDescending(v => v.AdministeredDate)
            .ToListAsync();
    }
}
