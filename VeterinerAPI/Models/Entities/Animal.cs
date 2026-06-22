using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("animals")]
public class Animal
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("owner_id")]
    public int OwnerId { get; set; }

    [Required]
    [MaxLength(100)]
    [Column("name")]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    [Column("species")]
    public string Species { get; set; } = string.Empty; // dog, cat, bird, rabbit, other

    [MaxLength(100)]
    [Column("breed")]
    public string? Breed { get; set; }

    [MaxLength(10)]
    [Column("gender")]
    public string? Gender { get; set; } // male, female, unknown

    [Column("birth_date")]
    public DateTime? BirthDate { get; set; }

    [Column("weight")]
    public decimal? Weight { get; set; }

    [MaxLength(50)]
    [Column("microchip_no")]
    public string? MicrochipNo { get; set; }

    [MaxLength(255)]
    [Column("photo_url")]
    public string? PhotoUrl { get; set; }

    [Column("notes")]
    public string? Notes { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    // Navigation properties
    [ForeignKey("OwnerId")]
    public User Owner { get; set; } = null!;

    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<Vaccine> Vaccines { get; set; } = new List<Vaccine>();
}
