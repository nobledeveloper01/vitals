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

    /// <summary>The fact's kind, so aggregates never open the bytes.</summary>
    public byte Kind { get; set; }
}

/// <summary>A facility the replica knows, and the LGA it reports under.</summary>
public sealed class FacilityRow
{
    public string Facility { get; set; } = "";
    public string Lga { get; set; } = "";
}

/// <summary>A pack reported as not on the list, by a facility, with no patient in it.</summary>
public sealed class CounterfeitReportRow
{
    public long Id { get; set; }
    public string Facility { get; set; } = "";
    public string Product { get; set; } = "";
    public string Number { get; set; } = "";
    public DateTime At { get; set; }
}

/// <summary>A device the replica has heard from, and whether a supervisor asked it to wipe.</summary>
public sealed class DeviceRow
{
    public string Device { get; set; } = "";
    public string Facility { get; set; } = "";
    public bool WipeRequested { get; set; }
    public DateTime? WipeRequestedAt { get; set; }
    public DateTime? WipedAt { get; set; }
}

public sealed class VitalsDbContext(DbContextOptions<VitalsDbContext> options) : DbContext(options)
{
    public DbSet<FactRow> Facts => Set<FactRow>();
    public DbSet<DeviceRow> Devices => Set<DeviceRow>();
    public DbSet<FacilityRow> Facilities => Set<FacilityRow>();
    public DbSet<CounterfeitReportRow> CounterfeitReports => Set<CounterfeitReportRow>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<DeviceRow>().HasKey(d => d.Device);
        b.Entity<FacilityRow>().HasKey(f => f.Facility);
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
    /// <summary>Remote wipe: a supervisor asks; the device sees it at its next meeting and erases; then says so.</summary>
    public async Task RequestWipeAsync(string device, string facility, CancellationToken ct)
    {
        var row = await db.Devices.FindAsync([device], ct);
        if (row is null) db.Devices.Add(row = new DeviceRow { Device = device, Facility = facility });
        row.WipeRequested = true;
        row.WipeRequestedAt = DateTime.UtcNow;
        row.WipedAt = null;
        await db.SaveChangesAsync(ct);
    }

    public async Task<DeviceRow?> DeviceAsync(string device, CancellationToken ct) => await db.Devices.FindAsync([device], ct);

    public async Task ConfirmWipedAsync(string device, CancellationToken ct)
    {
        var row = await db.Devices.FindAsync([device], ct);
        if (row is null) return;
        row.WipeRequested = false;
        row.WipedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>A facility's counts by kind and month, with no patient in the answer — the supervisor's view (Phase 7).</summary>
    public async Task<List<AggregateRow>> AggregateAsync(string? facility, string? lga, CancellationToken ct)
    {
        IQueryable<FactRow> q = db.Facts;
        if (facility is not null) q = q.Where(r => r.Facility == facility);
        if (lga is not null)
        {
            var names = await db.Facilities.Where(f => f.Lga == lga).Select(f => f.Facility).ToListAsync(ct);
            q = q.Where(r => names.Contains(r.Facility));
        }
        var rows = await q.Select(r => new { r.Facility, r.Kind, r.WallMillis, r.Patient }).ToListAsync(ct);
        return rows
            .GroupBy(r => (r.Facility, Month: DateTimeOffset.FromUnixTimeMilliseconds(r.WallMillis).ToString("yyyy-MM"), r.Kind))
            .Select(g => new AggregateRow(g.Key.Facility, g.Key.Month, ((FactKind)g.Key.Kind).ToString(), g.Count(), g.Select(x => x.Patient).Distinct().Count()))
            .OrderBy(a => a.Facility).ThenBy(a => a.Month).ThenBy(a => a.Kind)
            .ToList();
    }

    public async Task SetLgaAsync(string facility, string lga, CancellationToken ct)
    {
        var row = await db.Facilities.FindAsync([facility], ct);
        if (row is null) db.Facilities.Add(new FacilityRow { Facility = facility, Lga = lga });
        else row.Lga = lga;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>A pack not on the list, reported. The signal is a count over a window, never a finding.</summary>
    public async Task ReportCounterfeitAsync(string facility, string product, string number, DateTime at, CancellationToken ct)
    {
        db.CounterfeitReports.Add(new CounterfeitReportRow { Facility = facility, Product = product, Number = number, At = at });
        await db.SaveChangesAsync(ct);
    }

    /// <summary>Products reported not-on-the-list at least <paramref name="threshold"/> times across at least two facilities of an LGA within the window.</summary>
    public async Task<List<SignalRow>> SignalsAsync(string lga, DateTime since, int threshold, CancellationToken ct)
    {
        var names = await db.Facilities.Where(f => f.Lga == lga).Select(f => f.Facility).ToListAsync(ct);
        var reports = await db.CounterfeitReports.Where(r => names.Contains(r.Facility) && r.At >= since).ToListAsync(ct);
        return reports.GroupBy(r => r.Product)
            .Where(g => g.Count() >= threshold && g.Select(r => r.Facility).Distinct().Count() >= 2)
            .Select(g => new SignalRow(lga, g.Key, g.Count(), g.Select(r => r.Facility).Distinct().Count(), g.Max(r => r.At)))
            .OrderByDescending(s => s.Reports)
            .ToList();
    }

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
                Kind = (byte)f.Kind,
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

public sealed record AggregateRow(string Facility, string Month, string Kind, int Facts, int Patients);
public sealed record SignalRow(string Lga, string Product, int Reports, int Facilities, DateTime Latest);
