using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;

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

                // TODO: İleride SMS veya Push Notification servisi eklendiğinde
                // "Yaklaşan (24 saatten az kalmış) ve 'confirmed' olan randevuları bulup bildirim at" 
                // mantığı buraya eklenebilir.
                // Örn: var upcoming = dbContext.Appointments.Where(a => a.Status == "confirmed" && a.AppointmentDate > now && a.AppointmentDate <= now.AddHours(24)).ToList();
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
