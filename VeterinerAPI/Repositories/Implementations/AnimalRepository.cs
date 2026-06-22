using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class AnimalRepository : Repository<Animal>, IAnimalRepository
{
    public AnimalRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Animal>> GetAnimalsByOwnerAsync(int ownerId)
    {
        return await _dbSet
            .Where(a => a.OwnerId == ownerId && a.IsActive)
            .ToListAsync();
    }

    public async Task<Animal?> GetAnimalWithOwnerAsync(int animalId)
    {
        return await _dbSet
            .Include(a => a.Owner)
            .FirstOrDefaultAsync(a => a.Id == animalId && a.IsActive);
    }
}
