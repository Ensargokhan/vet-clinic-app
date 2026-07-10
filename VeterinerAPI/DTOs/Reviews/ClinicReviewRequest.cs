using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Reviews;

public class ClinicReviewRequest
{
    [Required(ErrorMessage = "Puan zorunludur.")]
    [Range(1, 5, ErrorMessage = "Puan 1 ile 5 arasında olmalıdır.")]
    public byte Rating { get; set; }

    [MaxLength(1000, ErrorMessage = "Yorum en fazla 1000 karakter olabilir.")]
    public string? Comment { get; set; }
}
