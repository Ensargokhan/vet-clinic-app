using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using VeterinerAPI.DTOs.AI;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize]
public class AiAssistantController : ControllerBase
{
    private readonly IAiAssistantService _aiService;

    public AiAssistantController(IAiAssistantService aiService)
    {
        _aiService = aiService;
    }

    private int? CurrentUserId =>
        HttpContext.Items.TryGetValue("UserId", out var uidObj) ? (int)uidObj! : null;

    private string CurrentUserRole =>
        HttpContext.Items["UserRole"]?.ToString() ?? "owner";

    [HttpPost("start-session")]
    public async Task<IActionResult> StartSession([FromBody] StartSessionRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz istek." });
        if (CurrentUserId is not int userId) return Unauthorized();

        var result = await _aiService.StartSessionAsync(userId, request.AnimalId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Ön muayene oturumu başlatıldı.",
            Data = result
        });
    }

    [HttpPost("sessions/{id}/chat")]
    [EnableRateLimiting("AiPolicy")]
    public async Task<IActionResult> Chat(int id, [FromBody] ChatRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(new ApiResponse<object> { Success = false, Message = "Mesaj geçersiz." });
        if (CurrentUserId is not int userId) return Unauthorized();

        var message = await _aiService.SendMessageAsync(userId, id, request.Message);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Yanıt üretildi.",
            Data = message
        });
    }

    [HttpGet("sessions/{id}/messages")]
    public async Task<IActionResult> GetMessages(int id)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var items = await _aiService.GetSessionMessagesAsync(userId, id);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Sohbet getirildi.",
            Data = items
        });
    }

    [HttpPost("sessions/{id}/finalize")]
    [EnableRateLimiting("AiPolicy")]
    public async Task<IActionResult> Finalize(int id)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var report = await _aiService.FinalizeReportAsync(userId, id);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Ön rapor hazırlandı.",
            Data = report
        });
    }

    [HttpPost("reports/{reportId}/attach/{appointmentId}")]
    public async Task<IActionResult> AttachToAppointment(int reportId, int appointmentId)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        await _aiService.AttachToAppointmentAsync(userId, reportId, appointmentId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Rapor randevuya bağlandı.",
            Data = null
        });
    }

    [HttpGet("reports/by-appointment/{appointmentId}")]
    public async Task<IActionResult> GetReportByAppointment(int appointmentId)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var report = await _aiService.GetReportByAppointmentAsync(userId, CurrentUserRole, appointmentId);
        if (report == null)
        {
            return NotFound(new ApiResponse<object>
            {
                Success = false,
                Message = "Bu randevuya bağlı ön rapor bulunamadı.",
                Data = null
            });
        }

        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Ön rapor getirildi.",
            Data = report
        });
    }
}
