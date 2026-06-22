using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

[Table("users")]
public class User
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Required]
    [MaxLength(128)]
    [Column("firebase_uid")]
    public string FirebaseUid { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    [Column("full_name")]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [MaxLength(150)]
    [Column("email")]
    public string Email { get; set; } = string.Empty;

    [MaxLength(20)]
    [Column("phone")]
    public string? Phone { get; set; }

    [Required]
    [MaxLength(20)]
    [Column("role")]
    public string Role { get; set; } = "owner"; // owner, vet, clinic_admin

    [MaxLength(255)]
    [Column("profile_photo")]
    public string? ProfilePhoto { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [Column("is_active")]
    public bool IsActive { get; set; } = true;

    // Navigation properties
    public ICollection<Animal> Animals { get; set; } = new List<Animal>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<ClinicReview> ClinicReviews { get; set; } = new List<ClinicReview>();
}
