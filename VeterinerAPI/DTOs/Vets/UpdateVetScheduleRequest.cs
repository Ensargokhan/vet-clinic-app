using System;

namespace VeterinerAPI.DTOs.Vets;

public class UpdateVetScheduleRequest
{
    public byte DayOfWeek { get; set; }     // 0=Pazar, 1=Pazartesi, ..., 6=Cumartesi
    public TimeSpan StartTime { get; set; } // Örn: 09:00
    public TimeSpan EndTime { get; set; }   // Örn: 17:00
    public int SlotDuration { get; set; }   // Dakika (ör: 30)
    public bool IsActive { get; set; }      // O gün çalışıyor mu?
}
