using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Vitals.Domain;
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

    private static Fact MakeFact(int seed, string device, long wall, FactKind kind = FactKind.Vitals, byte[]? supersedes = null)
    {
        var id = Enumerable.Range(0, 32).Select(i => (byte)((seed * 31 + i * 7) & 0xff)).ToArray();
        var patient = Enumerable.Range(0, 16).Select(i => (byte)((13 + i) & 0xff)).ToArray();
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
}
