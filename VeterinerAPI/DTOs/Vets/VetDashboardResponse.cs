namespace VeterinerAPI.DTOs.Vets;

public class VetDashboardResponse
{
    public int VetId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Title { get; set; }
    public string? Specialty { get; set; }
    public string ClinicName { get; set; } = string.Empty;
    public int TodayAppointmentCount { get; set; }
    public int PendingAppointmentCount { get; set; }
    public int TotalAppointmentCount { get; set; }
    public List<VetUpcomingAppointmentDto> UpcomingAppointments { get; set; } = new();
}

public class VetUpcomingAppointmentDto
{
    public int Id { get; set; }
    public string AnimalName { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;
    public DateTime AppointmentDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Reason { get; set; }
}
