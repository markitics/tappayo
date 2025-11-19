// SettingsView old - when changes did take effect

//    SettingsView.swift

//    Either use @State private var...
//    or use AppStorage

//    To get around this error: "Cannot use mutating member on immutable value: 'self' is immutable"
//    , let's try using a @State property for the array and update the @AppStorage property whenever the array changes. This approach will help us handle the mutability correctly. Here’s how you can adjust your SettingsView.swift:
//    @State private var quickAmountsState: [Double] = []

import SwiftUI
import PhotosUI
import MCEmojiPicker

struct SettingsView: View {
    @State private var savedProducts: [Product] = UserDefaults.standard.savedProducts
    @State var myAccentColor: Color = UserDefaults.standard.myAccentColor
    @State private var darkModePreference: String = UserDefaults.standard.darkModePreference
    @State private var businessName: String = UserDefaults.standard.businessName
    @State private var taxRate: Double = UserDefaults.standard.taxRate
    @State private var dismissKeypadAfterAdd: String = UserDefaults.standard.dismissKeypadAfterAdd
    @State private var inputMode: String = UserDefaults.standard.inputMode
    @FocusState private var focusedField: UUID?

    // Icon picker state
    @State private var showingIconPicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var selectedImage: UIImage?
    @State private var editingProductId: UUID?

    // Emoji picker state
    @State private var showingEmojiPicker = false
    @State private var editingEmojiForProductId: UUID?
    
