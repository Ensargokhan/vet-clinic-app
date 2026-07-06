using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

/// <summary>
/// Bir AI ön muayene oturumundaki tek mesaj. Rol 'user' (hasta sahibi) veya 'assistant' (AI) olur.
/// Gemini'ye gönderilirken 'assistant' rolü 'model'e eşlenir.
/// </summary>
[Table("ai_chat_messages")]
public class AiChatMessage
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("session_id")]
    public int SessionId { get; set; }

    [Required]
    [MaxLength(20)]
    [Column("role")]
    public string Role { get; set; } = string.Empty; // user, assistant

    [Required]
    [Column("content")]
    public string Content { get; set; } = string.Empty;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey("SessionId")]
    public AiChatSession Session { get; set; } = null!;
}
