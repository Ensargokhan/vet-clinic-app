using VeterinerAPI.DTOs.Animals;
using VeterinerAPI.Helpers;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class AnimalService : IAnimalService
{
    private readonly IAnimalRepository _animalRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IVetRepository _vetRepository;
    private readonly IClinicRepository _clinicRepository;

    public AnimalService(
        IAnimalRepository animalRepository,
        IAppointmentRepository appointmentRepository,
        IVetRepository vetRepository,
        IClinicRepository clinicRepository)
    {
        _animalRepository = animalRepository;
        _appointmentRepository = appointmentRepository;
        _vetRepository = vetRepository;
        _clinicRepository = clinicRepository;
    }

    public async Task<IEnumerable<AnimalResponse>> GetAnimalsByOwnerAsync(int ownerId)
    {
        var animals = await _animalRepository.GetAnimalsByOwnerAsync(ownerId);
        return animals.Select(a => new AnimalResponse
        {
            Id = a.Id,
            OwnerId = a.OwnerId,
            Name = a.Name,
            Species = a.Species,
            Breed = a.Breed,
            Gender = a.Gender,
            BirthDate = a.BirthDate,
            Weight = a.Weight,
            MicrochipNo = a.MicrochipNo,
            PhotoUrl = a.PhotoUrl,
            Notes = a.Notes,
            CreatedAt = a.CreatedAt
        });
    }

    public async Task<AnimalResponse?> GetAnimalByIdAsync(int id, int userId, string userRole)
    {
        var animal = await _animalRepository.GetAnimalWithOwnerAsync(id);
        if (animal == null) return null;

        // Yetki kontrolü: Rol bazlı erişim
        if (userRole == "owner")
        {
            // Hasta sahibi sadece kendi hayvanını görebilir
            if (animal.OwnerId != userId)
                throw new UnauthorizedAccessException("Bu hayvana erişim yetkiniz yok.");
        }
        else if (userRole == "vet")
        {
            // Veteriner sadece randevusu olan hayvanları görebilir
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == userId);
            if (vet == null)
                throw new UnauthorizedAccessException("Hekim profili bulunamadı.");

            var hasAppointment = await _appointmentRepository.AnyAsync(a =>
                a.VetId == vet.Id && a.AnimalId == id);
            if (!hasAppointment)
                throw new UnauthorizedAccessException("Bu hayvana erişim yetkiniz yok. Sadece randevusu olan hayvanları görüntüleyebilirsiniz.");
        }
        else if (userRole == "clinic_admin")
        {
            // Klinik admini sadece kliniğine randevusu olan hayvanları görebilir
            var clinic = await _clinicRepository.FirstOrDefaultAsync(c => c.AdminUserId == userId);
            if (clinic == null)
                throw new UnauthorizedAccessException("Klinik profili bulunamadı.");

            var hasAppointment = await _appointmentRepository.AnyAsync(a =>
                a.ClinicId == clinic.Id && a.AnimalId == id);
            if (!hasAppointment)
                throw new UnauthorizedAccessException("Bu hayvana erişim yetkiniz yok. Sadece kliniğinize randevusu olan hayvanları görüntüleyebilirsiniz.");
        }

        return new AnimalResponse
        {
            Id = animal.Id,
            OwnerId = animal.OwnerId,
            Name = animal.Name,
            Species = animal.Species,
            Breed = animal.Breed,
            Gender = animal.Gender,
            BirthDate = animal.BirthDate,
            Weight = animal.Weight,
            MicrochipNo = animal.MicrochipNo,
            PhotoUrl = animal.PhotoUrl,
            Notes = animal.Notes,
            CreatedAt = animal.CreatedAt
        };
    }

    public async Task<int> CreateAnimalAsync(AnimalRequest request, int ownerId)
    {
        var animal = new Animal
        {
            OwnerId = ownerId,
            Name = InputSanitizer.Sanitize(request.Name)!,
            Species = InputSanitizer.Sanitize(request.Species)!,
            Breed = InputSanitizer.Sanitize(request.Breed),
            Gender = request.Gender,
            BirthDate = request.BirthDate,
            Weight = request.Weight,
            MicrochipNo = InputSanitizer.Sanitize(request.MicrochipNo),
            PhotoUrl = request.PhotoUrl,
            Notes = InputSanitizer.Sanitize(request.Notes)
        };

        await _animalRepository.AddAsync(animal);
        await _animalRepository.SaveChangesAsync();
        return animal.Id;
    }

    public async Task<bool> UpdateAnimalAsync(int id, AnimalRequest request, int userId, string userRole)
    {
        var animal = await _animalRepository.GetByIdAsync(id);
        if (animal == null || !animal.IsActive) return false;

        // Sadece hasta sahibi hayvan bilgilerini güncelleyebilir
        if (userRole != "owner" || animal.OwnerId != userId)
        {
            throw new UnauthorizedAccessException("Hayvan bilgilerini sadece hayvanın sahibi güncelleyebilir.");
        }

        animal.Name = InputSanitizer.Sanitize(request.Name)!;
        animal.Species = InputSanitizer.Sanitize(request.Species)!;
        animal.Breed = InputSanitizer.Sanitize(request.Breed);
        animal.Gender = request.Gender;
        animal.BirthDate = request.BirthDate;
        animal.Weight = request.Weight;
        animal.MicrochipNo = InputSanitizer.Sanitize(request.MicrochipNo);
        animal.PhotoUrl = request.PhotoUrl;
        animal.Notes = InputSanitizer.Sanitize(request.Notes);

        _animalRepository.Update(animal);
        await _animalRepository.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAnimalAsync(int id, int userId, string userRole)
    {
        var animal = await _animalRepository.GetByIdAsync(id);
        if (animal == null || !animal.IsActive) return false;

        // Sadece hasta sahibi hayvanı silebilir
        if (userRole != "owner" || animal.OwnerId != userId)
        {
            throw new UnauthorizedAccessException("Hayvanı sadece hayvanın sahibi silebilir.");
        }

        animal.IsActive = false; // Soft delete
        _animalRepository.Update(animal);
        await _animalRepository.SaveChangesAsync();
        return true;
    }
}
