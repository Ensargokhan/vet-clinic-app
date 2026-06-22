using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("vaccines")]
public class Vaccine
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("animal_id")]
    public int AnimalId { get; set; }

    [Column("vet_id")]
    public int? VetId { get; set; }

    [Required]
    [MaxLength(150)]
    [Column("vaccine_name")]
    public string VaccineName { get; set; } = string.Empty;

    [Required]
    [Column("administered_date")]
    public DateTime AdministeredDate { get; set; }

    [Column("next_due_date")]
    public DateTime? NextDueDate { get; set; }

    [MaxLength(100)]
    [Column("batch_number")]
    public string? BatchNumber { get; set; }

    [Column("notes")]
    public string? Notes { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    [ForeignKey("AnimalId")]
    public Animal Animal { get; set; } = null!;

    [ForeignKey("VetId")]
    public Vet? Vet { get; set; }
}
