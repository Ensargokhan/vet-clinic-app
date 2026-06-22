using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VetsController : ControllerBase
{
    private readonly IVetService _vetService;

    public VetsController(IVetService vetService)
    {
        _vetService = vetService;
    }

    [HttpGet("{id}/schedule")]
    public async Task<IActionResult> GetVetSchedule(int id)
    {
        var schedules = await _vetService.GetVetScheduleAsync(id);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Çalışma takvimi getirildi.",
            Data = schedules
        });
    }

    [HttpGet("{id}/available-slots")]
    public async Task<IActionResult> GetAvailableSlots(int id, [FromQuery] string date)
    {
        if (!DateTime.TryParse(date, out DateTime requestedDate))
        {
            return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz tarih formatı (YYYY-MM-DD bekleniyor)." });
        }

        var slots = await _vetService.GetAvailableSlotsAsync(id, requestedDate);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Müsait saatler getirildi.",
            Data = slots
        });
    }


    [HttpGet("my-dashboard")]
    public async Task<IActionResult> GetMyDashboard()
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var dashboard = await _vetService.GetVetDashboardAsync(firebaseUid);
        return Ok(new ApiResponse<object> { Success = true, Data = dashboard });
    }

    [HttpGet("my-appointments")]
    public async Task<IActionResult> GetMyAppointments()
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var appointments = await _vetService.GetVetAppointmentsAsync(firebaseUid);
        return Ok(new ApiResponse<object> { Success = true, Data = appointments });
    }

    [HttpPut("my-appointments/{id}/status")]
    public async Task<IActionResult> UpdateAppointmentStatus(int id, [FromBody] VeterinerAPI.DTOs.Appointments.UpdateAppointmentStatusRequest request)
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        await _vetService.UpdateAppointmentStatusAsync(firebaseUid, id, request.Status, request.Notes);
        return Ok(new ApiResponse<object> { Success = true, Message = "Randevu durumu güncellendi." });
    }

    [HttpGet("my-schedule")]
    public async Task<IActionResult> GetMySchedule()
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var schedule = await _vetService.GetMyScheduleAsync(firebaseUid);
        return Ok(new ApiResponse<object> { Success = true, Data = schedule });
    }

    [HttpPut("my-schedule")]
    public async Task<IActionResult> UpdateMySchedule([FromBody] List<VeterinerAPI.DTOs.Vets.UpdateVetScheduleRequest> schedules)
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        await _vetService.UpdateMyScheduleAsync(firebaseUid, schedules);
        return Ok(new ApiResponse<object> { Success = true, Message = "Çalışma saatleri güncellendi." });
    }

    [HttpGet("my-profile")]
    public async Task<IActionResult> GetMyProfile()
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var profile = await _vetService.GetVetProfileAsync(firebaseUid);
        return Ok(new ApiResponse<object> { Success = true, Data = profile });
    }

    [HttpPut("my-profile")]
    public async Task<IActionResult> UpdateMyProfile([FromBody] VeterinerAPI.DTOs.Vets.UpdateVetProfileRequest request)
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var profile = await _vetService.UpdateVetProfileAsync(firebaseUid, request);
        return Ok(new ApiResponse<object> { Success = true, Message = "Profil güncellendi.", Data = profile });
    }
}
