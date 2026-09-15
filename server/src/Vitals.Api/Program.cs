using Microsoft.EntityFrameworkCore;
using Vitals.Api;
using Vitals.Domain;
using Vitals.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Postgres when configured; in memory otherwise — a laptop, a test, a demo.
var pg = builder.Configuration["DATABASE_URL"] ?? Environment.GetEnvironmentVariable("DATABASE_URL");
builder.Services.AddDbContext<VitalsDbContext>(o =>
{
    if (string.IsNullOrEmpty(pg)) o.UseInMemoryDatabase("vitals");
    else o.UseNpgsql(pg);
});
builder.Services.AddScoped<FactStore>();
builder.Services.AddOpenApi();
builder.Services.AddProblemDetails();

var app = builder.Build();
app.MapOpenApi();
app.UseExceptionHandler();

app.MapGet("/health", () => Results.Ok(new { ok = true, note = Messages.Healthy }));

// Sync: a facility's device pushes single-fact bundles; the server unions.
// A fact that arrived twice is ignored; a fact that decodes is never refused.
app.MapPost("/sync/push", async (PushRequest req, FactStore store, CancellationToken ct) =>
{
    var facts = new List<Fact>();
    foreach (var b64 in req.Facts)
    {
        try
        {
            facts.AddRange(Canonical.RecordFrom(Convert.FromBase64String(b64)).All);
        }
        catch (Exception e) when (e is CanonicalException or FormatException)
        {
            return Results.Problem(Messages.NotABundle, statusCode: 400);
        }
    }
    var added = await store.PushAsync(req.Facility, facts, ct);
    return Results.Ok(new PushResponse(added, facts.Count - added));
});

app.MapGet("/sync/pull", async (string facility, long after, int? limit, FactStore store, CancellationToken ct) =>
{
    var (facts, more) = await store.PullAsync(facility, after, Math.Clamp(limit ?? 200, 1, 1000), ct);
    return Results.Ok(new PullResponse(
        facts.Select(f => new PulledFact(f.Seq, Convert.ToBase64String(Canonical.BytesOf(Record.Of(f.Fact.Patient, [f.Fact]))))).ToList(),
        more,
        facts.Count == 0 ? after : facts[^1].Seq));
});

// A patient's record as the replica holds it, as canonical bytes: the same
// bytes the tablet would produce from the same facts.
app.MapGet("/patients/{patient}/record", async (string patient, FactStore store, CancellationToken ct) =>
{
    var r = await store.RecordAsync(Convert.FromHexString(patient), ct);
    return r is null ? Results.NotFound() : Results.Bytes(Canonical.BytesOf(r), "application/octet-stream");
});

app.Run();

public sealed record PushRequest(string Facility, List<string> Facts);
public sealed record PushResponse(int Added, int Known);
public sealed record PulledFact(long Seq, string Bundle);
public sealed record PullResponse(List<PulledFact> Facts, bool More, long Cursor);

public partial class Program;
