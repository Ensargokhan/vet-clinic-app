namespace VeterinerAPI.DTOs.Reviews;

public class ClinicReviewSummaryResponse
{
    /// <summary>Ortalama puan; hiç yorum yoksa null (arayüz "Henüz değerlendirilmemiş" gösterir).</summary>
    public double? Rating { get; set; }

    public int ReviewCount { get; set; }

    /// <summary>Yıldız dağılımı: 1–5 → o puanı veren yorum sayısı.</summary>
    public Dictionary<int, int> Distribution { get; set; } = new();
}
