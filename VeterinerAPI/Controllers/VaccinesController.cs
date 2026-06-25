using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeterinerAPI.DTOs.Vaccines;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VaccinesController : ControllerBase
{
    private readonly IVaccineService _vaccineService;

    public VaccinesController(IVaccineService vaccineService)
    {
        _vaccineService = vaccineService;
    }

    [HttpGet("animal/{animalId}")]
    public async Task<IActionResult> GetVaccines(int animalId)
    {
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int userId = (int)uidObj!;
        string role = HttpContext.Items["UserRole"]?.ToString() ?? "owner";

        var vaccines = await _vaccineService.GetVaccinesByAnimalAsync(animalId, userId, role);
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Aşı geçmişi getirildi.",
            Data = vaccines
        });
    }

    [HttpPost]
    public async Task<IActionResult> AddVaccine([FromBody] VaccineRequest request)
    {
        if (!ModelState.IsValid) return BadRequest();
        
        int? vetId = null; 

        var newVaccineId = await _vaccineService.CreateVaccineAsync(request, vetId);

        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Aşı başarıyla eklendi.",
            Data = new { VaccineId = newVaccineId }
        });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateVaccine(int id, [FromBody] VaccineRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(new ApiResponse<object> { Success = false, Message = "Geçersiz veriler." });
        string role = HttpContext.Items["UserRole"]?.ToString() ?? "owner";

        var success = await _vaccineService.UpdateVaccineAsync(id, request, role);
        if (!success)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Aşı bulunamadı." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Aşı güncellendi." });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteVaccine(int id)
    {
        string role = HttpContext.Items["UserRole"]?.ToString() ?? "owner";

        var success = await _vaccineService.DeleteVaccineAsync(id, role);
        if (!success)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Aşı bulunamadı." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Aşı silindi." });
    }
}
