using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.DTOs.Notifications;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    private int? CurrentUserId =>
        HttpContext.Items.TryGetValue("UserId", out var uidObj) ? (int)uidObj! : null;

    [HttpGet]
    public async Task<IActionResult> GetMyNotifications()
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var items = await _notificationService.GetForUserAsync(userId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Bildirimler getirildi.",
            Data = items
        });
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var count = await _notificationService.GetUnreadCountAsync(userId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Okunmamış bildirim sayısı.",
            Data = new { Count = count }
        });
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkRead(int id)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var success = await _notificationService.MarkReadAsync(id, userId);
        if (!success)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Bildirim bulunamadı." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Bildirim okundu olarak işaretlendi." });
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllRead()
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        await _notificationService.MarkAllReadAsync(userId);
        return Ok(new ApiResponse<object> { Success = true, Message = "Tüm bildirimler okundu olarak işaretlendi." });
    }

    [HttpPost("device-token")]
    public async Task<IActionResult> RegisterDeviceToken([FromBody] RegisterDeviceTokenRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz token." });
        if (CurrentUserId is not int userId) return Unauthorized();

        await _notificationService.RegisterDeviceTokenAsync(userId, request.Token);
        return Ok(new ApiResponse<object> { Success = true, Message = "Cihaz token'ı kaydedildi." });
    }

    [HttpDelete("device-token")]
    public async Task<IActionResult> ClearDeviceToken()
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        await _notificationService.ClearDeviceTokenAsync(userId);
        return Ok(new ApiResponse<object> { Success = true, Message = "Cihaz token'ı temizlendi." });
    }
}
