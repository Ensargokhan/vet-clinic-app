using VeterinerAPI.DTOs.Common;
using VeterinerAPI.DTOs.Reviews;
using VeterinerAPI.Helpers;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class ClinicReviewService : IClinicReviewService
{
    private readonly IClinicReviewRepository _reviewRepository;
    private readonly IClinicRepository _clinicRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IUserRepository _userRepository;
    private readonly INotificationService _notificationService;

    public ClinicReviewService(
        IClinicReviewRepository reviewRepository,
        IClinicRepository clinicRepository,
        IAppointmentRepository appointmentRepository,
        IUserRepository userRepository,
        INotificationService notificationService)
    {
        _reviewRepository = reviewRepository;
        _clinicRepository = clinicRepository;
        _appointmentRepository = appointmentRepository;
        _userRepository = userRepository;
        _notificationService = notificationService;
    }

    public async Task<int> CreateOrUpdateAsync(int userId, string role, int clinicId, ClinicReviewRequest request)
    {
        // Yalnız hasta sahibi değerlendirebilir (hekim/klinik yöneticisi kendi kliniğini puanlayamaz)
        if (role != "owner")
            throw new UnauthorizedAccessException("Değerlendirmeyi yalnızca hasta sahipleri yapabilir.");

        var clinic = await _clinicRepository.GetByIdAsync(clinicId);
        if (clinic == null || !clinic.IsActive)
            throw new KeyNotFoundException("Klinik bulunamadı.");

        // Yetki: bu klinikte tamamlanmış en az bir randevusu olmalı
        if (!await HasCompletedAppointmentAsync(userId, clinicId))
            throw new UnauthorizedAccessException(
                "Bu kliniği değerlendirebilmek için tamamlanmış bir randevunuz olmalıdır.");

        var comment = InputSanitizer.Sanitize(request.Comment);
        if (string.IsNullOrWhiteSpace(comment)) comment = null;

        var existing = await _reviewRepository.GetByClinicAndUserAsync(clinicId, userId);

        if (existing != null)
        {
            // Güncelleme: bildirim gönderilmez (spam olmasın)
            existing.Rating = request.Rating;
            existing.Comment = comment;
            _reviewRepository.Update(existing);
            await _reviewRepository.SaveChangesAsync();
            return existing.Id;
        }

        var review = new ClinicReview
        {
            ClinicId = clinicId,
            UserId = userId,
            Rating = request.Rating,
            Comment = comment,
            IsVisible = true
        };
        await _reviewRepository.AddAsync(review);
        await _reviewRepository.SaveChangesAsync();

        // Yeni değerlendirmede klinik yöneticisini bilgilendir
        var user = await _userRepository.GetByIdAsync(userId);
        var userName = user?.FullName ?? "Bir hasta sahibi";
        await _notificationService.NotifyAsync(
            clinic.AdminUserId,
            "Yeni değerlendirme",
            $"{userName} kliniğinizi {request.Rating} yıldızla değerlendirdi.",
            "new_review",
            clinicId);

        return review.Id;
    }

    public async Task<bool> DeleteAsync(int userId, int clinicId)
    {
        var review = await _reviewRepository.GetByClinicAndUserAsync(clinicId, userId);
        if (review == null) return false;

        _reviewRepository.Remove(review);
        await _reviewRepository.SaveChangesAsync();
        return true;
    }

    public async Task<PagedResponse<ClinicReviewResponse>> GetByClinicAsync(int clinicId, int userId, int page, int pageSize)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 50) pageSize = 10;

        var (items, totalCount) = await _reviewRepository.GetByClinicPagedAsync(clinicId, page, pageSize);
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        return new PagedResponse<ClinicReviewResponse>
        {
            Items = items.Select(r => ToResponse(r, userId)).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = totalPages,
            HasPrevious = page > 1,
            HasNext = page < totalPages
        };
    }

    public async Task<ClinicReviewSummaryResponse> GetSummaryAsync(int clinicId)
    {
        var distribution = await _reviewRepository.GetRatingDistributionAsync(clinicId);

        var reviewCount = distribution.Values.Sum();
        double? rating = null;
        if (reviewCount > 0)
        {
            var weightedSum = distribution.Sum(kv => kv.Key * kv.Value);
            rating = Math.Round(weightedSum / (double)reviewCount, 1);
        }

        return new ClinicReviewSummaryResponse
        {
            Rating = rating,
            ReviewCount = reviewCount,
            Distribution = distribution
        };
    }

    public async Task<MyReviewStatusResponse> GetMyStatusAsync(int userId, string role, int clinicId)
    {
        var isOwner = role == "owner";
        var hasCompleted = isOwner && await HasCompletedAppointmentAsync(userId, clinicId);

        var existing = await _reviewRepository.GetByClinicAndUserAsync(clinicId, userId);
        ClinicReviewResponse? mine = null;
        if (existing != null)
        {
            // Kendi yorumu olduğu için adı ayrıca çekmeye gerek yok
            var user = await _userRepository.GetByIdAsync(userId);
            mine = new ClinicReviewResponse
            {
                Id = existing.Id,
                UserId = existing.UserId,
                UserName = user?.FullName ?? string.Empty,
                Rating = existing.Rating,
                Comment = existing.Comment,
                CreatedAt = existing.CreatedAt,
                UpdatedAt = existing.UpdatedAt,
                IsMine = true
            };
        }

        return new MyReviewStatusResponse
        {
            CanReview = hasCompleted,
            HasCompletedAppointment = hasCompleted,
            Review = mine
        };
    }

    // ===== Yardımcılar =====

    private Task<bool> HasCompletedAppointmentAsync(int userId, int clinicId) =>
        _appointmentRepository.AnyAsync(a =>
            a.OwnerId == userId &&
            a.ClinicId == clinicId &&
            a.Status == AppointmentStatusRules.Completed);

    private static ClinicReviewResponse ToResponse(ClinicReview r, int currentUserId) => new()
    {
        Id = r.Id,
        UserId = r.UserId,
        UserName = r.User?.FullName ?? string.Empty,
        Rating = r.Rating,
        Comment = r.Comment,
        CreatedAt = r.CreatedAt,
        UpdatedAt = r.UpdatedAt,
        IsMine = r.UserId == currentUserId
    };
}
