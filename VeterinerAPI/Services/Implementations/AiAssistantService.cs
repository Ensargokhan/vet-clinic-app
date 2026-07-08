using System.IO;
using System.Text;
using VeterinerAPI.DTOs.AI;
using VeterinerAPI.Helpers;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Ai;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class AiAssistantService : IAiAssistantService
{
    private readonly IAiChatSessionRepository _sessionRepository;
    private readonly IAiChatMessageRepository _messageRepository;
    private readonly IAiReportRepository _reportRepository;
    private readonly IAnimalRepository _animalRepository;
    private readonly IVaccineRepository _vaccineRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IVetRepository _vetRepository;
    private readonly IGeminiClient _geminiClient;

    public AiAssistantService(
        IAiChatSessionRepository sessionRepository,
        IAiChatMessageRepository messageRepository,
        IAiReportRepository reportRepository,
        IAnimalRepository animalRepository,
        IVaccineRepository vaccineRepository,
        IAppointmentRepository appointmentRepository,
        IVetRepository vetRepository,
        IGeminiClient geminiClient)
    {
        _sessionRepository = sessionRepository;
        _messageRepository = messageRepository;
        _reportRepository = reportRepository;
        _animalRepository = animalRepository;
        _vaccineRepository = vaccineRepository;
        _appointmentRepository = appointmentRepository;
        _vetRepository = vetRepository;
        _geminiClient = geminiClient;
    }

    public async Task<StartSessionResponse> StartSessionAsync(int userId, int animalId)
    {
        var animal = await _animalRepository.GetByIdAsync(animalId);
        if (animal == null || !animal.IsActive)
            throw new KeyNotFoundException("Hayvan bulunamadı.");

        // Sahiplik: yalnız hayvanın sahibi ön muayene başlatabilir
        if (animal.OwnerId != userId)
            throw new UnauthorizedAccessException("Bu hayvan için ön muayene başlatma yetkiniz yok.");

        var session = new AiChatSession
        {
            UserId = userId,
            AnimalId = animalId,
            Status = "active"
        };
        await _sessionRepository.AddAsync(session);
        await _sessionRepository.SaveChangesAsync();

        // Açılış mesajı hardcode — kota harcamaz, sohbeti başlatır
        var opening = new AiChatMessage
        {
            SessionId = session.Id,
            Role = "assistant",
            Content = BuildOpeningMessage(animal.Name)
        };
        await _messageRepository.AddAsync(opening);
        await _messageRepository.SaveChangesAsync();

        return new StartSessionResponse
        {
            SessionId = session.Id,
            Message = ToResponse(opening)
        };
    }

    public async Task<ChatMessageResponse> SendMessageAsync(int userId, int sessionId, string message)
    {
        var session = await GetOwnedActiveSessionAsync(userId, sessionId);

        var clean = InputSanitizer.Sanitize(message);
        if (string.IsNullOrWhiteSpace(clean))
            throw new ArgumentException("Mesaj boş olamaz.");

        // Kullanıcı mesajını kaydet
        var userMessage = new AiChatMessage
        {
            SessionId = sessionId,
            Role = "user",
            Content = clean
        };
        await _messageRepository.AddAsync(userMessage);
        await _messageRepository.SaveChangesAsync();

        // Sistem promptu (hayvan bilgisi + aşı geçmişi) + tüm sohbet geçmişi
        var animal = await _animalRepository.GetByIdAsync(session.AnimalId);
        var systemPrompt = await BuildSystemPromptAsync(animal!);

        var history = (await _messageRepository.GetBySessionAsync(sessionId))
            .Select(m => (m.Role, m.Content))
            .ToList();

        var reply = await _geminiClient.GenerateReplyAsync(systemPrompt, history);

        var assistantMessage = new AiChatMessage
        {
            SessionId = sessionId,
            Role = "assistant",
            Content = reply
        };
        await _messageRepository.AddAsync(assistantMessage);
        await _messageRepository.SaveChangesAsync();

        return ToResponse(assistantMessage);
    }

    public async Task<IEnumerable<ChatMessageResponse>> GetSessionMessagesAsync(int userId, int sessionId)
    {
        var session = await _sessionRepository.GetByIdAsync(sessionId);
        if (session == null) throw new KeyNotFoundException("Oturum bulunamadı.");
        if (session.UserId != userId)
            throw new UnauthorizedAccessException("Bu oturuma erişim yetkiniz yok.");

        var messages = await _messageRepository.GetBySessionAsync(sessionId);
        return messages.Select(ToResponse).ToList();
    }

    public async Task<AiReportResponse> FinalizeReportAsync(int userId, int sessionId)
    {
        var session = await _sessionRepository.GetByIdAsync(sessionId);
        if (session == null) throw new KeyNotFoundException("Oturum bulunamadı.");
        if (session.UserId != userId)
            throw new UnauthorizedAccessException("Bu oturuma erişim yetkiniz yok.");

        // Zaten tamamlanmışsa mevcut raporu döndür (tekrar Gemini çağırma, kota harcama)
        if (session.Status == "completed")
        {
            var existing = await _reportRepository.FirstOrDefaultAsync(r => r.SessionId == sessionId);
            if (existing != null) return ToReportResponse(existing);
        }

        var messages = (await _messageRepository.GetBySessionAsync(sessionId)).ToList();
        if (!messages.Any(m => m.Role == "user"))
            throw new ArgumentException("Rapor oluşturmak için önce birkaç soruyu yanıtlayın.");

        var animal = await _animalRepository.GetByIdAsync(session.AnimalId);
        var transcript = BuildTranscript(messages);
        var finalizePrompt = await BuildFinalizePromptAsync(animal!);

        var result = await _geminiClient.GenerateReportAsync(finalizePrompt, transcript);

        var report = new AiReport
        {
            SessionId = sessionId,
            AnimalId = session.AnimalId,
            UserId = userId,
            ReportContent = result.ReportContent,
            SymptomsSummary = result.SymptomsSummary,
            UrgencyLevel = result.UrgencyLevel
        };
        await _reportRepository.AddAsync(report);

        session.Status = "completed";
        session.CompletedAt = DateTime.UtcNow;
        _sessionRepository.Update(session);
        await _reportRepository.SaveChangesAsync();

        return ToReportResponse(report);
    }

    public async Task AttachToAppointmentAsync(int userId, int reportId, int appointmentId)
    {
        var report = await _reportRepository.GetByIdAsync(reportId);
        if (report == null) throw new KeyNotFoundException("Rapor bulunamadı.");
        if (report.UserId != userId)
            throw new UnauthorizedAccessException("Bu raporu bağlama yetkiniz yok.");

        var appointment = await _appointmentRepository.GetByIdAsync(appointmentId);
        if (appointment == null) throw new KeyNotFoundException("Randevu bulunamadı.");
        if (appointment.OwnerId != userId)
            throw new UnauthorizedAccessException("Bu randevuya rapor bağlama yetkiniz yok.");

        // Rapor ve randevu aynı hayvana ait olmalı
        if (report.AnimalId != appointment.AnimalId)
            throw new ArgumentException("Rapor bu randevunun hayvanına ait değil.");

        report.AppointmentId = appointmentId;
        _reportRepository.Update(report);
        await _reportRepository.SaveChangesAsync();
    }

    public async Task<AiReportResponse?> GetReportByAppointmentAsync(int userId, string role, int appointmentId)
    {
        var appointment = await _appointmentRepository.GetByIdAsync(appointmentId);
        if (appointment == null) throw new KeyNotFoundException("Randevu bulunamadı.");

        // Yetki: Sadece hekim (vet) veya klinik admin'i görebilir
        if (role == "owner")
        {
            throw new UnauthorizedAccessException("Hayvan sahipleri klinik ön rapora erişemez.");
        }
        else if (role == "vet" || role == "clinic_admin")
        {
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == userId);
            if (vet == null || appointment.VetId != vet.Id)
                throw new UnauthorizedAccessException("Bu randevunun raporuna erişim yetkiniz yok.");
        }
        else
        {
            throw new UnauthorizedAccessException("Bu işlem için yetkiniz yok.");
        }

        var report = await _reportRepository.GetByAppointmentAsync(appointmentId);
        return report == null ? null : ToReportResponse(report);
    }

    // ===== Yardımcılar =====

    private async Task<AiChatSession> GetOwnedActiveSessionAsync(int userId, int sessionId)
    {
        var session = await _sessionRepository.GetByIdAsync(sessionId);
        if (session == null) throw new KeyNotFoundException("Oturum bulunamadı.");
        if (session.UserId != userId)
            throw new UnauthorizedAccessException("Bu oturuma erişim yetkiniz yok.");
        if (session.Status != "active")
            throw new InvalidOperationException("Bu oturum tamamlanmış; yeni mesaj gönderilemez.");
        return session;
    }

    private static string BuildOpeningMessage(string animalName) =>
        $"Merhaba! 🐾 Ben {animalName} için ön muayene asistanıyım. Hekiminize daha iyi bilgi " +
        $"verebilmek adına size birkaç kısa soru soracağım (teşhis koymam, yalnızca bilgi toplarım). " +
        $"Başlayalım: {animalName} ile ilgili sizi en çok endişelendiren şey nedir ve ne zamandır sürüyor?";

    // System prompt — Prompts klasöründeki txt dosyasından okunur
    private async Task<string> BuildSystemPromptAsync(Animal animal)
    {
        var vaccineHistory = await BuildVaccineHistoryAsync(animal.Id);

        var promptPath = Path.Combine(Directory.GetCurrentDirectory(), "Prompts", "SystemPrompt.txt");
        var template = await File.ReadAllTextAsync(promptPath);

        return template
            .Replace("{AnimalName}", animal.Name)
            .Replace("{AnimalSpecies}", MapSpecies(animal.Species))
            .Replace("{AnimalBreed}", string.IsNullOrWhiteSpace(animal.Breed) ? "Bilinmiyor" : animal.Breed)
            .Replace("{AnimalAge}", FormatAge(animal.BirthDate))
            .Replace("{AnimalWeight}", animal.Weight.HasValue ? $"{animal.Weight.Value:0.##} kg" : "Bilinmiyor")
            .Replace("{AnimalGender}", MapGender(animal.Gender))
            .Replace("{VaccineHistory}", vaccineHistory);
    }

    // Finalize promptu — Prompts klasöründeki txt dosyasından okunur
    private async Task<string> BuildFinalizePromptAsync(Animal animal)
    {
        var vaccineHistory = await BuildVaccineHistoryAsync(animal.Id);

        var promptPath = Path.Combine(Directory.GetCurrentDirectory(), "Prompts", "FinalizePrompt.txt");
        var template = await File.ReadAllTextAsync(promptPath);

        return template
            .Replace("{AnimalName}", animal.Name)
            .Replace("{AnimalSpecies}", MapSpecies(animal.Species))
            .Replace("{AnimalBreed}", string.IsNullOrWhiteSpace(animal.Breed) ? "Bilinmiyor" : animal.Breed)
            .Replace("{AnimalAge}", FormatAge(animal.BirthDate))
            .Replace("{AnimalWeight}", animal.Weight.HasValue ? $"{animal.Weight.Value:0.##} kg" : "Bilinmiyor")
            .Replace("{AnimalGender}", MapGender(animal.Gender))
            .Replace("{VaccineHistory}", vaccineHistory);
    }

    private async Task<string> BuildVaccineHistoryAsync(int animalId)
    {
        var vaccines = (await _vaccineRepository.GetVaccinesByAnimalAsync(animalId)).ToList();
        if (vaccines.Count == 0) return "Aşı kaydı yok";

        return string.Join(", ", vaccines.Select(v =>
            $"{v.VaccineName} ({v.AdministeredDate:dd.MM.yyyy})"));
    }

    private static string BuildTranscript(IEnumerable<AiChatMessage> messages)
    {
        var sb = new StringBuilder();
        sb.AppendLine("SOHBET GEÇMİŞİ:");
        foreach (var m in messages)
        {
            var speaker = m.Role == "user" ? "Hayvan Sahibi" : "Asistan";
            sb.AppendLine($"{speaker}: {m.Content}");
        }
        return sb.ToString();
    }

    private static string FormatAge(DateTime? birthDate)
    {
        if (birthDate == null) return "Bilinmiyor";

        var now = DateTime.UtcNow;
        var months = ((now.Year - birthDate.Value.Year) * 12) + now.Month - birthDate.Value.Month;
        if (now.Day < birthDate.Value.Day) months--;
        if (months < 0) months = 0;

        if (months < 12) return $"{months} aylık";
        var years = months / 12;
        var remMonths = months % 12;
        return remMonths > 0 ? $"{years} yaş {remMonths} ay" : $"{years} yaş";
    }

    private static string MapSpecies(string? species) => species switch
    {
        "dog" => "Köpek",
        "cat" => "Kedi",
        "bird" => "Kuş",
        "rabbit" => "Tavşan",
        _ => "Diğer"
    };

    private static string MapGender(string? gender) => gender switch
    {
        "male" => "Erkek",
        "female" => "Dişi",
        _ => "Bilinmiyor"
    };

    private static ChatMessageResponse ToResponse(AiChatMessage m) => new()
    {
        Id = m.Id,
        Role = m.Role,
        Content = m.Content,
        CreatedAt = m.CreatedAt
    };

    private static AiReportResponse ToReportResponse(AiReport r) => new()
    {
        Id = r.Id,
        AnimalId = r.AnimalId,
        AppointmentId = r.AppointmentId,
        ReportContent = r.ReportContent,
        SymptomsSummary = r.SymptomsSummary,
        UrgencyLevel = r.UrgencyLevel,
        CreatedAt = r.CreatedAt
    };
}
