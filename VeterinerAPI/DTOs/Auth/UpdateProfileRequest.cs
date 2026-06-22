using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Auth;

public class UpdateProfileRequest
{
    [Required(ErrorMessage = "Ad Soyad zorunludur.")]
    [MaxLength(100, ErrorMessage = "Ad Soyad en fazla 100 karakter olabilir.")]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(20, ErrorMessage = "Telefon numarası en fazla 20 karakter olabilir.")]
    public string? Phone { get; set; }
}
