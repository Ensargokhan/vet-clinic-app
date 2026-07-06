namespace VeterinerAPI.DTOs.AI;

public class StartSessionResponse
{
    public int SessionId { get; set; }
    public ChatMessageResponse Message { get; set; } = new();
}
