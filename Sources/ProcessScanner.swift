import Darwin
import Foundation

/// Reads the process table straight from the kernel via libproc, so a scan costs a few
/// milliseconds instead of spawning `ps` and `lsof`.
enum ProcessScanner {
    static func scan() -> [DevProcess] {
        let me = getuid()
        let ownPid = getpid()
        return allPids().compactMap { pid -> DevProcess? in
            guard pid > 0, pid != ownPid, let info = bsdInfo(pid), info.pbi_uid == me else { return nil }
            let name = withUnsafeBytes(of: info.pbi_comm) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
            let path = executablePath(pid) ?? ""
            let orphan = info.pbi_ppid == 1
            // Port lookup walks every file descriptor, so only do it for plausible candidates.
            guard ProcessRules.isRuntime(name) || ProcessRules.userPrefixes.contains(where: path.hasPrefix) else { return nil }
            let ports = listeningPorts(pid)
            guard ProcessRules.shouldList(name: name, path: path, listening: !ports.isEmpty, orphan: orphan) else { return nil }
            return DevProcess(pid: pid, name: name, arguments: arguments(pid), directory: workingDirectory(pid), ports: ports, isOrphan: orphan)
        }
        .sorted { ($0.project ?? "~", $0.pid) < ($1.project ?? "~", $1.pid) }
    }

    private static func allPids() -> [pid_t] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(count) + 64)
        let filled = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        return Array(pids.prefix(Int(max(filled, 0))))
    }

    private static func bsdInfo(_ pid: pid_t) -> proc_bsdinfo? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        return proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size ? info : nil
    }

    private static func executablePath(_ pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        return proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 ? String(cString: buffer) : nil
    }

    private static func workingDirectory(_ pid: pid_t) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size) == size else { return nil }
        let path = withUnsafeBytes(of: info.pvi_cdir.vip_path) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
        return path.isEmpty ? nil : path
    }

    private static func listeningPorts(_ pid: pid_t) -> [UInt16] {
        let bytes = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
        guard bytes > 0 else { return [] }
        var fds = [proc_fdinfo](repeating: proc_fdinfo(), count: Int(bytes) / MemoryLayout<proc_fdinfo>.size)
        let filled = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, &fds, bytes)
        var ports = Set<UInt16>()
        for fd in fds.prefix(Int(filled) / MemoryLayout<proc_fdinfo>.size) where fd.proc_fdtype == PROX_FDTYPE_SOCKET {
            var socket = socket_fdinfo()
            let size = Int32(MemoryLayout<socket_fdinfo>.size)
            guard proc_pidfdinfo(pid, fd.proc_fd, PROC_PIDFDSOCKETINFO, &socket, size) == size,
                  socket.psi.soi_kind == SOCKINFO_TCP,
                  socket.psi.soi_proto.pri_tcp.tcpsi_state == TSI_S_LISTEN else { continue }
            ports.insert(UInt16(bigEndian: UInt16(truncatingIfNeeded: socket.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport)))
        }
        return ports.sorted()
    }

    /// KERN_PROCARGS2 layout: argc, exec path, NUL padding, then argc NUL-terminated arguments.
    private static func arguments(_ pid: pid_t) -> [String] {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return [] }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else { return [] }
        let argc = buffer.withUnsafeBytes { $0.load(as: Int32.self) }
        var parts = buffer[MemoryLayout<Int32>.size..<size].split(separator: 0, omittingEmptySubsequences: true).dropFirst()
        var result: [String] = []
        while result.count < argc, let part = parts.first {
            result.append(String(decoding: part, as: UTF8.self))
            parts = parts.dropFirst()
        }
        return result
    }
}
