import Foundation

struct DevProcess: Identifiable, Equatable {
    let pid: Int32
    let name: String
    let arguments: [String]
    let directory: String?
    let ports: [UInt16]
    let isOrphan: Bool

    var id: Int32 { pid }

    var title: String { ProcessRules.title(name: name, arguments: arguments) }

    var project: String? {
        guard let directory, directory != "/", directory != NSHomeDirectory() else { return nil }
        return (directory as NSString).lastPathComponent
    }
}
