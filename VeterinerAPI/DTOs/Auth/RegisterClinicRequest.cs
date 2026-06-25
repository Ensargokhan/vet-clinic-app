using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Auth;

public class RegisterClinicRequest
{
    // Yöneticinin (Admin) Bilgileri
    [Required]
    [MaxLength(100)]
    public string AdminFullName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    [MaxLength(150)]
    public string AdminEmail { get; set; } = string.Empty;

    [RegularExpression(@"^0?\d{10}$", ErrorMessage = "Geçerli bir telefon numarası giriniz (10-11 hane).")]
    [MaxLength(20)]
    public string? AdminPhone { get; set; }

    // Kliniğin Bilgileri
    [Required]
    [MaxLength(150)]
    public string ClinicName { get; set; } = string.Empty;

    [MaxLength(100)]
    public string? ClinicCity { get; set; }

    [MaxLength(100)]
    public string? ClinicDistrict { get; set; }

    [Required(ErrorMessage = "Klinik adresi zorunludur.")]
    [MaxLength(300, ErrorMessage = "Adres bilgisi en fazla 300 karakter olabilir.")]
    public string ClinicAddress { get; set; } = string.Empty;

    [RegularExpression(@"^0?\d{10}$", ErrorMessage = "Geçerli bir telefon numarası giriniz (10-11 hane).")]
    [MaxLength(20)]
    public string? ClinicPhone { get; set; }

    [EmailAddress]
    [MaxLength(150)]
    public string? ClinicEmail { get; set; }
}
