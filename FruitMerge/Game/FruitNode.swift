import SpriteKit
import UIKit

public final class FruitNode: SKNode {
    public let fruitType: FruitType
    public let scaleFactor: CGFloat
    public let fruitId = UUID()
    public var isMerging: Bool = false
    public var timeAboveDangerLine: TimeInterval = 0

    private var spriteNode: SKSpriteNode?

    // Static texture cache for instant rendering performance
    private static var textureCache: [String: SKTexture] = [:]

    public init(fruitType: FruitType, scale: CGFloat = 1.0) {
        self.fruitType = fruitType
        self.scaleFactor = scale
        super.init()

        name = "Fruit_\(fruitType.displayName)"
        setupVisuals()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var effectiveRadius: CGFloat {
        fruitType.radius(scale: scaleFactor)
    }

    private func setupVisuals() {
        let physicalDiameter = effectiveRadius * 2
        // Scaled to 100% of physical diameter for flush, seamless contact boundaries
        let visualDiameter = physicalDiameter * 1.00
        let texture = FruitNode.texture(for: fruitType, diameter: visualDiameter)

        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: visualDiameter, height: visualDiameter)
        sprite.zPosition = 10
        addChild(sprite)
        self.spriteNode = sprite
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: effectiveRadius)
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
        let cacheKey = "\(fruitType.rawValue)_\(Int(diameter * 10))"
        if let cached = textureCache[cacheKey] {
            return cached
        }

        // 1. Check for custom PNG image asset
        if let customImage = UIImage(named: fruitType.assetName) {
            let texture = SKTexture(image: customImage)
            textureCache[cacheKey] = texture
            return texture
        }

