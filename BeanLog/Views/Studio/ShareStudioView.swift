import SwiftUI
import SwiftData

struct ShareStudioView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \CoffeeEntry.date, order: .reverse) private var entries: [CoffeeEntry]

    @State private var showEmojiSheet = false
    @State private var shareItem: ShareItem?
    @State private var toast: String?
    @State private var lastRemoved: (item: StickerItem, index: Int)?
    @State private var errorMessage: String?
    @State private var isWorking = false

    private var studio: StudioModel { appState.studio }

    private var selected: CoffeeEntry? {
        entries.first(where: { $0.id == appState.studioEntryID }) ?? entries.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let entry = selected {
                    content(entry)
                } else {
                    emptyState
                }
            }
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PaperBackground())
        .overlay(alignment: .top) { toastView }
        .sheet(isPresented: $showEmojiSheet) {
            EmojiPickerSheet { text in addSticker(.emoji(text)) }
                .presentationDetents([.height(300)])
        }
        .sheet(item: $shareItem) { item in
            ActivityView(items: [item.url]).ignoresSafeArea()
        }
        .alert("Couldn't export", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Share Studio").font(BLFont.display(30)).foregroundStyle(BL.espresso)
            Text("Live preview · exports a crisp 3× PNG").font(BLFont.ui(13)).foregroundStyle(BL.muted)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image("sticker_cup").resizable().scaledToFit().frame(width: 110)
            Text("Log a coffee first, then design its card here.")
                .font(BLFont.hand(24)).foregroundStyle(BL.ink2).multilineTextAlignment(.center)
            Button("Log a coffee") { appState.logSheet = .new }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    @ViewBuilder private func content(_ entry: CoffeeEntry) -> some View {
        @Bindable var studio = appState.studio
        // Coffee picker
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(entries) { e in
                    ChipButton(title: e.cafeName.isEmpty ? "Untitled" : e.cafeName, isOn: e.id == entry.id) {
                        appState.studioEntryID = e.id
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)

        Picker("Ratio", selection: $studio.ratio) {
            ForEach(CardRatio.allCases) { r in Text(r.title).tag(r) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.top, 12)

        // Stage
        ShareCardCanvas(entry: entry, fields: studio.fields, ratio: studio.ratio, stickers: $studio.stickers, interactive: true) { item in
            removeSticker(item)
        }
        .shadow(color: .black.opacity(0.3), radius: 18, x: 0, y: 14)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(BL.stage)
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.25), value: studio.ratio)

        Text("Drag to move · pinch to scale · twist to rotate · tap to remove")
            .font(BLFont.ui(11.5))
            .foregroundStyle(BL.muted)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

        sectionTitle("Stickers", action: studio.stickers.isEmpty ? nil : ("Clear all", { studio.stickers.removeAll() }))
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StickerCatalog.tray, id: \.self) { kind in
                    Button { addSticker(kind) } label: {
                        StickerContentView(kind: kind, score: entry.score)
                            .scaleEffect(0.56)
                            .frame(width: 66, height: 66)
                            .background(BL.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(BL.line))
                    }
                    .buttonStyle(.plain)
                }
                Button { showEmojiSheet = true } label: {
                    Label("Add Emoji", systemImage: "face.smiling")
                        .font(BLFont.ui(13, .bold))
                        .foregroundStyle(BL.espresso)
                        .padding(.horizontal, 14)
                        .frame(height: 66)
                        .background(BL.chip, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(BL.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }

        let allOn = studio.fields.count == CardField.allCases.count
        sectionTitle("Show on card", action: (allOn ? "Hide all" : "Show all", {
            studio.fields = allOn ? [] : Set(CardField.allCases)
        }))
        FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(CardField.allCases) { field in
                fieldToggle(field, isOn: studio.fields.contains(field)) { studio.toggle(field) }
            }
        }
        .padding(.horizontal, 20)

        HStack(spacing: 10) {
            Button { export(entry, share: false) } label: {
                Label("Save to Photos", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .foregroundStyle(BL.espresso)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(BL.line))
            }
            Button { export(entry, share: true) } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .foregroundStyle(BL.onAccent)
                    .background(BL.terracotta, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .font(BLFont.ui(15, .bold))
        .buttonStyle(.plain)
        .disabled(isWorking)
        .padding(.horizontal, 20)
        .padding(.top, 22)

        Text("\(studio.ratio.pixelLabel) PNG")
            .font(BLFont.ui(11))
            .foregroundStyle(BL.muted)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    private func sectionTitle(_ title: String, action: (String, () -> Void)?) -> some View {
        HStack {
            SectionLabel(text: title)
            Spacer()
            if let action {
                Button(action.0.uppercased(), action: action.1)
                    .font(BLFont.ui(11, .bold))
                    .tint(BL.terracotta)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func fieldToggle(_ field: CardField, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                Text(field.title).font(BLFont.ui(12.5, .semibold))
            }
            .padding(.leading, 9)
            .padding(.trailing, 11)
            .padding(.vertical, 6)
            .foregroundStyle(isOn ? BL.onAccent : BL.muted)
            .background(isOn ? BL.terracotta : BL.chip, in: Capsule())
            .overlay(Capsule().stroke(isOn ? BL.terracotta : BL.line))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            HStack(spacing: 12) {
                Text(toast).font(BLFont.ui(13, .semibold))
                if lastRemoved != nil {
                    Button("Undo") { undoRemove() }
                        .font(BLFont.ui(13, .bold))
                        .foregroundStyle(BL.ochre)
                }
            }
            .foregroundStyle(BL.cream)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(BL.espresso, in: Capsule())
            .shadow(radius: 8, y: 4)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Actions

    private func addSticker(_ kind: StickerKind) {
        let item = StickerItem(kind: kind,
                               x: CGFloat.random(in: 0.35...0.65),
                               y: CGFloat.random(in: 0.3...0.6),
                               scale: 1,
                               rotation: Double.random(in: -12...12))
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            studio.stickers.append(item)
        }
    }

    private func removeSticker(_ item: StickerItem) {
        guard let index = studio.stickers.firstIndex(where: { $0.id == item.id }) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        _ = withAnimation(.easeOut(duration: 0.15)) {
            studio.stickers.remove(at: index)
        }
        lastRemoved = (item, index)
        showToast("Sticker removed")
    }

    private func undoRemove() {
        guard let removed = lastRemoved else { return }
        studio.stickers.insert(removed.item, at: min(removed.index, studio.stickers.count))
        lastRemoved = nil
        withAnimation { toast = nil }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        let current = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            if toast == current {
                withAnimation { toast = nil }
                lastRemoved = nil
            }
        }
    }

    private func export(_ entry: CoffeeEntry, share: Bool) {
        guard let image = CardExporter.render(entry: entry, fields: studio.fields, ratio: studio.ratio, stickers: studio.stickers) else {
            errorMessage = "Rendering the card failed."
            return
        }
        if share {
            do {
                shareItem = ShareItem(url: try CardExporter.pngFile(image, name: entry.cafeName))
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            isWorking = true
            Task {
                do {
                    try await CardExporter.saveToPhotos(image)
                    lastRemoved = nil
                    showToast("Saved \(studio.ratio.pixelLabel) PNG to Photos")
                } catch {
                    errorMessage = error.localizedDescription
                }
                isWorking = false
            }
        }
    }
}

/// Drop any emoji (or a few characters) from the keyboard onto the card.
struct EmojiPickerSheet: View {
    var onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Emoji").font(BLFont.display(22)).foregroundStyle(BL.espresso)
            HStack {
                TextField("Type or paste any emoji", text: $text)
                    .font(.system(size: 22))
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(drop)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(BL.chip, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(BL.line))
                Button("Drop", action: drop)
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 6) {
                ForEach(StickerCatalog.quickEmoji, id: \.self) { e in
                    Button { onPick(e); dismiss() } label: { Text(e).font(.system(size: 28)) }
                        .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(BL.sheet)
        .onAppear { focused = true }
    }

    private func drop() {
        let t = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(12))
        guard !t.isEmpty else { return }
        onPick(t)
        dismiss()
    }
}
