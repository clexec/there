import SwiftUI
import Combine

// MARK: - View Extensions
extension View {

    func glassCard(cornerRadius: CGFloat = UIConstants.Radius.lg) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(ColorPalette.glassFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(ColorPalette.glassBorder, lineWidth: 0.5)
                    }
            }
    }

    func glassBackground(cornerRadius: CGFloat = UIConstants.Radius.lg) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(ColorPalette.glassBorder, lineWidth: 0.5)
                    }
            }
    }

    func liquidGlassButton(cornerRadius: CGFloat = UIConstants.Radius.pill) -> some View {
        self
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .strokeBorder(ColorPalette.glassBorder, lineWidth: 0.5)
                    }
                    .shadow(color: ColorPalette.glassShadow, radius: 8, x: 0, y: 4)
            }
    }

    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .font(.system(size: UIConstants.FontSize.callout, weight: .bold))
            .foregroundStyle(isEnabled ? ColorPalette.backgroundBlack : ColorPalette.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                Capsule()
                    .fill(isEnabled ? ColorPalette.primaryGreen : ColorPalette.surface3)
            }
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: UIConstants.FontSize.callout, weight: .semibold))
            .foregroundStyle(ColorPalette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                Capsule()
                    .strokeBorder(ColorPalette.textSecondary, lineWidth: 1.5)
            }
    }

    func cardShadow() -> some View {
        self.shadow(color: ColorPalette.glassShadow, radius: UIConstants.UI.shadowRadius, x: 0, y: 6)
    }

    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        })
    }

    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }

    func scaleOnPress(scale: CGFloat = 0.95) -> some View {
        self.modifier(ScaleOnPressModifier(scale: scale))
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        self.modifier(OnFirstAppearModifier(action: action))
    }

    func navigationBarGlass() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    func gradientOverlay(colors: [Color], startPoint: UnitPoint = .top, endPoint: UnitPoint = .bottom) -> some View {
        self.overlay {
            LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
                .allowsHitTesting(false)
        }
    }

    func greenGlowEffect(radius: CGFloat = 12) -> some View {
        self
            .shadow(color: ColorPalette.primaryGreen.opacity(0.4), radius: radius, x: 0, y: 0)
            .shadow(color: ColorPalette.primaryGreen.opacity(0.2), radius: radius * 2, x: 0, y: 0)
    }

    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(GeometryReader { geo in
            Color.clear.preference(key: SizePreferenceKey.self, value: geo.size)
        })
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

// MARK: - ShimmerModifier
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay {
                    GeometryReader { geo in
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.3), location: 0.4),
                                .init(color: .clear, location: 0.8)
                            ],
                            startPoint: UnitPoint(x: phase, y: 0),
                            endPoint: UnitPoint(x: phase + 1, y: 0)
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: geo.size.width * phase)
                    }
                    .clipped()
                    .allowsHitTesting(false)
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - ScaleOnPressModifier
struct ScaleOnPressModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1)
            .animation(UIConstants.Animation.interactiveSpring, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - OnFirstAppearModifier
struct OnFirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

// MARK: - RoundedCorner
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - SizePreferenceKey
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
