using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class UserRepository : Repository<User>, IUserRepository
{
    public UserRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<User?> GetByFirebaseUidAsync(string firebaseUid)
    {
        return await _dbSet.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid);
    }
}
