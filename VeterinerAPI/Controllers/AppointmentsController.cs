using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using VeterinerAPI.DTOs.Appointments;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AppointmentsController : ControllerBase
{
    private readonly IAppointmentService _appointmentService;

    public AppointmentsController(IAppointmentService appointmentService)
    {
        _appointmentService = appointmentService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMyAppointments()
    {
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int userId = (int)uidObj!;

        var appointments = await _appointmentService.GetAppointmentsByUserAsync(userId);
        
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Randevularınız getirildi.",
            Data = appointments
        });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetAppointmentById(int id)
    {
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int userId = (int)uidObj!;

        var appointment = await _appointmentService.GetAppointmentByIdAsync(id, userId);
        if (appointment == null)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Randevu bulunamadı." });

        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Randevu detayları getirildi.",
            Data = appointment
        });
    }

    [HttpPost]
    [EnableRateLimiting("AppointmentPolicy")]
    public async Task<IActionResult> CreateAppointment([FromBody] AppointmentRequest request)
    {
        if (!ModelState.IsValid) return BadRequest();
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int userId = (int)uidObj!;

        var appointmentId = await _appointmentService.CreateAppointmentAsync(request, userId);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Randevu başarıyla oluşturuldu.",
            Data = new { AppointmentId = appointmentId }
        });
    }

    [HttpPut("{id}/cancel")]
    public async Task<IActionResult> CancelAppointment(int id, [FromBody] CancelAppointmentRequest? request)
    {
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int userId = (int)uidObj!;

        var success = await _appointmentService.CancelAppointmentAsync(id, userId, request?.Reason);
        if (!success)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Randevu bulunamadı veya yetkisiz işlem." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Randevu iptal edildi." });
    }
}
