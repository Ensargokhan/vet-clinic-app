using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Vaccines;

public class VaccineRequest
{
    [Required(ErrorMessage = "Hayvan ID zorunludur.")]
    public int AnimalId { get; set; }

    [Required(ErrorMessage = "Aşı adı zorunludur.")]
    [MaxLength(200, ErrorMessage = "Aşı adı en fazla 200 karakter olabilir.")]
    public string VaccineName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Aşılanma tarihi zorunludur.")]
    public DateTime AdministeredDate { get; set; }

    public DateTime? NextDueDate { get; set; }

    [MaxLength(100, ErrorMessage = "Parti numarası en fazla 100 karakter olabilir.")]
    public string? BatchNumber { get; set; }

    [MaxLength(1000, ErrorMessage = "Notlar en fazla 1000 karakter olabilir.")]
    public string? Notes { get; set; }
}
