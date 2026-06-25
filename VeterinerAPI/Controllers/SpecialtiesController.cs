using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeterinerAPI.Constants;
using VeterinerAPI.DTOs.Common;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SpecialtiesController : ControllerBase
{
    [HttpGet]
    public IActionResult GetSpecialties()
    {
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Uzmanlık alanları getirildi.",
            Data = VetSpecialties.All
        });
    }
}
