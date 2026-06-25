namespace VeterinerAPI.Constants;

/// <summary>
/// Veteriner hekim uzmanlık alanlarının tek (kanonik) kaynağı.
/// Hem filtreleme hem hekim kaydı/güncelleme aynı listeyi kullanır.
/// </summary>
public static class VetSpecialties
{
    public static readonly string[] All =
    {
        "Genel Veteriner Hekimliği",
        "Ortopedi",
        "Kardiyoloji",
        "Dermatoloji",
        "Oftalmoloji",
        "Nöroloji",
        "Onkoloji",
        "Dahiliye",
        "Cerrahi",
        "Diş Hekimliği",
        "Egzotik Hayvanlar",
        "Büyükbaş Hayvan",
        "Küçükbaş Hayvan"
    };

    public static bool IsValid(string? value) =>
        !string.IsNullOrWhiteSpace(value) && All.Contains(value);
}
