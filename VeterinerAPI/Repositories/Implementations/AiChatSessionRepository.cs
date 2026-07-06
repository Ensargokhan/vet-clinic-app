using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class AiChatSessionRepository : Repository<AiChatSession>, IAiChatSessionRepository
{
    public AiChatSessionRepository(AppDbContext context) : base(context)
    {
    }
}
