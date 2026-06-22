using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ClinicsController : ControllerBase
{
    private readonly IClinicService _clinicService;

    public ClinicsController(IClinicService clinicService)
    {
        _clinicService = clinicService;
    }

    [HttpGet]
    public async Task<IActionResult> GetClinics([FromQuery] VeterinerAPI.DTOs.Clinics.ClinicSearchRequest request)
    {
        var clinics = await _clinicService.SearchClinicsAsync(request);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Klinikler başarıyla getirildi.",
            Data = clinics
        });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetClinicDetails(int id)
    {
        var clinic = await _clinicService.GetClinicDetailsAsync(id);
        if (clinic == null)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Klinik bulunamadı." });

        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Klinik detayları getirildi.",
            Data = clinic
        });
    }

    [HttpGet("my-clinic/dashboard")]
    public async Task<IActionResult> GetMyClinicDashboard()
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var data = await _clinicService.GetClinicDashboardAsync(firebaseUid);
        return Ok(new ApiResponse<object> { Success = true, Message = "Dashboard getirildi.", Data = data });
    }

    [HttpGet("my-clinic")]
    public async Task<IActionResult> GetMyClinic()
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var data = await _clinicService.GetMyClinicAsync(firebaseUid);
        return Ok(new ApiResponse<object> { Success = true, Message = "Klinik bilgileri getirildi.", Data = data });
    }

    [HttpPut("my-clinic")]
    public async Task<IActionResult> UpdateMyClinic([FromBody] VeterinerAPI.DTOs.Clinics.UpdateClinicRequest request)
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var data = await _clinicService.UpdateMyClinicAsync(firebaseUid, request);
        return Ok(new ApiResponse<object> { Success = true, Message = "Klinik güncellendi.", Data = data });
    }

    [HttpPost("my-clinic/vets")]
    public async Task<IActionResult> AddVetToClinic([FromBody] VeterinerAPI.DTOs.Vets.AddVetToClinicRequest request)
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var data = await _clinicService.AddVetToClinicAsync(firebaseUid, request);
        return Ok(new ApiResponse<object> { Success = true, Message = "Hekim eklendi.", Data = data });
    }

    [HttpDelete("my-clinic/vets/{id}")]
    public async Task<IActionResult> DeleteVetFromClinic(int id)
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var data = await _clinicService.RemoveVetFromClinicAsync(firebaseUid, id);
        return Ok(new ApiResponse<object> { Success = true, Message = "Hekim silindi.", Data = data });
    }

    [HttpGet("my-clinic/appointments")]
    public async Task<IActionResult> GetMyClinicAppointments()
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        var data = await _clinicService.GetClinicAppointmentsAsync(firebaseUid);
        return Ok(new ApiResponse<object> { Success = true, Message = "Randevular getirildi.", Data = data });
    }

    [HttpPut("my-clinic/appointments/{id}/status")]
    public async Task<IActionResult> UpdateClinicAppointmentStatus(int id, [FromBody] VeterinerAPI.DTOs.Appointments.UpdateAppointmentStatusRequest request)
    {
        var firebaseUid = User.FindFirstValue("FirebaseUid");
        if (string.IsNullOrEmpty(firebaseUid)) return Unauthorized();

        await _clinicService.UpdateClinicAppointmentStatusAsync(firebaseUid, id, request.Status, request.Notes);
        return Ok(new ApiResponse<object> { Success = true, Message = "Randevu durumu güncellendi." });
    }
}
