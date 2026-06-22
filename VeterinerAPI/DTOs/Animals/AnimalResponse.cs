namespace VeterinerAPI.DTOs.Animals;

public class AnimalResponse
{
    public int Id { get; set; }
    public int OwnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Species { get; set; } = string.Empty;
    public string? Breed { get; set; }
    public string? Gender { get; set; }
    public DateTime? BirthDate { get; set; }
    public decimal? Weight { get; set; }
    public string? MicrochipNo { get; set; }
    public string? PhotoUrl { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}
