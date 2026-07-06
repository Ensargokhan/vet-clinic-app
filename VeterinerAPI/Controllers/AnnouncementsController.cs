using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeterinerAPI.DTOs.Announcements;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Authorize]
public class AnnouncementsController : ControllerBase
{
    private readonly IAnnouncementService _announcementService;

    public AnnouncementsController(IAnnouncementService announcementService)
    {
        _announcementService = announcementService;
    }

    private int? CurrentUserId =>
        HttpContext.Items.TryGetValue("UserId", out var uidObj) ? (int)uidObj! : null;

    private string CurrentUserRole =>
        HttpContext.Items["UserRole"]?.ToString() ?? "owner";

    // ===== Klinik (admin) tarafı =====

    [HttpPost("api/clinics/my-clinic/announcements")]
    public async Task<IActionResult> Create([FromBody] AnnouncementRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz duyuru." });
        if (CurrentUserId is not int userId) return Unauthorized();

        var id = await _announcementService.CreateAsync(userId, CurrentUserRole, request);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Duyuru yayınlandı.",
            Data = new { AnnouncementId = id }
        });
    }

    [HttpGet("api/clinics/my-clinic/announcements")]
    public async Task<IActionResult> GetMyClinicAnnouncements()
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var items = await _announcementService.GetMyClinicAnnouncementsAsync(userId, CurrentUserRole);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Duyurular getirildi.",
            Data = items
        });
    }

    [HttpDelete("api/clinics/my-clinic/announcements/{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var success = await _announcementService.DeleteAsync(id, userId, CurrentUserRole);
        if (!success)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Duyuru bulunamadı." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Duyuru silindi." });
    }

    // ===== Owner tarafı (bir kliniğin aktif duyuruları) =====

    [HttpGet("api/clinics/{clinicId}/announcements")]
    public async Task<IActionResult> GetByClinic(int clinicId)
    {
        var items = await _announcementService.GetByClinicAsync(clinicId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Duyurular getirildi.",
            Data = items
        });
    }
}
