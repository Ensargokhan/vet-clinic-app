using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.BackgroundServices;

public class AppointmentStatusWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AppointmentStatusWorker> _logger;

    public AppointmentStatusWorker(IServiceProvider serviceProvider, ILogger<AppointmentStatusWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("AppointmentStatusWorker başlatıldı.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Şu anki UTC zamanı
                var now = DateTime.UtcNow;

                // Statüsü 'pending' olan ve randevu saati (AppointmentDate) geçmiş olanları bul
                var expiredAppointments = await dbContext.Appointments
                    .Where(a => a.Status == "pending" && a.AppointmentDate < now)
                    .ToListAsync(stoppingToken);

                if (expiredAppointments.Any())
                {
                    foreach (var appointment in expiredAppointments)
                    {
                        appointment.Status = "expired";
                        appointment.UpdatedAt = now;
                    }

                    await dbContext.SaveChangesAsync(stoppingToken);
                    _logger.LogInformation($"{expiredAppointments.Count} adet saati geçmiş randevu 'expired' (Süresi Doldu) olarak işaretlendi.");
                }

                // Saati geçmiş ama hâlâ 'confirmed' randevular: sonucu (Tamamlandı/Gelmedi)
                // işaretlemesi için hekime tek seferlik hatırlatma gönder.
                // Otomatik no_show YAPILMAZ — karar insanda kalır (CompletionReminderSent tekrar önler).
                var awaitingOutcome = await dbContext.Appointments
                    .Include(a => a.Vet)
                    .Where(a => a.Status == "confirmed"
                                && a.AppointmentDate < now
                                && !a.CompletionReminderSent)
                    .ToListAsync(stoppingToken);

                if (awaitingOutcome.Any())
                {
                    var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

                    foreach (var appointment in awaitingOutcome)
                    {
                        var dateStr = appointment.AppointmentDate.ToString("dd.MM.yyyy HH:mm");
                        await notificationService.NotifyAsync(
                            appointment.Vet.UserId,
                            "Randevu sonucu bekleniyor",
                            $"{dateStr} tarihli randevunun sonucunu (Tamamlandı / Gelmedi) işaretlemeyi unutmayın.",
                            "appointment_action_required",
                            appointment.Id);

                        appointment.CompletionReminderSent = true;
                    }

                    await dbContext.SaveChangesAsync(stoppingToken);
                    _logger.LogInformation($"{awaitingOutcome.Count} randevu için hekime 'sonucu işaretle' hatırlatması gönderildi.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AppointmentStatusWorker çalışırken bir hata oluştu.");
            }

            // 15 dakikada bir tekrarla
            await Task.Delay(TimeSpan.FromMinutes(15), stoppingToken);
        }
    }
}
