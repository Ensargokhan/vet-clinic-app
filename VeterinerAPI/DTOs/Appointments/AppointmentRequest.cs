using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Appointments;

public class AppointmentRequest
{
    [Required(ErrorMessage = "Hayvan ID zorunludur.")]
    public int AnimalId { get; set; }

    [Required(ErrorMessage = "Hekim ID zorunludur.")]
    public int VetId { get; set; }

    [Required(ErrorMessage = "Klinik ID zorunludur.")]
    public int ClinicId { get; set; }

    [Required(ErrorMessage = "Randevu tarihi zorunludur.")]
    public DateTime AppointmentDate { get; set; }

    [MaxLength(500, ErrorMessage = "Randevu sebebi en fazla 500 karakter olabilir.")]
    public string? Reason { get; set; }
}
