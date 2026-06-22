namespace VeterinerAPI.DTOs.Vets;

public class VetScheduleResponse
{
    public int Id { get; set; }
    public byte DayOfWeek { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public int SlotDuration { get; set; }
}
