using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class AiChatMessageRepository : Repository<AiChatMessage>, IAiChatMessageRepository
{
    public AiChatMessageRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<AiChatMessage>> GetBySessionAsync(int sessionId)
    {
        return await _dbSet
            .Where(m => m.SessionId == sessionId)
            .OrderBy(m => m.CreatedAt)
            .ThenBy(m => m.Id)
            .ToListAsync();
    }
}
