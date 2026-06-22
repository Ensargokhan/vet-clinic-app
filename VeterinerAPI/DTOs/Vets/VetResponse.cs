namespace VeterinerAPI.DTOs.Vets;

public class VetResponse
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Title { get; set; }
    public string? Specialty { get; set; }
    public string? ProfilePhoto { get; set; }
    public string? Bio { get; set; }
}
