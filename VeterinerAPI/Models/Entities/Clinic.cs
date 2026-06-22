using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("clinics")]
public class Clinic
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Required]
    [MaxLength(150)]
    [Column("name")]
    public string Name { get; set; } = string.Empty;

    [Column("address")]
    public string? Address { get; set; }

    [MaxLength(100)]
    [Column("city")]
    public string? City { get; set; }

    [MaxLength(100)]
    [Column("district")]
    public string? District { get; set; }

    [MaxLength(20)]
    [Column("phone")]
    public string? Phone { get; set; }

    [MaxLength(150)]
    [Column("email")]
    public string? Email { get; set; }

    [Column("description")]
    public string? Description { get; set; }

    [MaxLength(255)]
    [Column("logo_url")]
    public string? LogoUrl { get; set; }

    [Column("latitude")]
    public decimal? Latitude { get; set; }

    [Column("longitude")]
    public decimal? Longitude { get; set; }

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [Column("admin_user_id")]
    public int AdminUserId { get; set; }

    // Navigation properties
    [ForeignKey("AdminUserId")]
    public User AdminUser { get; set; } = null!;

    public ICollection<Vet> Vets { get; set; } = new List<Vet>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<ClinicReview> Reviews { get; set; } = new List<ClinicReview>();
}
