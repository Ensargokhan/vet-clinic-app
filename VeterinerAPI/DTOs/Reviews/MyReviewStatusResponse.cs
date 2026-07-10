namespace VeterinerAPI.DTOs.Reviews;

/// <summary>
/// Arayüzün "Değerlendir" / "Değerlendirmeni Düzenle" butonunu tek çağrıyla
/// karar verebilmesi için kullanıcının bu klinikteki değerlendirme durumu.
/// </summary>
public class MyReviewStatusResponse
{
    /// <summary>Kullanıcı bu kliniğe yorum yazabilir mi? (owner + tamamlanmış randevu)</summary>
    public bool CanReview { get; set; }

    /// <summary>Bu klinikte tamamlanmış en az bir randevusu var mı?</summary>
    public bool HasCompletedAppointment { get; set; }

    /// <summary>Zaten yazdığı yorum (yoksa null → buton "Değerlendir").</summary>
    public ClinicReviewResponse? Review { get; set; }
}
