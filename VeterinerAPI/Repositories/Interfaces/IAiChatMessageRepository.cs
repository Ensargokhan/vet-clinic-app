using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IAiChatMessageRepository : IRepository<AiChatMessage>
{
    Task<IEnumerable<AiChatMessage>> GetBySessionAsync(int sessionId);
}
