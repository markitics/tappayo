//  WelcomeView.swift
//  Tappayo

import SwiftUI
import AVKit

struct WelcomeView: View {
    @State private var currentPage: Int = 0
    // Pre-populate if user has set a custom business name (not the default "Tappayo")
    @State private var businessName: String = {
        let saved = UserDefaults.standard.businessName
        return saved == "Tappayo" ? "" : saved
    }()
    @State private var player: AVPlayer?
    @State private var cardToPhonePlayer: AVPlayer?
    @State private var cardToPhonePlayCount: Int = 0
    @State private var phoneToPhonePlayer: AVPlayer?
    @State private var phoneToPhonePlayCount: Int = 0
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Welcome
            welcomePage
                .tag(0)

            // Page 2: Easy to use (reassurance)
            easyToUsePage
                .tag(1)

            // Page 3: Business name + Get Started
            businessNamePage
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
        .onAppear {
            updatePageControlAppearance()
        }
        .onChange(of: colorScheme) { _, _ in
            updatePageControlAppearance()
        }
    }

    private func updatePageControlAppearance() {
        if colorScheme == .light {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.darkGray
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.lightGray.withAlphaComponent(0.4)
        } else {
            // Reset to system defaults for dark mode (nil restores the default white/gray contrast)
            UIPageControl.appearance().currentPageIndicatorTintColor = nil
            UIPageControl.appearance().pageIndicatorTintColor = nil
        }
    }

    // MARK: - Shared gradient background
    // TODO: Extract these colors to a central AppColors file to avoid duplication

    @ViewBuilder
    private var gradientBackground: some View {
        if colorScheme == .light {
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.94, blue: 0.92),
                    Color(red: 0.96, green: 0.98, blue: 0.97)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            Color(.systemBackground)
        }
    }

    @ViewBuilder
    private var gradientOverlay: some View {
        if colorScheme == .light {
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.94, blue: 0.92),
                    Color(red: 0.96, green: 0.98, blue: 0.97)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.92)
        } else {
            Color.black.opacity(0.85)
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        ZStack {
            gradientBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("Welcome to Tappayo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("The easiest way to accept payments.\nNo card reader needed.\n\nJust use your iPhone.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Apple's Tap to Pay education video
                if let player = player {
                    VideoPlayer(player: player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        currentPage = 1
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            setupWelcomeVideoPlayer()
        }
        .onChange(of: currentPage) { oldPage, newPage in
            // Pause when leaving page 0
            if oldPage == 0, let player = player {
                player.pause()
            }
            // Restart from beginning when returning to page 0
            if newPage == 0, let player = player {
                player.seek(to: .zero)
                player.play()
            }
        }
    }

    // MARK: - Page 2: Easy to use (reassurance)

    private var easyToUsePage: some View {
        ZStack {
            // Background video (card to phone)
            if let cardToPhonePlayer = cardToPhonePlayer {
                GeometryReader { geometry in
                    VideoPlayer(player: cardToPhonePlayer)
                        .aspectRatio(9/16, contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .disabled(true)
                }
                .ignoresSafeArea()
            }

            gradientOverlay.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("This app is easy to use")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                    .multilineTextAlignment(.center)

                Text("Most people are ready to charge a card in less than two minutes.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("This app is designed to be used by anyone. Anywhere. At any age.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button(action: {
                    withAnimation {
                        currentPage = 2
                    }
                }) {
                    Text("Let's go")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.bottom, 80)
            }
            .padding(.horizontal, 48)
        }
        .ignoresSafeArea()
        .onAppear {
            setupCardToPhoneVideoPlayer()
        }
        .onChange(of: currentPage) { oldPage, newPage in
            // Pause when leaving page 1
            if oldPage == 1, let cardToPhonePlayer = cardToPhonePlayer {
                cardToPhonePlayer.pause()
            }
            // Restart video when returning to page 1
            if newPage == 1, let cardToPhonePlayer = cardToPhonePlayer {
                cardToPhonePlayCount = 1
                cardToPhonePlayer.seek(to: .zero)
                cardToPhonePlayer.play()
            }
        }
    }

    // MARK: - Page 3: Business name + Get Started

    private var businessNamePage: some View {
        ZStack {
            // Background video (phone to phone)
            if let phoneToPhonePlayer = phoneToPhonePlayer {
                GeometryReader { geometry in
                    VideoPlayer(player: phoneToPhonePlayer)
                        .aspectRatio(9/16, contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .disabled(true)
                }
                .ignoresSafeArea()
            }

            gradientOverlay.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("What's your business called?")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                    .multilineTextAlignment(.center)

                // Styled text field
                TextField("e.g. Manny's Manicures", text: $businessName)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .light ? Color.white : Color(.systemGray5))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                    )
                    .foregroundColor(.primary)
                    .contentShape(Rectangle())

                Text("You can change this anytime in Settings.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button(action: {
                    let trimmedName = businessName.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty {
                        UserDefaults.standard.businessName = trimmedName
                    } else {
                        UserDefaults.standard.removeObject(forKey: "businessName")
                    }
                    UserDefaults.standard.hasCompletedInitialOnboarding = true
                    hasCompletedOnboarding = true
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.bottom, 80)
            }
            .padding(.horizontal, 48)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            setupPhoneToPhoneVideoPlayer()
        }
        .onChange(of: currentPage) { oldPage, newPage in
            // Pause when leaving page 2
            if oldPage == 2, let phoneToPhonePlayer = phoneToPhonePlayer {
                phoneToPhonePlayer.pause()
            }
            // Restart video when returning to page 2
            if newPage == 2, let phoneToPhonePlayer = phoneToPhonePlayer {
                phoneToPhonePlayCount = 1
                phoneToPhonePlayer.seek(to: .zero)
                phoneToPhonePlayer.play()
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

    // MARK: - Video Player Setup

    private func setupWelcomeVideoPlayer() {
        guard player == nil else { return }

        guard let url = Bundle.main.url(
            forResource: "How_to_Video_Short15_Social_Tap_to_Pay_on_iPhone",
            withExtension: "mp4"
        ) else { return }

        let newPlayer = AVPlayer(url: url)
        newPlayer.isMuted = true
        self.player = newPlayer
        newPlayer.play()

        // Auto-advance to page 2 when video ends (only if still on page 0)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { [self] _ in
            if currentPage == 0 {
                withAnimation {
                    currentPage = 1
                }
            }
        }
    }

    private func setupCardToPhoneVideoPlayer() {
        guard cardToPhonePlayer == nil else { return }

        guard let url = Bundle.main.url(
            forResource: "vertical_9x16_card_to_iphone",
            withExtension: "mp4"
        ) else { return }

        let newPlayer = AVPlayer(url: url)
        newPlayer.isMuted = true
        self.cardToPhonePlayer = newPlayer
        self.cardToPhonePlayCount = 1
        newPlayer.play()

        // Play twice then stop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { [self] _ in
            if cardToPhonePlayCount < 2 {
                cardToPhonePlayCount += 1
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
        }
    }

    private func setupPhoneToPhoneVideoPlayer() {
        guard phoneToPhonePlayer == nil else { return }

        guard let url = Bundle.main.url(
            forResource: "vertical_9x16_iphone_to_iphone",
            withExtension: "mp4"
        ) else { return }

        let newPlayer = AVPlayer(url: url)
        newPlayer.isMuted = true
        self.phoneToPhonePlayer = newPlayer
        self.phoneToPhonePlayCount = 1
        newPlayer.play()

        // Play twice then stop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { [self] _ in
            if phoneToPhonePlayCount < 2 {
                phoneToPhonePlayCount += 1
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
        }
    }
}

#Preview {
    WelcomeView(hasCompletedOnboarding: .constant(false))
}
