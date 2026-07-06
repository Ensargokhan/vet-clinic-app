using System.ComponentModel.DataAnnotations;

namespace VeterinerAPI.DTOs.Messaging;

public class StartConversationRequest
{
    // Karşı tarafın User.Id'si (owner ise hekimin User'ı, hekim ise owner)
    [Required(ErrorMessage = "Alıcı zorunludur.")]
    public int PeerUserId { get; set; }
}
