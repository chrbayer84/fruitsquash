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
        let diameter = fruitType.radius * 2
        let texture = FruitNode.texture(for: fruitType, diameter: diameter)

        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: diameter, height: diameter)
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

        // 2. Procedural high-resolution standalone artwork (transparent background, no colored coin disk)
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
            case .lime:
                drawWholeLime(in: rect, context: cgContext)
            default:
                drawEmojiArtwork(emoji: fruitType.emoji, in: rect, context: cgContext)
            }
        }

        let texture = SKTexture(image: renderedImage)
        textureCache[fruitType] = texture
        return texture
    }

    // MARK: - Dedicated Fruit Vector Renderers (No background discs)

    /// Draws a single glossy red currant berry
    private static func drawSingleRedCurrant(in rect: CGRect, context: CGContext) {
        let inset = rect.width * 0.04
        let berryRect = rect.insetBy(dx: inset, dy: inset)

        // Berry gradient body
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 0.98, green: 0.22, blue: 0.26, alpha: 1.0).cgColor,
            UIColor(red: 0.85, green: 0.08, blue: 0.14, alpha: 1.0).cgColor,
            UIColor(red: 0.55, green: 0.02, blue: 0.08, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.65, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context.saveGState()
            context.addEllipse(in: berryRect)
            context.clip()

            let center = CGPoint(x: berryRect.midX - berryRect.width * 0.15, y: berryRect.midY - berryRect.height * 0.15)
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
        let calyxSize = berryRect.width * 0.12
        let calyxRect = CGRect(
            x: berryRect.midX - calyxSize / 2,
            y: berryRect.minY + calyxSize * 0.2,
            width: calyxSize,
            height: calyxSize * 0.7
        )
        context.fillEllipse(in: calyxRect)

        // Gloss highlight arc
        context.setFillColor(UIColor.white.withAlphaComponent(0.65).cgColor)
        let highlight = CGRect(
            x: berryRect.minX + berryRect.width * 0.18,
            y: berryRect.minY + berryRect.height * 0.16,
            width: berryRect.width * 0.28,
            height: berryRect.height * 0.18
        )
        context.fillEllipse(in: highlight)
    }

    /// Draws a single indigo blueberry with star calyx crown
    private static func drawSingleBlueberry(in rect: CGRect, context: CGContext) {
        let inset = rect.width * 0.04
        let berryRect = rect.insetBy(dx: inset, dy: inset)

        // Blueberry gradient body
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 0.32, green: 0.48, blue: 0.96, alpha: 1.0).cgColor,
            UIColor(red: 0.18, green: 0.28, blue: 0.78, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.12, blue: 0.45, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.6, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context.saveGState()
            context.addEllipse(in: berryRect)
            context.clip()

            let center = CGPoint(x: berryRect.midX - berryRect.width * 0.12, y: berryRect.midY - berryRect.height * 0.12)
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
        context.setFillColor(UIColor(red: 0.05, green: 0.08, blue: 0.25, alpha: 0.9).cgColor)
        let crownRadius = berryRect.width * 0.14
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
        context.setFillColor(UIColor(red: 0.65, green: 0.78, blue: 1.0, alpha: 0.45).cgColor)
        let bloom = CGRect(
            x: berryRect.minX + berryRect.width * 0.18,
            y: berryRect.minY + berryRect.height * 0.22,
            width: berryRect.width * 0.32,
            height: berryRect.height * 0.20
        )
        context.fillEllipse(in: bloom)
    }

    /// Draws a single whole green lime (not a slice)
    private static func drawWholeLime(in rect: CGRect, context: CGContext) {
        let inset = rect.width * 0.04
        let limeRect = rect.insetBy(dx: inset, dy: inset)

        // Whole lime oval body
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 0.56, green: 0.90, blue: 0.20, alpha: 1.0).cgColor,
            UIColor(red: 0.40, green: 0.78, blue: 0.12, alpha: 1.0).cgColor,
            UIColor(red: 0.22, green: 0.52, blue: 0.06, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.65, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context.saveGState()
            context.addEllipse(in: limeRect)
            context.clip()

            let center = CGPoint(x: limeRect.midX - limeRect.width * 0.15, y: limeRect.midY - limeRect.height * 0.15)
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: CGPoint(x: limeRect.midX, y: limeRect.midY),
                endRadius: limeRect.width * 0.55,
                options: [.drawsAfterEndLocation]
            )
            context.restoreGState()
        }

        // Small stem node at top pole
        context.setFillColor(UIColor(red: 0.30, green: 0.45, blue: 0.10, alpha: 1.0).cgColor)
        let tipSize = limeRect.width * 0.14
        let tipRect = CGRect(
            x: limeRect.midX - tipSize / 2,
            y: limeRect.minY + tipSize * 0.1,
            width: tipSize,
            height: tipSize * 0.55
        )
        context.fillEllipse(in: tipRect)

        // Citrus peel sheen highlight
        context.setFillColor(UIColor.white.withAlphaComponent(0.40).cgColor)
        let sheen = CGRect(
            x: limeRect.minX + limeRect.width * 0.20,
            y: limeRect.minY + limeRect.height * 0.18,
            width: limeRect.width * 0.32,
            height: limeRect.height * 0.22
        )
        context.fillEllipse(in: sheen)
    }

    /// Draws full-bleed emoji graphic scaled to the exact circle boundary without background
    private static func drawEmojiArtwork(emoji: String, in rect: CGRect, context: CGContext) {
        let string = NSString(string: emoji)
        let fontSize = rect.width * 0.88
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
