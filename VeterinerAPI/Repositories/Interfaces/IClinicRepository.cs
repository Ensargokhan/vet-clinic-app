using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IClinicRepository : IRepository<Clinic>
{
    Task<IEnumerable<Clinic>> GetActiveClinicsAsync();
    Task<Clinic?> GetClinicWithVetsAsync(int clinicId);
    Task<Clinic?> GetClinicByAdminUserIdAsync(int adminUserId);
    Task<Clinic?> GetClinicWithDetailsAsync(int clinicId);
    Task<(IEnumerable<Clinic> Items, int TotalCount)> SearchClinicsAsync(string? search, string? city, string? district, string? specialty, int page, int pageSize);
}
