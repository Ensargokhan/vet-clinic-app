namespace VeterinerAPI.DTOs.Clinics;

public class UpcomingAppointmentDto
{
    public int Id { get; set; }
    public string AnimalName { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;
    public string VetName { get; set; } = string.Empty;
    public DateTime AppointmentDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Reason { get; set; }
}
