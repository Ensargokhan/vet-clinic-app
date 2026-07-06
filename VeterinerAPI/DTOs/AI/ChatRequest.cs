using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.AI;

public class ChatRequest
{
    [Required(ErrorMessage = "Mesaj boş olamaz.")]
    [MaxLength(2000)]
    public string Message { get; set; } = string.Empty;
}
