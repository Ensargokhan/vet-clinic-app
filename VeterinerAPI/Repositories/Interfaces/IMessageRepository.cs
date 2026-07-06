using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IMessageRepository : IRepository<Message>
{
    Task<IEnumerable<Message>> GetByConversationAsync(int conversationId);
    Task MarkReadAsync(int conversationId, int readerUserId);
    Task<int> GetUnreadCountAsync(IEnumerable<int> conversationIds, int readerUserId);
    Task<Dictionary<int, int>> GetUnreadCountsByConversationAsync(IEnumerable<int> conversationIds, int readerUserId);
}
