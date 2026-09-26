import SpriteKit
import SwiftUI

public final class GameScene: SKScene, SKPhysicsContactDelegate {
    public weak var gameState: GameState?

    // Scene dimensions & orientation
    public var isPortrait: Bool = false
    public var hudOffset: CGFloat = 210
    public var scaleFactor: CGFloat { 1.0 }

    private var containerWidth: CGFloat = 0
    private var containerHeight: CGFloat = 0
    private var containerOriginX: CGFloat = 0
    private var containerBottomY: CGFloat = 0
    private var dropZoneY: CGFloat = 0
    private var dangerLineY: CGFloat = 0

    // Previous container bounds for smooth rotation mapping
    private var prevOriginX: CGFloat = 0
    private var prevBottomY: CGFloat = 0
    private var prevWidth: CGFloat = 0
    private var prevHeight: CGFloat = 0

    // Layers & Nodes
    private var containerNode = SKNode()
    private var fruitLayer = SKNode()
    private var effectLayer = SKNode()
    private var fireworksLayer = SKNode()
    private var dropGuideLine = SKShapeNode()
    private var previewFruitNode: FruitNode?
    private var dangerLineNode = SKShapeNode()
    private var crosshairNode = SKNode()
    private var upgradeCrosshairNode = SKNode()

    // State
    private var canDrop: Bool = true
    private var isAiming: Bool = false
    public var isRotating: Bool = false
    private var isInitialSettling: Bool = false
    private var currentAimX: CGFloat = 0
    private var lastUpdateTime: TimeInterval = 0
    private var lastShakeTimestamp: TimeInterval = 0

