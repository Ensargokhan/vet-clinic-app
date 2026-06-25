using System;
using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Vets;

public class UpdateVetScheduleRequest
{
    [Range(0, 6, ErrorMessage = "Gün bilgisi 0 (Pazar) ile 6 (Cumartesi) arasında olmalıdır.")]
    public byte DayOfWeek { get; set; }     // 0=Pazar, 1=Pazartesi, ..., 6=Cumartesi
    public TimeSpan StartTime { get; set; } // Örn: 09:00
    public TimeSpan EndTime { get; set; }   // Örn: 17:00

    [Range(5, 240, ErrorMessage = "Randevu süresi 5 ile 240 dakika arasında olmalıdır.")]
    public int SlotDuration { get; set; }   // Dakika (ör: 30)
    public bool IsActive { get; set; }      // O gün çalışıyor mu?
}
