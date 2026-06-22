using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Repositories.Interfaces;

public interface IUserRepository : IRepository<User>
{
    Task<User?> GetByFirebaseUidAsync(string firebaseUid);
}
