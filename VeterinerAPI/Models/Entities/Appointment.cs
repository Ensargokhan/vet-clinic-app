using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("appointments")]
public class Appointment
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("animal_id")]
    public int AnimalId { get; set; }

    [Column("owner_id")]
    public int OwnerId { get; set; }

    [Column("vet_id")]
    public int VetId { get; set; }

    [Column("clinic_id")]
    public int ClinicId { get; set; }

    [Required]
    [Column("appointment_date")]
    public DateTime AppointmentDate { get; set; }

    [Column("duration_minutes")]
    public int DurationMinutes { get; set; } = 30;

    [Required]
    [MaxLength(20)]
    [Column("status")]
    public string Status { get; set; } = "pending"; // pending, confirmed, cancelled, completed

    [Column("reason")]
    public string? Reason { get; set; }

    [Column("notes")]
    public string? Notes { get; set; } // hekim notları

    // Randevu hatırlatması gönderildi mi? (AppointmentReminderWorker tekrar göndermesin)
    [Column("reminder_sent")]
    public bool ReminderSent { get; set; } = false;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    [ForeignKey("AnimalId")]
    public Animal Animal { get; set; } = null!;

    [ForeignKey("OwnerId")]
    public User Owner { get; set; } = null!;

    [ForeignKey("VetId")]
    public Vet Vet { get; set; } = null!;

    [ForeignKey("ClinicId")]
    public Clinic Clinic { get; set; } = null!;
}
