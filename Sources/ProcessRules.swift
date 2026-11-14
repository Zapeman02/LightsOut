import Foundation

/// Pure decisions about which processes count as leftover dev processes and how to label them.
enum ProcessRules {
    static let runtimes: Set<String> = ["node", "bun", "deno", "ruby", "java", "php", "dotnet", "beam.smp", "uvicorn", "gunicorn", "flask"]

    static let userPrefixes = ["/opt/homebrew/", "/usr/local/", NSHomeDirectory() + "/"]

    static func isRuntime(_ name: String) -> Bool {
        let lower = name.lowercased()
        return runtimes.contains(lower) || lower.hasPrefix("python")
    }

    /// Runtimes are listed when they hold a port or lost their parent.
    /// Anything else is listed only when it holds a port and was launched from a user location,
    /// so system services and regular apps stay out of the list.
    static func shouldList(name: String, path: String, listening: Bool, orphan: Bool) -> Bool {
        if isRuntime(name) { return listening || orphan }
        guard listening, !path.contains(".app/") else { return false }
        return userPrefixes.contains { path.hasPrefix($0) }
    }

    /// "node /x/node_modules/.bin/vite --port 3000" -> "vite", "python3 -m http.server" -> "http.server".
    static func title(name: String, arguments: [String]) -> String {
        guard isRuntime(name) else { return name }
        var args = arguments.dropFirst()
        while let arg = args.first {
            args = args.dropFirst()
            if arg == "-m", let module = args.first { return module }
            if ["-e", "-c", "-p", "--eval"].contains(arg) { return name }
            if !arg.hasPrefix("-") { return (arg as NSString).lastPathComponent }
        }
        return name
    }
}
