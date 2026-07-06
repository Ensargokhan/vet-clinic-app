using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class MessageRepository : Repository<Message>, IMessageRepository
{
    public MessageRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Message>> GetByConversationAsync(int conversationId)
    {
        return await _dbSet
            .Where(m => m.ConversationId == conversationId)
            .OrderBy(m => m.CreatedAt)
            .ToListAsync();
    }

    public async Task MarkReadAsync(int conversationId, int readerUserId)
    {
        // Karşı tarafın gönderdiği okunmamış mesajları okundu yap
        await _dbSet
            .Where(m => m.ConversationId == conversationId
                     && m.SenderUserId != readerUserId
                     && !m.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(m => m.IsRead, true));
    }

    public async Task<int> GetUnreadCountAsync(IEnumerable<int> conversationIds, int readerUserId)
    {
        var ids = conversationIds.ToList();
        if (ids.Count == 0) return 0;

        return await _dbSet.CountAsync(m => ids.Contains(m.ConversationId)
                                         && m.SenderUserId != readerUserId
                                         && !m.IsRead);
    }

    public async Task<Dictionary<int, int>> GetUnreadCountsByConversationAsync(IEnumerable<int> conversationIds, int readerUserId)
    {
        var ids = conversationIds.ToList();
        if (ids.Count == 0) return new Dictionary<int, int>();

        var grouped = await _dbSet
            .Where(m => ids.Contains(m.ConversationId)
                     && m.SenderUserId != readerUserId
                     && !m.IsRead)
            .GroupBy(m => m.ConversationId)
            .Select(g => new { ConversationId = g.Key, Count = g.Count() })
            .ToListAsync();

        return grouped.ToDictionary(x => x.ConversationId, x => x.Count);
    }
}
