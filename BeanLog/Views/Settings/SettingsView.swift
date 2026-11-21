import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: \CoffeeEntry.date, order: .reverse) private var entries: [CoffeeEntry]
    @AppStorage("defaultRatio") private var defaultRatio: String = CardRatio.story.rawValue

    @State private var exportDoc: BackupDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var importData: Data?
    @State private var message: String?
    @State private var confirmWipe = false

    private var backupName: String {
        "BeanLog-Backup-\(Date().formatted(.iso8601.year().month().day()))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings").font(BLFont.display(32)).foregroundStyle(BL.espresso).padding(.horizontal, 4)
                Text("Everything lives on this iPhone.").font(BLFont.hand(21)).foregroundStyle(BL.terracotta).padding(.horizontal, 4)

                Group {
                SectionLabel(text: "Backup").padding(.top, 18)
                BLGroup {
                    row("Export backup", detail: "JSON + photo archive (.zip) → Files, AirDrop…", symbol: "square.and.arrow.up", action: exportBackup)
                    Divider().overlay(BL.line)
                    row("Import backup", detail: "Merge with or replace your journal", symbol: "square.and.arrow.down") { showImporter = true }
                }

                SectionLabel(text: "Share defaults").padding(.top, 18)
                BLGroup {
                    HStack {
                        Text("Default card ratio").font(BLFont.ui(15)).foregroundStyle(BL.espresso)
                        Spacer()
                        Picker("Default card ratio", selection: $defaultRatio) {
                            ForEach(CardRatio.allCases) { r in Text(r.title).tag(r.rawValue) }
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                }

                }
                Group {
                SectionLabel(text: "Privacy").padding(.top, 18)
                BLGroup {
                    info("Storage", detail: "SwiftData on-device · no account · no iCloud", value: "\(entries.count) cups")
                    Divider().overlay(BL.line)
                    info("Location", detail: "Only used when you tap Locate", value: "When in use")
                }

                SectionLabel(text: "Danger zone").padding(.top, 18)
                BLGroup {
                    Button(role: .destructive) { confirmWipe = true } label: {
                        Label("Delete all coffees", systemImage: "trash")
                            .font(BLFont.ui(15))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    }
                    .disabled(entries.isEmpty)
                }

                }
                Text("BeanLog \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") · fonts: Fraunces & Caveat (SIL OFL)")
                    .font(BLFont.ui(11))
                    .foregroundStyle(BL.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            }
            .padding(16)
        }
        .background(PaperBackground())
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: defaultRatio) { _, newValue in
            if let r = CardRatio(rawValue: newValue) { appState.studio.ratio = r }
        }
        .fileExporter(isPresented: $showExporter, document: exportDoc, contentType: .zip, defaultFilename: backupName) { result in
            switch result {
            case .success: message = "Backup exported (\(entries.count) coffees)."
            case .failure(let error): message = error.localizedDescription
            }
            exportDoc = nil
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.zip]) { result in
            switch result {
            case .success(let url):
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                do { importData = try Data(contentsOf: url) } catch { message = error.localizedDescription }
            case .failure(let error):
                message = error.localizedDescription
            }
        }
        .confirmationDialog("Import backup", isPresented: Binding(get: { importData != nil }, set: { if !$0 { importData = nil } }), titleVisibility: .visible) {
            Button("Merge (keep existing)") { runImport(.merge) }
            Button("Replace everything", role: .destructive) { runImport(.replace) }
            Button("Cancel", role: .cancel) { importData = nil }
        } message: {
            Text("Merge adds coffees that aren't already in your journal. Replace deletes your current journal first.")
        }
        .confirmationDialog("Delete every coffee?", isPresented: $confirmWipe, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) {
                try? context.delete(model: CoffeeEntry.self)
                try? context.save()
            }
        } message: {
            Text("This can't be undone. Export a backup first if you might want them back.")
        }
        .alert("BeanLog", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func row(_ title: String, detail: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 17)).foregroundStyle(BL.terracotta).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(BLFont.ui(15)).foregroundStyle(BL.espresso)
                    Text(detail).font(BLFont.ui(12)).foregroundStyle(BL.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(BL.muted)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func info(_ title: String, detail: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(BLFont.ui(15)).foregroundStyle(BL.espresso)
                Text(detail).font(BLFont.ui(12)).foregroundStyle(BL.muted)
            }
            Spacer()
            Text(value).font(BLFont.ui(14)).foregroundStyle(BL.muted)
        }
        .padding(.vertical, 12)
    }

    private func exportBackup() {
        do {
            exportDoc = BackupDocument(data: try BackupService.makeArchive(entries: entries))
            showExporter = true
        } catch {
            message = error.localizedDescription
        }
    }

    private func runImport(_ mode: BackupService.ImportMode) {
        guard let data = importData else { return }
        importData = nil
        do {
            let count = try BackupService.restore(from: data, into: context, mode: mode)
            message = "Imported \(count) coffee\(count == 1 ? "" : "s")."
        } catch {
            message = error.localizedDescription
        }
    }
}
