import SpriteKit
import SwiftUI

public final class GameScene: SKScene, SKPhysicsContactDelegate {
    public weak var gameState: GameState?

    // Scene dimensions & layout
    public var leftHudOffset: CGFloat = 220
    private var containerWidth: CGFloat = 0
    private var containerHeight: CGFloat = 0
    private var containerOriginX: CGFloat = 0
    private var containerBottomY: CGFloat = 0
    private var dropZoneY: CGFloat = 0
    private var dangerLineY: CGFloat = 0

    // Layers & Nodes
    private var containerNode = SKNode()
    private var fruitLayer = SKNode()
    private var effectLayer = SKNode()
    private var dropGuideLine = SKShapeNode()
    private var previewFruitNode: FruitNode?
    private var dangerLineNode = SKShapeNode()

    // State
    private var canDrop: Bool = true
    private var isAiming: Bool = false
    private var currentAimX: CGFloat = 0
    private var lastUpdateTime: TimeInterval = 0

    public override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 1.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: -24.0)
        physicsWorld.contactDelegate = self

        setupLayers()
        setupContainer()
        setupDangerLine()
        setupDropGuide()
        prepareDropFruit()
    }

    private func setupLayers() {
        removeAllChildren()

        containerNode.zPosition = 1
        addChild(containerNode)

        fruitLayer.zPosition = 10
        addChild(fruitLayer)

        effectLayer.zPosition = 20
        addChild(effectLayer)
    }

    public func updateLayout(size: CGSize, leftOffset: CGFloat) {
        self.size = size
        self.leftHudOffset = leftOffset
        setupLayers()
        setupContainer()
        setupDangerLine()
        setupDropGuide()
        prepareDropFruit()
    }

    public func resetScene() {
        fruitLayer.removeAllChildren()
        effectLayer.removeAllChildren()
        canDrop = true
        isAiming = false
        prepareDropFruit()
    }

    private func setupContainer() {
        containerNode.removeAllChildren()

        let horizontalRightPadding: CGFloat = 20
        let horizontalLeftPadding = leftHudOffset + 12

        containerOriginX = horizontalLeftPadding
        containerWidth = max(280, size.width - containerOriginX - horizontalRightPadding)
        containerHeight = size.height * 0.78
        containerBottomY = size.height * 0.06
        dropZoneY = containerBottomY + containerHeight + 20
        dangerLineY = containerBottomY + containerHeight - 12

        // Visual Box Background
        let backgroundRect = CGRect(
            x: containerOriginX,
            y: containerBottomY,
            width: containerWidth,
            height: containerHeight
        )
        let backgroundBox = SKShapeNode(roundedRect: backgroundRect, cornerRadius: 20)
        backgroundBox.fillColor = SKColor(red: 0.11, green: 0.13, blue: 0.19, alpha: 0.95)
        backgroundBox.strokeColor = SKColor.white.withAlphaComponent(0.18)
        backgroundBox.lineWidth = 2.5
        containerNode.addChild(backgroundBox)

        // Physics Floor
        let floorBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: containerOriginX, y: containerBottomY),
            to: CGPoint(x: containerOriginX + containerWidth, y: containerBottomY)
        )
        floorBody.categoryBitMask = CollisionCategory.floor
        floorBody.collisionBitMask = CollisionCategory.fruit
        floorBody.friction = 0.5
        floorBody.restitution = 0.1

        let floorNode = SKNode()
        floorNode.physicsBody = floorBody
        containerNode.addChild(floorNode)

        // Physics Left Wall
        let leftWallBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: containerOriginX, y: containerBottomY),
            to: CGPoint(x: containerOriginX, y: containerBottomY + containerHeight + 80)
        )
        leftWallBody.categoryBitMask = CollisionCategory.wall
        leftWallBody.collisionBitMask = CollisionCategory.fruit
        leftWallBody.friction = 0.2

        let leftWallNode = SKNode()
        leftWallNode.physicsBody = leftWallBody
        containerNode.addChild(leftWallNode)

        // Physics Right Wall
        let rightWallBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: containerOriginX + containerWidth, y: containerBottomY),
            to: CGPoint(x: containerOriginX + containerWidth, y: containerBottomY + containerHeight + 80)
        )
        rightWallBody.categoryBitMask = CollisionCategory.wall
        rightWallBody.collisionBitMask = CollisionCategory.fruit
        rightWallBody.friction = 0.2

        let rightWallNode = SKNode()
        rightWallNode.physicsBody = rightWallBody
        containerNode.addChild(rightWallNode)
    }

    private func setupDangerLine() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: containerOriginX + 8, y: dangerLineY))
        path.addLine(to: CGPoint(x: containerOriginX + containerWidth - 8, y: dangerLineY))

        dangerLineNode.path = path
        dangerLineNode.strokeColor = SKColor.systemRed.withAlphaComponent(0.55)
        dangerLineNode.lineWidth = 2
        dangerLineNode.lineDashPattern = [6, 6]
        dangerLineNode.zPosition = 5
        containerNode.addChild(dangerLineNode)

        // Pulsing danger indicator
        let fadeOut = SKAction.fadeAlpha(to: 0.25, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 0.75, duration: 0.8)
        dangerLineNode.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
    }

    private func setupDropGuide() {
        dropGuideLine.strokeColor = SKColor.white.withAlphaComponent(0.28)
        dropGuideLine.lineWidth = 1.5
        dropGuideLine.lineDashPattern = [4, 4]
        dropGuideLine.zPosition = 9
        dropGuideLine.isHidden = true
        addChild(dropGuideLine)
    }

    private func prepareDropFruit() {
        guard let state = gameState else { return }

        previewFruitNode?.removeFromParent()

        let fruitType = state.currentFruit
        let fruit = FruitNode(fruitType: fruitType)
        fruit.physicsBody?.isDynamic = false // Static preview until dropped

        currentAimX = containerOriginX + (containerWidth / 2)
        fruit.position = CGPoint(x: currentAimX, y: dropZoneY)
        fruit.zPosition = 15
        fruit.playSpawnAnimation()

        addChild(fruit)
        previewFruitNode = fruit
        updateDropGuide()
    }

    private func updateDropGuide() {
        guard let preview = previewFruitNode else {
            dropGuideLine.isHidden = true
            return
        }

        let path = CGMutablePath()
        path.move(to: CGPoint(x: preview.position.x, y: preview.position.y))
        path.addLine(to: CGPoint(x: preview.position.x, y: containerBottomY))

        dropGuideLine.path = path
        dropGuideLine.isHidden = !isAiming
    }

    private func clampedX(_ touchX: CGFloat, radius: CGFloat) -> CGFloat {
        let minX = containerOriginX + radius + 3
        let maxX = containerOriginX + containerWidth - radius - 3
        return min(max(touchX, minX), maxX)
    }

    // MARK: - Touch Handling (Aim on Drag, Drop on Release)

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, canDrop, gameState?.phase == .playing else { return }
        let location = touch.location(in: self)

        // Only begin aiming if touch is within or near container horizontal area
        if location.x >= (containerOriginX - 30) {
            isAiming = true
            updateAimPosition(location.x)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isAiming, canDrop, gameState?.phase == .playing else { return }
        let location = touch.location(in: self)
        updateAimPosition(location.x)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isAiming, canDrop, gameState?.phase == .playing else { return }
        isAiming = false
        dropGuideLine.isHidden = true
        dropFruit()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isAiming = false
        dropGuideLine.isHidden = true
    }

    private func updateAimPosition(_ touchX: CGFloat) {
        guard let preview = previewFruitNode else { return }
        let clamped = clampedX(touchX, radius: preview.fruitType.radius)
        currentAimX = clamped
        preview.position.x = clamped
        updateDropGuide()
    }

    private func dropFruit() {
        guard let preview = previewFruitNode, let state = gameState else { return }

        canDrop = false
        preview.removeFromParent()

        // Create dropped fruit with active physics
        let droppedFruit = FruitNode(fruitType: preview.fruitType)
        droppedFruit.position = preview.position
        fruitLayer.addChild(droppedFruit)
        droppedFruit.physicsBody?.isDynamic = true

        // Audio & Haptic Feedback
        AudioManager.shared.playDropSound(isMuted: state.isMuted)
        HapticManager.shared.dropFeedback(enabled: state.isHapticsEnabled)

        // Advance to next fruit in state
        _ = state.advanceFruit()

        // Cooldown before next fruit is ready to drop
        let wait = SKAction.wait(forDuration: 0.50)
        run(wait) { [weak self] in
            guard let self = self, self.gameState?.phase == .playing else { return }
            self.canDrop = true
            self.prepareDropFruit()
        }
    }

    // MARK: - Collision Detection & Merging

    public func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node as? FruitNode,
              let nodeB = contact.bodyB.node as? FruitNode else {
            return
        }

        // Must match same fruit type and not be already in merge animation
        guard nodeA.fruitType == nodeB.fruitType,
              !nodeA.isMerging, !nodeB.isMerging else {
            return
        }

        nodeA.isMerging = true
        nodeB.isMerging = true

        let mergePoint = CGPoint(
            x: (nodeA.position.x + nodeB.position.x) / 2,
            y: (nodeA.position.y + nodeB.position.y) / 2
        )

        let fruitType = nodeA.fruitType

        // Animate both fruits shrinking into midpoint
        nodeA.playMergeEffect(into: mergePoint) {}
        nodeB.playMergeEffect(into: mergePoint) { [weak self] in
            guard let self = self else { return }
            self.handleMergeCompletion(for: fruitType, at: mergePoint)
        }
    }

    private func handleMergeCompletion(for type: FruitType, at point: CGPoint) {
        guard let state = gameState else { return }

        if let nextTier = type.nextTier {
            // Standard merge: evolve to next fruit tier
            let newFruit = FruitNode(fruitType: nextTier)
            newFruit.position = point
            fruitLayer.addChild(newFruit)
            newFruit.playSpawnAnimation()

            spawnMergeParticles(at: point, color: nextTier.skPrimaryColor, count: 16)
            state.recordMerge(resultFruit: nextTier)

            AudioManager.shared.playMergeSound(for: nextTier, isMuted: state.isMuted)
            HapticManager.shared.mergeFeedback(tier: nextTier, enabled: state.isHapticsEnabled)
        } else {
            // Watermelon + Watermelon: Supernova burst clearing space and awarding massive bonus
            spawnWatermelonSupernova(at: point)
            state.recordWatermelonBurst()

            AudioManager.shared.playMergeSound(for: .watermelon, isMuted: state.isMuted)
            HapticManager.shared.celebrationFeedback(enabled: state.isHapticsEnabled)
        }
    }

    private func spawnMergeParticles(at position: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            spark.fillColor = color
            spark.strokeColor = .clear
            spark.position = position
            spark.zPosition = 25
            effectLayer.addChild(spark)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 25...65)
            let dest = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )

            let move = SKAction.move(to: dest, duration: 0.32)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.32)
            let scale = SKAction.scale(to: 0.1, duration: 0.32)
            let group = SKAction.group([move, fade, scale])

            spark.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }

    private func spawnWatermelonSupernova(at position: CGPoint) {
        // Shockwave ring
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.strokeColor = SKColor.systemGreen
        ring.fillColor = .clear
        ring.lineWidth = 5
        ring.position = position
        ring.zPosition = 26
        effectLayer.addChild(ring)

        let ringExpand = SKAction.scale(to: 8.0, duration: 0.5)
        let ringFade = SKAction.fadeOut(withDuration: 0.5)
        ring.run(SKAction.sequence([SKAction.group([ringExpand, ringFade]), SKAction.removeFromParent()]))

        // Burst particles
        let colors: [SKColor] = [.systemGreen, .systemRed, .systemYellow, .white]
        for _ in 0..<36 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...8))
            particle.fillColor = colors.randomElement() ?? .systemGreen
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 27
            effectLayer.addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...140)
            let dest = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )

            let move = SKAction.move(to: dest, duration: 0.5)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let group = SKAction.group([move, fade])
            particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Game Loop & Danger Line Check

    public override func update(_ currentTime: TimeInterval) {
        guard gameState?.phase == .playing else { return }

        let deltaTime: TimeInterval
        if lastUpdateTime == 0 {
            deltaTime = 0
        } else {
            deltaTime = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime

        checkDangerLine(deltaTime: deltaTime)
    }

    private func checkDangerLine(deltaTime: TimeInterval) {
        guard deltaTime > 0 else { return }

        for child in fruitLayer.children {
            guard let fruit = child as? FruitNode,
                  let body = fruit.physicsBody,
                  body.isDynamic else {
                continue
            }

            let fruitTopY = fruit.position.y + fruit.fruitType.radius
            let isAbove = fruitTopY > dangerLineY
            let isSettled = abs(body.velocity.dy) < 15 && abs(body.velocity.dx) < 15

            if isAbove && isSettled {
                fruit.timeAboveDangerLine += deltaTime
                if fruit.timeAboveDangerLine > 2.0 {
                    triggerGameOver()
                    break
                }
            } else {
                fruit.timeAboveDangerLine = max(0, fruit.timeAboveDangerLine - deltaTime)
            }
        }
    }

    private func triggerGameOver() {
        guard let state = gameState, state.phase == .playing else { return }
        state.triggerGameOver()
        AudioManager.shared.playGameOverSound(isMuted: state.isMuted)
        HapticManager.shared.gameOverFeedback(enabled: state.isHapticsEnabled)
    }
}
