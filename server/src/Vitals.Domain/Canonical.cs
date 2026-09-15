using System.Text;

namespace Vitals.Domain;

/// <summary>
/// The byte encoding of a record, version 1 — the same bytes the Dart produces
/// for the same facts, and docs/parity is the proof.
/// </summary>
public static class Canonical
{
    public const byte Version = 1;

    public static byte[] BytesOf(Record r)
    {
        var o = new List<byte> { Version };
        BytesN(o, r.Patient, 1);
        var facts = r.All;
        U32(o, facts.Count);
        foreach (var f in facts)
        {
            BytesN(o, f.Id, 1);
            BytesN(o, f.Patient, 1);
            o.Add((byte)f.Kind);
            I64(o, f.Stamp.WallMillis);
            U32(o, f.Stamp.Counter);
            Str(o, f.Stamp.Device);
            Str(o, f.Author);
            BytesN(o, f.Payload, 4);
            if (f.Supersedes is null) o.Add(0);
            else { o.Add(1); BytesN(o, f.Supersedes, 1); }
        }
        return o.ToArray();
    }

    public static Record RecordFrom(ReadOnlySpan<byte> bytes)
    {
        var r = new Reader(bytes.ToArray());
        var v = r.U8();
        if (v != Version) throw new CanonicalException($"version {v}");
        var patient = r.Bytes(1);
        var n = r.U32();
        var facts = new List<Fact>(n);
        for (var i = 0; i < n; i++)
        {
            var id = r.Bytes(1);
            var p = r.Bytes(1);
            var kind = (FactKind)r.U8();
            var wall = r.I64();
            var counter = r.U32();
            var device = r.Str();
            var author = r.Str();
            var payload = r.Bytes(4);
            var hasSup = r.U8();
            var sup = hasSup == 1 ? r.Bytes(1) : null;
            facts.Add(new Fact(id, p, kind, new Stamp(wall, counter, device), author, payload, sup));
        }
        if (!r.Done) throw new CanonicalException("trailing bytes");
        return Record.Of(patient, facts);
    }

    private static void U32(List<byte> o, int v) { for (var s = 24; s >= 0; s -= 8) o.Add((byte)((v >> s) & 0xff)); }
    private static void I64(List<byte> o, long v) { for (var s = 56; s >= 0; s -= 8) o.Add((byte)((v >> s) & 0xff)); }
    private static void BytesN(List<byte> o, byte[] b, int width)
    {
        if (width == 1) { if (b.Length > 255) throw new CanonicalException("too long for one byte"); o.Add((byte)b.Length); }
        else U32(o, b.Length);
        o.AddRange(b);
    }
    private static void Str(List<byte> o, string s) => BytesN(o, Encoding.UTF8.GetBytes(s), 1);

    private sealed class Reader(byte[] b)
    {
        private int _i;
        public bool Done => _i == b.Length;
        public byte U8() { if (_i >= b.Length) throw new CanonicalException("truncated"); return b[_i++]; }
        public int U32() { var v = 0; for (var k = 0; k < 4; k++) v = (v << 8) | U8(); return v; }
        public long I64() { long v = 0; for (var k = 0; k < 8; k++) v = (v << 8) | U8(); return v; }
        public byte[] Bytes(int width)
        {
            var n = width == 1 ? U8() : U32();
            if (_i + n > b.Length) throw new CanonicalException("truncated");
            var slice = b[_i..(_i + n)];
            _i += n;
            return slice;
        }
        public string Str() => Encoding.UTF8.GetString(Bytes(1));
    }
}

public sealed class CanonicalException(string reason) : Exception(reason);
