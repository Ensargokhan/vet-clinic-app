using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VeterinerAPI.Models.Entities;

/// <summary>
/// AI ön muayene sohbetinin sonunda üretilen yapılandırılmış anamnez raporu.
/// Randevu akışında oluşturulur ve isteğe bağlı olarak bir randevuya bağlanır
/// (AppointmentId) — böylece hekim randevu kartından raporu görebilir.
/// </summary>
[Table("ai_reports")]
public class AiReport
{
    [Key]
    [Column("id")]
    public int Id { get; set; }

    [Column("session_id")]
    public int SessionId { get; set; }

    [Column("animal_id")]
    public int AnimalId { get; set; }

    [Column("user_id")]
    public int UserId { get; set; }

    // Rapor bir randevuya bağlanınca dolar; randevu silinirse null'a düşer (SetNull).
    [Column("appointment_id")]
    public int? AppointmentId { get; set; }

    [Required]
    [Column("report_content")]
    public string ReportContent { get; set; } = string.Empty;

    [Required]
    [Column("symptoms_summary")]
    public string SymptomsSummary { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    [Column("urgency_level")]
    public string UrgencyLevel { get; set; } = "low"; // low, medium, high, emergency

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    [ForeignKey("SessionId")]
    public AiChatSession Session { get; set; } = null!;

    [ForeignKey("AnimalId")]
    public Animal Animal { get; set; } = null!;

    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    [ForeignKey("AppointmentId")]
    public Appointment? Appointment { get; set; }
}
