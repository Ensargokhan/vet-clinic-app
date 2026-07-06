using VeterinerAPI.DTOs.Messaging;

namespace VeterinerAPI.Services.Interfaces;

public interface IMessageService
{
    /// <summary>Owner↔Hekim konuşmasını bulur ya da oluşturur (ortak randevu şartı). Konuşma id döner.</summary>
    Task<int> StartOrGetConversationAsync(int userId, string role, int peerUserId);

    Task<IEnumerable<ConversationResponse>> GetConversationsAsync(int userId, string role);

    /// <summary>Konuşmadaki mesajları döndürür ve gelenleri okundu işaretler.</summary>
    Task<IEnumerable<MessageResponse>> GetMessagesAsync(int conversationId, int userId, string role);

    Task<MessageResponse> SendMessageAsync(int conversationId, int userId, string role, string body);

    Task<int> GetUnreadCountAsync(int userId, string role);

    /// <summary>Mesaj başlatılabilecek kişiler (ortak randevusu olan hekim/owner).</summary>
    Task<IEnumerable<ContactResponse>> GetContactsAsync(int userId, string role);
}
