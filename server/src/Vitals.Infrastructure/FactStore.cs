using Microsoft.EntityFrameworkCore;
using Vitals.Domain;

namespace Vitals.Infrastructure;

/// <summary>
/// One row per fact, keyed by its id, append-only. The server never updates
/// or deletes a fact: a merge is a union, and a union only inserts. The
/// canonical bytes of the single-fact record are what is stored, so what
/// comes back out is exactly what went in.
/// </summary>
public sealed class FactRow
{
    public string Id { get; set; } = "";
    public string Patient { get; set; } = "";
    public string Facility { get; set; } = "";
    public long WallMillis { get; set; }
    public int Counter { get; set; }
    public string Device { get; set; } = "";
    public byte[] Bytes { get; set; } = [];
    /// <summary>The server's own arrival order, for paging a pull. Not a clock the record trusts.</summary>
    public long Seq { get; set; }
}

public sealed class VitalsDbContext(DbContextOptions<VitalsDbContext> options) : DbContext(options)
{
    public DbSet<FactRow> Facts => Set<FactRow>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        var e = b.Entity<FactRow>();
        e.HasKey(f => f.Id);
        e.HasIndex(f => new { f.Facility, f.Seq });
        e.HasIndex(f => f.Patient);
        // The arrival sequence is assigned by the store, not the provider: the
        // in-memory provider does not generate values for a non-key column, and
        // a pull that never sees Seq > 0 would silently return nothing.
        e.Property(f => f.Seq).ValueGeneratedNever();
    }
}

/// <summary>What the API needs of storage; the in-memory provider and Postgres both serve it.</summary>
public sealed class FactStore(VitalsDbContext db)
{
    /// <summary>Union: insert what is new, ignore what is known. Returns how many were new.</summary>
    public async Task<int> PushAsync(string facility, IEnumerable<Fact> facts, CancellationToken ct)
    {
        var added = 0;
        var seq = await db.Facts.MaxAsync(r => (long?)r.Seq, ct) ?? 0;
        foreach (var f in facts)
        {
            if (await db.Facts.AnyAsync(r => r.Id == f.Key, ct)) continue;
            db.Facts.Add(new FactRow
            {
                Id = f.Key,
                Patient = Convert.ToHexStringLower(f.Patient),
                Facility = facility,
                WallMillis = f.Stamp.WallMillis,
                Counter = f.Stamp.Counter,
                Device = f.Stamp.Device,
                Bytes = Canonical.BytesOf(Record.Of(f.Patient, [f])),
                Seq = ++seq,
            });
            added++;
        }
        await db.SaveChangesAsync(ct);
        return added;
    }

    /// <summary>Everything the facility has after a sequence number, in arrival order, a page at a time.</summary>
    public async Task<(List<(long Seq, Fact Fact)> Facts, bool More)> PullAsync(string facility, long after, int limit, CancellationToken ct)
    {
        var rows = await db.Facts.Where(r => r.Facility == facility && r.Seq > after).OrderBy(r => r.Seq).Take(limit + 1).ToListAsync(ct);
        var more = rows.Count > limit;
        var page = rows.Take(limit).Select(r => (r.Seq, Canonical.RecordFrom(r.Bytes).All.Single())).ToList();
        return (page, more);
    }

    /// <summary>A patient's whole record as the server holds it — a replica's view, no authority.</summary>
    public async Task<Record?> RecordAsync(byte[] patient, CancellationToken ct)
    {
        var hex = Convert.ToHexStringLower(patient);
        var rows = await db.Facts.Where(r => r.Patient == hex).ToListAsync(ct);
        if (rows.Count == 0) return null;
        return rows.Aggregate(Record.Empty(patient), (r, row) => Merge.Union(r, Canonical.RecordFrom(row.Bytes)));
    }
}
