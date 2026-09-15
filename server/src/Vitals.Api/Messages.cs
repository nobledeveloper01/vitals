namespace Vitals.Api;

/// <summary>Every sentence the server says to a person. `make copy-check` reads this file.</summary>
public static class Messages
{
    public const string NotABundle = "That is not a record bundle this server understands.";
    public const string WrongFacility = "This device is not enrolled at that facility.";
    public const string Healthy = "The server stores and relays. It computes nothing clinical.";
}
