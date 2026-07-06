using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.AI;

public class StartSessionRequest
{
    [Required]
    public int AnimalId { get; set; }
}
