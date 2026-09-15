namespace Vitals.Domain;

/// <summary>
/// A hybrid logical clock stamp: wall time as the device believed it, a counter
/// that breaks ties, and the device as the final tie-break. Total order, so
/// every device orders the same facts the same way.
/// </summary>
public readonly record struct Stamp(long WallMillis, int Counter, string Device) : IComparable<Stamp>
{
    public int CompareTo(Stamp other)
    {
        if (WallMillis != other.WallMillis) return WallMillis.CompareTo(other.WallMillis);
        if (Counter != other.Counter) return Counter.CompareTo(other.Counter);
        return string.CompareOrdinal(Device, other.Device);
    }

    public static Stamp Next(Stamp? last, long nowMillis, string device) =>
        last is null || nowMillis > last.Value.WallMillis
            ? new Stamp(nowMillis, 0, device)
            : new Stamp(last.Value.WallMillis, last.Value.Counter + 1, device);

    public override string ToString() => $"{WallMillis}.{Counter}@{Device}";
}
