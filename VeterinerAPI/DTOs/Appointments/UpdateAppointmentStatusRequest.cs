using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Appointments;

public class UpdateAppointmentStatusRequest
{
    [Required(ErrorMessage = "Durum alanı zorunludur.")]
    [RegularExpression("^(pending|confirmed|cancelled|completed)$", ErrorMessage = "Durum 'pending', 'confirmed', 'cancelled' veya 'completed' olmalıdır.")]
    public string Status { get; set; } = string.Empty;

    [MaxLength(1000, ErrorMessage = "Notlar en fazla 1000 karakter olabilir.")]
    public string? Notes { get; set; }
}
