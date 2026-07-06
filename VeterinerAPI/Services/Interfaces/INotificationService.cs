using VeterinerAPI.DTOs.Notifications;

namespace VeterinerAPI.Services.Interfaces;

public interface INotificationService
{
    /// <summary>
    /// Bir kullanıcıya bildirim gönderir: (1) bildirim merkezi için kalıcı kayıt oluşturur,
    /// (2) kullanıcının FCM token'ı varsa push bildirim yollar. Push başarısız olsa bile
    /// kayıt tutulur (bildirim kritik-yol değildir).
    /// </summary>
    Task NotifyAsync(int userId, string title, string body, string type, int? relatedId = null);

    Task<IEnumerable<NotificationResponse>> GetForUserAsync(int userId);
    Task<int> GetUnreadCountAsync(int userId);
    Task<bool> MarkReadAsync(int notificationId, int userId);
    Task MarkAllReadAsync(int userId);

    // Cihaz (FCM) token yönetimi
    Task RegisterDeviceTokenAsync(int userId, string token);
    Task ClearDeviceTokenAsync(int userId);
}
