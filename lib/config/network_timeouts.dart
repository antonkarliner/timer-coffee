/// Centralized network timeout budgets for all remote (Supabase / Firebase / HTTP)
/// operations.
///
/// These values are grounded in real-world connectivity data (Globalping, measured
/// against the Supabase project endpoint): on any network that is *going* to connect,
/// a full HTTPS round-trip completes in well under 3s worldwide — up to ~2.5s on
/// degraded-but-working networks under DPI. Waiting longer only punishes users on bad
/// connectivity, who are better served by falling back to bundled/cached data.
///
/// The budgets are tiered by payload size (gzipped wire size — what actually travels):
///   - tiny handshake / delta payloads (<5KB): [handshake]
///   - small syncs and writes (<150KB):        [smallSync]
///   - the full first-launch DB download (~500KB): [firstLaunchBulk]
///   - a delta-only re-sync on later launches:     [subsequentBulk]
///
/// Note: blocked/black-hole regions (where the connection never establishes and hangs)
/// are handled by a separate proxy layer, not by these timeouts.
class NetworkTimeouts {
  NetworkTimeouts._();

  /// Tiny handshake / delta payloads (<5KB): auth, client init, user
  /// preferences/stats/beans deltas, launch popup, feature flags.
  static const Duration handshake = Duration(seconds: 5);

  /// Small syncs and writes (<150KB): recipes/facts/collections fetches,
  /// user-recipe sync, and individual insert/update/upsert/delete operations.
  static const Duration smallSync = Duration(seconds: 8);

  /// The full initial DB download on first launch (~500KB gzipped: recipes +
  /// coffee facts + reference data, over a ~6-call chain).
  static const Duration firstLaunchBulk = Duration(seconds: 10);

  /// A delta-only re-sync on subsequent launches (local DB already seeded).
  static const Duration subsequentBulk = Duration(seconds: 8);
}
