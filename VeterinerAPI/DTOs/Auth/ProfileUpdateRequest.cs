namespace VeterinerAPI.DTOs.Auth;

public class ProfileUpdateRequest
{
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public string? ProfilePhoto { get; set; }
}
