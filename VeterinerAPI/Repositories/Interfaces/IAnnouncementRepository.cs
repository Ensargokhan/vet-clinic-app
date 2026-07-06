using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IAnnouncementRepository : IRepository<Announcement>
{
    Task<IEnumerable<Announcement>> GetActiveByClinicAsync(int clinicId);
}
