namespace VeterinerAPI.DTOs.Vaccines;

public class VaccineResponse
{
    public int Id { get; set; }
    public int AnimalId { get; set; }
    public int? VetId { get; set; }
    public string? VetName { get; set; }
    public string VaccineName { get; set; } = string.Empty;
    public DateTime AdministeredDate { get; set; }
    public DateTime? NextDueDate { get; set; }
    public string? BatchNumber { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}
