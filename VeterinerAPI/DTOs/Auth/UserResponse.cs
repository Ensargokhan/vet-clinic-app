namespace VeterinerAPI.DTOs.Auth;

public class UserResponse
{
    public int Id { get; set; }
    public string FirebaseUid { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public string? ProfilePhoto { get; set; }
    public DateTime CreatedAt { get; set; }
}
