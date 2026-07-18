using VeterinerAPI.DTOs.Appointments;

namespace VeterinerAPI.Services.Interfaces;

public interface IAppointmentService
{
    Task<IEnumerable<AppointmentResponse>> GetAppointmentsByUserAsync(int userId);
    Task<AppointmentResponse?> GetAppointmentByIdAsync(int id, int userId);
    Task<int> CreateAppointmentAsync(AppointmentRequest request, int userId);
    Task<bool> CancelAppointmentAsync(int id, int userId, string? reason);
}
