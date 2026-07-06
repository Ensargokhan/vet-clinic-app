using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

/// <summary>
/// Klinik duyurusu: klinik_admin yayınlar, klinikte randevusu olan sahiplere bildirim gider.
/// Tek yönlüdür (owner cevap veremez).
/// </summary>
[Table("announcements")]
public class Announcement
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("clinic_id")]
    public int ClinicId { get; set; }

    [Required]
    [MaxLength(150)]
    [Column("title")]
    public string Title { get; set; } = string.Empty;

    [Required]
    [MaxLength(1000)]
    [Column("body")]
    public string Body { get; set; } = string.Empty;

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey("ClinicId")]
    public Clinic Clinic { get; set; } = null!;
}
