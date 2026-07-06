using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IAiReportRepository : IRepository<AiReport>
{
    Task<AiReport?> GetByAppointmentAsync(int appointmentId);
    Task<IEnumerable<AiReport>> GetByAnimalAsync(int animalId);
}
