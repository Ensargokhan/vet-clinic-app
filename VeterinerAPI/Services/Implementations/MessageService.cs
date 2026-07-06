using VeterinerAPI.DTOs.Messaging;
using VeterinerAPI.Helpers;
using VeterinerAPI.Models.Entities;
using VeterinerAPI.Repositories.Interfaces;
using VeterinerAPI.Services.Interfaces;

namespace VeterinerAPI.Services.Implementations;

public class MessageService : IMessageService
{
    private readonly IConversationRepository _conversationRepository;
    private readonly IMessageRepository _messageRepository;
    private readonly IVetRepository _vetRepository;
    private readonly IAppointmentRepository _appointmentRepository;
    private readonly IUserRepository _userRepository;
    private readonly INotificationService _notificationService;

    public MessageService(
        IConversationRepository conversationRepository,
        IMessageRepository messageRepository,
        IVetRepository vetRepository,
        IAppointmentRepository appointmentRepository,
        IUserRepository userRepository,
        INotificationService notificationService)
    {
        _conversationRepository = conversationRepository;
        _messageRepository = messageRepository;
        _vetRepository = vetRepository;
        _appointmentRepository = appointmentRepository;
        _userRepository = userRepository;
        _notificationService = notificationService;
    }

    public async Task<int> StartOrGetConversationAsync(int userId, string role, int peerUserId)
    {
        int ownerUserId;
        int vetId;

        if (role == "vet")
        {
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == userId);
            if (vet == null) throw new UnauthorizedAccessException("Hekim profili bulunamadı.");
            vetId = vet.Id;
            ownerUserId = peerUserId; // karşı taraf owner
        }
        else if (role == "owner")
        {
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == peerUserId);
            if (vet == null) throw new KeyNotFoundException("Hekim bulunamadı.");
            vetId = vet.Id;
            ownerUserId = userId;
        }
        else
        {
            throw new UnauthorizedAccessException("Bu işlem için yetkiniz yok.");
        }

        // Yetki: owner ile hekim arasında en az bir randevu olmalı
        var hasAppointment = await _appointmentRepository.AnyAsync(a =>
            a.OwnerId == ownerUserId && a.VetId == vetId);
        if (!hasAppointment)
            throw new UnauthorizedAccessException("Bu kişiyle mesajlaşma yetkiniz yok (ortak randevu yok).");

        var existing = await _conversationRepository.GetByOwnerAndVetAsync(ownerUserId, vetId);
        if (existing != null) return existing.Id;

        var conversation = new Conversation
        {
            OwnerUserId = ownerUserId,
            VetId = vetId,
            LastMessageAt = DateTime.UtcNow
        };
        await _conversationRepository.AddAsync(conversation);
        await _conversationRepository.SaveChangesAsync();
        return conversation.Id;
    }

    public async Task<IEnumerable<ConversationResponse>> GetConversationsAsync(int userId, string role)
    {
        List<Conversation> conversations;
        if (role == "vet")
        {
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == userId);
            if (vet == null) return new List<ConversationResponse>();
            conversations = (await _conversationRepository.GetForVetAsync(vet.Id)).ToList();
        }
        else if (role == "owner")
        {
            conversations = (await _conversationRepository.GetForOwnerAsync(userId)).ToList();
        }
        else
        {
            return new List<ConversationResponse>();
        }

        var unreadCounts = await _messageRepository.GetUnreadCountsByConversationAsync(
            conversations.Select(c => c.Id), userId);

        return conversations.Select(c => new ConversationResponse
        {
            Id = c.Id,
            PeerName = role == "vet" ? c.OwnerUser.FullName : c.Vet.User.FullName,
            PeerTitle = role == "vet" ? null : c.Vet.Title,
            LastMessagePreview = c.LastMessagePreview,
            LastMessageAt = c.LastMessageAt,
            UnreadCount = unreadCounts.TryGetValue(c.Id, out var cnt) ? cnt : 0
        }).ToList();
    }

    public async Task<IEnumerable<MessageResponse>> GetMessagesAsync(int conversationId, int userId, string role)
    {
        await GetAuthorizedConversationAsync(conversationId, userId, role);

        // Gelen mesajları okundu yap
        await _messageRepository.MarkReadAsync(conversationId, userId);

        var messages = await _messageRepository.GetByConversationAsync(conversationId);
        return messages.Select(m => new MessageResponse
        {
            Id = m.Id,
            ConversationId = m.ConversationId,
            SenderUserId = m.SenderUserId,
            Body = m.Body,
            IsMine = m.SenderUserId == userId,
            IsRead = m.IsRead,
            CreatedAt = m.CreatedAt
        }).ToList();
    }

    public async Task<MessageResponse> SendMessageAsync(int conversationId, int userId, string role, string body)
    {
        var conversation = await GetAuthorizedConversationAsync(conversationId, userId, role);

        var clean = InputSanitizer.Sanitize(body);
        if (string.IsNullOrWhiteSpace(clean))
            throw new ArgumentException("Mesaj boş olamaz.");

        var message = new Message
        {
            ConversationId = conversationId,
            SenderUserId = userId,
            Body = clean,
            IsRead = false
        };
        await _messageRepository.AddAsync(message);

        // Konuşma önizleme + zaman güncelle
        conversation.LastMessageAt = message.CreatedAt;
        conversation.LastMessagePreview = Truncate(clean, 150);
        _conversationRepository.Update(conversation);
        await _messageRepository.SaveChangesAsync();

        // Alıcıyı çöz ve bildir
        var recipientUserId = await ResolveRecipientUserIdAsync(conversation, userId);
        var sender = await _userRepository.GetByIdAsync(userId);
        var senderName = sender?.FullName ?? "Yeni mesaj";
        await _notificationService.NotifyAsync(
            recipientUserId, senderName, Truncate(clean, 100), "new_message", conversationId);

        return new MessageResponse
        {
            Id = message.Id,
            ConversationId = conversationId,
            SenderUserId = userId,
            Body = clean,
            IsMine = true,
            IsRead = false,
            CreatedAt = message.CreatedAt
        };
    }

    public async Task<int> GetUnreadCountAsync(int userId, string role)
    {
        var conversationIds = await GetConversationIdsForUserAsync(userId, role);
        return await _messageRepository.GetUnreadCountAsync(conversationIds, userId);
    }

    public async Task<IEnumerable<ContactResponse>> GetContactsAsync(int userId, string role)
    {
        if (role == "owner")
        {
            var vets = await _appointmentRepository.GetMessagableVetsForOwnerAsync(userId);
            return vets.Select(v => new ContactResponse
            {
                UserId = v.UserId,
                Name = v.User.FullName,
                Title = v.Title
            }).ToList();
        }
        if (role == "vet")
        {
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == userId);
            if (vet == null) return new List<ContactResponse>();
            var owners = await _appointmentRepository.GetMessagableOwnersForVetAsync(vet.Id);
            return owners.Select(o => new ContactResponse
            {
                UserId = o.Id,
                Name = o.FullName,
                Title = null
            }).ToList();
        }
        return new List<ContactResponse>();
    }

    // ===== Yardımcılar =====

    private async Task<Conversation> GetAuthorizedConversationAsync(int conversationId, int userId, string role)
    {
        var conversation = await _conversationRepository.GetByIdAsync(conversationId);
        if (conversation == null) throw new KeyNotFoundException("Konuşma bulunamadı.");

        if (role == "owner")
        {
            if (conversation.OwnerUserId != userId)
                throw new UnauthorizedAccessException("Bu konuşmaya erişim yetkiniz yok.");
        }
        else if (role == "vet")
        {
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == userId);
            if (vet == null || conversation.VetId != vet.Id)
                throw new UnauthorizedAccessException("Bu konuşmaya erişim yetkiniz yok.");
        }
        else
        {
            throw new UnauthorizedAccessException("Bu işlem için yetkiniz yok.");
        }
        return conversation;
    }

    private async Task<int> ResolveRecipientUserIdAsync(Conversation conversation, int senderUserId)
    {
        if (conversation.OwnerUserId == senderUserId)
        {
            // Gönderen owner → alıcı hekimin User'ı
            var vet = await _vetRepository.GetByIdAsync(conversation.VetId);
            return vet?.UserId ?? conversation.OwnerUserId;
        }
        // Gönderen hekim → alıcı owner
        return conversation.OwnerUserId;
    }

    private async Task<List<int>> GetConversationIdsForUserAsync(int userId, string role)
    {
        if (role == "vet")
        {
            var vet = await _vetRepository.FirstOrDefaultAsync(v => v.UserId == userId);
            if (vet == null) return new List<int>();
            return (await _conversationRepository.GetForVetAsync(vet.Id)).Select(c => c.Id).ToList();
        }
        if (role == "owner")
        {
            return (await _conversationRepository.GetForOwnerAsync(userId)).Select(c => c.Id).ToList();
        }
        return new List<int>();
    }

    private static string Truncate(string value, int max) =>
        value.Length > max ? value.Substring(0, max) : value;
}
