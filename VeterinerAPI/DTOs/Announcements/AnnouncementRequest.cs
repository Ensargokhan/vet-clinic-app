using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Announcements;

public class AnnouncementRequest
{
    [Required(ErrorMessage = "Başlık zorunludur.")]
    [MaxLength(150, ErrorMessage = "Başlık en fazla 150 karakter olabilir.")]
    public string Title { get; set; } = string.Empty;

    [Required(ErrorMessage = "İçerik zorunludur.")]
    [MaxLength(1000, ErrorMessage = "İçerik en fazla 1000 karakter olabilir.")]
    public string Body { get; set; } = string.Empty;
}
