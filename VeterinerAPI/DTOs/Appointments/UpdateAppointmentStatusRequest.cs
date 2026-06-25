using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Appointments;

public class UpdateAppointmentStatusRequest
{
    [Required(ErrorMessage = "Durum alanı zorunludur.")]
    [RegularExpression("^(pending|confirmed|cancelled|completed|no_show)$", ErrorMessage = "Durum 'pending', 'confirmed', 'cancelled', 'completed' veya 'no_show' olmalıdır.")]
    public string Status { get; set; } = string.Empty;

    [MaxLength(1000, ErrorMessage = "Notlar en fazla 1000 karakter olabilir.")]
    public string? Notes { get; set; }
}
