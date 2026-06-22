using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Animals;

public class AnimalRequest
{
    [Required(ErrorMessage = "Hayvan adı zorunludur.")]
    [MaxLength(100, ErrorMessage = "Hayvan adı en fazla 100 karakter olabilir.")]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Tür bilgisi zorunludur.")]
    [MaxLength(50, ErrorMessage = "Tür bilgisi en fazla 50 karakter olabilir.")]
    public string Species { get; set; } = string.Empty; // dog, cat, bird, rabbit, other

    [MaxLength(100, ErrorMessage = "Irk bilgisi en fazla 100 karakter olabilir.")]
    public string? Breed { get; set; }

    [MaxLength(10, ErrorMessage = "Cinsiyet bilgisi en fazla 10 karakter olabilir.")]
    [RegularExpression("^(male|female|unknown)$", ErrorMessage = "Cinsiyet 'male', 'female' veya 'unknown' olmalıdır.")]
    public string? Gender { get; set; } // male, female, unknown

    public DateTime? BirthDate { get; set; }
    public decimal? Weight { get; set; }

    [MaxLength(50, ErrorMessage = "Mikroçip numarası en fazla 50 karakter olabilir.")]
    public string? MicrochipNo { get; set; }

    [MaxLength(500, ErrorMessage = "Fotoğraf URL'si en fazla 500 karakter olabilir.")]
    public string? PhotoUrl { get; set; }

    [MaxLength(1000, ErrorMessage = "Notlar en fazla 1000 karakter olabilir.")]
    public string? Notes { get; set; }
}
