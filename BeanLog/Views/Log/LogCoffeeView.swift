import SwiftUI
import SwiftData
import PhotosUI

/// Editable copy of an entry so Cancel discards changes.
struct CoffeeDraft {
    var cafeName = ""
    var suburb = ""
    var drink: DrinkType = .flatWhite
    var customDrink = ""
    var isIced = false
    var milk: MilkType = .fullCream
    var priceText = ""
    var score: Double = 7.5
    var roast = ""
    var tags: [String] = []
    var sweetness: Double = 3
    var acidity: Double = 3
    var thoughts = ""
    var date = Date()
    var photoData: Data?
    var latitude: Double?
    var longitude: Double?

    init() {}

    init(entry e: CoffeeEntry) {
        cafeName = e.cafeName
        suburb = e.suburb
        drink = e.drinkType
        customDrink = e.customDrinkName
        isIced = e.isIced
        milk = e.milkType
        priceText = e.price.map { String(format: "%.2f", $0) } ?? ""
        score = e.score
        roast = e.roastOrigin
        tags = e.tags
        sweetness = Double(e.sweetness)
        acidity = Double(e.acidity)
        thoughts = e.thoughts
        date = e.date
        photoData = e.photoData
        latitude = e.latitude
        longitude = e.longitude
    }

    var price: Double? {
        let cleaned = priceText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    func apply(to e: CoffeeEntry) {
        e.cafeName = cafeName.trimmingCharacters(in: .whitespacesAndNewlines)
        e.suburb = suburb.trimmingCharacters(in: .whitespacesAndNewlines)
        e.drinkType = drink
        e.customDrinkName = customDrink
        e.isIced = isIced
        e.milkType = milk
        e.price = price
        e.score = (score * 10).rounded() / 10
        e.roastOrigin = roast.trimmingCharacters(in: .whitespacesAndNewlines)
        e.tags = tags
        e.sweetness = Int(sweetness)
        e.acidity = Int(acidity)
        e.thoughts = thoughts.trimmingCharacters(in: .whitespacesAndNewlines)
        e.date = date
        e.photoData = photoData
        e.latitude = latitude
        e.longitude = longitude
    }
}

struct LogCoffeeView: View {
    let entry: CoffeeEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    @State private var draft: CoffeeDraft
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var newTag = ""
    @State private var cafeError = false
    @State private var isLocating = false
    @State private var alertMessage: String?
    @State private var confirmDelete = false

    init(entry: CoffeeEntry?) {
        self.entry = entry
        _draft = State(initialValue: entry.map { CoffeeDraft(entry: $0) } ?? CoffeeDraft())
    }

