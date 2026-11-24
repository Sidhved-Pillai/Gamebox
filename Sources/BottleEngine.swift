import Foundation
import AppKit

struct Bottle: Identifiable {
    let name: String
    let url: URL
    var id: String { url.path }
}

enum EngineError: LocalizedError {
    case noRunner, invalidName, alreadyExists, missingBottle, failed(String)
    var errorDescription: String? {
        switch self {
        case .noRunner: "Select a Wine runner in Settings first."
        case .invalidName: "Use letters, numbers, spaces, underscores, or hyphens for the bottle name."
        case .alreadyExists: "A bottle with that name already exists."
        case .missingBottle: "The selected bottle is missing."
        case .failed(let message): message
        }
    }
}

@MainActor final class BottleEngine {
    static let shared = BottleEngine()
    let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Gamebox/Bottles", isDirectory: true)
    var runner: URL? {
        get { UserDefaults.standard.string(forKey: "wineRunner").map { URL(fileURLWithPath: $0) } }
        set { UserDefaults.standard.set(newValue?.path, forKey: "wineRunner") }
    }
    init() { try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }
    func bottles() -> [Bottle] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        return urls.filter { FileManager.default.fileExists(atPath: $0.appendingPathComponent("drive_c").path) }
            .map { Bottle(name: $0.lastPathComponent, url: $0) }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    func validName(_ name: String) -> Bool {
        !name.isEmpty && name.range(of: #"^[A-Za-z0-9 _-]+$"#, options: .regularExpression) != nil && name != "." && name != ".."
    }
    func create(_ name: String, completion: @escaping (Result<Bottle, Error>) -> Void) throws {
        guard validName(name) else { throw EngineError.invalidName }
        let url = root.appendingPathComponent(name, isDirectory: true)
        guard !FileManager.default.fileExists(atPath: url.path) else { throw EngineError.alreadyExists }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        do { try run(["wineboot", "-u"], in: url) { result in
            if case .failure = result { try? FileManager.default.removeItem(at: url) }
            completion(result.map { _ in Bottle(name: name, url: url) })
        }} catch { try? FileManager.default.removeItem(at: url); throw error }
    }
    func run(_ arguments: [String], in bottle: URL, completion: @escaping (Result<String, Error>) -> Void) throws {
        guard let runner, FileManager.default.isExecutableFile(atPath: runner.path) else { throw EngineError.noRunner }
        guard FileManager.default.fileExists(atPath: bottle.path) else { throw EngineError.missingBottle }
        let process = Process()
        process.executableURL = runner
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment.merging(["WINEPREFIX": bottle.path]) { _, new in new }
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent("gamebox-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        let log = try FileHandle(forWritingTo: logURL)
        process.standardOutput = log
        process.standardError = log
        process.terminationHandler = { process in
            try? log.close()
            let data = (try? Data(contentsOf: logURL)) ?? Data()
            try? FileManager.default.removeItem(at: logURL)
            let output = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async { completion(process.terminationStatus == 0 ? .success(output) : .failure(EngineError.failed(output.isEmpty ? "Wine exited with code \(process.terminationStatus)." : output))) }
        }
        do { try process.run() }
        catch { try? log.close(); try? FileManager.default.removeItem(at: logURL); throw error }
    }
    func delete(_ bottle: Bottle) throws {
        guard bottle.url.deletingLastPathComponent() == root,
              FileManager.default.fileExists(atPath: bottle.url.appendingPathComponent("drive_c").path) else { throw EngineError.missingBottle }
        try FileManager.default.trashItem(at: bottle.url, resultingItemURL: nil)
    }
}
