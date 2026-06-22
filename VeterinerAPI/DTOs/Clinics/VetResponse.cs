namespace VeterinerAPI.DTOs.Clinics;

public class OldVetResponse
{
    public int Id { get; set; }
    public int ClinicId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Title { get; set; }
    public string? Specialty { get; set; }
    public string? Bio { get; set; }
    public string? ProfilePhoto { get; set; }
}
