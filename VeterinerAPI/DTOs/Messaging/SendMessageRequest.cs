using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Messaging;

public class SendMessageRequest
{
    [Required(ErrorMessage = "Mesaj boş olamaz.")]
    [MaxLength(2000, ErrorMessage = "Mesaj en fazla 2000 karakter olabilir.")]
    public string Body { get; set; } = string.Empty;
}
