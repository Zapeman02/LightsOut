import Foundation
import Testing
@testable import LightsOut

@MainActor
struct ProcessStoreTests {
    private func process(_ pid: Int32) -> DevProcess {
        DevProcess(pid: pid, name: "node", arguments: ["node", "server.js"], directory: "/tmp/app", ports: [3000], isOrphan: false)
    }

    @Test func refreshPublishesScanResult() {
        var result = [process(1)]
        let store = ProcessStore { result }
        store.refresh()
        #expect(store.processes.map(\.pid) == [1])
        result = []
        store.refresh()
        #expect(store.processes.isEmpty)
    }

    @Test func projectIsWorkingDirectoryName() {
        #expect(process(1).project == "app")
        #expect(DevProcess(pid: 1, name: "node", arguments: [], directory: "/", ports: [], isOrphan: true).project == nil)
    }
}

/// Starts a real server and checks the kernel-level scan and kill against it.
@MainActor
struct ProcessScannerTests {
    @Test func findsAndKillsListeningServer() async throws {
        let port = UInt16.random(in: 40000...50000)
        let server = Process()
        server.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        server.arguments = ["-m", "http.server", "\(port)", "--bind", "127.0.0.1"]
        server.currentDirectoryURL = FileManager.default.temporaryDirectory
        server.standardOutput = FileHandle.nullDevice
        server.standardError = FileHandle.nullDevice
        try server.run()
        defer { if server.isRunning { server.terminate() } }

        var found: DevProcess?
        for _ in 0..<50 where found == nil {
            try await Task.sleep(for: .milliseconds(100))
            found = ProcessScanner.scan().first { $0.ports.contains(port) }
        }
        let process = try #require(found)
        #expect(process.title == "http.server")

        let store = ProcessStore()
        store.refresh()
        store.kill(process)
        server.waitUntilExit()
        #expect(!store.processes.contains { $0.pid == process.pid })
    }
}
