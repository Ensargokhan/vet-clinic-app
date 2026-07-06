namespace VeterinerAPI.DTOs.Announcements;

public class AnnouncementResponse
{
    public int Id { get; set; }
    public int ClinicId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
