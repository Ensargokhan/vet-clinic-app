using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class ConversationRepository : Repository<Conversation>, IConversationRepository
{
    public ConversationRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<Conversation?> GetByOwnerAndVetAsync(int ownerUserId, int vetId)
    {
        return await _dbSet
            .FirstOrDefaultAsync(c => c.OwnerUserId == ownerUserId && c.VetId == vetId);
    }

    public async Task<IEnumerable<Conversation>> GetForOwnerAsync(int ownerUserId)
    {
        return await _dbSet
            .Include(c => c.Vet)
                .ThenInclude(v => v.User)
            .Where(c => c.OwnerUserId == ownerUserId)
            .OrderByDescending(c => c.LastMessageAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<Conversation>> GetForVetAsync(int vetId)
    {
        return await _dbSet
            .Include(c => c.OwnerUser)
            .Where(c => c.VetId == vetId)
            .OrderByDescending(c => c.LastMessageAt)
            .ToListAsync();
    }
}
