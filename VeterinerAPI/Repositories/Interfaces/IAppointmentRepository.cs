using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IAppointmentRepository : IRepository<Appointment>
{
    Task<IEnumerable<Appointment>> GetAppointmentsByUserAsync(int userId);
    Task<IEnumerable<Appointment>> GetAppointmentsByVetAndDateAsync(int vetId, DateTime date);
    Task<Appointment?> GetAppointmentWithDetailsAsync(int appointmentId);
    Task<IEnumerable<Appointment>> GetAppointmentsByClinicIdAsync(int clinicId);
    Task<int> GetTodayAppointmentCountByClinicAsync(int clinicId);
    Task<int> GetPendingAppointmentCountByClinicAsync(int clinicId);
    Task<IEnumerable<Appointment>> GetAppointmentsByVetIdAsync(int vetId);

    // Klinik duyurusu kitlesi: klinikte iptal olmayan randevusu olan farklı sahipler
    Task<IEnumerable<int>> GetDistinctOwnerIdsByClinicAsync(int clinicId);

    // Mesajlaşma kişi listesi (ortak randevu şartı)
    Task<IEnumerable<Vet>> GetMessagableVetsForOwnerAsync(int ownerUserId);
    Task<IEnumerable<User>> GetMessagableOwnersForVetAsync(int vetId);
}
