using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IAnimalRepository : IRepository<Animal>
{
    Task<IEnumerable<Animal>> GetAnimalsByOwnerAsync(int ownerId);
    Task<Animal?> GetAnimalWithOwnerAsync(int animalId);
}
