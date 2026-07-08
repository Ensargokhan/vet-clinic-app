using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Vaccines;

public class VaccineRequest
{
    [Required(ErrorMessage = "Hayvan ID zorunludur.")]
    public int AnimalId { get; set; }

    [Required(ErrorMessage = "Aşı adı zorunludur.")]
    [MaxLength(150, ErrorMessage = "Aşı adı en fazla 150 karakter olabilir.")]
    public string VaccineName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Aşılanma tarihi zorunludur.")]
    public DateTime AdministeredDate { get; set; }

    public DateTime? NextDueDate { get; set; }

    [MaxLength(1000, ErrorMessage = "Notlar en fazla 1000 karakter olabilir.")]
    public string? Notes { get; set; }
}
