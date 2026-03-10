// Gr0veWidgets.swift
//
// ══════════════════════════════════════════════════════════════
// SETUP CHECKLIST (do this in Xcode before building):
//
// 1. File > New > Target > Widget Extension
//    Name it exactly: Gr0veWidgetExtension
//    Uncheck "Include Configuration App Intent"
//
// 2. Both Runner AND Gr0veWidgetExtension need:
//    Signing & Capabilities → + Capability → App Groups
//    Add group: group.com.yourcompany.gr0ve   (match _kAppGroup in Dart)
//
// 3. Replace the generated .swift file in the extension with this file.
//
// 4. In Gr0veWidgetExtension's Info.plist, NSExtension > NSExtensionAttributes
//    > WKAppBundleIdentifier should be your main bundle id (auto-set).
//
// 5. In AppDelegate.swift add inside application(_:didFinishLaunchingWithOptions):
//    if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
//    (This is also called from Dart via home_widget — belt-and-suspenders.)
//
// ══════════════════════════════════════════════════════════════

import WidgetKit
import SwiftUI

// ── Shared app group key ──────────────────────────────────────
private let appGroup = "group.com.arjunyuvaraj.gr0ve"

// ── UserDefaults helper ───────────────────────────────────────
private func ud() -> UserDefaults {
    UserDefaults(suiteName: appGroup) ?? .standard
}

private func jsonArray(_ key: String) -> [[String: Any]] {
    guard let raw = ud().string(forKey: key),
          let data = raw.data(using: .utf8),
          let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    return arr
}

private func jsonDict(_ key: String) -> [String: Any] {
    guard let raw = ud().string(forKey: key),
          let data = raw.data(using: .utf8),
          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return [:] }
    return dict
}

// ══════════════════════════════════════════════════════════════
// MARK: — PALETTE
// ══════════════════════════════════════════════════════════════

private extension Color {
    static let gr0veGreen   = Color(red: 0.20, green: 0.90, blue: 0.50)
    static let gr0veRed     = Color(red: 0.97, green: 0.44, blue: 0.44)
    static let gr0veAmber   = Color(red: 0.98, green: 0.75, blue: 0.14)
    static let gr0veSurface = Color(UIColor.secondarySystemBackground)
    static let gr0veBG      = Color(UIColor.systemBackground)
}

// ══════════════════════════════════════════════════════════════
// MARK: — SHARED TIMELINE PROVIDER (simple every-30-min refresh)
// ══════════════════════════════════════════════════════════════

struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [SimpleEntry(date: Date())], policy: .after(next)))
    }
}

struct SimpleEntry: TimelineEntry { let date: Date }

// ══════════════════════════════════════════════════════════════
// MARK: — BUS WIDGET
// ══════════════════════════════════════════════════════════════

struct BusWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    private var buses: [[String: Any]] { jsonArray("bus_data") }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:  BusSmall(buses: buses)
            case .systemMedium: BusMedium(buses: buses)
            case .systemLarge:  BusLarge(buses: buses)
            default:            BusSmall(buses: buses)
            }
        }
        .containerBackground(Color.gr0veBG, for: .widget)
    }
}

// ── Small: one bus, full circle ────────────────────────────────
private struct BusSmall: View {
    let buses: [[String: Any]]
    var body: some View {
        if let bus = buses.first {
            BusCircleCard(bus: bus, size: 90)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EmptyBusPlaceholder()
        }
    }
}

// ── Medium: 2 buses, or 1 wide ────────────────────────────────
private struct BusMedium: View {
    let buses: [[String: Any]]
    var body: some View {
        if buses.isEmpty {
            EmptyBusPlaceholder()
        } else if buses.count == 1 {
            BusCircleCard(bus: buses[0], size: 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HStack(spacing: 12) {
                ForEach(Array(buses.prefix(2).enumerated()), id: \.offset) { _, bus in
                    BusCircleCard(bus: bus, size: 72)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
        }
    }
}

// ── Large: up to 4 buses in 2×2 grid ─────────────────────────
private struct BusLarge: View {
    let buses: [[String: Any]]
    var body: some View {
        if buses.isEmpty {
            EmptyBusPlaceholder()
        } else {
            let grid = Array(buses.prefix(4))
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "bus.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("BUSES")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                let rows = stride(from: 0, to: grid.count, by: 2).map {
                    Array(grid[$0..<min($0+2, grid.count)])
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 10) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, bus in
                            BusCircleCard(bus: bus, size: 80)
                                .frame(maxWidth: .infinity)
                        }
                        if row.count == 1 { Spacer().frame(maxWidth: .infinity) }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }
}

private struct BusCircleCard: View {
    let bus: [String: Any]
    let size: CGFloat

    private var code:      String { bus["code"]   as? String ?? "?" }
    private var town:      String { bus["town"]   as? String ?? "" }
    private var status:    String { bus["status"] as? String ?? "" }
    private var isArrived: Bool   { status.lowercased() == "arrived" }
    private var isUnknown: Bool   { code == "?" || code.isEmpty }
    private var accentColor: Color {
        isUnknown ? .gr0veRed : isArrived ? .gr0veGreen : .gr0veAmber
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.25), lineWidth: 3)
                    .frame(width: size, height: size)
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: size - 6, height: size - 6)
                Text(code)
                    .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                    .foregroundColor(accentColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            Text(town)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary.opacity(0.7))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: size + 10)
        }
    }
}

