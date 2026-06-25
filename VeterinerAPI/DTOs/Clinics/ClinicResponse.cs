using VeterinerAPI.DTOs.Vets;

namespace VeterinerAPI.DTOs.Clinics;

public class ClinicResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public List<VetResponse>? Vets { get; set; }

    // Arama sonuç kartlarını zenginleştirmek için
    public List<string> Specialties { get; set; } = new();
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
}
