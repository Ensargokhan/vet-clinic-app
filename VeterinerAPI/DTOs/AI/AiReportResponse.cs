namespace VeterinerAPI.DTOs.AI;

public class AiReportResponse
{
    public int Id { get; set; }
    public int AnimalId { get; set; }
    public int? AppointmentId { get; set; }
    public string ReportContent { get; set; } = string.Empty;
    public string SymptomsSummary { get; set; } = string.Empty;
    public string UrgencyLevel { get; set; } = "low";
    public DateTime CreatedAt { get; set; }
}
