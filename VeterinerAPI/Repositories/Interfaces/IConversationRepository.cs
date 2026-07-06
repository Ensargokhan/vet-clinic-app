using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IConversationRepository : IRepository<Conversation>
{
    Task<Conversation?> GetByOwnerAndVetAsync(int ownerUserId, int vetId);
    Task<IEnumerable<Conversation>> GetForOwnerAsync(int ownerUserId);
    Task<IEnumerable<Conversation>> GetForVetAsync(int vetId);
}
