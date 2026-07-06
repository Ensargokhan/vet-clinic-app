using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface INotificationRepository : IRepository<Notification>
{
    Task<IEnumerable<Notification>> GetByUserAsync(int userId);
    Task<int> GetUnreadCountAsync(int userId);
    Task MarkAllReadAsync(int userId);
}
