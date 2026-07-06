namespace VeterinerAPI.Constants;

/// <summary>
/// Yaygın evcil hayvan aşılarının kanonik listesi.
/// Frontend aşı ekleme formunda dropdown olarak sunulur; listede olmayan aşılar için
/// "Diğer" seçeneğiyle serbest metin girilebilir (yumuşak enforcement — sunucu reddetmez).
/// </summary>
public static class VaccineNames
{
    public static readonly string[] All =
    {
        "Kuduz",
        "Karma (DHPP)",
        "Karma (DHPPi)",
        "Bordetella",
        "Leptospiroz",
        "Coronavirus",
        "Feline Panlökopeni",
        "FVRCP (Karma Kedi)",
        "Feline Lösemi (FeLV)",
        "Feline Peritonit (FIP)"
    };

    public static bool IsValid(string? value) =>
        !string.IsNullOrWhiteSpace(value) && All.Contains(value);
}
