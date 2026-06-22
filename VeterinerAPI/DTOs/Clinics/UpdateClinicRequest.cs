using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Clinics;

public class UpdateClinicRequest
{
    [MaxLength(150, ErrorMessage = "Klinik adı en fazla 150 karakter olabilir.")]
    public string? Name { get; set; }

    [MaxLength(20, ErrorMessage = "Telefon numarası en fazla 20 karakter olabilir.")]
    public string? Phone { get; set; }

    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    [MaxLength(150, ErrorMessage = "E-posta adresi en fazla 150 karakter olabilir.")]
    public string? Email { get; set; }

    [MaxLength(100, ErrorMessage = "Şehir bilgisi en fazla 100 karakter olabilir.")]
    public string? City { get; set; }

    [MaxLength(100, ErrorMessage = "İlçe bilgisi en fazla 100 karakter olabilir.")]
    public string? District { get; set; }

    [MaxLength(300, ErrorMessage = "Adres bilgisi en fazla 300 karakter olabilir.")]
    public string? Address { get; set; }

    [MaxLength(1000, ErrorMessage = "Açıklama en fazla 1000 karakter olabilir.")]
    public string? Description { get; set; }
}