    var body: some View {
        Form {
            Section(header: Text("Business Name")) {
                TextField("Business name", text: $businessName)
            }

            Section(header: Text("Saved Products")) {
                ForEach(savedProducts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Product name", text: Binding(
                            get: { savedProducts[index].name },
                            set: { savedProducts[index].name = $0 }
                        ))
                        .focused($focusedField, equals: savedProducts[index].id)

                        // Icon picker - unified button for emoji/photo
                        Button(action: {
                            editingProductId = savedProducts[index].id
                            showingIconPicker = true
                        }) {
                            HStack(spacing: 12) {
                                // Show current icon or camera placeholder
                                if let photoFilename = savedProducts[index].photoFilename,
                                   let image = PhotoStorageHelper.loadPhoto(photoFilename) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else if let emoji = savedProducts[index].emoji, !emoji.isEmpty {
                                    Text(emoji)
                                        .font(.system(size: 50))
                                        .frame(width: 60, height: 60)
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    if savedProducts[index].photoFilename != nil || savedProducts[index].emoji != nil {
                                        Text("Tap to change icon")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Tap to add icon")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        CurrencyTextField(
                            value: Binding(
                                get: { savedProducts[index].priceInCents },
                                set: { savedProducts[index].priceInCents = $0 }
                            ),
                            placeholder: "Price",
                            font: .body
                        )
                        .multilineTextAlignment(.leading)

                        // Validation message
                        if savedProducts[index].emoji == nil && savedProducts[index].photoFilename == nil {
                            Text("⚠️ Add an emoji or photo")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                    .confirmationDialog("Choose Icon", isPresented: $showingIconPicker) {
                        Button("Choose emoji") {
                            if let productId = editingProductId {
                                editingEmojiForProductId = productId
                                showingEmojiPicker = true
                            }
                        }
                        Button("Take Photo") {
                            showingCamera = true
                        }
                        Button("Choose from Library") {
                            showingPhotoLibrary = true
                        }

                        // Show remove option only if product has an icon
                        if let productId = editingProductId,
                           let idx = savedProducts.firstIndex(where: { $0.id == productId }),
                           (savedProducts[idx].photoFilename != nil || savedProducts[idx].emoji != nil) {
                            Button("Remove Icon", role: .destructive) {
                                // Delete photo file if exists
                                if let filename = savedProducts[idx].photoFilename {
                                    PhotoStorageHelper.deletePhoto(filename)
                                }
                                // Clear both emoji and photo
                                savedProducts[idx].photoFilename = nil
                                savedProducts[idx].emoji = nil
                            }
                        }

                        Button("Cancel", role: .cancel) {}
                    }
                    .emojiPicker(
                        isPresented: $showingEmojiPicker,
                        selectedEmoji: Binding(
                            get: {
                                if let productId = editingEmojiForProductId,
                                   let idx = savedProducts.firstIndex(where: { $0.id == productId }) {
                                    return savedProducts[idx].emoji ?? ""
                                }
                                return ""
                            },
                            set: { newEmoji in
                                if let productId = editingEmojiForProductId,
                                   let idx = savedProducts.firstIndex(where: { $0.id == productId }) {
                                    savedProducts[idx].emoji = newEmoji.isEmpty ? nil : newEmoji
                                }
                            }
                        )
                    )
                    .sheet(isPresented: $showingCamera) {
                        ImagePicker(image: $selectedImage, sourceType: .camera)
                    }
                    .sheet(isPresented: $showingPhotoLibrary) {
                        ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                    }
                    .onChange(of: selectedImage) { newImage in
                        if let image = newImage,
                           let productId = editingProductId,
                           let idx = savedProducts.firstIndex(where: { $0.id == productId }) {
                            if let filename = PhotoStorageHelper.savePhoto(image) {
                                // Delete old photo if exists
                                if let oldFilename = savedProducts[idx].photoFilename {
                                    PhotoStorageHelper.deletePhoto(oldFilename)
                                }
                                savedProducts[idx].photoFilename = filename
                            }
                            selectedImage = nil
                            editingProductId = nil
                        }
                    }
                }
                .onDelete { indexSet in
                    savedProducts.remove(atOffsets: indexSet)
                }

                Button(action: {
                    let newProduct = Product(name: "", priceInCents: 0)
                    savedProducts.append(newProduct)
                    focusedField = newProduct.id
                }) {
                    Text("Add Product")
                }
                .foregroundColor(myAccentColor)

                Text(savedProducts.isEmpty ? "Add products with names and prices for quick checkout" : "Swipe left to delete any product")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Section(header: Text("Pick Accent Color")) {
                ColorPicker("Pick a color", selection: $myAccentColor)
                if myAccentColor != Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0) {
                    Button("Restore Default Color") {
                        myAccentColor = Color(red: 0.0, green: 214.0 / 255.0, blue: 111.0 / 255.0)
                    }.foregroundColor(myAccentColor)
                }
            }

            Section(header: Text("Dark Mode")) {
                Picker(darkModePreferenceHeader, selection: $darkModePreference) {
                    Text("iPhone default").tag("system")
                    Text("Dark").tag("on")
                    Text("Light").tag("off")
                }
            }

            Section(header: Text("Display Options")) {
                Picker(inputModeHeader, selection: $inputMode) {
                    Text("I'll type cents, like $5.99 or $5.00").tag("cents")
                    Text("Only whole numbers, like $5, $50").tag("dollars")
                }

                Picker(keypadBehaviorHeader, selection: $dismissKeypadAfterAdd) {
                    Text("Dismiss keypad after adding a manual price").tag("dismiss")
                    Text("Quickly adding multiple custom items").tag("stay")
                }
            }

            Section(header: Text("Tax Rate")) {
                HStack {
                    TextField("Tax %", value: $taxRate, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                    Text("%")
                        .foregroundColor(.secondary)
                }
                Text("Enter tax rate as percentage (0 = no tax, max 2 decimals)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Section {
                NavigationLink(destination: AboutView()) {
                    Text("About")
                }
            }
        }
        .navigationTitle("Tappayo Settings")
        .onDisappear {
            UserDefaults.standard.savedProducts = savedProducts
            UserDefaults.standard.myAccentColor = myAccentColor
            UserDefaults.standard.darkModePreference = darkModePreference
            UserDefaults.standard.businessName = businessName
            UserDefaults.standard.taxRate = taxRate
            UserDefaults.standard.dismissKeypadAfterAdd = dismissKeypadAfterAdd
            UserDefaults.standard.inputMode = inputMode
        }
        .onAppear {
            savedProducts = UserDefaults.standard.savedProducts
            myAccentColor = UserDefaults.standard.myAccentColor
            darkModePreference = UserDefaults.standard.darkModePreference
            businessName = UserDefaults.standard.businessName
            taxRate = UserDefaults.standard.taxRate
            dismissKeypadAfterAdd = UserDefaults.standard.dismissKeypadAfterAdd
            inputMode = UserDefaults.standard.inputMode
            applyDarkModePreference()

            // Update navigation bar appearance
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(myAccentColor)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(myAccentColor)]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(myAccentColor)]

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().tintColor = UIColor(myAccentColor)
        }
        .onChange(of: savedProducts) { newValue in
            UserDefaults.standard.savedProducts = newValue
        }
        .onChange(of: darkModePreference) { _ in
            // Ensure accent dark mode preference, set in the Settings page, updates immediately
            UserDefaults.standard.darkModePreference = darkModePreference
            applyDarkModePreference()
        }
        .onChange(of: myAccentColor) { newValue in
            // Ensure accent color updates immediately
            UserDefaults.standard.myAccentColor = newValue
        }
        .onChange(of: businessName) { newValue in
            UserDefaults.standard.businessName = newValue
        }
        .onChange(of: taxRate) { newValue in
            UserDefaults.standard.taxRate = newValue
        }
        .onChange(of: dismissKeypadAfterAdd) { newValue in
            UserDefaults.standard.dismissKeypadAfterAdd = newValue
        }
        .onChange(of: inputMode) { newValue in
            UserDefaults.standard.inputMode = newValue
        }
    }
    
    //    private
    func applyDarkModePreference() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let window = windowScene.windows.first else { return }
        switch darkModePreference {
        case "on":
            window.overrideUserInterfaceStyle = .dark
        case "off":
            window.overrideUserInterfaceStyle = .light
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    var darkModePreferenceHeader: String {
        switch darkModePreference {
        case "on":
            return "Dark mode on"
        case "off":
            return "Always off"
        default:
            return "System setting"
        }
    }

    var inputModeHeader: String {
        switch inputMode {
        case "dollars":
            return "Only whole numbers"
        default:
            return "Input mode"
        }
    }

    var keypadBehaviorHeader: String {
        switch dismissKeypadAfterAdd {
        case "stay":
            return "Stay in keypad mode"
        default:
            return "Dismiss keypad after adding to cart"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

