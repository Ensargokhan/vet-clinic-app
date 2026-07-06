using VeterinerAPI.DTOs.Vaccines;

namespace VeterinerAPI.Services.Interfaces;

public interface IVaccineService
{
    Task<IEnumerable<VaccineResponse>> GetVaccinesByAnimalAsync(int animalId, int userId, string userRole);
    Task<int> CreateVaccineAsync(VaccineRequest request, int userId, string userRole);
    Task<bool> UpdateVaccineAsync(int id, VaccineRequest request, string userRole);
    Task<bool> DeleteVaccineAsync(int id, string userRole);
}
