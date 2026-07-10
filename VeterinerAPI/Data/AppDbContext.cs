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
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<Conversation> Conversations { get; set; }
    public DbSet<Message> Messages { get; set; }
    public DbSet<Announcement> Announcements { get; set; }
    public DbSet<AiChatSession> AiChatSessions { get; set; }
    public DbSet<AiChatMessage> AiChatMessages { get; set; }
    public DbSet<AiReport> AiReports { get; set; }

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

            // Arama/filtreleme için index'ler
            entity.HasIndex(c => c.City);
            entity.HasIndex(c => c.District);
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

            // Uzmanlık filtresi (Vets.Any join) için index'ler
            entity.HasIndex(v => v.ClinicId);
            entity.HasIndex(v => v.Specialty);
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

        // ===== NOTIFICATION =====
        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasOne(n => n.User)
                  .WithMany()
                  .HasForeignKey(n => n.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            // Kullanıcının bildirimlerini tarih sırasıyla çekmek için
            entity.HasIndex(n => n.UserId);
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

            // Bir kullanıcı bir kliniğe yalnızca tek yorum yazabilir (düzenlenebilir).
            entity.HasIndex(cr => new { cr.ClinicId, cr.UserId }).IsUnique();

            // Kliniğin yorumlarını tarih sırasıyla listelemek için
            entity.HasIndex(cr => cr.ClinicId);
        });

        // ===== CONVERSATION =====
        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.HasOne(c => c.OwnerUser)
                  .WithMany()
                  .HasForeignKey(c => c.OwnerUserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(c => c.Vet)
                  .WithMany()
                  .HasForeignKey(c => c.VetId)
                  .OnDelete(DeleteBehavior.Restrict);

            // Bir owner–hekim çifti için tek konuşma
            entity.HasIndex(c => new { c.OwnerUserId, c.VetId }).IsUnique();
        });

        // ===== MESSAGE =====
        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasOne(m => m.Conversation)
                  .WithMany(c => c.Messages)
                  .HasForeignKey(m => m.ConversationId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(m => m.Sender)
                  .WithMany()
                  .HasForeignKey(m => m.SenderUserId)
                  .OnDelete(DeleteBehavior.Restrict);

            // Konuşma mesajlarını sırayla çekmek + okunmamış sorgusu için
            entity.HasIndex(m => new { m.ConversationId, m.CreatedAt });
            entity.HasIndex(m => new { m.ConversationId, m.IsRead });
        });

        // ===== ANNOUNCEMENT =====
        modelBuilder.Entity<Announcement>(entity =>
        {
            entity.HasOne(a => a.Clinic)
                  .WithMany()
                  .HasForeignKey(a => a.ClinicId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(a => a.ClinicId);
        });

        // ===== AI CHAT SESSION =====
        modelBuilder.Entity<AiChatSession>(entity =>
        {
            entity.HasOne(s => s.User)
                  .WithMany()
                  .HasForeignKey(s => s.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(s => s.Animal)
                  .WithMany()
                  .HasForeignKey(s => s.AnimalId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(s => s.UserId);
        });

        // ===== AI CHAT MESSAGE =====
        modelBuilder.Entity<AiChatMessage>(entity =>
        {
            entity.HasOne(m => m.Session)
                  .WithMany(s => s.Messages)
                  .HasForeignKey(m => m.SessionId)
                  .OnDelete(DeleteBehavior.Cascade);

            // Oturum mesajlarını sırayla çekmek için
            entity.HasIndex(m => new { m.SessionId, m.CreatedAt });
        });

        // ===== AI REPORT =====
        modelBuilder.Entity<AiReport>(entity =>
        {
            entity.HasOne(r => r.Session)
                  .WithMany()
                  .HasForeignKey(r => r.SessionId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Animal)
                  .WithMany()
                  .HasForeignKey(r => r.AnimalId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.User)
                  .WithMany()
                  .HasForeignKey(r => r.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            // Randevu silinirse rapor kalsın ama bağ kopsun
            entity.HasOne(r => r.Appointment)
                  .WithMany()
                  .HasForeignKey(r => r.AppointmentId)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(r => r.AnimalId);
            entity.HasIndex(r => r.AppointmentId);
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
