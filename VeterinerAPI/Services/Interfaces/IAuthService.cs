using VeterinerAPI.Models.Entities;
using VeterinerAPI.DTOs.Auth;

namespace VeterinerAPI.Services.Interfaces;

public interface IAuthService
{
    Task<User> RegisterUserAsync(string firebaseUid, RegisterRequest request);
    Task<User?> GetUserByFirebaseUidAsync(string firebaseUid);
    Task<User?> GetUserProfileAsync(string firebaseUid);
    Task<User> RegisterClinicAsync(string firebaseUid, RegisterClinicRequest request);
    Task<User> UpdateProfileAsync(string firebaseUid, UpdateProfileRequest request);
    Task<string?> UpdateProfilePhotoAsync(string firebaseUid, string photoUrl);
    Task DeactivateUserAccountAsync(string firebaseUid);
    Task<object> GetUserStatsAsync(string firebaseUid);
}
