namespace VeterinerAPI.Services.Ai;

/// <summary>
/// Gemini REST API istemcisi. İki mod: (1) sohbet cevabı üretme, (2) yapılandırılmış rapor üretme.
/// </summary>
public interface IGeminiClient
{
    /// <summary>
    /// Verilen sistem talimatı + sohbet geçmişiyle bir sonraki assistant cevabını üretir.
    /// history: (role, content) — role DB değeriyle ('user'/'assistant'); 'assistant' Gemini'ye 'model' olarak gider.
    /// </summary>
    Task<string> GenerateReplyAsync(
        string systemInstruction,
        IEnumerable<(string role, string content)> history,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Sohbet transkriptinden JSON şemalı yapılandırılmış rapor üretir
    /// ({reportContent, symptomsSummary, urgencyLevel}).
    /// </summary>
    Task<GeminiReportResult> GenerateReportAsync(
        string systemInstruction,
        string transcript,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Finalize aşamasında Gemini'nin döndürdüğü yapılandırılmış rapor.
/// </summary>
public class GeminiReportResult
{
    public string ReportContent { get; set; } = string.Empty;
    public string SymptomsSummary { get; set; } = string.Empty;
    public string UrgencyLevel { get; set; } = "low"; // low, medium, high, emergency
}
