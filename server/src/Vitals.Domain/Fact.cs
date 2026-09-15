namespace Vitals.Domain;

/// <summary>What kind of thing a fact records. The number is the encoding's; add at the end, never renumber.</summary>
public enum FactKind : byte
{
    Registration = 0,
    Vitals = 1,
    Immunisation = 2,
    AncVisit = 3,
    StockMovement = 4,
    Note = 5,
    Supersession = 6,
    Access = 7,
}

/// <summary>One immutable observation. Equality is by id; order is by stamp then id.</summary>
public sealed class Fact : IComparable<Fact>, IEquatable<Fact>
{
    public Fact(byte[] id, byte[] patient, FactKind kind, Stamp stamp, string author, byte[] payload, byte[]? supersedes)
    {
        Id = id; Patient = patient; Kind = kind; Stamp = stamp; Author = author; Payload = payload; Supersedes = supersedes;
        Key = Convert.ToHexStringLower(id);
    }

    public byte[] Id { get; }
    public byte[] Patient { get; }
    public FactKind Kind { get; }
    public Stamp Stamp { get; }
    public string Author { get; }
    public byte[] Payload { get; }
    public byte[]? Supersedes { get; }
    public string Key { get; }

    public int CompareTo(Fact? other)
    {
        if (other is null) return 1;
        var c = Stamp.CompareTo(other.Stamp);
        return c != 0 ? c : Bytes.Compare(Id, other.Id);
    }

    public bool Equals(Fact? other) => other is not null && Key == other.Key;
    public override bool Equals(object? obj) => Equals(obj as Fact);
    public override int GetHashCode() => Key.GetHashCode(StringComparison.Ordinal);
}

public static class Bytes
{
    public static int Compare(ReadOnlySpan<byte> a, ReadOnlySpan<byte> b)
    {
        var n = Math.Min(a.Length, b.Length);
        for (var i = 0; i < n; i++)
        {
            if (a[i] != b[i]) return a[i].CompareTo(b[i]);
        }
        return a.Length.CompareTo(b.Length);
    }

    public static bool Same(ReadOnlySpan<byte> a, ReadOnlySpan<byte> b) => Compare(a, b) == 0;
}
