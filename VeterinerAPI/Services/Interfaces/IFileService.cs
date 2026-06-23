namespace VeterinerAPI.Services.Interfaces;

public interface IFileService
{
    Task<string> UploadImageAsync(IFormFile file, string folder);
    void DeleteImage(string filePath);
}
