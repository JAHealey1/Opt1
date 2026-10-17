import Foundation

/// Movement buffs the player has unlocked, used to tune scan next-spot recommendations.
///
/// `doubleSurge`, `doubleEscape`, and `mobilePerk` are threaded through for OPT1-6
/// Phase 1 travel-time estimation via `ScanTimeModel`. This ticket only applies
/// `meerkats` (+5 scan range before the first observation).
struct ScanAssumptions: Equatable {
    var doubleSurge: Bool
    var doubleEscape: Bool
    var meerkats: Bool
    var mobilePerk: Bool

    /// Conservative baseline with no buffs assumed — safe for tests and explicit overrides.
    static let `default` = ScanAssumptions(
        doubleSurge: false,
        doubleEscape: false,
        meerkats: false,
        mobilePerk: false
    )

    /// Reads the four scan-assumption toggles from `AppSettings` (absent keys → enabled).
    static func fromSettings() -> ScanAssumptions {
        ScanAssumptions(
            doubleSurge: AppSettings.isScanAssumeDoubleSurgeEnabled,
            doubleEscape: AppSettings.isScanAssumeDoubleEscapeEnabled,
            meerkats: AppSettings.isScanAssumeMeerkatsEnabled,
            mobilePerk: AppSettings.isScanAssumeMobilePerkEnabled
        )
    }
}
