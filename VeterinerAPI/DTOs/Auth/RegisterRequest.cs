using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Auth;

public class RegisterRequest
{
    [Required]
    public string FirebaseUid { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ad Soyad zorunludur.")]
    [MaxLength(100, ErrorMessage = "Ad Soyad en fazla 100 karakter olabilir.")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "E-posta adresi zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    [MaxLength(150, ErrorMessage = "E-posta adresi en fazla 150 karakter olabilir.")]
    public string Email { get; set; } = string.Empty;

    [MaxLength(20, ErrorMessage = "Telefon numarası en fazla 20 karakter olabilir.")]
    public string? Phone { get; set; }

    [Required]
    [RegularExpression("^(owner|vet|clinic_admin)$", ErrorMessage = "Geçersiz rol.")]
    public string Role { get; set; } = "owner"; // owner, vet, clinic_admin
}
