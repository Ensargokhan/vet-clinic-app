using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VeterinerAPI.DTOs.Animals;
using VeterinerAPI.DTOs.Common;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AnimalsController : ControllerBase
{
    private readonly IAnimalService _animalService;

    public AnimalsController(IAnimalService animalService)
    {
        _animalService = animalService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMyAnimals()
    {
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj) || uidObj is null)
            return Unauthorized();
            
        int ownerId = (int)uidObj;
        var animals = await _animalService.GetAnimalsByOwnerAsync(ownerId);
        
        return Ok(new ApiResponse<object>
        {
            Success = true,
            Message = "Hayvanlarınız başarıyla getirildi.",
            Data = animals
        });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetAnimal(int id)
    {
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int userId = (int)uidObj!;
        string role = HttpContext.Items["UserRole"]?.ToString() ?? "owner";

        var animal = await _animalService.GetAnimalByIdAsync(id, userId, role);
        if (animal == null)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Hayvan bulunamadı." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Hayvan bilgileri getirildi.", Data = animal });
    }

    [HttpPost]
    public async Task<IActionResult> AddAnimal([FromBody] AnimalRequest request)
    {
        if (!ModelState.IsValid) return BadRequest();
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int ownerId = (int)uidObj!;

        var newAnimalId = await _animalService.CreateAnimalAsync(request, ownerId);
        
        return CreatedAtAction(nameof(GetAnimal), new { id = newAnimalId }, new ApiResponse<object>
        {
            Success = true,
            Message = "Hayvan başarıyla eklendi.",
            Data = new { AnimalId = newAnimalId }
        });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateAnimal(int id, [FromBody] AnimalRequest request)
    {
        if (!ModelState.IsValid) return BadRequest();
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int userId = (int)uidObj!;
        string role = HttpContext.Items["UserRole"]?.ToString() ?? "owner";

        var success = await _animalService.UpdateAnimalAsync(id, request, userId, role);
        if (!success)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Hayvan bulunamadı." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Hayvan bilgileri güncellendi." });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAnimal(int id)
    {
        if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
        int userId = (int)uidObj!;
        string role = HttpContext.Items["UserRole"]?.ToString() ?? "owner";

        var success = await _animalService.DeleteAnimalAsync(id, userId, role);
        if (!success)
            return NotFound(new ApiResponse<object> { Success = false, Message = "Hayvan bulunamadı." });

        return Ok(new ApiResponse<object> { Success = true, Message = "Hayvan başarıyla silindi." });
    }
}
