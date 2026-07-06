namespace VeterinerAPI.DTOs.Messaging;

public class MessageResponse
{
    public int Id { get; set; }
    public int ConversationId { get; set; }
    public int SenderUserId { get; set; }
    public string Body { get; set; } = string.Empty;
    public bool IsMine { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}
