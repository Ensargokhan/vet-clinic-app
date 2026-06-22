using VeterinerAPI.DTOs.Vets;

namespace VeterinerAPI.Services.Interfaces;

public interface IVetService
{
    Task<IEnumerable<VetScheduleResponse>> GetVetScheduleAsync(int vetId);
    Task<IEnumerable<AvailableSlotResponse>> GetAvailableSlotsAsync(int vetId, DateTime date);

    // Hekim Paneli İçin Yeni Metotlar
    Task<VetDashboardResponse?> GetVetDashboardAsync(string firebaseUid);
    Task<IEnumerable<VeterinerAPI.DTOs.Appointments.AppointmentResponse>> GetVetAppointmentsAsync(string firebaseUid);
    Task<bool> UpdateAppointmentStatusAsync(string firebaseUid, int appointmentId, string newStatus, string? notes);
    Task<IEnumerable<VetScheduleResponse>> GetMyScheduleAsync(string firebaseUid);
    Task<bool> UpdateMyScheduleAsync(string firebaseUid, List<UpdateVetScheduleRequest> schedules);
    Task<VetResponse?> GetVetProfileAsync(string firebaseUid);
    Task<VetResponse?> UpdateVetProfileAsync(string firebaseUid, UpdateVetProfileRequest request);
}
