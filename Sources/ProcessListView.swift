import AppKit
import SwiftUI

struct ProcessListView: View {
    let store: ProcessStore
    @State private var startsAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(store.processes) { process in
                        ProcessRow(process: process) { store.kill(process) }
                    }
                }
                .padding(6)
            }
            .frame(maxHeight: 360)
            .fixedSize(horizontal: false, vertical: true)
            Divider()
            footer
        }
        .frame(width: 340)
    }

    private var header: some View {
        HStack {
            Text(store.processes.count == 1 ? "1 process running" : "\(store.processes.count) processes running")
                .font(.headline)
            Spacer()
            Button("Kill all", role: .destructive) { store.killAll() }
                .buttonStyle(.plain)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.red, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack {
            Toggle("Start at login", isOn: $startsAtLogin)
                .toggleStyle(.checkbox)
                .onChange(of: startsAtLogin) { _, enabled in LoginItem.set(enabled) }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.borderless)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct ProcessRow: View {
    let process: DevProcess
    let onKill: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: process.ports.isEmpty ? "moon.zzz.fill" : "network")
                .foregroundStyle(process.ports.isEmpty ? .orange : .green)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(process.title).fontWeight(.medium).lineLimit(1)
                    ForEach(process.ports, id: \.self) { port in
                        Text(verbatim: ":\(port)")
                            .font(.caption.monospacedDigit())
                            .padding(.horizontal, 5)
                            .background(.quaternary, in: Capsule())
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Button(action: onKill) {
                Image(systemName: "xmark.circle.fill").font(.title3)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(isHovered ? .red : .secondary)
            .help("Kill \(process.title)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear), in: RoundedRectangle(cornerRadius: 6))
        .onHover { isHovered = $0 }
        .help(process.arguments.joined(separator: " "))
    }

    private var subtitle: String {
        [process.project, process.name, "pid \(process.pid)", process.isOrphan ? "orphaned" : nil]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