private struct EmptyBusPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bus")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Star buses in gr0ve")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Gr0veBusWidget: Widget {
    let kind = "Gr0veBusWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
            BusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("gr0ve Buses")
        .description("Live status for your starred bus routes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: — TEACHER WIDGET
// ══════════════════════════════════════════════════════════════

struct TeacherWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    private var teachers: [[String: Any]] { jsonArray("teacher_data") }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:  TeacherSmall(teachers: teachers)
            case .systemMedium: TeacherMedium(teachers: teachers)
            case .systemLarge:  TeacherLarge(teachers: teachers)
            default:            TeacherSmall(teachers: teachers)
            }
        }
        .containerBackground(Color.gr0veBG, for: .widget)
    }
}

private func teacherStatusColor(_ status: String) -> Color {
    status.lowercased() == "present" ? .gr0veGreen : .gr0veRed
}

private struct TeacherRow: View {
    let teacher: [String: Any]
    let compact: Bool

    private var name:   String { teacher["name"]       as? String ?? "" }
    private var dept:   String { teacher["department"] as? String ?? "" }
    private var status: String { teacher["status"]     as? String ?? "Present" }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(teacherStatusColor(status))
                .frame(width: 8, height: 8)
                .shadow(color: teacherStatusColor(status).opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: compact ? 12 : 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if !compact {
                    Text(dept)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(status)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(teacherStatusColor(status).opacity(0.15))
                .foregroundColor(teacherStatusColor(status))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, compact ? 7 : 10)
        .background(Color.gr0veSurface)
        .cornerRadius(12)
    }
}

private struct TeacherSmall: View {
    let teachers: [[String: Any]]
    var body: some View {
        if let t = teachers.first {
            VStack(alignment: .leading, spacing: 6) {
                Label("TEACHER", systemImage: "person.fill")
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                TeacherRow(teacher: t, compact: false)
                Spacer()
            }
            .padding(14)
        } else {
            EmptyTeacherPlaceholder()
        }
    }
}

private struct TeacherMedium: View {
    let teachers: [[String: Any]]
    var body: some View {
        if teachers.isEmpty {
            EmptyTeacherPlaceholder()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Label("TEACHERS", systemImage: "person.2.fill")
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(Array(teachers.prefix(2).enumerated()), id: \.offset) { _, t in
                        TeacherRow(teacher: t, compact: false)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(14)
        }
    }
}

private struct TeacherLarge: View {
    let teachers: [[String: Any]]
    var body: some View {
        if teachers.isEmpty {
            EmptyTeacherPlaceholder()
        } else {
            VStack(alignment: .leading, spacing: 7) {
                Label("TEACHERS", systemImage: "person.2.fill")
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)

                ForEach(Array(teachers.prefix(5).enumerated()), id: \.offset) { _, t in
                    TeacherRow(teacher: t, compact: false)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }
}

private struct EmptyTeacherPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.slash")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Star teachers in gr0ve")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Gr0veTeacherWidget: Widget {
    let kind = "Gr0veTeacherWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
            TeacherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("gr0ve Teachers")
        .description("Absence status for your starred teachers.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: — SCHEDULE / COUNTDOWN WIDGET
// ══════════════════════════════════════════════════════════════

struct ScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), payload: ["phase": "period", "label": "Period 4", "secs": 1800, "prog": 0.5])
    }
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let payload = jsonDict("schedule_data")
        let entry   = ScheduleEntry(date: Date(), payload: payload)
        let next    = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let payload: [String: Any]
}

private func fmtSec(_ s: Int) -> String {
    let h = s / 3600, m = (s % 3600) / 60, sc = s % 60
    let mm = String(format: "%02d", m), ss = String(format: "%02d", sc)
    return h > 0 ? String(format: "%02d", h) + ":\(mm):\(ss)" : "\(mm):\(ss)"
}

struct ScheduleWidgetEntryView: View {
    var entry: ScheduleEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme

    private var p: [String: Any] { entry.payload }
    private var phase: String { p["phase"]  as? String ?? "pre" }
    private var label: String { p["label"]  as? String ?? "" }
    private var secs:  Int    { p["secs"]   as? Int    ?? 0 }
    private var prog:  Double { p["prog"]   as? Double ?? 0 }
    private var next:  String { p["next"]   as? String ?? "" }

    private var accentColor: Color {
        switch phase {
        case "done":    return .gr0veGreen
        case "passing": return .gr0veAmber
        case "pre":     return .secondary
        default:        return Color.accentColor
        }
    }

