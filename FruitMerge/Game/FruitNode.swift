import SpriteKit
import UIKit

public final class FruitNode: SKNode {
    public let fruitType: FruitType
    public let fruitId = UUID()
    public var isMerging: Bool = false
    public var timeAboveDangerLine: TimeInterval = 0

    private var spriteNode: SKSpriteNode?
    private var circleNode: SKShapeNode?
    private var labelNode: SKLabelNode?

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

        // Check if custom PNG asset exists in asset catalog or bundle
        if let image = UIImage(named: fruitType.assetName) {
            let texture = SKTexture(image: image)
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: diameter, height: diameter)
            sprite.zPosition = 10
            addChild(sprite)
            self.spriteNode = sprite
        } else {
            // Procedural vector sprite fallback
            setupProceduralVisuals()
        }
    }

    private func setupProceduralVisuals() {
        let radius = fruitType.radius

        // Base Circle Body
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.fillColor = fruitType.skPrimaryColor
        circle.strokeColor = SKColor.white.withAlphaComponent(0.4)
        circle.lineWidth = max(1.5, radius * 0.05)
        circle.glowWidth = 0.5
        circle.zPosition = 10
        addChild(circle)
        self.circleNode = circle

        // Gloss / Lighting Arc Highlight
        let highlightRadius = radius * 0.28
        let highlight = SKShapeNode(circleOfRadius: highlightRadius)
        highlight.fillColor = SKColor.white.withAlphaComponent(0.42)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(
            x: -radius * 0.35,
            y: radius * 0.35
        )
        highlight.zPosition = 11
        addChild(highlight)

        // Emoji / Face Icon
        let label = SKLabelNode(text: fruitType.emoji)
        label.fontSize = radius * 1.05
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 12
        addChild(label)
        self.labelNode = label
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
}
