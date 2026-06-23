using Microsoft.EntityFrameworkCore;
using VeterinerAPI.Data;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication;
using VeterinerAPI.Middleware;
using VeterinerAPI.Repositories;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Repositories.Implementations;
using VeterinerAPI.Services.Interfaces;
using VeterinerAPI.Services.Implementations;
using VeterinerAPI.BackgroundServices;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// MySQL & Entity Framework Core
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

// Repositories
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IClinicRepository, ClinicRepository>();
builder.Services.AddScoped<IVetRepository, VetRepository>();
builder.Services.AddScoped<IAnimalRepository, AnimalRepository>();
builder.Services.AddScoped<IVaccineRepository, VaccineRepository>();
builder.Services.AddScoped<IAppointmentRepository, AppointmentRepository>();

// Services
builder.Services.AddScoped<IFileService, FileService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IClinicService, ClinicService>();
builder.Services.AddScoped<IVetService, VetService>();
builder.Services.AddScoped<IAnimalService, AnimalService>();
builder.Services.AddScoped<IVaccineService, VaccineService>();
builder.Services.AddScoped<IAppointmentService, AppointmentService>();

// Background Services
builder.Services.AddHostedService<AppointmentStatusWorker>();

// CORS — Ortam bazlı yapılandırma
builder.Services.AddCors(options =>
{
    if (builder.Environment.IsDevelopment())
    {
        // Geliştirme ortamında tüm kaynaklara izin ver
        options.AddPolicy("AppCorsPolicy", policy =>
        {
            policy.AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        });
    }
    else
    {
        // Production ortamında sadece izin verilen origin'ler
        var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
            ?? new[] { "https://localhost" };
        options.AddPolicy("AppCorsPolicy", policy =>
        {
            policy.WithOrigins(allowedOrigins)
                  .WithMethods("GET", "POST", "PUT", "DELETE")
                  .AllowAnyHeader()
                  .AllowCredentials();
        });
    }
});

// Rate Limiting — Kötüye kullanım ve DDoS koruması
builder.Services.AddRateLimiter(options =>
{
    // Genel politika: Tüm API için dakikada 60 istek
    options.AddFixedWindowLimiter("GeneralPolicy", opt =>
    {
        opt.PermitLimit = 60;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 0;
    });

    // Auth politikası: Kayıt/giriş için 10 dakikada 5 istek (brute-force koruması)
    options.AddFixedWindowLimiter("AuthPolicy", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromMinutes(10);
        opt.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 0;
    });

    // Randevu politikası: Randevu oluşturma için dakikada 5 istek (takvim spam koruması)
    options.AddFixedWindowLimiter("AppointmentPolicy", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 0;
    });

    // Rate limit aşıldığında dönen yanıt
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (context, cancellationToken) =>
    {
        // Retry-After header'ı ekle (saniye cinsinden)
        if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
        {
            context.HttpContext.Response.Headers.RetryAfter = ((int)retryAfter.TotalSeconds).ToString();
        }
        else
        {
            context.HttpContext.Response.Headers.RetryAfter = "60";
        }

        context.HttpContext.Response.ContentType = "application/json";
        await context.HttpContext.Response.WriteAsync(
            "{\"success\":false,\"message\":\"Çok fazla istek gönderildi. Lütfen bir süre bekleyip tekrar deneyin.\"}",
            cancellationToken);
    };
});

// Firebase Init
var firebaseConfigPath = Path.Combine(builder.Environment.ContentRootPath, "firebase-adminsdk.json");
if (File.Exists(firebaseConfigPath))
{
    FirebaseApp.Create(new AppOptions()
    {
        Credential = GoogleCredential.FromFile(firebaseConfigPath)
    });
}

// Authentication
builder.Services.AddAuthentication("Firebase")
    .AddScheme<AuthenticationSchemeOptions, FirebaseAuthHandler>("Firebase", null);

var app = builder.Build();

// Veritabanına Örnek Veri (Seed Data) Ekleme
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await DbSeeder.SeedDataAsync(context);
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Middleware sıralaması önemlidir!
app.UseMiddleware<GlobalExceptionMiddleware>(); // En dışta: tüm hataları yakalar

// HTTP Güvenlik Header'ları (Madde 7)
app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "DENY";
    context.Response.Headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
    context.Response.Headers["X-XSS-Protection"] = "1; mode=block";
    context.Response.Headers["Content-Security-Policy"] = "default-src 'self'; img-src 'self' data: https:; frame-ancestors 'none';";
    // Sunucu bilgisini gizle
    context.Response.Headers.Remove("Server");
    context.Response.Headers.Remove("X-Powered-By");

    // HSTS — Sadece production'da (HTTPS zorunlu)
    if (!app.Environment.IsDevelopment())
    {
        context.Response.Headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains";
    }

    await next();
});

app.UseStaticFiles(); // wwwroot içindeki statik dosyaları (resimler vb.) sunmak için
app.UseCors("AppCorsPolicy");
app.UseRateLimiter(); // Rate limiting
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<UserResolverMiddleware>();
app.MapControllers().RequireRateLimiting("GeneralPolicy"); // Tüm endpoint'lere GeneralPolicy uygula

app.Run();

