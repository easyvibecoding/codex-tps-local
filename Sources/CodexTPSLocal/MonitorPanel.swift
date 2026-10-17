import AppKit
import CodexTPSCore
import SwiftUI

struct MonitorPanel: View {
  @EnvironmentObject private var store: MonitorStore

  private var metrics: WindowMetrics {
    store.selectedWindow.metrics(from: store.snapshot)
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      throughput
      Divider()
      footer
    }
    .frame(width: 380)
    .fixedSize(horizontal: false, vertical: true)
  }

  private var header: some View {
    HStack(spacing: 12) {
      Image(nsImage: NSApplication.shared.applicationIconImage)
        .resizable()
        .interpolation(.high)
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        Text("Codex TPS Local")
          .font(.headline)

        HStack(spacing: 6) {
          Circle()
            .fill(statusColor)
            .frame(width: 7, height: 7)
          Text(statusText)
          Text("·")
          Text(store.snapshot.generatedAt, style: .time)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      Spacer()

      HStack(spacing: 4) {
        HeaderIconButton(
          systemName: "arrow.clockwise",
          help: "立即重新整理",
          isDisabled: store.isRefreshing
        ) {
          Task { await store.refresh() }
        }

        HeaderIconButton(
          systemName: "folder",
          help: "開啟 Codex 對話目錄",
          action: store.openSessionsDirectory
        )
      }
    }
    .padding(16)
  }

  private var throughput: some View {
    VStack(alignment: .leading, spacing: 15) {
      Picker(
        "統計時間窗",
        selection: Binding(
          get: { store.selectedWindow },
          set: { window in store.setMetricWindow(window) }
        )
      ) {
        ForEach(MetricWindow.allCases) { window in
          Text(window.rawValue).tag(window)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()

      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text(RateFormatter.detailed(metrics.tokensPerSecond))
          .font(.system(size: 32, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.72)
          .layoutPriority(1)
        Text("token/s")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)

        Spacer(minLength: 12)

        VStack(alignment: .trailing, spacing: 2) {
          Text(metrics.requestsPerMinute.formatted(.number.precision(.fractionLength(1))))
            .font(.headline.weight(.semibold))
            .monospacedDigit()
          Text("請求/分鐘")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      HStack(spacing: 0) {
        RateColumn(title: "輸入", value: metrics.inputTokensPerSecond, color: .blue)
        RateColumn(title: "快取", value: metrics.cachedInputTokensPerSecond, color: .teal)
        RateColumn(title: "輸出", value: metrics.outputTokensPerSecond, color: .orange)
        RateColumn(title: "推理", value: metrics.reasoningTokensPerSecond, color: .purple)
      }

      HStack(spacing: 16) {
        Label("\(store.snapshot.activeSessions) 個活躍對話", systemImage: "rectangle.stack")
        Spacer()
        Text("快取占比 \(metrics.cacheRatio.formatted(.percent.precision(.fractionLength(0))))")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .padding(16)
  }

  private var footer: some View {
    VStack(spacing: 10) {
      Text("僅限本機 · 無網路連線")
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack {
        Picker(
          "自動重新整理",
          selection: Binding(
            get: { store.refreshCadence },
            set: { cadence in store.setRefreshCadence(cadence) }
          )
        ) {
          ForEach(RefreshCadence.allCases) { cadence in
            Text(cadence.label).tag(cadence)
          }
        }
        .pickerStyle(.menu)
        .controlSize(.small)
        .fixedSize()

        Spacer()

        Toggle(
          "登入時啟動",
          isOn: Binding(
            get: { store.launchAtLoginEnabled },
            set: { enabled in store.setLaunchAtLogin(enabled) }
          )
        )
        .toggleStyle(.switch)
        .controlSize(.small)

        Spacer()

        Button(action: store.quit) {
          Image(systemName: "power")
        }
        .buttonStyle(.borderless)
        .help("結束 Codex TPS Local")
      }

      if let settingsError = store.settingsError {
        Text(settingsError)
          .font(.caption)
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(16)
  }

  private var statusText: String {
    if store.isRefreshing { return "讀取中" }
    switch store.snapshot.status {
    case .ready:
      return store.snapshot.malformedRelevantLines == 0 ? "就緒" : "部分紀錄無法解析"
    case .sessionsDirectoryMissing:
      return "找不到對話目錄"
    case .readFailed:
      return "讀取失敗"
    }
  }

  private var statusColor: Color {
    if store.isRefreshing { return .blue }
    switch store.snapshot.status {
    case .ready:
      return store.snapshot.malformedRelevantLines == 0 ? .green : .orange
    case .sessionsDirectoryMissing:
      return .orange
    case .readFailed:
      return .red
    }
  }
}

private struct RateColumn: View {
  let title: String
  let value: Double
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(spacing: 5) {
        Circle()
          .fill(color)
          .frame(width: 5, height: 5)
        Text(title)
          .foregroundStyle(.secondary)
      }
      .font(.caption)

      Text(RateFormatter.compact(value))
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      Text("token/s")
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

private struct HeaderIconButton: View {
  let systemName: String
  let help: String
  var isDisabled = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 14, weight: .medium))
        .frame(width: 24, height: 24)
        .contentShape(Rectangle())
    }
    .buttonStyle(.borderless)
    .foregroundStyle(.secondary)
    .disabled(isDisabled)
    .help(help)
  }
}
