using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("clinic_reviews")]
public class ClinicReview
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("clinic_id")]
    public int ClinicId { get; set; }

    [Column("user_id")]
    public int UserId { get; set; }

    [Required]
    [Column("rating")]
    public byte Rating { get; set; } // 1–5

    [Column("comment")]
    public string? Comment { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Yorum düzenlendiğinde AppDbContext.UpdateTimestamps() tarafından otomatik set edilir.
    [Column("updated_at")]
    public DateTime? UpdatedAt { get; set; }

    [Column("is_visible")]
    public bool IsVisible { get; set; } = true;

    // Navigation properties
    [ForeignKey("ClinicId")]
    public Clinic Clinic { get; set; } = null!;

    [ForeignKey("UserId")]
    public User User { get; set; } = null!;
}