    /// Preview entry so the generated cup art reacts to drink / iced choices.
    private var previewSeed: Int { entry?.seed ?? 4242 }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        cupSection.id("top")
                        scoreSection
                        detailsSection
                        footer
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: cafeError) { _, newValue in
                    if newValue { withAnimation { proxy.scrollTo("top", anchor: .top) } }
                }
            }
            .background(PaperBackground(color: BL.sheet))
            .navigationTitle(entry == nil ? "Log a Coffee" : "Edit Coffee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).fontWeight(.bold)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    if let image, let data = ImageUtils.storageJPEG(from: image) { draft.photoData = data }
                }
                .ignoresSafeArea()
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let jpeg = ImageUtils.storageJPEG(from: data) {
                        draft.photoData = jpeg
                    }
                    pickerItem = nil
                }
            }
            .alert("Heads up", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            .confirmationDialog("Delete this coffee?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let entry {
                        context.delete(entry)
                        try? context.save()
                    }
                    dismiss()
                }
            }
        }
        .tint(BL.terracotta)
    }

    // MARK: Sections

    private var cupSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "The cup").padding(.top, 14)
            BLGroup {
                field("Cafe name", trailing: "required", error: cafeError) {
                    TextField("e.g. Little Fig Espresso", text: $draft.cafeName)
                        .font(BLFont.ui(17))
                        .textInputAutocapitalization(.words)
                        .onChange(of: draft.cafeName) { _, _ in cafeError = false }
                        .modifier(ShakeEffect(shakes: cafeError ? 2 : 0))
                        .animation(.default, value: cafeError)
                }
                field("Drink") {
                    FlowLayout {
                        ForEach(DrinkType.allCases) { d in
                            ChipButton(title: d.rawValue, isOn: draft.drink == d) { draft.drink = d }
                        }
                    }
                    if draft.drink == .custom {
                        TextField("Name your drink (e.g. Magic, Piccolo)", text: $draft.customDrink)
                            .font(BLFont.ui(16))
                            .padding(.top, 8)
                    }
                }
                field("Temperature") {
                    Picker("Temperature", selection: $draft.isIced) {
                        Text("♨︎ Hot").tag(false)
                        Text("❄︎ Iced").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                field("Milk") {
                    FlowLayout {
                        ForEach(MilkType.allCases) { m in
                            ChipButton(title: m.rawValue, isOn: draft.milk == m) { draft.milk = m }
                        }
                    }
                }
                field("Price", divider: false) {
                    HStack(spacing: 4) {
                        Text("$").font(BLFont.ui(17)).foregroundStyle(BL.muted)
                        TextField("0.00", text: $draft.priceText)
                            .keyboardType(.decimalPad)
                            .font(BLFont.ui(17))
                    }
                }
            }
        }
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "Score").padding(.top, 14)
            BLGroup {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(Fmt.score(draft.score))
                            .font(BLFont.serif(54))
                            .monospacedDigit()
                            .foregroundStyle(BL.espresso)
                            .contentTransition(.numericText())
                        Text("/ 10").font(BLFont.ui(16)).foregroundStyle(BL.muted)
                        Spacer()
                        stepButton("minus", delta: -0.1)
                        stepButton("plus", delta: 0.1)
                    }
                    Slider(value: $draft.score, in: 0...10, step: 0.1)
                    HStack {
                        Text("0.0 undrinkable"); Spacer(); Text("5.0 fine"); Spacer(); Text("10.0 perfect")
                    }
                    .font(BLFont.ui(11))
                    .foregroundStyle(BL.muted)
                }
                .padding(.vertical, 10)
            }
        }
    }

    private func stepButton(_ symbol: String, delta: Double) -> some View {
        Button {
            withAnimation(.snappy) {
                draft.score = min(10, max(0, ((draft.score + delta) * 10).rounded() / 10))
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(BL.espresso)
                .frame(width: 42, height: 42)
                .background(BL.chip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(BL.line))
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "Details").padding(.top, 14)
            BLGroup {
                field("Photo of the cup") { photoRow }
                field("Date & time") {
                    DatePicker("When", selection: $draft.date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                field("Suburb / location") {
                    HStack(spacing: 8) {
                        TextField("Type a suburb…", text: $draft.suburb)
                            .font(BLFont.ui(16))
                            .textInputAutocapitalization(.words)
                        Button(action: locate) {
                            HStack(spacing: 4) {
                                if isLocating { ProgressView().controlSize(.mini) } else { Image(systemName: "location.fill") }
                                Text(isLocating ? "Locating" : "Locate")
                            }
                            .font(BLFont.ui(12, .semibold))
                            .foregroundStyle(BL.terracotta)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(BL.chip, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(BL.line))
                        }
                        .buttonStyle(.plain)
                        .disabled(isLocating)
                    }
                }
                field("Roast / origin") {
                    TextField("e.g. Ethiopia Guji · Light", text: $draft.roast).font(BLFont.ui(16))
                }
                field("Tasting notes") { tagsEditor }
                field("Sweetness", trailing: "\(Int(draft.sweetness)) / 5") {
                    Slider(value: $draft.sweetness, in: 1...5, step: 1)
                    ends("dry", "syrupy")
                }
                field("Acidity", trailing: "\(Int(draft.acidity)) / 5") {
                    Slider(value: $draft.acidity, in: 1...5, step: 1)
                    ends("mellow", "bright")
                }
                field("General thoughts", divider: false) {
                    TextField("How was it? The vibe, the barista, would you go back…", text: $draft.thoughts, axis: .vertical)
                        .font(BLFont.ui(16))
                        .lineLimit(3...8)
                }
            }
        }
    }

    private var photoRow: some View {
        HStack(spacing: 14) {
            Polaroid(width: 104, caption: "", rotation: -2, showTape: false) {
                if let data = draft.photoData, let img = ImageUtils.downsample(data: data, maxPixel: 400) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    CupPlaceholder(seed: previewSeed, iced: draft.isIced, kind: placeholderKind)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    photoButtonLabel("Choose from Library", symbol: "photo.on.rectangle")
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button { showCamera = true } label: { photoButtonLabel("Take Photo", symbol: "camera") }
                }
                if draft.photoData != nil {
                    Button { draft.photoData = nil } label: { photoButtonLabel("Remove photo", symbol: "trash") }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var placeholderKind: CupPlaceholder.Kind {
        if draft.drink == .matcha { return .matcha }
        if draft.drink == .longBlack || draft.drink == .batchBrew || draft.milk == .none { return .black }
        return .milk
    }

    private func photoButtonLabel(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(BLFont.ui(13))
            .foregroundStyle(BL.espresso)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(BL.chip, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(BL.line))
    }

    private var tagsEditor: some View {
        let all = TastingTags.defaults + draft.tags.filter { !TastingTags.defaults.contains($0) }
        return VStack(alignment: .leading, spacing: 8) {
            FlowLayout {
                ForEach(all, id: \.self) { tag in
                    ChipButton(title: tag, isOn: draft.tags.contains(tag)) { toggleTag(tag) }
                }
            }
            HStack(spacing: 6) {
                TextField("+ custom tag (e.g. Caramel)", text: $newTag)
                    .font(BLFont.ui(13))
                    .submitLabel(.done)
                    .onSubmit(addTag)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(Capsule().stroke(BL.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                Button("Add", action: addTag)
                    .font(BLFont.ui(13, .semibold))
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: save) {
                Text(entry == nil ? "Save to journal" : "Save changes")
                    .font(BLFont.ui(16, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(BL.onAccent)
                    .background(BL.terracotta, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            if let entry {
                Button {
                    save()
                    appState.openStudio(for: entry)
                } label: {
                    Label("Save & open in Share Studio", systemImage: "square.and.arrow.up")
                        .font(BLFont.ui(15, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(BL.espresso)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(BL.line))
                }
                .buttonStyle(.plain)
                Button("Delete entry", role: .destructive) { confirmDelete = true }
                    .font(BLFont.ui(14, .semibold))
                    .padding(.top, 4)
            }
        }
        .padding(.top, 18)
    }

    // MARK: Helpers

    @ViewBuilder
    private func field<Content: View>(_ label: String, trailing: String? = nil, error: Bool = false, divider: Bool = true,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                if let trailing { Text(trailing) }
            }
            .font(BLFont.ui(12))
            .foregroundStyle(error ? Color.red : BL.muted)
            content()
        }
        .padding(.vertical, 10)
        if divider { Divider().overlay(BL.line) }
    }

    private func ends(_ a: String, _ b: String) -> some View {
        HStack { Text(a); Spacer(); Text(b) }
            .font(BLFont.ui(11))
            .foregroundStyle(BL.muted)
    }

    private func toggleTag(_ tag: String) {
        if let i = draft.tags.firstIndex(of: tag) { draft.tags.remove(at: i) } else { draft.tags.append(tag) }
    }

    private func addTag() {
        let t = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let formatted = t.prefix(1).uppercased() + t.dropFirst()
        if !draft.tags.contains(formatted) { draft.tags.append(formatted) }
        newTag = ""
    }

    private func locate() {
        isLocating = true
        Task {
            do {
                let place = try await LocationService.shared.currentPlace()
                draft.suburb = place.name
                draft.latitude = place.coordinate.latitude
                draft.longitude = place.coordinate.longitude
            } catch {
                alertMessage = error.localizedDescription
            }
            isLocating = false
        }
    }

    private func save() {
        guard !draft.cafeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cafeError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        if let entry {
            draft.apply(to: entry)
        } else {
            let new = CoffeeEntry()
            draft.apply(to: new)
            context.insert(new)
        }
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

/// Horizontal shake for validation errors.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 2), y: 0))
    }
}

/// Camera capture via UIImagePickerController.
struct CameraPicker: UIViewControllerRepresentable {
    var onFinish: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.onFinish(info[.originalImage] as? UIImage)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onFinish(nil)
            parent.dismiss()
        }
    }
}
