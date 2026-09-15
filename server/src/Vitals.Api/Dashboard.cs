using System.Net;
using System.Text;
using Vitals.Infrastructure;

namespace Vitals.Api;

/// <summary>
/// The supervisor's page: counts by facility, month and kind, and the signals
/// for an LGA. No patient is named because none is in the data it reads.
/// Plain HTML, no script, so it opens on any browser a supervisor has.
/// </summary>
public static class Dashboard
{
    public static string Render(IReadOnlyList<AggregateRow> rows, IReadOnlyList<SignalRow> signals, string? lga)
    {
        var sb = new StringBuilder();
        sb.Append("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\">");
        sb.Append("<title>Vitals — supervisor</title>");
        sb.Append("<style>body{font-family:system-ui,sans-serif;margin:2rem;color:#0B1220;background:#F5F7FA}table{border-collapse:collapse;margin:1rem 0}td,th{padding:.4rem .8rem;border-bottom:1px solid #C8D2DE;text-align:left}th{font-weight:600}.note{color:#4A5568;max-width:60ch}.signal{color:#9A5B00}</style></head><body>");
        sb.Append("<h1>Vitals — supervisor</h1>");
        sb.Append("<p class=\"note\">Counts of facts and of distinct patients, by facility, month and kind. Nothing on this page names a patient; the replica holds bytes it does not open.</p>");
        if (lga is not null) sb.Append("<p>LGA: <strong>").Append(E(lga)).Append("</strong></p>");
        sb.Append("<table><tr><th>Facility</th><th>Month</th><th>Kind</th><th>Facts</th><th>Patients</th></tr>");
        foreach (var r in rows)
            sb.Append("<tr><td>").Append(E(r.Facility)).Append("</td><td>").Append(r.Month).Append("</td><td>").Append(r.Kind).Append("</td><td>").Append(r.Facts).Append("</td><td>").Append(r.Patients).Append("</td></tr>");
        if (rows.Count == 0) sb.Append("<tr><td colspan=\"5\">Nothing yet.</td></tr>");
        sb.Append("</table>");
        if (lga is not null)
        {
            sb.Append("<h2>Signals</h2><p class=\"note\">A product reported not on the list from two or more facilities of this LGA within thirty days. A signal for a person to look at; it decides nothing.</p>");
            if (signals.Count == 0) sb.Append("<p>None in the last thirty days.</p>");
            foreach (var s in signals)
                sb.Append("<p class=\"signal\">").Append(E(s.Product)).Append(": ").Append(s.Reports).Append(" reports from ").Append(s.Facilities).Append(" facilities, latest ").Append(s.Latest.ToString("yyyy-MM-dd")).Append("</p>");
        }
        sb.Append("</body></html>");
        return sb.ToString();
    }

    private static string E(string s) => WebUtility.HtmlEncode(s);
}
