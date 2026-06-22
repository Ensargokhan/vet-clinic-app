using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("vets")]
public class Vet
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("user_id")]
    public int UserId { get; set; }

    [Column("clinic_id")]
    public int ClinicId { get; set; }

    [MaxLength(50)]
    [Column("title")]
    public string? Title { get; set; } // "Dr.", "Doç.Dr." vb.

    [MaxLength(100)]
    [Column("specialty")]
    public string? Specialty { get; set; }

    [Column("bio")]
    public string? Bio { get; set; }

    [MaxLength(255)]
    [Column("profile_photo")]
    public string? ProfilePhoto { get; set; }

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    [ForeignKey("ClinicId")]
    public Clinic Clinic { get; set; } = null!;

    public ICollection<VetSchedule> Schedules { get; set; } = new List<VetSchedule>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
}
