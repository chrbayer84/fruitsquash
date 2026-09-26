import SpriteKit
import UIKit

public final class FruitNode: SKNode {
    public let fruitType: FruitType
    public let fruitId = UUID()
    public var isMerging: Bool = false
    public var timeAboveDangerLine: TimeInterval = 0

    private var spriteNode: SKSpriteNode?

    // Static texture cache for instant rendering performance
    private static var textureCache: [FruitType: SKTexture] = [:]

    public init(fruitType: FruitType) {
        self.fruitType = fruitType
        super.init()

        name = "Fruit_\(fruitType.displayName)"
        setupVisuals()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupVisuals() {
        let baseDiameter = fruitType.radius * 2
        // Picture size increased by 20% so fruits touch visually at collision boundaries without gaps
        let visualDiameter = baseDiameter * 1.20
        let texture = FruitNode.texture(for: fruitType, diameter: visualDiameter)

        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: visualDiameter, height: visualDiameter)
        sprite.zPosition = 10
        addChild(sprite)
        self.spriteNode = sprite
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: fruitType.radius)
        body.isDynamic = true
        body.categoryBitMask = CollisionCategory.fruit
        body.collisionBitMask = CollisionCategory.fruit | CollisionCategory.wall | CollisionCategory.floor
        body.contactTestBitMask = CollisionCategory.fruit | CollisionCategory.dangerLine
        body.density = 1.0
        body.friction = 0.35
        body.restitution = 0.12
        body.linearDamping = 0.15
        body.angularDamping = 0.25
        body.allowsRotation = true
        self.physicsBody = body
    }

    public func playSpawnAnimation() {
        setScale(0.01)
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.16)
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.08)
        let scaleNormal = SKAction.scale(to: 1.0, duration: 0.06)
        run(SKAction.sequence([scaleUp, scaleDown, scaleNormal]))
    }

    public func playMergeEffect(into targetPoint: CGPoint, completion: @escaping () -> Void) {
        isMerging = true
        physicsBody = nil // Disable collisions immediately

        let moveTo = SKAction.move(to: targetPoint, duration: 0.10)
        moveTo.timingMode = .easeIn
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.08)
        let fadeOut = SKAction.fadeOut(withDuration: 0.05)

        let group = SKAction.group([moveTo, scaleUp, fadeOut])
        run(SKAction.sequence([group, SKAction.removeFromParent()])) {
            completion()
        }
    }

    // MARK: - Texture Generation & Asset Fallback

    public static func texture(for fruitType: FruitType, diameter: CGFloat) -> SKTexture {
        if let cached = textureCache[fruitType] {
            return cached
        }

        // 1. Check for custom PNG image asset
        if let customImage = UIImage(named: fruitType.assetName) {
            let texture = SKTexture(image: customImage)
            textureCache[fruitType] = texture
            return texture
        }

        // 2. Procedural high-resolution standalone artwork (transparent background, zero margin)
        let scale = UIScreen.main.scale
        let size = CGSize(width: diameter * scale, height: diameter * scale)
        let renderer = UIGraphicsImageRenderer(size: size)

        let renderedImage = renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)

            switch fruitType {
            case .redCurrant:
                drawSingleRedCurrant(in: rect, context: cgContext)
            case .blueberry:
                drawSingleBlueberry(in: rect, context: cgContext)
            case .lemon:
                drawWholeLemon(in: rect, context: cgContext)
            default:
                drawEmojiArtwork(emoji: fruitType.emoji, in: rect, context: cgContext)
            }
        }

        let texture = SKTexture(image: renderedImage)
        textureCache[fruitType] = texture
        return texture
    }

    // MARK: - Dedicated Fruit Vector Renderers (Full-bleed, no colored coin background)

    /// Draws a single glossy red currant berry
    private static func drawSingleRedCurrant(in rect: CGRect, context: CGContext) {
        let berryRect = rect

        // Berry gradient body
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 1.0, green: 0.25, blue: 0.30, alpha: 1.0).cgColor,
            UIColor(red: 0.88, green: 0.08, blue: 0.14, alpha: 1.0).cgColor,
            UIColor(red: 0.52, green: 0.02, blue: 0.06, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.65, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context.saveGState()
            context.addEllipse(in: berryRect)
            context.clip()

            let center = CGPoint(x: berryRect.midX - berryRect.width * 0.16, y: berryRect.midY - berryRect.height * 0.16)
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: CGPoint(x: berryRect.midX, y: berryRect.midY),
                endRadius: berryRect.width * 0.55,
                options: [.drawsAfterEndLocation]
            )
            context.restoreGState()
        }

        // Top stem calyx dot
        context.setFillColor(UIColor(red: 0.35, green: 0.02, blue: 0.04, alpha: 1.0).cgColor)
        let calyxSize = berryRect.width * 0.13
        let calyxRect = CGRect(
            x: berryRect.midX - calyxSize / 2,
            y: berryRect.minY + calyxSize * 0.1,
            width: calyxSize,
            height: calyxSize * 0.75
        )
        context.fillEllipse(in: calyxRect)

        // Gloss highlight arc
        context.setFillColor(UIColor.white.withAlphaComponent(0.70).cgColor)
        let highlight = CGRect(
            x: berryRect.minX + berryRect.width * 0.16,
            y: berryRect.minY + berryRect.height * 0.14,
            width: berryRect.width * 0.30,
            height: berryRect.height * 0.20
        )
        context.fillEllipse(in: highlight)
    }

    /// Draws a single indigo blueberry with star calyx crown
    private static func drawSingleBlueberry(in rect: CGRect, context: CGContext) {
        let berryRect = rect

        // Blueberry gradient body
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 0.35, green: 0.52, blue: 0.98, alpha: 1.0).cgColor,
            UIColor(red: 0.18, green: 0.28, blue: 0.80, alpha: 1.0).cgColor,
            UIColor(red: 0.07, green: 0.10, blue: 0.42, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.60, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context.saveGState()
            context.addEllipse(in: berryRect)
            context.clip()

            let center = CGPoint(x: berryRect.midX - berryRect.width * 0.14, y: berryRect.midY - berryRect.height * 0.14)
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: CGPoint(x: berryRect.midX, y: berryRect.midY),
                endRadius: berryRect.width * 0.55,
                options: [.drawsAfterEndLocation]
            )
            context.restoreGState()
        }

        // Star calyx crown at top
        context.setFillColor(UIColor(red: 0.05, green: 0.08, blue: 0.28, alpha: 0.95).cgColor)
        let crownRadius = berryRect.width * 0.15
        let crownCenter = CGPoint(x: berryRect.midX, y: berryRect.minY + crownRadius * 1.1)

        let path = CGMutablePath()
        let points = 5
        for i in 0..<(points * 2) {
            let r = (i % 2 == 0) ? crownRadius : (crownRadius * 0.45)
            let angle = (CGFloat(i) * .pi / CGFloat(points)) - (.pi / 2)
            let pt = CGPoint(x: crownCenter.x + cos(angle) * r, y: crownCenter.y + sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        context.addPath(path)
        context.fillPath()

        // Dusty bloom soft highlight
        context.setFillColor(UIColor(red: 0.70, green: 0.82, blue: 1.0, alpha: 0.50).cgColor)
        let bloom = CGRect(
            x: berryRect.minX + berryRect.width * 0.16,
            y: berryRect.minY + berryRect.height * 0.20,
            width: berryRect.width * 0.34,
            height: berryRect.height * 0.22
        )
        context.fillEllipse(in: bloom)
    }

    /// Draws a whole sunny yellow lemon with tapered pointed ends
    private static func drawWholeLemon(in rect: CGRect, context: CGContext) {
        let lemonRect = rect

        // Lemon body shape path with tapered lemon tips
        let path = CGMutablePath()
        let tipW = lemonRect.width * 0.08
        let tipH = lemonRect.height * 0.08

        path.move(to: CGPoint(x: lemonRect.midX, y: lemonRect.minY))
        // Top right to right tip
        path.addQuadCurve(
            to: CGPoint(x: lemonRect.maxX, y: lemonRect.midY),
            control: CGPoint(x: lemonRect.maxX + tipW, y: lemonRect.minY + tipH)
        )
        // Right tip to bottom
        path.addQuadCurve(
            to: CGPoint(x: lemonRect.midX, y: lemonRect.maxY),
            control: CGPoint(x: lemonRect.maxX - tipW, y: lemonRect.maxY)
        )
        // Bottom to left tip
        path.addQuadCurve(
            to: CGPoint(x: lemonRect.minX, y: lemonRect.midY),
            control: CGPoint(x: lemonRect.minX - tipW, y: lemonRect.maxY - tipH)
        )
        // Left tip to top
        path.addQuadCurve(
            to: CGPoint(x: lemonRect.midX, y: lemonRect.minY),
            control: CGPoint(x: lemonRect.minX + tipW, y: lemonRect.minY)
        )
        path.closeSubpath()

        // Lemon radial gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 1.00, green: 0.94, blue: 0.35, alpha: 1.0).cgColor,
            UIColor(red: 1.00, green: 0.84, blue: 0.08, alpha: 1.0).cgColor,
            UIColor(red: 0.86, green: 0.65, blue: 0.04, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.65, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context.saveGState()
            context.addPath(path)
            context.clip()

            let center = CGPoint(x: lemonRect.midX - lemonRect.width * 0.15, y: lemonRect.midY - lemonRect.height * 0.15)
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: CGPoint(x: lemonRect.midX, y: lemonRect.midY),
                endRadius: lemonRect.width * 0.55,
                options: [.drawsAfterEndLocation]
            )
            context.restoreGState()
        }

        // Small stem calyx at top pole
        context.setFillColor(UIColor(red: 0.42, green: 0.55, blue: 0.15, alpha: 1.0).cgColor)
        let stemSize = lemonRect.width * 0.12
        let stemRect = CGRect(
            x: lemonRect.midX - stemSize / 2,
            y: lemonRect.minY,
            width: stemSize,
            height: stemSize * 0.55
        )
        context.fillEllipse(in: stemRect)

        // Gloss highlight
        context.setFillColor(UIColor.white.withAlphaComponent(0.55).cgColor)
        let gloss = CGRect(
            x: lemonRect.minX + lemonRect.width * 0.20,
            y: lemonRect.minY + lemonRect.height * 0.16,
            width: lemonRect.width * 0.34,
            height: lemonRect.height * 0.22
        )
        context.fillEllipse(in: gloss)
    }

    /// Draws full-bleed emoji graphic scaled to fill the entire square boundary
    private static func drawEmojiArtwork(emoji: String, in rect: CGRect, context: CGContext) {
        let string = NSString(string: emoji)
        let fontSize = rect.width * 0.96
        let font = UIFont.systemFont(ofSize: fontSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]

        let textSize = string.size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.midX - (textSize.width / 2),
            y: rect.midY - (textSize.height / 2),
            width: textSize.width,
            height: textSize.height
        )

        string.draw(in: textRect, withAttributes: attributes)
    }
}
