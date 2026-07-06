using FirebaseAdmin.Messaging;
using VeterinerAPI.DTOs.Notifications;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;
using NotificationEntity = VeterinerAPI.Models.Entities.Notification;

namespace VeterinerAPI.Services.Implementations;

public class NotificationService : INotificationService
{
    private readonly INotificationRepository _notificationRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        INotificationRepository notificationRepository,
        IUserRepository userRepository,
        ILogger<NotificationService> logger)
    {
        _notificationRepository = notificationRepository;
        _userRepository = userRepository;
        _logger = logger;
    }

    public async Task NotifyAsync(int userId, string title, string body, string type, int? relatedId = null)
    {
        // 1. Bildirim merkezi için kalıcı kayıt
        var notification = new NotificationEntity
        {
            UserId = userId,
            Title = title,
            Body = body,
            Type = type,
            RelatedId = relatedId,
            IsRead = false
        };
        await _notificationRepository.AddAsync(notification);
        await _notificationRepository.SaveChangesAsync();

        // 2. Push bildirim (kullanıcının token'ı varsa). Hata olursa akışı bozma.
        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null || string.IsNullOrEmpty(user.FcmToken))
        {
            return;
        }

        try
        {
            var message = new Message
            {
                Token = user.FcmToken,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = title,
                    Body = body
                },
                Data = new Dictionary<string, string>
                {
                    ["type"] = type,
                    ["relatedId"] = relatedId?.ToString() ?? string.Empty
                }
            };

            await FirebaseMessaging.DefaultInstance.SendAsync(message);
        }
        catch (Exception ex)
        {
            // Geçersiz/expired token veya FCM erişim hatası — bildirim kaydı yine de duruyor.
            _logger.LogWarning(ex, "FCM push gönderilemedi. UserId: {UserId}", userId);
        }
    }

    public async Task<IEnumerable<NotificationResponse>> GetForUserAsync(int userId)
    {
        var items = await _notificationRepository.GetByUserAsync(userId);
        return items.Select(n => new NotificationResponse
        {
            Id = n.Id,
            Title = n.Title,
            Body = n.Body,
            Type = n.Type,
            RelatedId = n.RelatedId,
            IsRead = n.IsRead,
            CreatedAt = n.CreatedAt
        });
    }

    public Task<int> GetUnreadCountAsync(int userId) =>
        _notificationRepository.GetUnreadCountAsync(userId);

    public async Task<bool> MarkReadAsync(int notificationId, int userId)
    {
        var notification = await _notificationRepository.GetByIdAsync(notificationId);
        if (notification == null || notification.UserId != userId)
        {
            return false;
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            _notificationRepository.Update(notification);
            await _notificationRepository.SaveChangesAsync();
        }
        return true;
    }

    public Task MarkAllReadAsync(int userId) =>
        _notificationRepository.MarkAllReadAsync(userId);

    public async Task RegisterDeviceTokenAsync(int userId, string token)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null) return;
        user.FcmToken = token;
        _userRepository.Update(user);
        await _userRepository.SaveChangesAsync();
    }

    public async Task ClearDeviceTokenAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null) return;
        user.FcmToken = null;
        _userRepository.Update(user);
        await _userRepository.SaveChangesAsync();
    }
}
