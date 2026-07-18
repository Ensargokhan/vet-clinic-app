namespace VeterinerAPI.Services;

/// <summary>
/// Randevu durum (status) geçişleri için tek kaynak. Hem hekim hem klinik personeli
/// aynı geçiş kurallarına tabidir. Geçersiz geçişlerde InvalidOperationException fırlatılır
/// (GlobalExceptionMiddleware bunu 400 BadRequest'e çevirir).
/// </summary>
public static class AppointmentStatusRules
{
    public const string Pending = "pending";
    public const string Confirmed = "confirmed";
    public const string Cancelled = "cancelled";
    public const string Completed = "completed";
    public const string NoShow = "no_show";
    public const string Expired = "expired";

    /// <summary>
    /// Hasta sahibi, randevu saatine bu süreden az kaldığında artık iptal edemez
    /// (hekimin programını korumak için). Tek kaynak: hem servis kuralı hem hata mesajı bunu kullanır.
    /// </summary>
    public static readonly TimeSpan OwnerCancellationCutoff = TimeSpan.FromHours(2);

    // Personel (hekim/klinik) tarafından bir durumdan geçilebilecek hedef durumlar.
    // Terminal durumlar (completed, cancelled, no_show, expired) listede yoktur → geçiş kapalı.
    private static readonly IReadOnlyDictionary<string, string[]> StaffTransitions =
        new Dictionary<string, string[]>
        {
            [Pending] = new[] { Confirmed, Cancelled },
            [Confirmed] = new[] { Completed, NoShow, Cancelled },
        };

    /// <summary>
    /// Personelin (hekim/klinik) gönderebileceği geçerli durum değerleri.
    /// 'expired' yalnızca arka plan servisi tarafından set edilir; kullanıcı gönderemez.
    /// </summary>
    public static bool IsAssignableByStaff(string status) =>
        status is Confirmed or Cancelled or Completed or NoShow or Pending;

    /// <summary>
    /// from → to geçişi personel için geçerli mi?
    /// </summary>
    public static bool CanTransition(string from, string to)
    {
        if (string.Equals(from, to, StringComparison.OrdinalIgnoreCase))
            return false; // aynı duruma "geçiş" anlamsız

        return StaffTransitions.TryGetValue(from, out var allowed) &&
               allowed.Contains(to, StringComparer.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Geçiş geçersizse anlamlı mesajla InvalidOperationException fırlatır.
    /// </summary>
    public static void EnsureTransition(string from, string to)
    {
        if (!IsAssignableByStaff(to))
            throw new InvalidOperationException($"'{to}' geçerli bir randevu durumu değil.");

        if (CanTransition(from, to))
            return;

        var fromLabel = ToTurkish(from);
        var toLabel = ToTurkish(to);

        // Terminal durumdan çıkış denemesi için daha açıklayıcı mesaj
        if (!StaffTransitions.ContainsKey(from))
            throw new InvalidOperationException(
                $"'{fromLabel}' durumundaki bir randevu artık güncellenemez.");

        throw new InvalidOperationException(
            $"Randevu '{fromLabel}' durumundan '{toLabel}' durumuna geçirilemez.");
    }

    /// <summary>
    /// Hasta sahibinin randevu iptali için tek kaynak kural: yalnız 'pending'/'confirmed'
    /// iptal edilebilir (merkezi geçiş tablosuyla aynı) ve randevu saatine
    /// OwnerCancellationCutoff'tan fazla süre kalmış olmalıdır.
    /// Kural ihlalinde InvalidOperationException fırlatır (→ 400).
    /// </summary>
    public static void EnsureOwnerCancellable(string status, DateTime appointmentDate, DateTime now)
    {
        if (!CanTransition(status, Cancelled))
        {
            if (string.Equals(status, Cancelled, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Bu randevu zaten iptal edilmiş.");

            throw new InvalidOperationException(
                $"'{ToTurkish(status)}' durumundaki bir randevu iptal edilemez.");
        }

        if (appointmentDate <= now + OwnerCancellationCutoff)
            throw new InvalidOperationException(
                $"Randevu saatine {(int)OwnerCancellationCutoff.TotalHours} saatten az kaldığı için iptal edilemez. Lütfen kliniği arayınız.");
    }

    /// <summary>Durumun kullanıcıya gösterilecek Türkçe etiketi.</summary>
    public static string ToTurkishLabel(string status) => ToTurkish(status);

    private static string ToTurkish(string status) => status switch
    {
        Pending => "Bekliyor",
        Confirmed => "Onaylandı",
        Cancelled => "İptal Edildi",
        Completed => "Tamamlandı",
        NoShow => "Gelmedi",
        Expired => "Süresi Doldu",
        _ => status
    };
}
