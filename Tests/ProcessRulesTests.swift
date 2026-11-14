import Testing
@testable import LightsOut

struct ProcessRulesTests {
    @Test func recognisesRuntimes() {
        #expect(ProcessRules.isRuntime("node"))
        #expect(ProcessRules.isRuntime("Python"))
        #expect(ProcessRules.isRuntime("python3.12"))
        #expect(!ProcessRules.isRuntime("Safari"))
    }

    @Test func runtimeListedOnlyWhenListeningOrOrphaned() {
        #expect(ProcessRules.shouldList(name: "node", path: "/opt/homebrew/bin/node", listening: true, orphan: false))
        #expect(ProcessRules.shouldList(name: "node", path: "/opt/homebrew/bin/node", listening: false, orphan: true))
        #expect(!ProcessRules.shouldList(name: "node", path: "/opt/homebrew/bin/node", listening: false, orphan: false))
    }

    @Test func otherBinariesNeedPortAndUserLocation() {
        #expect(ProcessRules.shouldList(name: "postgres", path: "/opt/homebrew/bin/postgres", listening: true, orphan: false))
        #expect(!ProcessRules.shouldList(name: "postgres", path: "/opt/homebrew/bin/postgres", listening: false, orphan: true))
        #expect(!ProcessRules.shouldList(name: "rapportd", path: "/usr/libexec/rapportd", listening: true, orphan: true))
        #expect(!ProcessRules.shouldList(name: "Helper", path: "/usr/local/Foo.app/Contents/MacOS/Helper", listening: true, orphan: false))
    }

    @Test func titlePicksScriptOrModule() {
        #expect(ProcessRules.title(name: "node", arguments: ["node", "/p/node_modules/.bin/vite", "--port", "3000"]) == "vite")
        #expect(ProcessRules.title(name: "Python", arguments: ["python3", "-m", "http.server", "8000"]) == "http.server")
        #expect(ProcessRules.title(name: "Python", arguments: ["python3", "-u", "manage.py", "runserver"]) == "manage.py")
        #expect(ProcessRules.title(name: "node", arguments: ["node"]) == "node")
        #expect(ProcessRules.title(name: "node", arguments: ["node", "-e", "setInterval(() => {}, 1000)"]) == "node")
        #expect(ProcessRules.title(name: "postgres", arguments: ["postgres", "-D", "/data"]) == "postgres")
    }
}
