using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeterinerAPI.Constants;
using VeterinerAPI.DTOs.Common;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VaccineNamesController : ControllerBase
{
    [HttpGet]
    public IActionResult GetVaccineNames()
    {
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Aşı adları getirildi.",
            Data = VaccineNames.All
        });
    }
}
