import AppKit
import CodexTPSCore
import ServiceManagement
import SwiftUI

@MainActor
final class MonitorStore: ObservableObject {
  @Published private(set) var snapshot: UsageSnapshot
  @Published private(set) var isRefreshing = false
  @Published private(set) var launchAtLoginEnabled = false
  @Published private(set) var selectedWindow: MetricWindow
  @Published private(set) var refreshCadence: RefreshCadence
  @Published private(set) var settingsError: String?

  let sessionsURL: URL
  private let scanner: SessionScanner
  private var refreshLoop: Task<Void, Never>?
  private static let selectedWindowDefaultsKey = "selectedMetricWindow"
  private static let refreshCadenceDefaultsKey = "refreshCadenceSeconds"

  init() {
    // The signed GUI only grants read access to the default sessions root.
    let codexHome = SessionScanner.defaultCodexHome(environment: [:])
    let savedWindow = UserDefaults.standard.string(forKey: Self.selectedWindowDefaultsKey)
    let savedCadence = UserDefaults.standard.double(forKey: Self.refreshCadenceDefaultsKey)
    selectedWindow = savedWindow.flatMap(MetricWindow.init(rawValue:)) ?? .oneMinute
    refreshCadence = RefreshCadence(rawValue: savedCadence) ?? .fifteenSeconds
    scanner = SessionScanner(codexHome: codexHome)
    sessionsURL = codexHome.appendingPathComponent("sessions", isDirectory: true)
    snapshot = .empty(at: Date(), status: .ready)
    refreshLaunchAtLoginStatus()
  }

  var menuBarTitle: String {
    guard snapshot.status == .ready else { return "-- t/s" }
    return "\(RateFormatter.compact(selectedWindow.metrics(from: snapshot).tokensPerSecond)) t/s"
  }

  func start() {
    guard refreshLoop == nil else { return }
    scheduleRefreshLoop()
  }

  func setRefreshCadence(_ cadence: RefreshCadence) {
    guard cadence != refreshCadence else { return }
    refreshCadence = cadence
    UserDefaults.standard.set(cadence.rawValue, forKey: Self.refreshCadenceDefaultsKey)
    scheduleRefreshLoop()
  }

  func setMetricWindow(_ window: MetricWindow) {
    guard window != selectedWindow else { return }
    selectedWindow = window
    UserDefaults.standard.set(window.rawValue, forKey: Self.selectedWindowDefaultsKey)
  }

  private func scheduleRefreshLoop() {
    refreshLoop?.cancel()
    let cadence = refreshCadence
    refreshLoop = Task { [weak self] in
      while !Task.isCancelled {
        guard let self else { return }
        await refresh()
        try? await Task.sleep(for: .seconds(cadence.rawValue))
      }
    }
  }

  func refresh() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    snapshot = await scanner.refresh()
    isRefreshing = false
  }

  func openSessionsDirectory() {
    NSWorkspace.shared.open(sessionsURL)
  }

  func refreshLaunchAtLoginStatus() {
    launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
  }

  func setLaunchAtLogin(_ enabled: Bool) {
    do {
      if enabled, SMAppService.mainApp.status != .enabled {
        try SMAppService.mainApp.register()
      } else if !enabled, SMAppService.mainApp.status == .enabled {
        try SMAppService.mainApp.unregister()
      }
      settingsError = nil
    } catch {
      settingsError = error.localizedDescription
    }
    refreshLaunchAtLoginStatus()
  }

  func quit() {
    NSApplication.shared.terminate(nil)
  }
}

enum MetricWindow: String, CaseIterable, Identifiable {
  case oneMinute = "1 分鐘"
  case fiveMinutes = "5 分鐘"
  case thirtyMinutes = "30 分鐘"
  case oneHour = "1 小時"

  var id: Self { self }

  func metrics(from snapshot: UsageSnapshot) -> WindowMetrics {
    switch self {
    case .oneMinute:
      snapshot.oneMinute
    case .fiveMinutes:
      snapshot.fiveMinutes
    case .thirtyMinutes:
      snapshot.thirtyMinutes
    case .oneHour:
      snapshot.oneHour
    }
  }
}

enum RefreshCadence: Double, CaseIterable, Identifiable {
  case fiveSeconds = 5
  case fifteenSeconds = 15
  case thirtySeconds = 30
  case oneMinute = 60

  var id: Self { self }

  var label: String {
    switch self {
    case .fiveSeconds:
      "5 秒"
    case .fifteenSeconds:
      "15 秒"
    case .thirtySeconds:
      "30 秒"
    case .oneMinute:
      "1 分鐘"
    }
  }
}

enum RateFormatter {
  static func compact(_ value: Double) -> String {
    switch abs(value) {
    case 1_000_000...:
      return String(format: "%.1fM", value / 1_000_000)
    case 1_000...:
      return String(format: "%.1fk", value / 1_000)
    case 10...:
      return String(format: "%.0f", value)
    default:
      return String(format: "%.1f", value)
    }
  }

  static func detailed(_ value: Double) -> String {
    if abs(value) >= 1_000 {
      return value.formatted(.number.precision(.fractionLength(0)))
    }
    return value.formatted(.number.precision(.fractionLength(1)))
  }
}
