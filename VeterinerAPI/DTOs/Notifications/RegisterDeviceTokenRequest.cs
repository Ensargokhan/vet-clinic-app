using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Notifications;

public class RegisterDeviceTokenRequest
{
    [Required(ErrorMessage = "Token alanı zorunludur.")]
    [MaxLength(255)]
    public string Token { get; set; } = string.Empty;
}
