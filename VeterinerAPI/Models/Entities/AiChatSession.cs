using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

/// <summary>
/// Yapay zekâ ön muayene sohbet oturumu. Bir hasta sahibi (User), bir hayvan (Animal) için
/// çok turlu soru-cevap sohbeti başlatır; oturum bitince rapor üretilir.
/// </summary>
[Table("ai_chat_sessions")]
public class AiChatSession
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("user_id")]
    public int UserId { get; set; }

    [Column("animal_id")]
    public int AnimalId { get; set; }

    [Required]
    [MaxLength(20)]
    [Column("status")]
    public string Status { get; set; } = "active"; // active, completed

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("completed_at")]
    public DateTime? CompletedAt { get; set; }

    // Navigation properties
    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    [ForeignKey("AnimalId")]
    public Animal Animal { get; set; } = null!;

    public ICollection<AiChatMessage> Messages { get; set; } = new List<AiChatMessage>();
}
