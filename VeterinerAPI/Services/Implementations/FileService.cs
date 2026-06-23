using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class FileService : IFileService
{
    private readonly IWebHostEnvironment _env;
    private readonly string[] _allowedExtensions = { ".jpg", ".jpeg", ".png", ".webp" };
    private const int MaxFileSize = 5 * 1024 * 1024; // 5 MB

    public FileService(IWebHostEnvironment env)
    {
        _env = env;
    }

    public async Task<string> UploadImageAsync(IFormFile file, string folder)
    {
        if (file == null || file.Length == 0)
            throw new ArgumentException("Dosya seçilmedi veya boş.");

        if (file.Length > MaxFileSize)
            throw new ArgumentException("Dosya boyutu 5 MB'ı aşamaz.");

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (string.IsNullOrEmpty(ext) || !_allowedExtensions.Contains(ext))
            throw new ArgumentException("Sadece .jpg, .jpeg, .png ve .webp uzantılı dosyalara izin verilmektedir.");

        var fileName = $"{Guid.NewGuid()}{ext}";
        
        var uploadPath = Path.Combine(_env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), "uploads", folder);
        
        if (!Directory.Exists(uploadPath))
        {
            Directory.CreateDirectory(uploadPath);
        }

        var filePath = Path.Combine(uploadPath, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        return $"/uploads/{folder}/{fileName}";
    }

    public void DeleteImage(string filePath)
    {
        if (string.IsNullOrEmpty(filePath)) return;

        // Path traversal attack önlemi
        if (filePath.Contains("..")) return;

        // "uploads/..." pathinden tam dosya yolunu bul
        var relativePath = filePath.TrimStart('/');
        var fullPath = Path.Combine(_env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), relativePath);

        if (File.Exists(fullPath))
        {
            try
            {
                File.Delete(fullPath);
            }
            catch
            {
                // Hata yutulabilir, loglanabilir
            }
        }
    }
}
