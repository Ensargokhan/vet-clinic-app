using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.DTOs.Messaging;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ConversationsController : ControllerBase
{
    private readonly IMessageService _messageService;

    public ConversationsController(IMessageService messageService)
    {
        _messageService = messageService;
    }

    private int? CurrentUserId =>
        HttpContext.Items.TryGetValue("UserId", out var uidObj) ? (int)uidObj! : null;

    private string CurrentUserRole =>
        HttpContext.Items["UserRole"]?.ToString() ?? "owner";

    [HttpGet]
    public async Task<IActionResult> GetConversations()
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var items = await _messageService.GetConversationsAsync(userId, CurrentUserRole);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Konuşmalar getirildi.",
            Data = items
        });
    }

    [HttpPost]
    public async Task<IActionResult> StartConversation([FromBody] StartConversationRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz istek." });
        if (CurrentUserId is not int userId) return Unauthorized();

        var conversationId = await _messageService.StartOrGetConversationAsync(userId, CurrentUserRole, request.PeerUserId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Konuşma hazır.",
            Data = new { ConversationId = conversationId }
        });
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var count = await _messageService.GetUnreadCountAsync(userId, CurrentUserRole);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Okunmamış mesaj sayısı.",
            Data = new { Count = count }
        });
    }

    [HttpGet("contacts")]
    public async Task<IActionResult> GetContacts()
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var items = await _messageService.GetContactsAsync(userId, CurrentUserRole);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Kişiler getirildi.",
            Data = items
        });
    }

    [HttpGet("{id}/messages")]
    public async Task<IActionResult> GetMessages(int id)
    {
        if (CurrentUserId is not int userId) return Unauthorized();

        var items = await _messageService.GetMessagesAsync(id, userId, CurrentUserRole);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Mesajlar getirildi.",
            Data = items
        });
    }

    [HttpPost("{id}/messages")]
    public async Task<IActionResult> SendMessage(int id, [FromBody] SendMessageRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(new ApiResponse<object> { Success = false, Message = "Mesaj geçersiz." });
        if (CurrentUserId is not int userId) return Unauthorized();

        var message = await _messageService.SendMessageAsync(id, userId, CurrentUserRole, request.Body);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Mesaj gönderildi.",
            Data = message
        });
    }
}
