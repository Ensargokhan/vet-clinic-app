using System.Text.RegularExpressions;

namespace VeterinerAPI.Helpers;

/// <summary>
/// Kullanıcı girdilerinden zararlı HTML/Script etiketlerini temizler.
/// XSS (Cross-Site Scripting) saldırılarına karşı koruma sağlar.
/// </summary>
public static class InputSanitizer
{
    // Tehlikeli HTML etiketlerini temizleyen regex pattern
    private static readonly Regex HtmlTagRegex = new(
        @"<\s*\/?\s*(script|iframe|object|embed|form|input|button|textarea|select|style|link|meta|base|applet)[^>]*>",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Event handler attribute'larını temizleyen regex (onerror, onclick vb.)
    private static readonly Regex EventHandlerRegex = new(
        @"\s*on\w+\s*=\s*[""'][^""']*[""']",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // javascript: ve data: protokollerini temizleyen regex
    private static readonly Regex DangerousProtocolRegex = new(
        @"(javascript|data|vbscript)\s*:",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);

    /// <summary>
    /// Verilen string'den zararlı HTML etiketlerini, event handler'ları ve
    /// tehlikeli protokolleri temizler.
    /// </summary>
    /// <param name="input">Temizlenecek string</param>
    /// <returns>Temizlenmiş string, null ise null döner</returns>
    public static string? Sanitize(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
            return input;

        var result = HtmlTagRegex.Replace(input, string.Empty);
        result = EventHandlerRegex.Replace(result, string.Empty);
        result = DangerousProtocolRegex.Replace(result, string.Empty);

        return result.Trim();
    }
}
