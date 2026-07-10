using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.DTOs.Reviews;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Authorize]
public class ClinicReviewsController : ControllerBase
{
    private readonly IClinicReviewService _reviewService;

    public ClinicReviewsController(IClinicReviewService reviewService)
    {
        _reviewService = reviewService;
    }

    private int? CurrentUserId =>
        HttpContext.Items.TryGetValue("UserId", out var uidObj) ? (int)uidObj! : null;

    private string CurrentUserRole =>
        HttpContext.Items["UserRole"]?.ToString() ?? "owner";

    [HttpGet("api/clinics/{clinicId}/reviews")]
    public async Task<IActionResult> GetByClinic(int clinicId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var items = await _reviewService.GetByClinicAsync(clinicId, userId, page, pageSize);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Değerlendirmeler getirildi.",
            Data = items
        });
    }

    [HttpGet("api/clinics/{clinicId}/reviews/summary")]
    public async Task<IActionResult> GetSummary(int clinicId)
    {
        var summary = await _reviewService.GetSummaryAsync(clinicId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Değerlendirme özeti getirildi.",
            Data = summary
        });
    }

    [HttpGet("api/clinics/{clinicId}/reviews/me")]
    public async Task<IActionResult> GetMyStatus(int clinicId)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var status = await _reviewService.GetMyStatusAsync(userId, CurrentUserRole, clinicId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Değerlendirme durumu getirildi.",
            Data = status
        });
    }

    /// <summary>Yorum oluşturur veya mevcut yorumu günceller (kullanıcı+klinik başına tek yorum).</summary>
    [HttpPost("api/clinics/{clinicId}/reviews")]
    public async Task<IActionResult> CreateOrUpdate(int clinicId, [FromBody] ClinicReviewRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz değerlendirme." });
        if (CurrentUserId is not int userId) return Unauthorized();

        var id = await _reviewService.CreateOrUpdateAsync(userId, CurrentUserRole, clinicId, request);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Değerlendirmeniz kaydedildi.",
            Data = new { ReviewId = id }
        });
    }

    [HttpDelete("api/clinics/{clinicId}/reviews/me")]
    public async Task<IActionResult> DeleteMine(int clinicId)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var success = await _reviewService.DeleteAsync(userId, clinicId);
        if (!success)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Değerlendirme bulunamadı." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Değerlendirmeniz silindi." });
    }
}
