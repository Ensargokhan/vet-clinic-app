using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.BackgroundServices;

/// <summary>
/// Sonraki tarihi (NextDueDate) 3 gün içinde olan aşılar için hayvan sahibine bir kez
/// hatırlatma bildirimi gönderir. Tekrar göndermemek için Vaccine.ReminderSent kullanılır.
/// Her 12 saatte bir çalışır.
/// </summary>
public class VaccineReminderWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<VaccineReminderWorker> _logger;

    public VaccineReminderWorker(IServiceProvider serviceProvider, ILogger<VaccineReminderWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("VaccineReminderWorker başlatıldı.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

                var today = DateTime.UtcNow.Date;
                var windowEnd = today.AddDays(3);

                // Sonraki tarihi bugün ile 3 gün sonrası arasında olan, hatırlatılmamış aşılar
                var dueVaccines = await dbContext.Vaccines
                    .Include(v => v.Animal)
                    .Where(v => v.NextDueDate != null
                                && !v.ReminderSent
                                && v.NextDueDate.Value.Date >= today
                                && v.NextDueDate.Value.Date <= windowEnd)
                    .ToListAsync(stoppingToken);

                foreach (var vaccine in dueVaccines)
                {
                    var dateStr = vaccine.NextDueDate!.Value.ToString("dd.MM.yyyy");
                    await notificationService.NotifyAsync(
                        vaccine.Animal.OwnerId,
                        "Aşı hatırlatması",
                        $"{vaccine.Animal.Name} için {vaccine.VaccineName} aşısının zamanı yaklaşıyor ({dateStr}).",
                        "vaccine_reminder",
                        vaccine.AnimalId);

                    vaccine.ReminderSent = true;
                }

                if (dueVaccines.Any())
                {
                    await dbContext.SaveChangesAsync(stoppingToken);
                    _logger.LogInformation($"{dueVaccines.Count} aşı için hatırlatma gönderildi.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "VaccineReminderWorker çalışırken bir hata oluştu.");
            }

            // 12 saatte bir tekrarla
            await Task.Delay(TimeSpan.FromHours(12), stoppingToken);
        }
    }
}