    public override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: -24.0)
        physicsWorld.contactDelegate = self

        setupLayers()
        setupContainer()
        setupDangerLine()
        setupDropGuide()
        setupCrosshair()
        prefillBox()
        prepareDropFruit()
    }

    private func setupLayers() {
        if containerNode.parent == nil {
            containerNode.zPosition = 1
            addChild(containerNode)
        }
        if fruitLayer.parent == nil {
            fruitLayer.zPosition = 10
            addChild(fruitLayer)
        }
        if effectLayer.parent == nil {
            effectLayer.zPosition = 20
            addChild(effectLayer)
        }
        if fireworksLayer.parent == nil {
            fireworksLayer.zPosition = 30
            addChild(fireworksLayer)
        }
        if dropGuideLine.parent == nil {
            addChild(dropGuideLine)
        }
    }

    private func setupCrosshair() {
        crosshairNode.removeAllChildren()
        upgradeCrosshairNode.removeAllChildren()

        // 1. Bomb Reticle (Red)
        let ring = SKShapeNode(circleOfRadius: 22)
        ring.strokeColor = SKColor.systemRed
        ring.lineWidth = 2.5
        ring.fillColor = SKColor.systemRed.withAlphaComponent(0.12)
        crosshairNode.addChild(ring)

        let dot = SKShapeNode(circleOfRadius: 3.5)
        dot.fillColor = SKColor.systemYellow
        dot.strokeColor = .clear
        crosshairNode.addChild(dot)

        let offsets: [(CGPoint, CGPoint)] = [
            (CGPoint(x: 0, y: 15), CGPoint(x: 0, y: 30)),
            (CGPoint(x: 0, y: -15), CGPoint(x: 0, y: -30)),
            (CGPoint(x: 15, y: 0), CGPoint(x: 30, y: 0)),
            (CGPoint(x: -15, y: 0), CGPoint(x: -30, y: 0))
        ]

        for (start, end) in offsets {
            let path = CGMutablePath()
            path.move(to: start)
            path.addLine(to: end)
            let line = SKShapeNode(path: path)
            line.strokeColor = SKColor.systemRed
            line.lineWidth = 2.5
            crosshairNode.addChild(line)
        }

        crosshairNode.zPosition = 40
        crosshairNode.isHidden = true
        if crosshairNode.parent == nil {
            effectLayer.addChild(crosshairNode)
        }

        // 2. Upgrade Reticle (Emerald Green & Gold)
        let upRing = SKShapeNode(circleOfRadius: 24)
        upRing.strokeColor = SKColor.systemGreen
        upRing.lineWidth = 2.5
        upRing.fillColor = SKColor.systemGreen.withAlphaComponent(0.15)
        upgradeCrosshairNode.addChild(upRing)

        let upArrow = SKShapeNode(circleOfRadius: 4)
        upArrow.fillColor = SKColor.systemYellow
        upArrow.strokeColor = .clear
        upgradeCrosshairNode.addChild(upArrow)

        for (start, end) in offsets {
            let path = CGMutablePath()
            path.move(to: start)
            path.addLine(to: end)
            let line = SKShapeNode(path: path)
            line.strokeColor = SKColor.systemGreen
            line.lineWidth = 2.5
            upgradeCrosshairNode.addChild(line)
        }

        upgradeCrosshairNode.zPosition = 40
        upgradeCrosshairNode.isHidden = true
        if upgradeCrosshairNode.parent == nil {
            effectLayer.addChild(upgradeCrosshairNode)
        }
    }

    public func updateLayout(size: CGSize, isPortrait: Bool, hudOffset: CGFloat) {
        self.size = size
        self.isPortrait = isPortrait
        self.hudOffset = hudOffset

        // Record previous container bounds for proportional fruit translation
        prevOriginX = containerOriginX
        prevBottomY = containerBottomY
        prevWidth = containerWidth
        prevHeight = containerHeight

        // Freeze all fruits immediately during rotation to prevent accidental merges
        isRotating = true
        for child in fruitLayer.children {
            if let fruit = child as? FruitNode {
                fruit.physicsBody?.isDynamic = false
                fruit.physicsBody?.velocity = .zero
                fruit.physicsBody?.angularVelocity = 0
            }
        }

        setupLayers()
        setupContainer()
        setupDangerLine()
        setupDropGuide()
        setupCrosshair()

        // Reposition active fruits proportionally into the new orientation box
        if prevWidth > 0 && prevHeight > 0 && !fruitLayer.children.isEmpty {
            for child in fruitLayer.children {
                if let fruit = child as? FruitNode {
                    let relX = (fruit.position.x - prevOriginX) / prevWidth
                    let relY = (fruit.position.y - prevBottomY) / prevHeight
                    let clampedRelX = min(max(relX, 0.08), 0.92)
                    let clampedRelY = min(max(relY, 0.05), 0.95)

                    fruit.position = CGPoint(
                        x: containerOriginX + (clampedRelX * containerWidth),
                        y: containerBottomY + (clampedRelY * containerHeight)
                    )
                }
            }
        } else {
            prefillBox()
        }

        prepareDropFruit()

        // After rotation settles smoothly (0.45s), unfreeze physics and re-enable input
        let unfreezeWait = SKAction.wait(forDuration: 0.45)
        run(unfreezeWait) { [weak self] in
            guard let self = self else { return }
            for child in self.fruitLayer.children {
                if let fruit = child as? FruitNode {
                    fruit.physicsBody?.isDynamic = true
                }
            }
            self.isRotating = false
        }
    }

    public func resetScene() {
        fruitLayer.removeAllChildren()
        effectLayer.removeAllChildren()
        fireworksLayer.removeAllChildren()
        crosshairNode.isHidden = true
        canDrop = true
        isAiming = false
        setupCrosshair()
        prefillBox()
        prepareDropFruit()
    }

    /// Pre-fills ~1/4 of the square box with a varied mix of fruit tiers (Red Currant up to Apple)
    public func prefillBox() {
        fruitLayer.removeAllChildren()
        isInitialSettling = true
        gameState?.score = 0
        gameState?.mergeCount = 0

        let allowedTiers: [FruitType] = [
            .redCurrant, .blueberry, .lemon, .purpleGrapeBunch, .orange, .apple
        ]

        let targetFillHeight = containerHeight * 0.28
        let maxY = containerBottomY + targetFillHeight
        let margin: CGFloat = 10

        var y = containerBottomY + (20 * scaleFactor)
        var lastRowTiers: [FruitType] = []

        while y <= maxY {
            var x = containerOriginX + margin + (14 * scaleFactor)
            var currentRowTiers: [FruitType] = []
            var lastTierInRow: FruitType? = nil

            while x <= (containerOriginX + containerWidth - margin - (14 * scaleFactor)) {
                let colIndex = currentRowTiers.count
                let belowTier = (colIndex < lastRowTiers.count) ? lastRowTiers[colIndex] : nil

                let candidateTiers = allowedTiers.filter { tier in
                    tier != lastTierInRow && tier != belowTier
                }
                let chosenTier = candidateTiers.randomElement() ?? allowedTiers.randomElement() ?? .redCurrant

                let fruit = FruitNode(fruitType: chosenTier, scale: scaleFactor)
                let jitterX = CGFloat.random(in: -2...2)
                let jitterY = CGFloat.random(in: -1...1)
                fruit.position = CGPoint(x: x + jitterX, y: y + jitterY)
                fruit.physicsBody?.isDynamic = true
                fruitLayer.addChild(fruit)

                currentRowTiers.append(chosenTier)
                lastTierInRow = chosenTier

                x += (chosenTier.radius(scale: scaleFactor) * 2) + (4 * scaleFactor)
            }

            lastRowTiers = currentRowTiers
            y += (34 * scaleFactor)
        }

        // Temporary debug: spawn a pineapple directly on board start for inspection
        let debugPineapple = FruitNode(fruitType: .pineapple, scale: scaleFactor)
        debugPineapple.position = CGPoint(
            x: containerOriginX + containerWidth * 0.5,
            y: containerBottomY + targetFillHeight + (debugPineapple.effectiveSize.height * 0.5) + 10
        )
        debugPineapple.physicsBody?.isDynamic = true
        fruitLayer.addChild(debugPineapple)

        // Complete initial settling after 1.2s and enforce 0 start points
        removeAction(forKey: "initialSettling")
        let settleAction = SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.isInitialSettling = false
                self.gameState?.score = 0
                self.gameState?.mergeCount = 0
            }
        ])
        run(settleAction, withKey: "initialSettling")
    }

    /// Shakes the board: applies random physical impulses to all fruits and shakes the scene visually
    public func shakeBoard() {
        guard gameState?.phase == .playing, !isRotating, !(gameState?.isBombModeActive ?? false) else { return }

        let now = CACurrentMediaTime()
        guard now - lastShakeTimestamp > 0.40 else { return }
        lastShakeTimestamp = now

        for child in fruitLayer.children {
            guard let fruit = child as? FruitNode,
                  let body = fruit.physicsBody,
                  body.isDynamic else {
                continue
            }

            let impulseX = CGFloat.random(in: -65...65) * scaleFactor
            let impulseY = CGFloat.random(in: 40...130) * scaleFactor
            body.applyImpulse(CGVector(dx: impulseX, dy: impulseY))
            body.applyAngularImpulse(CGFloat.random(in: -0.04...0.04))
        }

        let shakeSequence = SKAction.sequence([
            .moveBy(x: -7, y: 3, duration: 0.03),
            .moveBy(x: 14, y: -6, duration: 0.035),
            .moveBy(x: -12, y: 5, duration: 0.035),
            .moveBy(x: 7, y: -3, duration: 0.03),
            .moveBy(x: -2, y: 1, duration: 0.025),
            .move(to: .zero, duration: 0.025)
        ])

        containerNode.run(shakeSequence)
        fruitLayer.run(shakeSequence)

        if let state = gameState {
            AudioManager.shared.playButtonTap(isMuted: state.isMuted)
            HapticManager.shared.mergeFeedback(tier: .orange, enabled: state.isHapticsEnabled)
        }
    }

    private func setupContainer() {
        containerNode.removeAllChildren()

        let minDim = min(size.width, size.height)

        // Unified absolute box size that is identical in both Portrait and Landscape
        let availableWidth = minDim - 32
        let availableHeight = minDim - 36
        let boxSize = min(availableWidth, availableHeight) * 0.92

        containerWidth = boxSize
        containerHeight = boxSize

        if isPortrait {
            // Portrait Layout: Center box horizontally and vertically in the area below top HUD
            let topPadding = hudOffset + 14
            let availableAreaHeight = max(240, size.height - topPadding)

            containerOriginX = (size.width - boxSize) / 2
            containerBottomY = (availableAreaHeight - boxSize) / 2
            dropZoneY = containerBottomY + containerHeight + 22
            dangerLineY = containerBottomY + containerHeight - 12
        } else {
            // Landscape Layout: Center box horizontally and vertically in the area to the right of left HUD
            let leftPadding = hudOffset + 14
            let availableAreaWidth = size.width - leftPadding
            let centerX = leftPadding + (availableAreaWidth / 2)

            containerOriginX = centerX - (boxSize / 2)
            containerBottomY = (size.height - boxSize) / 2
            dropZoneY = containerBottomY + containerHeight + 22
            dangerLineY = containerBottomY + containerHeight - 12
        }

        // Visual Square Background with Theme Tinting
        let theme = gameState?.theme ?? .dark
        let backgroundRect = CGRect(
            x: containerOriginX,
            y: containerBottomY,
            width: containerWidth,
            height: containerHeight
        )
        let backgroundBox = SKShapeNode(rect: backgroundRect, cornerRadius: 20)
        backgroundBox.name = "backgroundBox"
        backgroundBox.fillColor = theme.skContainerFill
        backgroundBox.strokeColor = theme.skContainerStroke
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

    public func applyTheme(_ theme: GameTheme) {
        if let box = containerNode.childNode(withName: "backgroundBox") as? SKShapeNode {
            box.fillColor = theme.skContainerFill
            box.strokeColor = theme.skContainerStroke
        }
        dangerLineNode.strokeColor = theme.skDangerLineColor
        dropGuideLine.strokeColor = theme.skDropGuideColor
    }

    private func setupDangerLine() {
        dangerLineNode.removeFromParent()
        dangerLineNode.removeAllActions()

        let path = CGMutablePath()
        path.move(to: CGPoint(x: containerOriginX + 8, y: dangerLineY))
        path.addLine(to: CGPoint(x: containerOriginX + containerWidth - 8, y: dangerLineY))

        let dashedPath = path.copy(dashingWithPhase: 0, lengths: [6.0, 6.0])
        dangerLineNode.path = dashedPath
        dangerLineNode.strokeColor = SKColor.systemRed.withAlphaComponent(0.55)
        dangerLineNode.lineWidth = 2
        dangerLineNode.zPosition = 5
        containerNode.addChild(dangerLineNode)

        let fadeOut = SKAction.fadeAlpha(to: 0.25, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 0.75, duration: 0.8)
        dangerLineNode.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
    }

    private func setupDropGuide() {
        dropGuideLine.strokeColor = SKColor.white.withAlphaComponent(0.28)
        dropGuideLine.lineWidth = 1.5
        dropGuideLine.zPosition = 9
        dropGuideLine.isHidden = true
        if dropGuideLine.parent == nil {
            addChild(dropGuideLine)
        }
    }

    private func prepareDropFruit() {
        guard let state = gameState else { return }

        previewFruitNode?.removeFromParent()

        let fruitType = state.currentFruit
        let fruit = FruitNode(fruitType: fruitType, scale: scaleFactor)
        fruit.physicsBody?.isDynamic = false

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

        let dashedPath = path.copy(dashingWithPhase: 0, lengths: [4.0, 4.0])
        dropGuideLine.path = dashedPath
        let isPowerUpActive = (gameState?.isBombModeActive ?? false) || (gameState?.isUpgradeModeActive ?? false)
        dropGuideLine.isHidden = !isAiming || isPowerUpActive
    }

    private func clampedX(_ touchX: CGFloat, radius: CGFloat) -> CGFloat {
        let minX = containerOriginX + radius + 3
        let maxX = containerOriginX + containerWidth - radius - 3
        return min(max(touchX, minX), maxX)
    }

    // MARK: - Touch Handling (Drop Aiming vs. Bomb / Upgrade Targeting)

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isRotating, gameState?.phase == .playing else { return }
        let location = touch.location(in: self)

        if gameState?.isUpgradeModeActive == true {
            upgradeCrosshairNode.position = location
            upgradeCrosshairNode.isHidden = false
            crosshairNode.isHidden = true
            previewFruitNode?.isHidden = true
            dropGuideLine.isHidden = true
            return
        }

        if gameState?.isBombModeActive == true {
            crosshairNode.position = location
            crosshairNode.isHidden = false
            upgradeCrosshairNode.isHidden = true
            previewFruitNode?.isHidden = true
            dropGuideLine.isHidden = true
            return
        }

        if canDrop && location.x >= (containerOriginX - 30) && location.x <= (containerOriginX + containerWidth + 30) {
            isAiming = true
            updateAimPosition(location.x)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isRotating, gameState?.phase == .playing else { return }
        let location = touch.location(in: self)

        if gameState?.isUpgradeModeActive == true {
            upgradeCrosshairNode.position = location
            upgradeCrosshairNode.isHidden = false
            return
        }

        if gameState?.isBombModeActive == true {
            crosshairNode.position = location
            crosshairNode.isHidden = false
            return
        }

        if isAiming && canDrop {
            updateAimPosition(location.x)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isRotating, gameState?.phase == .playing else { return }
        let location = touch.location(in: self)

        // UPGRADE MODE EXECUTION
        if gameState?.isUpgradeModeActive == true {
            handleUpgradeTargeting(at: location)
            return
        }

        // BOMB MODE EXECUTION
        if gameState?.isBombModeActive == true {
            handleBombTargeting(at: location)
            return
        }

        // REGULAR DROP
        guard isAiming, canDrop else { return }
        isAiming = false
        dropGuideLine.isHidden = true
        dropFruit()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isAiming = false
        dropGuideLine.isHidden = true
        if !(gameState?.isBombModeActive ?? false) {
            crosshairNode.isHidden = true
        }
        if !(gameState?.isUpgradeModeActive ?? false) {
            upgradeCrosshairNode.isHidden = true
        }
    }

    private func handleUpgradeTargeting(at location: CGPoint) {
        let hitNodes = nodes(at: location)
        var targetFruit: FruitNode?

        for node in hitNodes {
            if let f = node as? FruitNode {
                targetFruit = f
                break
            } else if let f = node.parent as? FruitNode {
                targetFruit = f
                break
            }
        }

        if let fruit = targetFruit {
            if fruit.fruitType == .watermelon {
                // Watermelon cannot be upgraded further - play wobble feedback
                let wobble = SKAction.sequence([
                    .rotate(byAngle: -0.12, duration: 0.05),
                    .rotate(byAngle: 0.24, duration: 0.05),
                    .rotate(byAngle: -0.12, duration: 0.05)
                ])
                fruit.run(wobble)
                HapticManager.shared.buttonTapFeedback(enabled: gameState?.isHapticsEnabled ?? true)
            } else if let nextTier = fruit.fruitType.nextTier {
                upgradeFruit(fruit, to: nextTier)
            }
        } else {
            // If tapped outside container, cancel upgrade mode
            if location.x < containerOriginX || location.x > (containerOriginX + containerWidth) || location.y < containerBottomY {
                gameState?.deactivateUpgradeMode()
                upgradeCrosshairNode.isHidden = true
                prepareDropFruit()
            }
        }
    }

    /// Upgrades a single selected fruit to its next evolution tier
    private func upgradeFruit(_ fruit: FruitNode, to nextTier: FruitType) {
        guard let state = gameState else { return }
        let pos = fruit.position

        // 1. Sparkle evolution particles
        let sparkColors: [SKColor] = [.systemYellow, .systemGreen, .white]
        for _ in 0..<20 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            spark.fillColor = sparkColors.randomElement() ?? .systemYellow
            spark.strokeColor = .clear
            spark.position = pos
            spark.zPosition = 33
            effectLayer.addChild(spark)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...60) * scaleFactor
            let dest = CGPoint(x: pos.x + cos(angle) * distance, y: pos.y + sin(angle) * distance)

            let move = SKAction.move(to: dest, duration: 0.30)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.30)
            let shrink = SKAction.scale(to: 0.1, duration: 0.30)
            spark.run(SKAction.sequence([SKAction.group([move, fade, shrink]), SKAction.removeFromParent()]))
        }

        // 2. Replace with upgraded fruit
        fruit.removeFromParent()
        let upgradedFruit = FruitNode(fruitType: nextTier, scale: scaleFactor)
        upgradedFruit.position = pos
        fruitLayer.addChild(upgradedFruit)
        upgradedFruit.playSpawnAnimation()

        // 3. Audio & Haptics
        AudioManager.shared.playMergeSound(for: nextTier, isMuted: state.isMuted)
        HapticManager.shared.mergeFeedback(tier: nextTier, enabled: state.isHapticsEnabled)

        // 4. Deactivate Upgrade Mode and re-enable drop preview
        state.deactivateUpgradeMode()
        upgradeCrosshairNode.isHidden = true

        let wait = SKAction.wait(forDuration: 0.25)
        run(wait) { [weak self] in
            guard let self = self, self.gameState?.phase == .playing else { return }
            self.prepareDropFruit()
        }
    }

    private func handleBombTargeting(at location: CGPoint) {
        let hitNodes = nodes(at: location)
        var targetFruit: FruitNode?

        for node in hitNodes {
            if let f = node as? FruitNode {
                targetFruit = f
                break
            } else if let f = node.parent as? FruitNode {
                targetFruit = f
                break
            }
        }

        if let fruit = targetFruit {
            detonateFruit(fruit)
        } else {
            // If tapped outside container, cancel bomb mode
            if location.x < containerOriginX || location.x > (containerOriginX + containerWidth) || location.y < containerBottomY {
                gameState?.deactivateBombMode()
                crosshairNode.isHidden = true
                prepareDropFruit()
            }
        }
    }

    /// Blows up the selected fruit, pushing surrounding fruits and allowing gravity to fill the gap
    private func detonateFruit(_ fruit: FruitNode) {
        guard let state = gameState else { return }
        let blastPoint = fruit.position

        // 1. Blast shockwave ring
        let shockwave = SKShapeNode(circleOfRadius: 15)
        shockwave.strokeColor = SKColor.systemOrange
        shockwave.lineWidth = 4
        shockwave.fillColor = SKColor.yellow.withAlphaComponent(0.25)
        shockwave.position = blastPoint
        shockwave.zPosition = 32
        effectLayer.addChild(shockwave)

        let expand = SKAction.scale(to: 5.0, duration: 0.28)
        let fade = SKAction.fadeOut(withDuration: 0.28)
        shockwave.run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))

        // 2. Fiery explosion particles
        let colors: [SKColor] = [.systemOrange, .systemRed, .systemYellow, .white]
        for _ in 0..<32 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...7))
            spark.fillColor = colors.randomElement() ?? .systemOrange
            spark.strokeColor = .clear
            spark.position = blastPoint
            spark.zPosition = 33
            effectLayer.addChild(spark)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...90) * scaleFactor
            let dest = CGPoint(
                x: blastPoint.x + cos(angle) * distance,
                y: blastPoint.y + sin(angle) * distance
            )

            let move = SKAction.move(to: dest, duration: 0.35)
            move.timingMode = .easeOut
            let particleFade = SKAction.fadeOut(withDuration: 0.35)
            let shrink = SKAction.scale(to: 0.1, duration: 0.35)
            spark.run(SKAction.sequence([SKAction.group([move, particleFade, shrink]), SKAction.removeFromParent()]))
        }

        // 3. Radial impulse shockwave to surrounding fruits
        let blastRadius = 160.0 * scaleFactor
        for child in fruitLayer.children {
            guard let other = child as? FruitNode, other !== fruit,
                  let body = other.physicsBody, body.isDynamic else { continue }

            let dx = other.position.x - blastPoint.x
            let dy = other.position.y - blastPoint.y
            let dist = max(12, sqrt(dx * dx + dy * dy))

            if dist < blastRadius {
                let strength = ((blastRadius - dist) / blastRadius) * (85.0 * scaleFactor)
                body.applyImpulse(CGVector(dx: (dx / dist) * strength, dy: (dy / dist) * strength + 18))
            }
        }

        // 4. Remove targeted fruit
        fruit.removeFromParent()

        // 5. Sound & Haptics
        AudioManager.shared.playBombKlaxonSound(isMuted: state.isMuted)
        HapticManager.shared.gameOverFeedback(enabled: state.isHapticsEnabled)

        // 6. Deactivate Bomb Mode and re-enable preview
        state.deactivateBombMode()
        crosshairNode.isHidden = true

        let wait = SKAction.wait(forDuration: 0.25)
        run(wait) { [weak self] in
            guard let self = self, self.gameState?.phase == .playing else { return }
            self.prepareDropFruit()
        }
    }

    private func updateAimPosition(_ touchX: CGFloat) {
        guard let preview = previewFruitNode else { return }
        let clamped = clampedX(touchX, radius: preview.effectiveRadius)
        currentAimX = clamped
        preview.position.x = clamped
        updateDropGuide()
    }

    private func dropFruit() {
        guard let preview = previewFruitNode, let state = gameState else { return }

        canDrop = false
        preview.removeFromParent()

        let droppedFruit = FruitNode(fruitType: preview.fruitType, scale: scaleFactor)
        droppedFruit.position = preview.position
        fruitLayer.addChild(droppedFruit)
        droppedFruit.physicsBody?.isDynamic = true

        AudioManager.shared.playDropSound(isMuted: state.isMuted)
        HapticManager.shared.dropFeedback(enabled: state.isHapticsEnabled)

        _ = state.advanceFruit()

        let wait = SKAction.wait(forDuration: 0.50)
        run(wait) { [weak self] in
            guard let self = self, self.gameState?.phase == .playing else { return }
            self.canDrop = true
            self.prepareDropFruit()
        }
    }

    // MARK: - Collision Detection, Merging & Victory

    public func didBegin(_ contact: SKPhysicsContact) {
        guard !isRotating else { return }

        guard let nodeA = contact.bodyA.node as? FruitNode,
              let nodeB = contact.bodyB.node as? FruitNode else {
            return
        }

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

        nodeA.playMergeEffect(into: mergePoint) {}
        nodeB.playMergeEffect(into: mergePoint) { [weak self] in
            guard let self = self else { return }
            self.handleMergeCompletion(for: fruitType, at: mergePoint)
        }
    }

    private func handleMergeCompletion(for type: FruitType, at point: CGPoint) {
        guard let state = gameState else { return }

        if let nextTier = type.nextTier {
            let newFruit = FruitNode(fruitType: nextTier, scale: scaleFactor)
            newFruit.position = point
            fruitLayer.addChild(newFruit)
            newFruit.playSpawnAnimation()

            spawnMergeParticles(at: point, color: nextTier.skPrimaryColor, count: 16)

            if !isInitialSettling {
                state.recordMerge(resultFruit: nextTier)
            }

            AudioManager.shared.playMergeSound(for: nextTier, isMuted: state.isMuted)
            HapticManager.shared.mergeFeedback(tier: nextTier, enabled: state.isHapticsEnabled)
        } else {
            // Two Watermelons Touch -> GAME WON!
            triggerGameWon(at: point)
        }
    }

    private func triggerGameWon(at point: CGPoint) {
        guard let state = gameState, state.phase == .playing else { return }

        spawnWatermelonSupernova(at: point)
        launchFireworksShow()

        state.triggerWin()
        AudioManager.shared.playMergeSound(for: .watermelon, isMuted: state.isMuted)
        HapticManager.shared.celebrationFeedback(enabled: state.isHapticsEnabled)
    }

    private func launchFireworksShow() {
        fireworksLayer.removeAllChildren()

        let colors: [SKColor] = [.systemYellow, .systemRed, .systemPink, .systemCyan, .systemGreen, .white]

        for i in 0..<6 {
            let delay = SKAction.wait(forDuration: Double(i) * 0.25)
            let burst = SKAction.run { [weak self] in
                guard let self = self else { return }
                let randomX = CGFloat.random(in: self.containerOriginX...(self.containerOriginX + self.containerWidth))
                let randomY = CGFloat.random(in: (self.containerBottomY + self.containerHeight * 0.4)...(self.containerBottomY + self.containerHeight * 0.95))
                self.spawnFireworkRocket(at: CGPoint(x: randomX, y: randomY), colors: colors)
            }
            fireworksLayer.run(SKAction.sequence([delay, burst]))
        }
    }

    private func spawnFireworkRocket(at position: CGPoint, colors: [SKColor]) {
        let particleCount = 28
        let color = colors.randomElement() ?? .systemYellow

        for _ in 0..<particleCount {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...7))
            spark.fillColor = color
            spark.strokeColor = .clear
            spark.position = position
            spark.zPosition = 35
            fireworksLayer.addChild(spark)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...95)
            let dest = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )

            let move = SKAction.move(to: dest, duration: 0.45)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.45)
            let scale = SKAction.scale(to: 0.1, duration: 0.45)

            spark.run(SKAction.sequence([SKAction.group([move, fade, scale]), SKAction.removeFromParent()]))
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
        guard gameState?.phase == .playing, !isRotating else { return }

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

            let fruitTopY = fruit.position.y + fruit.effectiveRadius
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
