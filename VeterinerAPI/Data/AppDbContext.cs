using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Models.Entities;

namespace VeterinerAPI.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Clinic> Clinics { get; set; }
    public DbSet<Vet> Vets { get; set; }
    public DbSet<Animal> Animals { get; set; }
    public DbSet<Appointment> Appointments { get; set; }
    public DbSet<VetSchedule> VetSchedules { get; set; }
    public DbSet<Vaccine> Vaccines { get; set; }
    public DbSet<ClinicReview> ClinicReviews { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ===== USER =====
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(u => u.FirebaseUid).IsUnique();
            entity.HasIndex(u => u.Email).IsUnique();
        });

        // ===== CLINIC =====
        modelBuilder.Entity<Clinic>(entity =>
        {
            entity.Property(c => c.Latitude).HasPrecision(10, 8);
            entity.Property(c => c.Longitude).HasPrecision(11, 8);
        });

        // ===== VET =====
        modelBuilder.Entity<Vet>(entity =>
        {
            entity.HasOne(v => v.User)
                  .WithMany()
                  .HasForeignKey(v => v.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(v => v.Clinic)
                  .WithMany(c => c.Vets)
                  .HasForeignKey(v => v.ClinicId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // ===== ANIMAL =====
        modelBuilder.Entity<Animal>(entity =>
        {
            entity.HasOne(a => a.Owner)
                  .WithMany(u => u.Animals)
                  .HasForeignKey(a => a.OwnerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.Property(a => a.Weight).HasPrecision(5, 2);
            entity.HasIndex(a => a.OwnerId);
        });

        // ===== APPOINTMENT =====
        modelBuilder.Entity<Appointment>(entity =>
        {
            entity.HasOne(a => a.Animal)
                  .WithMany(an => an.Appointments)
                  .HasForeignKey(a => a.AnimalId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(a => a.Owner)
                  .WithMany(u => u.Appointments)
                  .HasForeignKey(a => a.OwnerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(a => a.Vet)
                  .WithMany(v => v.Appointments)
                  .HasForeignKey(a => a.VetId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(a => a.Clinic)
                  .WithMany(c => c.Appointments)
                  .HasForeignKey(a => a.ClinicId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(a => a.OwnerId);
            entity.HasIndex(a => a.VetId);
            entity.HasIndex(a => a.AppointmentDate);
        });

        // ===== VET SCHEDULE =====
        modelBuilder.Entity<VetSchedule>(entity =>
        {
            entity.HasOne(vs => vs.Vet)
                  .WithMany(v => v.Schedules)
                  .HasForeignKey(vs => vs.VetId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // ===== VACCINE =====
        modelBuilder.Entity<Vaccine>(entity =>
        {
            entity.HasOne(v => v.Animal)
                  .WithMany(a => a.Vaccines)
                  .HasForeignKey(v => v.AnimalId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(v => v.Vet)
                  .WithMany()
                  .HasForeignKey(v => v.VetId)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        // ===== CLINIC REVIEW =====
        modelBuilder.Entity<ClinicReview>(entity =>
        {
            entity.HasOne(cr => cr.Clinic)
                  .WithMany(c => c.Reviews)
                  .HasForeignKey(cr => cr.ClinicId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(cr => cr.User)
                  .WithMany(u => u.ClinicReviews)
                  .HasForeignKey(cr => cr.UserId)
                  .OnDelete(DeleteBehavior.Restrict);
        });
    }

    public override int SaveChanges()
    {
        UpdateTimestamps();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateTimestamps();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void UpdateTimestamps()
    {
        var entries = ChangeTracker.Entries()
            .Where(e => e.State == EntityState.Modified);

        foreach (var entry in entries)
        {
            var updatedAtProperty = entry.Properties
                .FirstOrDefault(p => p.Metadata.Name == "UpdatedAt");

            if (updatedAtProperty != null)
            {
                updatedAtProperty.CurrentValue = DateTime.UtcNow;
            }
        }
    }
}
