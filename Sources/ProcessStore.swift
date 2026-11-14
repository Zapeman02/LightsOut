import Foundation
import Observation

@MainActor
@Observable
final class ProcessStore {
    static let interval: TimeInterval = 3
    static let gracePeriod: Duration = .seconds(2)

    private(set) var processes: [DevProcess] = []
    private let scan: () -> [DevProcess]
    private var timer: Timer?

    init(scan: @escaping () -> [DevProcess] = ProcessScanner.scan) {
        self.scan = scan
    }

    func start() {
        refresh()
        let timer = Timer(timeInterval: Self.interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func refresh() {
        let fresh = scan()
        if fresh != processes { processes = fresh }
    }

    func kill(_ process: DevProcess) {
        terminate([process.pid])
    }

    func killAll() {
        terminate(processes.map(\.pid))
    }

    /// SIGTERM first so servers can shut down cleanly, SIGKILL whatever is still alive after the grace period.
    private func terminate(_ pids: [Int32]) {
        pids.forEach { Darwin.kill($0, SIGTERM) }
        processes.removeAll { pids.contains($0.pid) }
        Task {
            try? await Task.sleep(for: Self.gracePeriod)
            pids.filter { Darwin.kill($0, 0) == 0 }.forEach { Darwin.kill($0, SIGKILL) }
            refresh()
        }
    }
}
