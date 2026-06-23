using VeterinerAPI.DTOs.Clinics;
using VeterinerAPI.DTOs.Vets;

namespace VeterinerAPI.Services.Interfaces;

public interface IClinicService
{
    Task<IEnumerable<ClinicResponse>> GetAllActiveClinicsAsync();
    Task<VeterinerAPI.DTOs.Common.PagedResponse<ClinicResponse>> SearchClinicsAsync(ClinicSearchRequest request);
    Task<ClinicDetailResponse?> GetClinicDetailsAsync(int clinicId);
    
    // Clinic Admin özel metotları
    Task<ClinicDashboardResponse?> GetClinicDashboardAsync(string firebaseUid);
    Task<ClinicDetailResponse?> GetMyClinicAsync(string firebaseUid);
    Task<ClinicDetailResponse?> UpdateMyClinicAsync(string firebaseUid, UpdateClinicRequest request);
    Task<object> AddVetToClinicAsync(string firebaseUid, AddVetToClinicRequest request);
    Task<object> RemoveVetFromClinicAsync(string firebaseUid, int vetId);
    Task<IEnumerable<object>> GetClinicAppointmentsAsync(string firebaseUid);
    Task<bool> UpdateClinicAppointmentStatusAsync(string firebaseUid, int appointmentId, string newStatus, string? notes);
    Task<string?> UpdateClinicLogoAsync(string firebaseUid, string logoUrl);
}
