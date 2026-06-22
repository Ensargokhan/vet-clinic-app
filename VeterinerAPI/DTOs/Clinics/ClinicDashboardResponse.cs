namespace VeterinerAPI.DTOs.Clinics;

public class ClinicDashboardResponse
{
    public int ClinicId { get; set; }
    public string ClinicName { get; set; } = string.Empty;
    public string AdminName { get; set; } = string.Empty;

    // İstatistikler
    public int TodayAppointmentCount { get; set; }
    public int PendingAppointmentCount { get; set; }
    public int ActiveVetCount { get; set; }

    // Yaklaşan Randevular (İlk 5)
    public List<UpcomingAppointmentDto> UpcomingAppointments { get; set; } = new();
}
