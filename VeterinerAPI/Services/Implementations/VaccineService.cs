using VeterinerAPI.DTOs.Vaccines;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class VaccineService : IVaccineService
{
    private readonly IVaccineRepository _vaccineRepository;
    private readonly IAnimalRepository _animalRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IVetRepository _vetRepository;
    private readonly IClinicRepository _clinicRepository;

    public VaccineService(
        IVaccineRepository vaccineRepository,
        IAnimalRepository animalRepository,
        IAppointmentRepository appointmentRepository,
        IVetRepository vetRepository,
        IClinicRepository clinicRepository)
    {
        _vaccineRepository = vaccineRepository;
        _animalRepository = animalRepository;
        _appointmentRepository = appointmentRepository;
        _vetRepository = vetRepository;
        _clinicRepository = clinicRepository;
    }

    public async Task<IEnumerable<VaccineResponse>> GetVaccinesByAnimalAsync(int animalId, int userId, string userRole)
    {
        // Yetki kontrolü için hayvanın sahibini bul
        var animal = await _animalRepository.GetByIdAsync(animalId);
        if (animal == null || !animal.IsActive) return new List<VaccineResponse>();

        if (userRole == "owner")
        {
            // Hasta sahibi sadece kendi hayvanının aşılarını görebilir
            if (animal.OwnerId != userId)
                throw new UnauthorizedAccessException("Bu hayvanın aşı geçmişini görüntüleme yetkiniz yok.");
        }
        else if (userRole == "vet")
        {
            // Veteriner sadece randevusu olan hayvanın aşılarını görebilir
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == userId);
            if (vet == null)
                throw new UnauthorizedAccessException("Hekim profili bulunamadı.");

            var hasAppointment = await _appointmentRepository.AnyAsync(a =>
                a.VetId == vet.Id && a.AnimalId == animalId);
            if (!hasAppointment)
                throw new UnauthorizedAccessException("Bu hayvanın aşı geçmişini görüntüleme yetkiniz yok.");
        }
        else if (userRole == "clinic_admin")
        {
            // Klinik admini sadece kliniğine randevusu olan hayvanın aşılarını görebilir
            var clinic = await _clinicRepository.FirstOrDefaultAsync(c => c.AdminUserId == userId);
            if (clinic == null)
                throw new UnauthorizedAccessException("Klinik profili bulunamadı.");

            var hasAppointment = await _appointmentRepository.AnyAsync(a =>
                a.ClinicId == clinic.Id && a.AnimalId == animalId);
            if (!hasAppointment)
                throw new UnauthorizedAccessException("Bu hayvanın aşı geçmişini görüntüleme yetkiniz yok.");
        }

        var vaccines = await _vaccineRepository.GetVaccinesByAnimalAsync(animalId);
        return vaccines.Select(v => new VaccineResponse
        {
            Id = v.Id,
            AnimalId = v.AnimalId,
            VetId = v.VetId,
            VetName = v.Vet?.User.FullName,
            VaccineName = v.VaccineName,
            AdministeredDate = v.AdministeredDate,
            NextDueDate = v.NextDueDate,
            BatchNumber = v.BatchNumber,
            Notes = v.Notes
        });
    }

    public async Task<int> CreateVaccineAsync(VaccineRequest request, int? vetId)
    {
        var vaccine = new Vaccine
        {
            AnimalId = request.AnimalId,
            VetId = vetId,
            VaccineName = request.VaccineName,
            AdministeredDate = request.AdministeredDate,
            NextDueDate = request.NextDueDate,
            BatchNumber = request.BatchNumber,
            Notes = request.Notes
        };

        await _vaccineRepository.AddAsync(vaccine);
        await _vaccineRepository.SaveChangesAsync();
        return vaccine.Id;
    }

    public async Task<bool> UpdateVaccineAsync(int id, VaccineRequest request, string userRole)
    {
        if (userRole != "vet" && userRole != "clinic_admin")
        {
            throw new UnauthorizedAccessException("Aşıları sadece hekimler güncelleyebilir.");
        }

        var vaccine = await _vaccineRepository.GetByIdAsync(id);
        if (vaccine == null) return false;

        vaccine.VaccineName = request.VaccineName;
        vaccine.AdministeredDate = request.AdministeredDate;
        vaccine.NextDueDate = request.NextDueDate;
        vaccine.BatchNumber = request.BatchNumber;
        vaccine.Notes = request.Notes;

        _vaccineRepository.Update(vaccine);
        await _vaccineRepository.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteVaccineAsync(int id, string userRole)
    {
        if (userRole != "vet" && userRole != "clinic_admin")
        {
            throw new UnauthorizedAccessException("Aşıları sadece hekimler silebilir.");
        }

        var vaccine = await _vaccineRepository.GetByIdAsync(id);
        if (vaccine == null) return false;

        _vaccineRepository.Remove(vaccine);
        await _vaccineRepository.SaveChangesAsync();
        return true;
    }
}
