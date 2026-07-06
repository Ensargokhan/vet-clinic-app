using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.BackgroundServices;

/// <summary>
/// Onaylı (confirmed) ve 24 saatten az kalmış randevular için hasta sahibine bir kez
/// hatırlatma bildirimi gönderir. Tekrar göndermemek için Appointment.ReminderSent kullanılır.
/// Her 30 dakikada bir çalışır.
/// </summary>
public class AppointmentReminderWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AppointmentReminderWorker> _logger;

    public AppointmentReminderWorker(IServiceProvider serviceProvider, ILogger<AppointmentReminderWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("AppointmentReminderWorker başlatıldı.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

                var now = DateTime.UtcNow;
                var windowEnd = now.AddHours(24);

                // Onaylı, hatırlatılmamış ve 24 saat içindeki randevular
                var upcoming = await dbContext.Appointments
                    .Where(a => a.Status == "confirmed"
                                && !a.ReminderSent
                                && a.AppointmentDate > now
                                && a.AppointmentDate <= windowEnd)
                    .ToListAsync(stoppingToken);

                foreach (var appointment in upcoming)
                {
                    var dateStr = appointment.AppointmentDate.ToString("dd.MM.yyyy HH:mm");
                    await notificationService.NotifyAsync(
                        appointment.OwnerId,
                        "Randevu hatırlatması",
                        $"{dateStr} tarihli randevunuz yaklaşıyor.",
                        "appointment_reminder",
                        appointment.Id);

                    appointment.ReminderSent = true;
                }

                if (upcoming.Any())
                {
                    await dbContext.SaveChangesAsync(stoppingToken);
                    _logger.LogInformation($"{upcoming.Count} randevu için hatırlatma gönderildi.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AppointmentReminderWorker çalışırken bir hata oluştu.");
            }

            // 30 dakikada bir tekrarla
            await Task.Delay(TimeSpan.FromMinutes(30), stoppingToken);
        }
    }
}
