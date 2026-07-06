namespace VeterinerAPI.DTOs.AI;

public class ChatMessageResponse
{
    public int Id { get; set; }
    public string Role { get; set; } = string.Empty; // user, assistant
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
