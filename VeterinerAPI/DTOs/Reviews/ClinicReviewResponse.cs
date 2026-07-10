namespace VeterinerAPI.DTOs.Reviews;

public class ClinicReviewResponse
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public byte Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    /// <summary>Yorum, isteği yapan kullanıcıya mı ait? (düzenle/sil butonları için)</summary>
    public bool IsMine { get; set; }
}