        // 2. Procedural high-resolution standalone artwork (transparent background, 10% safety margin)
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
            case .purpleGrapeBunch:
                drawRoundGrapeBunch(in: rect, context: cgContext)
            case .dragonfruit:
                drawWholeDragonfruit(in: rect, context: cgContext)
            default:
                drawEmojiArtwork(emoji: fruitType.emoji, in: rect, context: cgContext)
            }
        }

        let texture = SKTexture(image: renderedImage)
        textureCache[cacheKey] = texture
        return texture
    }

    // MARK: - Dedicated Fruit Vector Renderers

    /// Draws a single glossy red currant berry
    private static func drawSingleRedCurrant(in rect: CGRect, context: CGContext) {
        let berryRect = rect

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

        // Top calyx dot
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

        // Star calyx crown
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

        // Dusty bloom highlight
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
        let path = CGMutablePath()
        let tipW = lemonRect.width * 0.08
        let tipH = lemonRect.height * 0.08

        path.move(to: CGPoint(x: lemonRect.midX, y: lemonRect.minY))
        path.addQuadCurve(
            to: CGPoint(x: lemonRect.maxX, y: lemonRect.midY),
            control: CGPoint(x: lemonRect.maxX + tipW, y: lemonRect.minY + tipH)
        )
        path.addQuadCurve(
            to: CGPoint(x: lemonRect.midX, y: lemonRect.maxY),
            control: CGPoint(x: lemonRect.maxX - tipW, y: lemonRect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: lemonRect.minX, y: lemonRect.midY),
            control: CGPoint(x: lemonRect.minX - tipW, y: lemonRect.maxY - tipH)
        )
        path.addQuadCurve(
            to: CGPoint(x: lemonRect.midX, y: lemonRect.minY),
            control: CGPoint(x: lemonRect.minX + tipW, y: lemonRect.minY)
        )
        path.closeSubpath()

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

        // Calyx tip
        context.setFillColor(UIColor(red: 0.42, green: 0.55, blue: 0.15, alpha: 1.0).cgColor)
        let stemSize = lemonRect.width * 0.12
        let stemRect = CGRect(
            x: lemonRect.midX - stemSize / 2,
            y: lemonRect.minY,
            width: stemSize,
            height: stemSize * 0.55
        )
        context.fillEllipse(in: stemRect)

        // Gloss
        context.setFillColor(UIColor.white.withAlphaComponent(0.55).cgColor)
        let gloss = CGRect(
            x: lemonRect.minX + lemonRect.width * 0.20,
            y: lemonRect.minY + lemonRect.height * 0.16,
            width: lemonRect.width * 0.34,
            height: lemonRect.height * 0.22
        )
        context.fillEllipse(in: gloss)
    }

    /// Draws a round cluster of purple grapes approximating a spherical shape
    private static func drawRoundGrapeBunch(in rect: CGRect, context: CGContext) {
        let c = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.03)
        let r = rect.width * 0.44

        // Positions of individual grapes arranged spherically
        let grapeRadius = rect.width * 0.155
        let offsets: [CGPoint] = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: -r * 0.55, y: -r * 0.45),
            CGPoint(x: r * 0.55, y: -r * 0.45),
            CGPoint(x: -r * 0.65, y: r * 0.20),
            CGPoint(x: r * 0.65, y: r * 0.20),
            CGPoint(x: 0, y: -r * 0.60),
            CGPoint(x: -r * 0.32, y: r * 0.62),
            CGPoint(x: r * 0.32, y: r * 0.62),
            CGPoint(x: 0, y: r * 0.55),
            CGPoint(x: -r * 0.28, y: -r * 0.15),
            CGPoint(x: r * 0.28, y: -r * 0.15)
        ]

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let grapeColors = [
            UIColor(red: 0.72, green: 0.35, blue: 0.95, alpha: 1.0).cgColor,
            UIColor(red: 0.48, green: 0.15, blue: 0.75, alpha: 1.0).cgColor,
            UIColor(red: 0.25, green: 0.05, blue: 0.45, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.65, 1.0]
        guard let grapeGrad = CGGradient(colorsSpace: colorSpace, colors: grapeColors, locations: locations) else { return }

        // Draw each spherical grape with depth and highlight
        for pt in offsets {
            let grapeCenter = CGPoint(x: c.x + pt.x, y: c.y + pt.y)
            let gRect = CGRect(
                x: grapeCenter.x - grapeRadius,
                y: grapeCenter.y - grapeRadius,
                width: grapeRadius * 2,
                height: grapeRadius * 2
            )

            context.saveGState()
            context.addEllipse(in: gRect)
            context.clip()

            let lightCenter = CGPoint(x: gRect.midX - grapeRadius * 0.25, y: gRect.midY - grapeRadius * 0.25)
            context.drawRadialGradient(
                grapeGrad,
                startCenter: lightCenter,
                startRadius: 0,
                endCenter: CGPoint(x: gRect.midX, y: gRect.midY),
                endRadius: grapeRadius * 1.05,
                options: [.drawsAfterEndLocation]
            )
            context.restoreGState()

            // Small gloss specular on each grape
            context.setFillColor(UIColor.white.withAlphaComponent(0.40).cgColor)
            let specular = CGRect(
                x: gRect.minX + grapeRadius * 0.35,
                y: gRect.minY + grapeRadius * 0.30,
                width: grapeRadius * 0.55,
                height: grapeRadius * 0.40
            )
            context.fillEllipse(in: specular)
        }

        // Top stem (woody brown twig)
        context.setFillColor(UIColor(red: 0.45, green: 0.28, blue: 0.12, alpha: 1.0).cgColor)
        let stemPath = CGMutablePath()
        stemPath.move(to: CGPoint(x: rect.midX - rect.width * 0.03, y: rect.minY + rect.height * 0.10))
        stemPath.addQuadCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.02, y: rect.minY),
            control: CGPoint(x: rect.midX - rect.width * 0.01, y: rect.minY + rect.height * 0.03)
        )
        stemPath.addLine(to: CGPoint(x: rect.midX + rect.width * 0.06, y: rect.minY + rect.height * 0.01))
        stemPath.addQuadCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.01, y: rect.minY + rect.height * 0.10),
            control: CGPoint(x: rect.midX + rect.width * 0.03, y: rect.minY + rect.height * 0.04)
        )
        stemPath.closeSubpath()
        context.addPath(stemPath)
        context.fillPath()

        // Proper lobed grape vine leaf branching naturally to the left
        let leafPath = CGMutablePath()
        let leafBase = CGPoint(x: rect.midX - rect.width * 0.02, y: rect.minY + rect.height * 0.06)
        leafPath.move(to: leafBase)

        // Left lower lobe
        leafPath.addQuadCurve(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.minY + rect.height * 0.08), control: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.minY + rect.height * 0.12))
        // Left sinus
        leafPath.addQuadCurve(to: CGPoint(x: rect.midX - rect.width * 0.14, y: rect.minY + rect.height * 0.03), control: CGPoint(x: rect.midX - rect.width * 0.16, y: rect.minY + rect.height * 0.05))
        // Center main pointed tip
        leafPath.addQuadCurve(to: CGPoint(x: rect.midX - rect.width * 0.22, y: rect.minY), control: CGPoint(x: rect.midX - rect.width * 0.20, y: rect.minY + rect.height * 0.01))
        // Top sinus
        leafPath.addQuadCurve(to: CGPoint(x: rect.midX - rect.width * 0.10, y: rect.minY + rect.height * 0.01), control: CGPoint(x: rect.midX - rect.width * 0.16, y: rect.minY + rect.height * 0.005))
        // Right upper lobe
        leafPath.addQuadCurve(to: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.minY + rect.height * 0.03), control: CGPoint(x: rect.midX - rect.width * 0.07, y: rect.minY + rect.height * 0.015))
        // Back to base
        leafPath.addQuadCurve(to: leafBase, control: CGPoint(x: rect.midX - rect.width * 0.04, y: rect.minY + rect.height * 0.04))
        leafPath.closeSubpath()

        // Leaf fill
        context.setFillColor(UIColor(red: 0.25, green: 0.65, blue: 0.18, alpha: 1.0).cgColor)
        context.addPath(leafPath)
        context.fillPath()

        // Leaf vein details
        context.setStrokeColor(UIColor(red: 0.15, green: 0.45, blue: 0.10, alpha: 0.8).cgColor)
        context.setLineWidth(rect.width * 0.012)
        context.move(to: leafBase)
        context.addLine(to: CGPoint(x: rect.midX - rect.width * 0.22, y: rect.minY))
        context.move(to: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.minY + rect.height * 0.04))
        context.addLine(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.minY + rect.height * 0.08))
        context.strokePath()
    }

    /// Draws a whole dragonfruit (pitaya) with vibrant pink body and green-tipped scales
    private static func drawWholeDragonfruit(in rect: CGRect, context: CGContext) {
        let fruitRect = rect

        // Dragonfruit body oval
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let pinkColors = [
            UIColor(red: 1.00, green: 0.25, blue: 0.60, alpha: 1.0).cgColor,
            UIColor(red: 0.90, green: 0.10, blue: 0.45, alpha: 1.0).cgColor,
            UIColor(red: 0.60, green: 0.02, blue: 0.28, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.65, 1.0]

        guard let pinkGrad = CGGradient(colorsSpace: colorSpace, colors: pinkColors, locations: locations) else { return }

        context.saveGState()
        context.addEllipse(in: fruitRect)
        context.clip()

        let lightCenter = CGPoint(x: fruitRect.midX - fruitRect.width * 0.15, y: fruitRect.midY - fruitRect.height * 0.15)
        context.drawRadialGradient(
            pinkGrad,
            startCenter: lightCenter,
            startRadius: 0,
            endCenter: CGPoint(x: fruitRect.midX, y: fruitRect.midY),
            endRadius: fruitRect.width * 0.55,
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()

        // Green-tipped curved scales projecting across the body
        let scalePositions: [(CGPoint, CGFloat)] = [
            (CGPoint(x: fruitRect.minX + fruitRect.width * 0.18, y: fruitRect.midY - fruitRect.height * 0.20), -0.5),
            (CGPoint(x: fruitRect.maxX - fruitRect.width * 0.18, y: fruitRect.midY - fruitRect.height * 0.20), 0.5),
            (CGPoint(x: fruitRect.minX + fruitRect.width * 0.15, y: fruitRect.midY + fruitRect.height * 0.12), -0.4),
            (CGPoint(x: fruitRect.maxX - fruitRect.width * 0.15, y: fruitRect.midY + fruitRect.height * 0.12), 0.4),
            (CGPoint(x: fruitRect.midX, y: fruitRect.minY + fruitRect.height * 0.08), 0.0),
            (CGPoint(x: fruitRect.midX - fruitRect.width * 0.12, y: fruitRect.midY), -0.2),
            (CGPoint(x: fruitRect.midX + fruitRect.width * 0.12, y: fruitRect.midY), 0.2),
            (CGPoint(x: fruitRect.midX, y: fruitRect.maxY - fruitRect.height * 0.15), 0.0)
        ]

        let scaleW = fruitRect.width * 0.22
        let scaleH = fruitRect.height * 0.18

        for (pos, angle) in scalePositions {
            context.saveGState()
            context.translateBy(x: pos.x, y: pos.y)
            context.rotate(by: angle)

            let scalePath = CGMutablePath()
            scalePath.move(to: CGPoint(x: -scaleW / 2, y: scaleH / 2))
            scalePath.addQuadCurve(to: CGPoint(x: 0, y: -scaleH / 2), control: CGPoint(x: -scaleW * 0.3, y: -scaleH * 0.2))
            scalePath.addQuadCurve(to: CGPoint(x: scaleW / 2, y: scaleH / 2), control: CGPoint(x: scaleW * 0.3, y: -scaleH * 0.2))
            scalePath.closeSubpath()

            // Scale color: bright green with yellow tip
            context.setFillColor(UIColor(red: 0.35, green: 0.85, blue: 0.15, alpha: 0.95).cgColor)
            context.addPath(scalePath)
            context.fillPath()

            context.restoreGState()
        }

        // Gloss arc
        context.setFillColor(UIColor.white.withAlphaComponent(0.40).cgColor)
        let gloss = CGRect(
            x: fruitRect.minX + fruitRect.width * 0.22,
            y: fruitRect.minY + fruitRect.height * 0.18,
            width: fruitRect.width * 0.32,
            height: fruitRect.height * 0.20
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
