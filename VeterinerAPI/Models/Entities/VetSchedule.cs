using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("vet_schedules")]
public class VetSchedule
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("vet_id")]
    public int VetId { get; set; }

    [Column("day_of_week")]
    public byte DayOfWeek { get; set; } // 0=Pazartesi ... 6=Pazar

    [Required]
    [Column("start_time")]
    public TimeSpan StartTime { get; set; }

    [Required]
    [Column("end_time")]
    public TimeSpan EndTime { get; set; }

    [Column("slot_duration")]
    public int SlotDuration { get; set; } = 30; // dakika

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    // Navigation properties
    [ForeignKey("VetId")]
    public Vet Vet { get; set; } = null!;
}
