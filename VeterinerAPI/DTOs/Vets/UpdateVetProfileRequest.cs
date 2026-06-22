using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Vets;

public class UpdateVetProfileRequest
{
    [MaxLength(50, ErrorMessage = "Unvan en fazla 50 karakter olabilir.")]
    public string? Title { get; set; }

    [MaxLength(100, ErrorMessage = "Uzmanlık alanı en fazla 100 karakter olabilir.")]
    public string? Specialty { get; set; }

    [MaxLength(1000, ErrorMessage = "Biyografi en fazla 1000 karakter olabilir.")]
    public string? Bio { get; set; }

    [MaxLength(20, ErrorMessage = "Telefon numarası en fazla 20 karakter olabilir.")]
    public string? Phone { get; set; }
}
