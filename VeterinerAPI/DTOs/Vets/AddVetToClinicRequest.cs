using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Vets;

public class AddVetToClinicRequest
{
    [Required(ErrorMessage = "Ad Soyad zorunludur.")]
    [MaxLength(100, ErrorMessage = "Ad Soyad en fazla 100 karakter olabilir.")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "E-posta adresi zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    [MaxLength(150, ErrorMessage = "E-posta adresi en fazla 150 karakter olabilir.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Şifre zorunludur.")]
    [MinLength(6, ErrorMessage = "Şifre en az 6 karakter olmalıdır.")]
    [MaxLength(100, ErrorMessage = "Şifre en fazla 100 karakter olabilir.")]
    public string Password { get; set; } = string.Empty;

    [RegularExpression(@"^0?\d{10}$", ErrorMessage = "Geçerli bir telefon numarası giriniz (10-11 hane).")]
    [MaxLength(20, ErrorMessage = "Telefon numarası en fazla 20 karakter olabilir.")]
    public string? Phone { get; set; }
    
    [MaxLength(50, ErrorMessage = "Unvan en fazla 50 karakter olabilir.")]
    public string? Title { get; set; }      // "Dr.", "Doç. Dr."

    [MaxLength(100, ErrorMessage = "Uzmanlık alanı en fazla 100 karakter olabilir.")]
    public string? Specialty { get; set; }  // "Cerrahi", "Dahiliye"

    [MaxLength(1000, ErrorMessage = "Biyografi en fazla 1000 karakter olabilir.")]
    public string? Bio { get; set; }
}
