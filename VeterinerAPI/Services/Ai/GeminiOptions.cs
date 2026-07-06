namespace VeterinerAPI.Services.Ai;

/// <summary>
/// Gemini API yapılandırması. appsettings.json içindeki "GeminiAI" bölümünden bağlanır.
/// ApiKey gitignored appsettings.json'da tutulur (örnek şablonda boştur).
/// </summary>
public class GeminiOptions
{
    public string ApiKey { get; set; } = string.Empty;
    public string Model { get; set; } = "gemini-2.5-flash";
    public string BaseUrl { get; set; } = "https://generativelanguage.googleapis.com";
}
