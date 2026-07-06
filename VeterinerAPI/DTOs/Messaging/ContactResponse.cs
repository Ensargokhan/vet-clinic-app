namespace VeterinerAPI.DTOs.Messaging;

/// <summary>Yeni mesaj başlatırken seçilebilecek kişi (ortak randevusu olan hekim/owner).</summary>
public class ContactResponse
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Title { get; set; }
}
