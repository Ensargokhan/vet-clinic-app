using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace VeterinerAPI.Data;

/// <summary>
/// Yalnızca EF Core tasarım-zamanı araçları (dotnet ef migrations/database) tarafından kullanılır.
/// Program.cs'teki ServerVersion.AutoDetect canlı DB bağlantısı gerektirir; bu factory sabit bir
/// sürüm kullanarak `migrations add`'in bağlantı olmadan çalışmasını sağlar. Çalışma zamanını etkilemez.
/// </summary>
public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .Build();

        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? "server=localhost;database=vetdb;user=root;password=";

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 32)))
            .Options;

        return new AppDbContext(options);
    }
}
