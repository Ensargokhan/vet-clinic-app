using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("notifications")]
public class Notification
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("user_id")]
    public int UserId { get; set; }

    [Required]
    [MaxLength(150)]
    [Column("title")]
    public string Title { get; set; } = string.Empty;

    [Required]
    [MaxLength(500)]
    [Column("body")]
    public string Body { get; set; } = string.Empty;

    // Bildirim türü (ör. appointment_created, appointment_status). Frontend yönlendirmesi için.
    [Required]
    [MaxLength(50)]
    [Column("type")]
    public string Type { get; set; } = string.Empty;

    // İlişkili kaydın id'si (ör. appointmentId). Tıklamada ilgili ekrana gitmek için.
    [Column("related_id")]
    public int? RelatedId { get; set; }

    [Column("is_read")]
    public bool IsRead { get; set; } = false;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey("UserId")]
    public User User { get; set; } = null!;
}
