using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IVetRepository : IRepository<Vet>
{
    Task<Vet?> GetVetWithScheduleAsync(int vetId, byte dayOfWeek);
    Task<IEnumerable<VetSchedule>> GetVetSchedulesAsync(int vetId);
}
