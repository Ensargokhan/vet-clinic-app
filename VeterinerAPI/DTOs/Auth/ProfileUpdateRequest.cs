using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Auth;

public class ProfileUpdateRequest
{
    [Required(ErrorMessage = "Ad Soyad zorunludur.")]
    [MaxLength(100, ErrorMessage = "Ad Soyad en fazla 100 karakter olabilir.")]
    public string? FullName { get; set; }

    [RegularExpression(@"^0?\d{10}$", ErrorMessage = "Geçerli bir telefon numarası giriniz (10-11 hane).")]
    [MaxLength(20, ErrorMessage = "Telefon numarası en fazla 20 karakter olabilir.")]
    public string? Phone { get; set; }

    [MaxLength(255, ErrorMessage = "Fotoğraf URL'si en fazla 255 karakter olabilir.")]
    public string? ProfilePhoto { get; set; }
}
