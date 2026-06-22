using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IVaccineRepository : IRepository<Vaccine>
{
    Task<IEnumerable<Vaccine>> GetVaccinesByAnimalAsync(int animalId);
}
