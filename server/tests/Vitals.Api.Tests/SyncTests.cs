using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Vitals.Domain;
using Vitals.Infrastructure;
using Xunit;
using Record = Vitals.Domain.Record;

namespace Vitals.Api.Tests;

/// <summary>
/// The replica: two tablets push what they hold, the server unions, a third
/// pulls everything and reaches the same bytes the tablets would. The server
/// refuses what it cannot decode and never a fact it can.
/// </summary>
public class SyncTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    public SyncTests(WebApplicationFactory<Program> f) => _client = f
        .WithWebHostBuilder(b => b.UseSetting("ADMIN_TOKEN", "test-supervisor-token"))
        .CreateClient();

    private static Fact MakeFact(int seed, string device, long wall, FactKind kind = FactKind.Vitals, byte[]? supersedes = null, int patientSeed = 13)
    {
        var id = Enumerable.Range(0, 32).Select(i => (byte)((seed * 31 + i * 7) & 0xff)).ToArray();
        var patient = Enumerable.Range(0, 16).Select(i => (byte)((patientSeed + i) & 0xff)).ToArray();
        return new Fact(id, patient, kind, new Stamp(wall, seed % 3, device), "nurse-a", [(byte)seed, 0x42], supersedes);
    }

    private static string Bundle(Fact f) => Convert.ToBase64String(Canonical.BytesOf(Record.Of(f.Patient, [f])));

    [Fact]
    public async Task HealthSaysWhatTheServerIs()
    {
        var res = await _client.GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        Assert.Contains("computes nothing clinical", await res.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task TwoTabletsPushAThirdPullsAndTheBytesAgree()
    {
        var facility = $"ikeja-{Guid.NewGuid():N}";
        var a = new[] { MakeFact(1, "tab-a", 1000), MakeFact(2, "tab-a", 2000) };
        var b = new[] { MakeFact(2, "tab-a", 2000), MakeFact(3, "tab-b", 1500), MakeFact(4, "tab-b", 2500, FactKind.Supersession, MakeFact(1, "tab-a", 1000).Id) };

        var pa = await _client.PostAsJsonAsync("/sync/push", new PushRequest(facility, a.Select(Bundle).ToList()));
        var ra = await pa.Content.ReadFromJsonAsync<PushResponse>();
        Assert.Equal((2, 0), (ra!.Added, ra.Known));

        var pb = await _client.PostAsJsonAsync("/sync/push", new PushRequest(facility, b.Select(Bundle).ToList()));
        var rb = await pb.Content.ReadFromJsonAsync<PushResponse>();
        Assert.Equal((2, 1), (rb!.Added, rb.Known));

        var pull = await _client.GetFromJsonAsync<PullResponse>($"/sync/pull?facility={facility}&after=0&limit=2");
        Assert.True(pull!.More);
        Assert.Equal(2, pull.Facts.Count);
        var rest = await _client.GetFromJsonAsync<PullResponse>($"/sync/pull?facility={facility}&after={pull.Cursor}");
        Assert.False(rest!.More);
        Assert.Equal(2, rest.Facts.Count);

        var pulled = pull.Facts.Concat(rest.Facts).SelectMany(p => Canonical.RecordFrom(Convert.FromBase64String(p.Bundle)).All).ToList();
        var expected = Record.Of(a[0].Patient, a.Concat(b));
        Assert.Equal(Canonical.BytesOf(expected), Canonical.BytesOf(Record.Of(a[0].Patient, pulled)));

        // The replica's own view of the patient is the same bytes.
        var record = await _client.GetByteArrayAsync($"/patients/{Convert.ToHexStringLower(a[0].Patient)}/record");
        Assert.Equal(Canonical.BytesOf(expected), record);
        Assert.Equal(2, Canonical.RecordFrom(record).Current.Count); // four facts; one corrected, the correction itself not shown
    }

    [Fact]
    public async Task ABundleThatDoesNotDecodeIsRefusedAndNothingIsStored()
    {
        var facility = $"bad-{Guid.NewGuid():N}";
        var res = await _client.PostAsJsonAsync("/sync/push", new PushRequest(facility, [Convert.ToBase64String([9, 9, 9])]));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
        var pull = await _client.GetFromJsonAsync<PullResponse>($"/sync/pull?facility={facility}&after=0");
        Assert.Empty(pull!.Facts);
    }

    [Fact]
    public async Task AnUnknownPatientIsNotFound()
    {
        var res = await _client.GetAsync("/patients/00000000000000000000000000000000/record");
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    [Fact]
    public async Task AWipeNeedsTheSupervisorsTokenAndTheDeviceSeesItThenConfirms()
    {
        var device = $"tab-{Guid.NewGuid():N}";
        // Nobody has asked.
        var status = await _client.GetFromJsonAsync<DeviceStatus>($"/devices/{device}");
        Assert.False(status!.Wipe);
        // Without the token: refused, and the device still sees nothing.
        var refused = await _client.PostAsync($"/devices/{device}/wipe?facility=ikeja", null);
        Assert.Equal(HttpStatusCode.Forbidden, refused.StatusCode);
        status = await _client.GetFromJsonAsync<DeviceStatus>($"/devices/{device}");
        Assert.False(status!.Wipe);
        // With it: the device is told at its next meeting.
        using var req = new HttpRequestMessage(HttpMethod.Post, $"/devices/{device}/wipe?facility=ikeja");
        req.Headers.Add("X-Admin-Token", "test-supervisor-token");
        var ok = await _client.SendAsync(req);
        Assert.Equal(HttpStatusCode.OK, ok.StatusCode);
        status = await _client.GetFromJsonAsync<DeviceStatus>($"/devices/{device}");
        Assert.True(status!.Wipe);
        // The device erased and said so.
        var confirmed = await _client.PostAsync($"/devices/{device}/wiped", null);
        Assert.Equal(HttpStatusCode.OK, confirmed.StatusCode);
        status = await _client.GetFromJsonAsync<DeviceStatus>($"/devices/{device}");
        Assert.False(status!.Wipe);
        Assert.NotNull(status.WipedAt);
    }

    [Fact]
    public async Task TheSupervisorSeesTwoFacilitiesAggregatesWithNoPatientIdentifiable()
    {
        var lga = $"lga-{Guid.NewGuid():N}";
        var a = $"fac-a-{Guid.NewGuid():N}";
        var b = $"fac-b-{Guid.NewGuid():N}";
        foreach (var (fac, seed) in new[] { (a, 1), (a, 2), (b, 3) })
        {
            // Its own patient, so the sync test's record is not touched.
            var f = MakeFact(seed * 100 + 7, "tab", 1_760_000_000_000L + seed, seed == 2 ? FactKind.Immunisation : FactKind.Registration, patientSeed: 200);
            var res = await _client.PostAsJsonAsync("/sync/push", new PushRequest(fac, [Bundle(f)]));
            Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        }
        foreach (var fac in new[] { a, b })
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, $"/facilities/{fac}/lga?lga={lga}");
            req.Headers.Add("X-Admin-Token", "test-supervisor-token");
            Assert.Equal(HttpStatusCode.OK, (await _client.SendAsync(req)).StatusCode);
        }
        var rows = await _client.GetFromJsonAsync<List<AggregateRow>>($"/reports/aggregate?lga={lga}");
        Assert.NotNull(rows);
        Assert.Equal(3, rows!.Count);
        Assert.Contains(rows, r => r.Facility == a && r.Kind == "Registration" && r.Facts == 1 && r.Patients == 1);
        Assert.Contains(rows, r => r.Facility == a && r.Kind == "Immunisation" && r.Facts == 1);
        Assert.Contains(rows, r => r.Facility == b && r.Facts == 1);
        // The page: both facilities, the counts, and no patient id anywhere on it.
        var html = await _client.GetStringAsync($"/dashboard?lga={lga}");
        Assert.Contains(a, html);
        Assert.Contains(b, html);
        Assert.Contains("Immunisation", html);
        Assert.DoesNotContain("c8c9cacb", html); // the patient bytes' hex
        Assert.DoesNotContain("nurse-a", html);
    }

    [Fact]
    public async Task ThreeReportsFromTwoFacilitiesOfAnLgaAreASignalAndOneFacilityIsNot()
    {
        var lga = $"lga-{Guid.NewGuid():N}";
        var a = $"fac-a-{Guid.NewGuid():N}";
        var b = $"fac-b-{Guid.NewGuid():N}";
        foreach (var fac in new[] { a, b })
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, $"/facilities/{fac}/lga?lga={lga}");
            req.Headers.Add("X-Admin-Token", "test-supervisor-token");
            await _client.SendAsync(req);
        }
        // Three from one facility: not a signal.
        for (var i = 0; i < 3; i++)
            await _client.PostAsJsonAsync("/reports/counterfeit", new CounterfeitReport(a, "Paracetamol", "A4-9999"));
        var none = await _client.GetFromJsonAsync<List<SignalRow>>($"/signals?lga={lga}");
        Assert.Empty(none!);
        // One more from the other facility: a signal.
        await _client.PostAsJsonAsync("/reports/counterfeit", new CounterfeitReport(b, "Paracetamol", "A4-9998"));
        var signals = await _client.GetFromJsonAsync<List<SignalRow>>($"/signals?lga={lga}");
        var s = Assert.Single(signals!);
        Assert.Equal(("Paracetamol", 4, 2), (s.Product, s.Reports, s.Facilities));
        var html = await _client.GetStringAsync($"/dashboard?lga={lga}");
        Assert.Contains("Paracetamol: 4 reports from 2 facilities", html);
        Assert.DoesNotContain("genuine", html);
        Assert.DoesNotContain("counterfeit", html.ToLowerInvariant().Replace("/reports/counterfeit", ""));
    }
}
