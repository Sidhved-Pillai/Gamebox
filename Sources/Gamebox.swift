import AppKit

@MainActor final class GameboxApp: NSObject, NSApplicationDelegate {
    let engine = BottleEngine.shared
    var window: NSWindow!
    var sidebar = NSStackView()
    var center = NSStackView()
    var actions = NSStackView()
    var selected: Bottle?
    var notice = ""
    var updateURL: URL?
    var updateVersion: String?
    var callbacks: [ObjectIdentifier: () -> Void] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1120, height: 700), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Gamebox"
        window.minSize = NSSize(width: 900, height: 550)
        window.center()
        let root = NSView(frame: window.contentView!.bounds)
        root.autoresizingMask = [.width, .height]
        window.contentView = root
        let left = pane(sidebar, color: NSColor.controlBackgroundColor)
        let middle = pane(center, color: NSColor.windowBackgroundColor)
        let right = pane(actions, color: NSColor.controlBackgroundColor)
        let split = NSSplitView(frame: root.bounds)
        split.isVertical = true
        split.dividerStyle = .thin
        split.autoresizingMask = [.width, .height]
        split.addSubview(left)
        split.addSubview(middle)
        split.addSubview(right)
        root.addSubview(split)
        split.setPosition(230, ofDividerAt: 0)
        split.setPosition(850, ofDividerAt: 1)
        render()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        Task { await checkUpdates() }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func pane(_ stack: NSStackView, color: NSColor) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 700))
        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 13
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 25)])
        return view
    }
    func render() {
        callbacks.removeAll()
        for stack in [sidebar, center, actions] { for view in stack.arrangedSubviews { stack.removeArrangedSubview(view); view.removeFromSuperview() } }
        sidebar.addArrangedSubview(text("GAMEBOX", size: 18, bold: true))
        sidebar.addArrangedSubview(text("BOTTLES", size: 11, bold: true, color: .secondaryLabelColor))
        sidebar.addArrangedSubview(button("⌂  Home") { self.selected = nil; self.render() })
        for bottle in engine.bottles() {
            let item = button("◼  \(bottle.name)") { self.selected = bottle; self.render() }
            item.state = selected?.id == bottle.id ? .on : .off
            sidebar.addArrangedSubview(item)
        }
        sidebar.addArrangedSubview(button("＋  New Bottle", action: createBottle))
        sidebar.addArrangedSubview(text("RUNNER", size: 11, bold: true, color: .secondaryLabelColor))
        sidebar.addArrangedSubview(text(engine.runner?.lastPathComponent ?? "Not configured", size: 12, color: .secondaryLabelColor))
        sidebar.addArrangedSubview(button("Choose Wine Runner…", action: chooseRunner))
        if let version = updateVersion, let url = updateURL {
            sidebar.addArrangedSubview(text("Version \(version) available", size: 12))
            sidebar.addArrangedSubview(button("Update now") { NSWorkspace.shared.open(url) })
        }

        if let bottle = selected {
            center.addArrangedSubview(text(bottle.name, size: 30, bold: true))
            center.addArrangedSubview(text("Windows bottle · Ready", size: 13, color: .secondaryLabelColor))
            center.addArrangedSubview(rule())
            center.addArrangedSubview(text("PROGRAMS", size: 12, bold: true, color: .secondaryLabelColor))
            center.addArrangedSubview(button("▶  Run Windows Program…", action: runProgram))
            center.addArrangedSubview(button("◉  Run Steam") { self.runSteam() })
            center.addArrangedSubview(button("↓  Install Steam in this bottle") { self.installSteam() })
            center.addArrangedSubview(button("★  Open GTA V Enhanced in Steam") { self.openGTA() })
            center.addArrangedSubview(rule())
            center.addArrangedSubview(text("CONFIGURATION", size: 12, bold: true, color: .secondaryLabelColor))
            center.addArrangedSubview(button("Windows version and drives…") { self.command("winecfg") })
            center.addArrangedSubview(button("Registry editor…") { self.command("regedit") })
            center.addArrangedSubview(button("Control panel…") { self.command("control") })
        } else {
            center.addArrangedSubview(text("Welcome to Gamebox", size: 30, bold: true))
            center.addArrangedSubview(text("Create a bottle to install and run Windows games on your Mac.", size: 14, color: .secondaryLabelColor))
            center.addArrangedSubview(rule())
            center.addArrangedSubview(text("YOUR BOTTLES", size: 12, bold: true, color: .secondaryLabelColor))
            if engine.bottles().isEmpty { center.addArrangedSubview(text("No bottles yet. Choose a Wine runner, then create a bottle.", size: 13, color: .secondaryLabelColor)) }
            for bottle in engine.bottles() { center.addArrangedSubview(button("◼  \(bottle.name)") { self.selected = bottle; self.render() }) }
            center.addArrangedSubview(button("＋  Create Bottle", action: createBottle))
        }
        if !notice.isEmpty { center.addArrangedSubview(rule()); center.addArrangedSubview(text(notice, size: 12, color: .secondaryLabelColor)) }

        actions.addArrangedSubview(text("BOTTLE ACTIONS", size: 11, bold: true, color: .secondaryLabelColor))
        actions.addArrangedSubview(button("Install Windows App…", action: runProgram))
        actions.addArrangedSubview(button("Install Steam", action: installSteam))
        actions.addArrangedSubview(button("Open C: Drive") { if let bottle = self.selected { NSWorkspace.shared.open(bottle.url.appendingPathComponent("drive_c")) } })
        actions.addArrangedSubview(button("Run Command…", action: runCommandDialog))
        actions.addArrangedSubview(rule())
        actions.addArrangedSubview(text("SYSTEM CONFIGURATION", size: 11, bold: true, color: .secondaryLabelColor))
        actions.addArrangedSubview(button("Wine Configuration") { self.command("winecfg") })
        actions.addArrangedSubview(button("Registry Editor") { self.command("regedit") })
        actions.addArrangedSubview(button("Game Controllers") { self.command("control", "joy.cpl") })
        actions.addArrangedSubview(rule())
        actions.addArrangedSubview(text("MANAGE", size: 11, bold: true, color: .secondaryLabelColor))
        actions.addArrangedSubview(button("Open Bottle Folder") { if let bottle = self.selected { NSWorkspace.shared.open(bottle.url) } })
        actions.addArrangedSubview(button("Move Bottle to Trash…", action: deleteBottle))
        actions.addArrangedSubview(button("Refresh") { self.render() })
        for button in actions.arrangedSubviews.compactMap({ $0 as? NSButton }) { button.isEnabled = selected != nil || button.title == "Refresh" }
    }
    func text(_ value: String, size: CGFloat, bold: Bool = false, color: NSColor = .labelColor) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: value)
        label.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        label.textColor = color
        return label
    }
    func button(_ title: String, action: @escaping () -> Void) -> NSButton {
        let button = NSButton(title: title, target: self, action: #selector(clicked(_:)))
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        callbacks[ObjectIdentifier(button)] = action
        return button
    }
    @objc func clicked(_ sender: NSButton) { callbacks[ObjectIdentifier(sender)]?() }
    func rule() -> NSView { let line = NSBox(); line.boxType = .separator; return line }
    func chooseRunner() {
        let panel = NSOpenPanel()
        panel.message = "Select a Wine executable from a Wine or CrossOver installation"
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { engine.runner = url; render() }
    }
    func createBottle() {
        guard engine.runner != nil else { notice = "Choose a Wine runner first."; render(); return }
        let alert = NSAlert()
        alert.messageText = "Create Bottle"
        alert.informativeText = "Each bottle has its own Windows files and settings."
        let field = NSTextField(string: "")
        field.placeholderString = "Bottle name"
        field.frame = NSRect(x: 0, y: 0, width: 260, height: 26)
        alert.accessoryView = field
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        notice = "Creating \(field.stringValue)…"
        render()
        do { try engine.create(field.stringValue) { result in
            switch result { case .success(let bottle): self.selected = bottle; self.notice = "Bottle created."
            case .failure(let error): self.notice = error.localizedDescription }
            self.render()
        }} catch { notice = error.localizedDescription; render() }
    }
    func command(_ arguments: String...) {
        guard let bottle = selected else { return }
        do { try engine.run(arguments, in: bottle.url) { result in
            if case .failure(let error) = result { self.notice = error.localizedDescription; self.render() }
        }} catch { notice = error.localizedDescription; render() }
    }
    func runProgram() {
        guard selected != nil else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.exe]
        panel.message = "Choose a Windows installer or program"
        if panel.runModal() == .OK, let url = panel.url { command(url.path) }
    }
    func runSteam() {
        guard let bottle = selected else { return }
        let paths = ["Program Files (x86)/Steam/steam.exe", "Program Files/Steam/steam.exe"]
        if let path = paths.map({ bottle.url.appendingPathComponent("drive_c").appendingPathComponent($0) }).first(where: { FileManager.default.fileExists(atPath: $0.path) }) { command(path.path) }
        else { notice = "Steam is not installed in this bottle. Download SteamSetup.exe and use Install Windows App."; render(); NSWorkspace.shared.open(URL(string: "https://store.steampowered.com/about/")!) }
    }
    func installSteam() {
        guard let bottle = selected else { return }
        notice = "Downloading Steam installer from Valve…"
        render()
        Task {
            do {
                let url = URL(string: "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe")!
                let (temporary, response) = try await URLSession.shared.download(from: url)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw EngineError.failed("Steam download failed.") }
                let installer = FileManager.default.temporaryDirectory.appendingPathComponent("Gamebox-SteamSetup-\(UUID().uuidString).exe")
                try FileManager.default.moveItem(at: temporary, to: installer)
                notice = "Running Steam installer…"
                render()
                try engine.run([installer.path], in: bottle.url) { result in
                    try? FileManager.default.removeItem(at: installer)
                    self.notice = result.map { _ in "Steam installer finished." }.getOrMessage()
                    self.render()
                }
            } catch { notice = error.localizedDescription; render() }
        }
    }
    func openGTA() {
        guard let bottle = selected else { return }
        let paths = ["Program Files (x86)/Steam/steam.exe", "Program Files/Steam/steam.exe"]
        if let path = paths.map({ bottle.url.appendingPathComponent("drive_c").appendingPathComponent($0) }).first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            do { try engine.run([path.path, "steam://install/3240220"], in: bottle.url) { result in
                if case .failure(let error) = result { self.notice = error.localizedDescription; self.render() }
            }} catch { notice = error.localizedDescription; render() }
        } else { notice = "Install Steam in this bottle first."; render() }
    }
    func runCommandDialog() {
        guard selected != nil else { return }
        let alert = NSAlert()
        alert.messageText = "Run Command"
        let field = NSTextField(string: "")
        field.placeholderString = "Windows executable path or command"
        field.frame = NSRect(x: 0, y: 0, width: 350, height: 26)
        alert.accessoryView = field
        alert.addButton(withTitle: "Run")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty { command(field.stringValue) }
    }
    func deleteBottle() {
        guard let bottle = selected else { return }
        let alert = NSAlert()
        alert.messageText = "Move \(bottle.name) to Trash?"
        alert.informativeText = "The bottle and installed Windows programs will move to the Mac Trash."
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            do { try engine.delete(bottle); selected = nil; notice = "Bottle moved to Trash." }
            catch { notice = error.localizedDescription }
            render()
        }
    }
    func checkUpdates() async {
        guard let url = URL(string: "https://api.github.com/repos/Sidhved-Pillai/Gamebox/releases/latest") else { return }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            let release = try JSONDecoder().decode(Release.self, from: data)
            let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
            let version = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            if version.compare(current, options: .numeric) == .orderedDescending {
                updateVersion = version
                updateURL = release.assets.first(where: { $0.name == "Gamebox.zip" })?.browser_download_url ?? release.html_url
                render()
            }
        } catch { /* A missing release or offline connection should not interrupt bottle work. */ }
    }
    struct Release: Decodable {
        let tag_name: String
        let html_url: URL
        let assets: [Asset]
        struct Asset: Decodable { let name: String; let browser_download_url: URL }
    }
}

extension Result where Success == String, Failure == Error {
    func getOrMessage() -> String {
        switch self { case .success(let value): return value.isEmpty ? "Done." : value
        case .failure(let error): return error.localizedDescription }
    }
}

@main struct Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = GameboxApp()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
