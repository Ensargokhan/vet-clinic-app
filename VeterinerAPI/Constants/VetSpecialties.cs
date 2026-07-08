namespace VeterinerAPI.Constants;

/// <summary>
/// Veteriner hekim uzmanlık alanlarının tek (kanonik) kaynağı.
/// Hem filtreleme hem hekim kaydı/güncelleme aynı listeyi kullanır.
/// </summary>
public static class VetSpecialties
{
    public static readonly string[] All =
    {
        "Büyükbaş Hayvan",
        "Cerrahi",
        "Dahiliye",
        "Dermatoloji",
        "Diş Hekimliği",
        "Egzotik Hayvanlar",
        "Genel Veteriner Hekimliği",
        "Kardiyoloji",
        "Küçükbaş Hayvan",
        "Nöroloji",
        "Oftalmoloji",
        "Onkoloji",
        "Ortopedi"
    };

    public static bool IsValid(string? value) =>
        !string.IsNullOrWhiteSpace(value) && All.Contains(value);
}
