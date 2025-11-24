import SwiftUI

struct ToastView: View {
    let message: String
    let duration: Double = 3.0
    @Binding var isShowing: Bool
    @State private var progress: Double = 1.0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)

                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 3)

                    // Progress indicator
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 3)
                        .animation(.linear(duration: duration), value: progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 20)
        .onAppear {
            // Start the progress animation
            withAnimation(.linear(duration: duration)) {
                progress = 0.0
            }

            // Auto-dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.spring()) {
                    isShowing = false
                }
            }
        }
    }
}

// Toast modifier for easy use
struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let message = message {
                VStack {
                    Spacer()

                    ToastView(message: message, isShowing: Binding(
                        get: { self.message != nil },
                        set: { if !$0 { self.message = nil } }
                    ))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
                }
                .animation(.spring(), value: message)
            }
        }
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
