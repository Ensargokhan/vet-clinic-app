using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Repositories.Implementations;

public class AppointmentRepository : Repository<Appointment>, IAppointmentRepository
{
    public AppointmentRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<Appointment>> GetAppointmentsByUserAsync(int userId)
    {
        return await _dbSet
            .Include(a => a.Animal)
            .Include(a => a.Vet)
                .ThenInclude(v => v!.User)
            .Where(a => a.OwnerId == userId)
            .OrderByDescending(a => a.AppointmentDate)
            .ToListAsync();
    }

    public async Task<IEnumerable<Appointment>> GetAppointmentsByVetAndDateAsync(int vetId, DateTime date)
    {
        return await _dbSet
            .Where(a => a.VetId == vetId 
                     && a.AppointmentDate.Date == date.Date 
                     && a.Status != "cancelled")
            .ToListAsync();
    }

    public async Task<Appointment?> GetAppointmentWithDetailsAsync(int appointmentId)
    {
        return await _dbSet
            .Include(a => a.Animal)
            .Include(a => a.Vet)
                .ThenInclude(v => v.User)
            .FirstOrDefaultAsync(a => a.Id == appointmentId);
    }

    public async Task<IEnumerable<Appointment>> GetAppointmentsByClinicIdAsync(int clinicId)
    {
        return await _dbSet
            .Include(a => a.Animal)
            .Include(a => a.Owner)
            .Include(a => a.Vet)
                .ThenInclude(v => v.User)
            .Where(a => a.ClinicId == clinicId)
            .OrderByDescending(a => a.AppointmentDate)
            .ToListAsync();
    }

    public async Task<int> GetTodayAppointmentCountByClinicAsync(int clinicId)
    {
        var today = DateTime.UtcNow.Date;
        return await _dbSet.CountAsync(a => 
            a.ClinicId == clinicId && 
            a.AppointmentDate.Date == today &&
            a.Status != "cancelled");
    }

    public async Task<int> GetPendingAppointmentCountByClinicAsync(int clinicId)
    {
        return await _dbSet.CountAsync(a => 
            a.ClinicId == clinicId && 
            a.Status == "pending");
    }

    public async Task<IEnumerable<Appointment>> GetAppointmentsByVetIdAsync(int vetId)
    {
        return await _dbSet
            .Include(a => a.Animal)
            .Include(a => a.Owner)
            .Include(a => a.Clinic)
            .Include(a => a.Vet)
                .ThenInclude(v => v.User)
            .Where(a => a.VetId == vetId)
            .OrderByDescending(a => a.AppointmentDate)
            .ToListAsync();
    }
}
