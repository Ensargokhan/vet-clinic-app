using VeterinerAPI.DTOs.Animals;

namespace VeterinerAPI.Services.Interfaces;

public interface IAnimalService
{
    Task<IEnumerable<AnimalResponse>> GetAnimalsByOwnerAsync(int ownerId);
    Task<AnimalResponse?> GetAnimalByIdAsync(int id, int userId, string userRole);
    Task<int> CreateAnimalAsync(AnimalRequest request, int ownerId);
    Task<bool> UpdateAnimalAsync(int id, AnimalRequest request, int userId, string userRole);
    Task<bool> DeleteAnimalAsync(int id, int userId, string userRole);
}
