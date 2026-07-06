using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

/// <summary>
/// Bir konuşmadaki tek mesaj. Gönderen owner veya hekim (User) olabilir; alıcı diğer taraftır.
/// </summary>
[Table("messages")]
public class Message
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("conversation_id")]
    public int ConversationId { get; set; }

    [Column("sender_user_id")]
    public int SenderUserId { get; set; }

    [Required]
    [MaxLength(2000)]
    [Column("body")]
    public string Body { get; set; } = string.Empty;

    [Column("is_read")]
    public bool IsRead { get; set; } = false;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey("ConversationId")]
    public Conversation Conversation { get; set; } = null!;

    [ForeignKey("SenderUserId")]
    public User Sender { get; set; } = null!;
}
