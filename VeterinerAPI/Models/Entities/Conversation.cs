using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

/// <summary>
/// Owner ↔ Hekim birebir sohbet başlığı. Bir owner (User) ile bir Vet arasında tek konuşma olur.
/// </summary>
[Table("conversations")]
public class Conversation
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    // Sohbetin sahip (owner) tarafı — User.Id
    [Column("owner_user_id")]
    public int OwnerUserId { get; set; }

    // Sohbetin hekim tarafı — Vet.Id
    [Column("vet_id")]
    public int VetId { get; set; }

    [Column("last_message_at")]
    public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

    [MaxLength(150)]
    [Column("last_message_preview")]
    public string? LastMessagePreview { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey("OwnerUserId")]
    public User OwnerUser { get; set; } = null!;

    [ForeignKey("VetId")]
    public Vet Vet { get; set; } = null!;

    public ICollection<Message> Messages { get; set; } = new List<Message>();
}
