namespace VeterinerAPI.DTOs.Messaging;

public class ConversationResponse
{
    public int Id { get; set; }
    public string PeerName { get; set; } = string.Empty;
    public string? PeerTitle { get; set; }
    public string? LastMessagePreview { get; set; }
    public DateTime LastMessageAt { get; set; }
    public int UnreadCount { get; set; }
}
