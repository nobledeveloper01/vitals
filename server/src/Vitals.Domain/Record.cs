namespace Vitals.Domain;

/// <summary>A patient's record: the set of its facts. Nothing here deletes.</summary>
public sealed class Record
{
    private readonly Dictionary<string, Fact> _facts;

    private Record(byte[] patient, Dictionary<string, Fact> facts)
    {
        Patient = patient;
        _facts = facts;
    }

    public byte[] Patient { get; }

    public static Record Empty(byte[] patient) => new(patient, new Dictionary<string, Fact>(StringComparer.Ordinal));

    public static Record Of(byte[] patient, IEnumerable<Fact> facts)
    {
        var r = Empty(patient);
        foreach (var f in facts) r._facts[f.Key] = f;
        return r;
    }

    public int Length => _facts.Count;
    public bool Contains(Fact f) => _facts.ContainsKey(f.Key);

    /// <summary>Every fact ever recorded, in stamp order.</summary>
    public List<Fact> All
    {
        get
        {
            var list = _facts.Values.ToList();
            list.Sort();
            return list;
        }
    }

    /// <summary>The facts a reader is shown: not superseded, and not themselves supersessions.</summary>
    public List<Fact> Current
    {
        get
        {
            var superseded = new HashSet<string>(StringComparer.Ordinal);
            foreach (var f in _facts.Values)
            {
                if (f.Kind == FactKind.Supersession && f.Supersedes is not null) superseded.Add(Convert.ToHexStringLower(f.Supersedes));
            }
            return All.Where(f => f.Kind != FactKind.Supersession && !superseded.Contains(f.Key)).ToList();
        }
    }
}

/// <summary>Set union. The whole merge, by construction commutative, associative and idempotent.</summary>
public static class Merge
{
    public static Record Union(Record a, Record b)
    {
        if (!Bytes.Same(a.Patient, b.Patient)) throw new ArgumentException("records of two patients cannot merge");
        return Record.Of(a.Patient, a.All.Concat(b.All));
    }
}