    // The gradient background used by the schedule widget — applied
    // via containerBackground so it works on Home, Lock, and StandBy.
    private var gradientBG: some ShapeStyle {
        LinearGradient(
            colors: [accentColor.opacity(scheme == .dark ? 0.12 : 0.06), Color.gr0veBG],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                ScheduleSmall(phase: phase, label: label, secs: secs, accent: accentColor)
            case .systemMedium:
                ScheduleMedium(phase: phase, label: label, secs: secs, prog: prog, next: next, accent: accentColor)
            case .systemLarge:
                ScheduleLarge(phase: phase, label: label, secs: secs, prog: prog, next: next, accent: accentColor, now: entry.date)
            default:
                ScheduleSmall(phase: phase, label: label, secs: secs, accent: accentColor)
            }
        }
        .containerBackground(gradientBG, for: .widget)
    }
}

// ── Small ──────────────────────────────────────────────────────
private struct ScheduleSmall: View {
    let phase: String, label: String, secs: Int, accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Circle().fill(accent).frame(width: 6, height: 6)
                    .shadow(color: accent.opacity(0.7), radius: 3)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if phase == "done" {
                Text("Done! 🎉")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(accent)
            } else if phase == "pre" {
                Text("8:00 AM")
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundColor(.primary)
            } else {
                Text(fmtSec(secs))
                    .font(.system(size: 30, weight: .black, design: .monospaced))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// ── Medium ─────────────────────────────────────────────────────
private struct ScheduleMedium: View {
    let phase: String, label: String, secs: Int, prog: Double, next: String, accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(accent).frame(width: 7, height: 7)
                    .shadow(color: accent.opacity(0.7), radius: 4)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                Spacer()
                Text(timeString())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Group {
                    if phase == "done" {
                        Text("Done! 🎉")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(accent)
                    } else if phase == "pre" {
                        Text("Starts 8:00 AM")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.primary)
                    } else {
                        Text(fmtSec(secs))
                            .font(.system(size: 38, weight: .black, design: .monospaced))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }
                if phase == "passing", !next.isEmpty {
                    Text("→ \(next)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if phase == "period" {
                    Text("remaining")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            if phase == "period" || phase == "countdown" {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accent)
                            .frame(width: geo.size.width * CGFloat(prog), height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func timeString() -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "h:mm a"
        return fmt.string(from: Date())
    }
}

// ── Large ──────────────────────────────────────────────────────
private struct ScheduleLarge: View {
    let phase: String, label: String, secs: Int, prog: Double, next: String, accent: Color, now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Circle().fill(accent).frame(width: 8, height: 8)
                            .shadow(color: accent.opacity(0.8), radius: 5)
                        Text(label.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.8)
                            .foregroundColor(.secondary)
                    }
                    Text(timeString())
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                Spacer()
                Text("gr0ve")
                    .font(.system(size: 11, weight: .black))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(accent.opacity(0.15))
                    .foregroundColor(accent)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 18).padding(.top, 18)

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                if phase == "done" {
                    Text("Done! 🎉")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(accent)
                } else if phase == "pre" {
                    Text("8:00 AM")
                        .font(.system(size: 52, weight: .black, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("School starts soon")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                } else {
                    Text(fmtSec(secs))
                        .font(.system(size: 56, weight: .black, design: .monospaced))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    if phase == "passing", !next.isEmpty {
                        Text("→ \(next)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(accent)
                    } else if phase == "period" {
                        Text("remaining in \(label)")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    } else if phase == "countdown" {
                        Text("until school")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 18)

            Spacer()

            if phase == "period" || phase == "countdown" || phase == "passing" {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [accent, accent.opacity(0.6)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geo.size.width * CGFloat(phase == "passing" ? 0.5 : prog),
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)

                    HStack(spacing: 3) {
                        ForEach(0..<10, id: \.self) { i in
                            let isCurrent = isPeriodActive(index: i)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isCurrent ? accent : Color.primary.opacity(0.1))
                                .frame(height: isCurrent ? 14 : 8)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 14)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            } else {
                Spacer().frame(height: 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func isPeriodActive(index: Int) -> Bool {
        let h  = Calendar.current.component(.hour,   from: now)
        let m  = Calendar.current.component(.minute, from: now)
        let nm = h * 60 + m
        let starts = [480, 534, 542, 596, 650, 704, 758, 812, 866, 920]
        let ends   = [530, 538, 592, 646, 700, 754, 808, 862, 916, 970]
        guard index < starts.count else { return false }
        return nm >= starts[index] && nm < ends[index]
    }

    private func timeString() -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "EEEE · h:mm a"
        return fmt.string(from: now)
    }
}

struct Gr0veScheduleWidget: Widget {
    let kind = "Gr0veScheduleWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleProvider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("gr0ve Schedule")
        .description("Live period countdown and school day progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: — BUNDLE
// ══════════════════════════════════════════════════════════════

@main
struct Gr0veWidgetBundle: WidgetBundle {
    var body: some Widget {
        Gr0veBusWidget()
        Gr0veTeacherWidget()
        Gr0veScheduleWidget()
    }
}