using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Appointments;

/// <summary>
/// Hasta sahibinin randevu iptali isteği. Gerekçe isteğe bağlıdır;
/// doluysa hekim tarafında "İptal gerekçesi" olarak gösterilir.
/// </summary>
public class CancelAppointmentRequest
{
    [MaxLength(500)]
    public string? Reason { get; set; }
}
