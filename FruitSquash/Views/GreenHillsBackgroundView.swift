import SwiftUI

public struct GreenHillsBackgroundView: View {
    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack {
                // Sky Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.32, green: 0.68, blue: 0.96),
                        Color(red: 0.55, green: 0.82, blue: 0.98),
                        Color(red: 0.78, green: 0.92, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Sun & Glow
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.92, blue: 0.45).opacity(0.35))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.96, blue: 0.65),
                                    Color(red: 1.0, green: 0.82, blue: 0.25)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 36
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.yellow.opacity(0.5), radius: 15)
                }
                .position(x: w * 0.82, y: h * 0.15)

                // Drifting Clouds
                CloudShape(scale: 1.1)
                    .position(x: w * 0.22, y: h * 0.18)
                    .opacity(0.92)

                CloudShape(scale: 0.75)
                    .position(x: w * 0.52, y: h * 0.12)
                    .opacity(0.85)

                CloudShape(scale: 0.95)
                    .position(x: w * 0.75, y: h * 0.24)
                    .opacity(0.88)

                // Distant Hills (Layer 1)
                DistantHillsShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.48, green: 0.80, blue: 0.52),
                                Color(red: 0.35, green: 0.70, blue: 0.40)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: h * 0.55)
                    .position(x: w * 0.5, y: h * 0.75)

                // Midground Rolling Hills (Layer 2)
                MidgroundHillsShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.32, green: 0.68, blue: 0.35),
                                Color(red: 0.22, green: 0.56, blue: 0.26)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: h * 0.48)
                    .position(x: w * 0.5, y: h * 0.80)

                // Foreground Lush Hill (Layer 3)
                ForegroundHillsShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.60, blue: 0.28),
                                Color(red: 0.16, green: 0.48, blue: 0.20)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: h * 0.40)
                    .position(x: w * 0.5, y: h * 0.85)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Procedural Cloud Shape

private struct CloudShape: View {
    var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 44 * scale, height: 44 * scale)
                .offset(x: -20 * scale, y: 0)

            Circle()
                .fill(Color.white)
                .frame(width: 58 * scale, height: 58 * scale)
                .offset(x: 0, y: -10 * scale)

            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 40 * scale, height: 40 * scale)
                .offset(x: 24 * scale, y: 2 * scale)

            Capsule()
                .fill(Color.white)
                .frame(width: 85 * scale, height: 32 * scale)
                .offset(x: 2 * scale, y: 8 * scale)
        }
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
    }
}

// MARK: - Hill Bezier Shapes

private struct DistantHillsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.55))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.55, y: rect.height * 0.35),
            control1: CGPoint(x: rect.width * 0.25, y: rect.height * 0.20),
            control2: CGPoint(x: rect.width * 0.40, y: rect.height * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.40),
            control1: CGPoint(x: rect.width * 0.75, y: rect.height * 0.25),
            control2: CGPoint(x: rect.width * 0.88, y: rect.height * 0.45)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct MidgroundHillsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.30))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.60, y: rect.height * 0.45),
            control1: CGPoint(x: rect.width * 0.20, y: rect.height * 0.55),
            control2: CGPoint(x: rect.width * 0.42, y: rect.height * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.35),
            control1: CGPoint(x: rect.width * 0.78, y: rect.height * 0.60),
            control2: CGPoint(x: rect.width * 0.90, y: rect.height * 0.20)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct ForegroundHillsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.50))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.50, y: rect.height * 0.25),
            control1: CGPoint(x: rect.width * 0.18, y: rect.height * 0.20),
            control2: CGPoint(x: rect.width * 0.35, y: rect.height * 0.30)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.45),
            control1: CGPoint(x: rect.width * 0.70, y: rect.height * 0.20),
            control2: CGPoint(x: rect.width * 0.85, y: rect.height * 0.60)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
