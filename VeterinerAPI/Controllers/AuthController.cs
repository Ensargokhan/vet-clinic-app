using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using VeterinerAPI.DTOs.Auth;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [Authorize]
    [HttpPost("register")]
    [EnableRateLimiting("AuthPolicy")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz veriler." });

        var firebaseUid = User.FindFirst("FirebaseUid")?.Value;
        if (string.IsNullOrEmpty(firebaseUid))
            return Unauthorized(new ApiResponse<object> { Success = false, Message = "Firebase kimlik doğrulaması başarısız." });

        var user = await _authService.RegisterUserAsync(firebaseUid, request);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Kullanıcı başarıyla kaydedildi.",
            Data = new { user.Id, user.FullName, user.Email, user.Role }
        });
    }

    [HttpPost("register-clinic")]
    [Authorize]
    [EnableRateLimiting("AuthPolicy")]
    public async Task<IActionResult> RegisterClinic([FromBody] RegisterClinicRequest request)
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid))
            return Unauthorized(new ApiResponse<object> { Success = false, Message = "Firebase UID bulunamadı." });

        var user = await _authService.RegisterClinicAsync(firebaseUid, request);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Kurumsal klinik kaydı başarılı.",
            Data = user
        });
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetCurrentUser()
    {
        var firebaseUid = User.FindFirst("FirebaseUid")?.Value;
        if (string.IsNullOrEmpty(firebaseUid))
            return Unauthorized();

        var user = await _authService.GetUserProfileAsync(firebaseUid);
        if (user == null)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Kullanıcı profili bulunamadı. Lütfen kaydınızı tamamlayın." });

        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Profil bilgileri getirildi.",
            Data = new { user.Id, user.FullName, user.Email, user.Phone, user.Role }
        });
    }

    [Authorize]
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz veriler." });

        var firebaseUid = User.FindFirst("FirebaseUid")?.Value;
        if (string.IsNullOrEmpty(firebaseUid))
            return Unauthorized(new ApiResponse<object> { Success = false, Message = "Firebase kimlik doğrulaması başarısız." });

        var user = await _authService.UpdateProfileAsync(firebaseUid, request);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Profil başarıyla güncellendi.",
            Data = new { user.Id, user.FullName, user.Email, user.Phone, user.Role }
        });
    }

    [Authorize]
    [HttpDelete("account")]
    public async Task<IActionResult> DeleteAccount()
    {
        var firebaseUid = User.FindFirst("FirebaseUid")?.Value;
        if (string.IsNullOrEmpty(firebaseUid))
            return Unauthorized(new ApiResponse<object> { Success = false, Message = "Firebase kimlik doğrulaması başarısız." });

        await _authService.DeactivateUserAccountAsync(firebaseUid);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Hesap başarıyla silindi ve tüm ilişkili işlemler pasife alındı."
        });
    }

    [Authorize]
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var firebaseUid = User.FindFirst("FirebaseUid")?.Value;
        if (string.IsNullOrEmpty(firebaseUid))
            return Unauthorized(new ApiResponse<object> { Success = false, Message = "Firebase kimlik doğrulaması başarısız." });

        var stats = await _authService.GetUserStatsAsync(firebaseUid);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Kullanıcı istatistikleri başarıyla getirildi.",
            Data = stats
        });
    }
}
