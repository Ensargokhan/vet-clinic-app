namespace VeterinerAPI.DTOs.Clinics;

public class ClinicSearchRequest
{
    public string? Search { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    
    private int _page = 1;
    public int Page
    {
        get => _page;
        set => _page = value < 1 ? 1 : value;
    }

    private int _pageSize = 15;
    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value > 50 ? 50 : (value < 1 ? 1 : value);
    }
}
