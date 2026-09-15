using Vitals.Domain;
using Xunit;

namespace Vitals.Domain.Tests;

/// <summary>
/// The Dart tests wrote docs/parity: for two hundred generated worlds, every
/// fact recorded and the bytes every settled device holds. The C# merge must
/// reach the same bytes from the same facts, in any order, or the server is
/// not a replica.
/// </summary>
public class ParityTests
{
    private static string Dir()
    {
        var d = AppContext.BaseDirectory;
        while (d is not null && !Directory.Exists(Path.Combine(d, "docs", "parity"))) d = Path.GetDirectoryName(d);
        return Path.Combine(d ?? throw new InvalidOperationException("docs/parity not found above the test binary"), "docs", "parity");
    }

    private static List<Fact> Facts(string path)
    {
        var bytes = File.ReadAllBytes(path);
        var facts = new List<Fact>();
        var i = 0;
        while (i < bytes.Length)
        {
            var n = (bytes[i] << 24) | (bytes[i + 1] << 16) | (bytes[i + 2] << 8) | bytes[i + 3];
            i += 4;
            facts.AddRange(Canonical.RecordFrom(bytes.AsSpan(i, n)).All);
            i += n;
        }
        return facts;
    }

    [Fact]
    public void TheFixtureIsPresentAndNotSmall()
    {
        var index = File.ReadAllLines(Path.Combine(Dir(), "INDEX"));
        Assert.Equal(200, index.Length);
    }

    [Fact]
    public void EveryWorldMergesToTheDartBytesInForwardReverseAndShuffledOrder()
    {
        var dir = Dir();
        foreach (var line in File.ReadAllLines(Path.Combine(dir, "INDEX")))
        {
            var seed = int.Parse(line.Split(' ')[0], System.Globalization.CultureInfo.InvariantCulture);
            var facts = Facts(Path.Combine(dir, $"{seed}.facts"));
            var expected = File.ReadAllBytes(Path.Combine(dir, $"{seed}.merged"));
            var patient = facts[0].Patient;

            var forward = facts.Aggregate(Record.Empty(patient), (r, f) => Merge.Union(r, Record.Of(patient, [f])));
            Assert.Equal(expected, Canonical.BytesOf(forward));

            var reverse = Enumerable.Reverse(facts).Aggregate(Record.Empty(patient), (r, f) => Merge.Union(Record.Of(patient, [f]), r));
            Assert.Equal(expected, Canonical.BytesOf(reverse));

            // A deterministic shuffle: no randomness in a test that must repeat.
            var shuffled = facts.OrderBy(f => f.Key.GetHashCode(StringComparison.Ordinal) ^ seed).ToList();
            var halves = Merge.Union(Record.Of(patient, shuffled.Take(shuffled.Count / 2)), Record.Of(patient, shuffled.Skip(shuffled.Count / 2)));
            Assert.Equal(expected, Canonical.BytesOf(Merge.Union(halves, halves)));

            // And the bytes round-trip through this side's decoder.
            Assert.Equal(expected, Canonical.BytesOf(Canonical.RecordFrom(expected)));
        }
    }

    [Fact]
    public void ACorrectionNeverHidesTheOriginal()
    {
        // Across every world, not one chosen by hand: the generator decides
        // where corrections fall, and there must be some.
        var dir = Dir();
        var seen = 0;
        foreach (var line in File.ReadAllLines(Path.Combine(dir, "INDEX")))
        {
            var seed = line.Split(' ')[0];
            var facts = Facts(Path.Combine(dir, $"{seed}.facts"));
            var r = Record.Of(facts[0].Patient, facts);
            foreach (var s in r.All.Where(f => f.Kind == FactKind.Supersession))
            {
                var original = r.All.Single(f => Bytes.Same(f.Id, s.Supersedes!));
                Assert.True(r.Contains(original));
                Assert.DoesNotContain(original, r.Current);
                seen++;
            }
        }
        Assert.True(seen > 100, $"only {seen} corrections across two hundred worlds");
    }

    [Fact]
    public void RecordsOfTwoPatientsRefuseToMerge()
    {
        var a = Record.Of([1, 2, 3], []);
        var b = Record.Of([4, 5, 6], []);
        Assert.Throws<ArgumentException>(() => Merge.Union(a, b));
    }
}
