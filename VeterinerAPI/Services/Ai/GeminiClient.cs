using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace VeterinerAPI.Services.Ai;

/// <summary>
/// Gemini REST API'sini HttpClient ile çağıran istemci (dış SDK yok).
/// Endpoint: POST {BaseUrl}/v1beta/models/{Model}:generateContent?key={ApiKey}
/// </summary>
public class GeminiClient : IGeminiClient
{
    private readonly HttpClient _httpClient;
    private readonly GeminiOptions _options;
    private readonly ILogger<GeminiClient> _logger;

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
    };

    public GeminiClient(HttpClient httpClient, IOptions<GeminiOptions> options, ILogger<GeminiClient> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<string> GenerateReplyAsync(
        string systemInstruction,
        IEnumerable<(string role, string content)> history,
        CancellationToken cancellationToken = default)
    {
        var contents = history.Select(h => new
        {
            role = MapRole(h.role),
            parts = new[] { new { text = h.content } }
        }).ToArray();

        var body = new
        {
            systemInstruction = new { parts = new[] { new { text = systemInstruction } } },
            contents,
            generationConfig = new { temperature = 0.4 }
        };

        var text = await SendAsync(body, cancellationToken);
        if (string.IsNullOrWhiteSpace(text))
            throw new InvalidOperationException("AI şu an yanıt veremiyor. Lütfen daha sonra tekrar deneyin.");
        return text.Trim();
    }

    public async Task<GeminiReportResult> GenerateReportAsync(
        string systemInstruction,
        string transcript,
        CancellationToken cancellationToken = default)
    {
        var body = new
        {
            systemInstruction = new { parts = new[] { new { text = systemInstruction } } },
            contents = new[]
            {
                new { role = "user", parts = new[] { new { text = transcript } } }
            },
            generationConfig = new
            {
                temperature = 0.2,
                responseMimeType = "application/json",
                responseSchema = new
                {
                    type = "OBJECT",
                    properties = new
                    {
                        reportContent = new { type = "STRING" },
                        symptomsSummary = new { type = "STRING" },
                        urgencyLevel = new
                        {
                            type = "STRING",
                            @enum = new[] { "low", "medium", "high", "emergency" }
                        }
                    },
                    required = new[] { "reportContent", "symptomsSummary", "urgencyLevel" }
                }
            }
        };

        var text = await SendAsync(body, cancellationToken);
        if (string.IsNullOrWhiteSpace(text))
            throw new InvalidOperationException("AI raporu şu an üretilemiyor. Lütfen daha sonra tekrar deneyin.");

        try
        {
            var result = JsonSerializer.Deserialize<GeminiReportResult>(text, JsonOpts);
            if (result == null || string.IsNullOrWhiteSpace(result.ReportContent))
                throw new InvalidOperationException("AI raporu okunamadı.");

            // Aciliyet değerini bilinen kümeyle normalize et (beklenmedik değer gelirse 'medium')
            result.UrgencyLevel = NormalizeUrgency(result.UrgencyLevel);
            return result;
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Gemini rapor JSON parse hatası. Ham metin: {Text}", text);
            throw new InvalidOperationException("AI raporu okunamadı.");
        }
    }

    // ===== Yardımcılar =====

    private async Task<string?> SendAsync(object body, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            _logger.LogError("Gemini ApiKey yapılandırılmamış (appsettings 'GeminiAI:ApiKey').");
            throw new InvalidOperationException("AI servisi yapılandırılmamış.");
        }

        var url = $"{_options.BaseUrl.TrimEnd('/')}/v1beta/models/{_options.Model}:generateContent?key={_options.ApiKey}";
        var json = JsonSerializer.Serialize(body, JsonOpts);

        try
        {
            using var content = new StringContent(json, Encoding.UTF8, "application/json");
            using var response = await _httpClient.PostAsync(url, content, cancellationToken);
            var responseText = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Gemini API hatası {Status}: {Body}", (int)response.StatusCode, responseText);
                throw new InvalidOperationException("AI şu an yanıt veremiyor. Lütfen daha sonra tekrar deneyin.");
            }

            return ExtractText(responseText);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Gemini API'ye ulaşılamadı.");
            throw new InvalidOperationException("AI şu an yanıt veremiyor. Lütfen daha sonra tekrar deneyin.");
        }
        catch (TaskCanceledException ex)
        {
            _logger.LogError(ex, "Gemini API zaman aşımı.");
            throw new InvalidOperationException("AI yanıtı zaman aşımına uğradı. Lütfen tekrar deneyin.");
        }
    }

    // candidates[0].content.parts[*].text birleştirir
    private static string? ExtractText(string responseJson)
    {
        using var doc = JsonDocument.Parse(responseJson);
        var root = doc.RootElement;

        if (!root.TryGetProperty("candidates", out var candidates) ||
            candidates.ValueKind != JsonValueKind.Array ||
            candidates.GetArrayLength() == 0)
        {
            return null;
        }

        var first = candidates[0];
        if (!first.TryGetProperty("content", out var contentEl) ||
            !contentEl.TryGetProperty("parts", out var parts) ||
            parts.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        var sb = new StringBuilder();
        foreach (var part in parts.EnumerateArray())
        {
            if (part.TryGetProperty("text", out var textEl) && textEl.ValueKind == JsonValueKind.String)
            {
                sb.Append(textEl.GetString());
            }
        }

        return sb.Length > 0 ? sb.ToString() : null;
    }

    // DB rolü ('user'/'assistant') → Gemini rolü ('user'/'model')
    private static string MapRole(string role) =>
        role == "assistant" ? "model" : "user";

    private static string NormalizeUrgency(string? value)
    {
        var v = value?.Trim().ToLowerInvariant();
        return v is "low" or "medium" or "high" or "emergency" ? v : "medium";
    }
}
