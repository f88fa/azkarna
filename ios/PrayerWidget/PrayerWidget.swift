import SwiftUI
import WidgetKit

// MARK: - Shared data (written by the app, see lib/features/prayer_widget)

let appGroupId = "group.com.alray.azkarna"

struct PrayerSlot: Codable, Hashable {
  /// Prayer id: fajr, dhuhr, asr, maghrib, isha.
  let n: String
  /// Arabic name.
  let l: String
  /// Adhan instant, epoch seconds.
  let t: Double

  var date: Date { Date(timeIntervalSince1970: t) }

  /// After the Adhan the widget counts up for an hour (40 minutes after
  /// Maghrib), then moves on to the next prayer.
  var elapsedWindow: TimeInterval { n == "maghrib" ? 40 * 60 : 60 * 60 }

  var symbol: String {
    switch n {
    case "fajr": return "sun.horizon.fill"
    case "dhuhr": return "sun.max.fill"
    case "asr": return "sun.min.fill"
    case "maghrib": return "sunset.fill"
    default: return "moon.stars.fill"
    }
  }
}

enum PrayerStore {
  static func slots() -> [PrayerSlot] {
    guard
      let json = UserDefaults(suiteName: appGroupId)?.string(forKey: "prayers"),
      let data = json.data(using: .utf8),
      let slots = try? JSONDecoder().decode([PrayerSlot].self, from: data)
    else { return [] }
    return slots.sorted { $0.t < $1.t }
  }
}

// MARK: - What to show at a given moment

enum Phase: Hashable {
  /// Before the Adhan: count down to it.
  case upcoming(PrayerSlot)
  /// After the Adhan, inside its window: count up from it.
  case elapsed(PrayerSlot)
  /// No data yet (app never opened) or it ran out.
  case empty

  static func at(_ now: Date, in slots: [PrayerSlot]) -> Phase {
    let t = now.timeIntervalSince1970
    if let last = slots.last(where: { $0.t <= t }), t < last.t + last.elapsedWindow {
      return .elapsed(last)
    }
    if let next = slots.first(where: { $0.t > t }) { return .upcoming(next) }
    return .empty
  }
}

struct PrayerEntry: TimelineEntry {
  let date: Date
  let phase: Phase
}

struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(
      date: Date(),
      phase: .upcoming(PrayerSlot(n: "asr", l: "العصر", t: Date().addingTimeInterval(45 * 60).timeIntervalSince1970))
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    let slots = PrayerStore.slots()
    completion(slots.isEmpty ? placeholder(in: context) : PrayerEntry(date: Date(), phase: Phase.at(Date(), in: slots)))
  }

  /// One entry now plus one at every switch (each Adhan and the end of each
  /// elapsed window) for the next day; the live timer text does the rest.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let slots = PrayerStore.slots()
    let now = Date()
    let horizon = now.addingTimeInterval(26 * 3600)

    var switches: [Date] = []
    for slot in slots {
      for edge in [slot.date, slot.date.addingTimeInterval(slot.elapsedWindow)] where edge > now && edge < horizon {
        switches.append(edge)
      }
    }
    switches.sort()

    var entries = [PrayerEntry(date: now, phase: Phase.at(now, in: slots))]
    for date in switches {
      // A hair after the edge so the phase is unambiguous.
      entries.append(PrayerEntry(date: date, phase: Phase.at(date.addingTimeInterval(1), in: slots)))
    }
    let reload = switches.last ?? now.addingTimeInterval(6 * 3600)
    completion(Timeline(entries: entries, policy: .after(reload)))
  }
}

// MARK: - Views

private let arabic = Locale(identifier: "ar")

private func clock(_ date: Date) -> String {
  let f = DateFormatter()
  f.locale = arabic
  f.dateFormat = "h:mm"
  return f.string(from: date)
}

struct PrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PrayerEntry

  var body: some View {
    content
      .environment(\.locale, arabic)
      .environment(\.layoutDirection, .rightToLeft)
      .widgetBackground()
  }

  @ViewBuilder private var content: some View {
    switch entry.phase {
    case .empty:
      VStack(alignment: .leading, spacing: 2) {
        Label("أوّاب", systemImage: "moon.stars.fill").font(.headline)
        Text("افتح التطبيق لتحديث المواقيت").font(.caption)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

    case let .upcoming(slot):
      layout(slot: slot, caption: "بقي على \(slot.l)")

    case let .elapsed(slot):
      layout(slot: slot, caption: "مضى على \(slot.l)")
    }
  }

  @ViewBuilder private func layout(slot: PrayerSlot, caption: String) -> some View {
    switch family {
    case .accessoryInline:
      Label {
        Text("\(slot.l) ") + Text(slot.date, style: .timer)
      } icon: {
        Image(systemName: slot.symbol)
      }

    case .accessoryCircular:
      VStack(spacing: 0) {
        Image(systemName: slot.symbol).font(.caption)
        Text(slot.l).font(.system(size: 11, weight: .semibold)).lineLimit(1)
        Text(slot.date, style: .timer)
          .font(.system(size: 12, weight: .bold))
          .monospacedDigit()
          .multilineTextAlignment(.center)
          .minimumScaleFactor(0.6)
      }

    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 4) {
          Image(systemName: slot.symbol)
          Text("\(slot.l) \(clock(slot.date))")
        }
        .font(.system(size: 14, weight: .semibold))
        Text(caption).font(.system(size: 13))
        Text(slot.date, style: .timer)
          .font(.system(size: 22, weight: .bold))
          .monospacedDigit()
          .widgetAccentable()
      }
      .frame(maxWidth: .infinity, alignment: .leading)

    default:
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Image(systemName: slot.symbol)
          Text(slot.l)
          Spacer()
          Text(clock(slot.date)).foregroundStyle(.secondary)
        }
        .font(.system(size: 15, weight: .semibold))
        Spacer(minLength: 0)
        Text(caption).font(.system(size: 13)).foregroundStyle(.secondary)
        Text(slot.date, style: .timer)
          .font(.system(size: 30, weight: .bold))
          .monospacedDigit()
          .minimumScaleFactor(0.6)
          .foregroundStyle(Color(red: 0.04, green: 0.49, blue: 0.40))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
  }
}

private extension View {
  /// iOS 17 requires a container background; older versions ignore it.
  @ViewBuilder func widgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { Color(.systemBackground) }
    } else {
      self
    }
  }
}

// MARK: - Widget

struct PrayerWidget: Widget {
  let kind = "PrayerWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
      PrayerWidgetView(entry: entry)
    }
    .configurationDisplayName("الصلاة القادمة")
    .description("وقت الصلاة القادمة وكم بقي عليها، وكم مضى بعد الأذان.")
    .supportedFamilies([
      .accessoryRectangular,
      .accessoryInline,
      .accessoryCircular,
      .systemSmall,
    ])
  }
}

@main
struct PrayerWidgetBundle: WidgetBundle {
  var body: some Widget {
    PrayerWidget()
  }
}
