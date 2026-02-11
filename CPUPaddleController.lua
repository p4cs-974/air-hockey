CPUPaddleController = Class {}

function CPUPaddleController:init(paddle, targetBall)
    self.paddle = paddle
    self.ball = targetBall
    self.ghost = GhostPuck()
    self.prediction = { x = 0, y = 0 }

    self.states = { DEFEND = 1, ATTACK = 2, RECOVER = 3 }
    self.currentState = self.states.DEFEND

    self.thinkInterval = 5
    self.thinkCounter = 0

    self.currentSpeedX = 0
    self.currentSpeedY = 0
    self.maxSpeed = PADDLE_SPEED * 0.85
    self.acceleration = 450

    self.slowThreshold = 100
    self.fastThreshold = 250
    self.cpuDefensiveLine = VIRTUAL_HEIGHT - 45.2 - 30
    self.predictionSteps = 0
    self.bounceCount = 0

    self.windUpFrames = 8
    self.currentWindUp = 0
    self.isWindingUp = false

    self.strikeTargets = { LEFT_CORNER = 1, RIGHT_CORNER = 2, CENTER = 3 }
    self.currentStrikeTarget = self.strikeTargets.CENTER

    self.debugTargetX = 0
    self.debugTargetY = 0
end

function CPUPaddleController:update(dt, opponentPaddle)
    self.thinkCounter = self.thinkCounter + 1
    if self.thinkCounter >= self.thinkInterval then
        self.thinkCounter = 0
        self:updatePrediction()
    end

    self:updateState(dt, opponentPaddle)
    local targetX, targetY = self:getTargetPosition()
    self:moveTowardsTarget(dt, targetX, targetY)
end

function CPUPaddleController:updatePrediction()
    self.ghost:snapshot(self.ball)

    local puckSpeed = self.ghost:getSpeed()
    local maxBounces
    if puckSpeed < self.slowThreshold then
        maxBounces = 3
    elseif puckSpeed < self.fastThreshold then
        maxBounces = 1
    else
        maxBounces = 0
    end

    local bounces = 0
    local dt = 1 / 60
    local steps = 0
    local movingTowardCPU = self.ghost.dy > 0

    if not movingTowardCPU and maxBounces > 0 then
        maxBounces = 1
    end

    while steps < 180 do
        steps = steps + 1
        local bounced = self.ghost:step(dt)
        if bounced then
            bounces = bounces + 1
            if bounces > maxBounces then break end
        end
        if self.ghost.y <= self.cpuDefensiveLine then break end
        if self.ghost:collidesWithPaddle(self.paddle) then break end
    end

    self.prediction.x = self.ghost.x
    self.prediction.y = self.ghost.y
    self.predictionSteps = steps
    self.bounceCount = bounces
    self.debugTargetX = self.prediction.x
    self.debugTargetY = self.prediction.y
end

function CPUPaddleController:updateState(dt, opponentPaddle)
    local ballBehindPaddle = self.ball.y < self.paddle.y - 5

    if self.currentState == self.states.DEFEND then
        local ballInAIHalf = self.ball.y >= VIRTUAL_HEIGHT / 2
        local ballNearCenter = self.ball.y >= VIRTUAL_HEIGHT / 2 - 30 and self.ball.y < VIRTUAL_HEIGHT / 2
        local movingFastTowardAI = self.ball.dy > 100

        if ballInAIHalf or (ballNearCenter and movingFastTowardAI) then
            self.currentState = self.states.ATTACK
            self.isWindingUp = true
            self.currentWindUp = 0
        elseif ballBehindPaddle then
            self.currentState = self.states.RECOVER
        end

    elseif self.currentState == self.states.ATTACK then
        if self.ball:collides(self.paddle) then
            self.currentState = self.states.DEFEND
            self.isWindingUp = false
            self:calculateStrikeTarget(opponentPaddle)
        elseif ballBehindPaddle then
            self.currentState = self.states.RECOVER
            self.isWindingUp = false
        elseif self.ball.y > VIRTUAL_HEIGHT / 2 + 40 and self.ball.dy < 0 then
            self.currentState = self.states.DEFEND
            self.isWindingUp = false
        end

    elseif self.currentState == self.states.RECOVER then
        local ballMovingTowardAI = self.ball.dy > 0
        if ballMovingTowardAI and not ballBehindPaddle then
            self.currentState = self.states.ATTACK
            self.isWindingUp = true
            self.currentWindUp = 0
        elseif not ballBehindPaddle then
            self.currentState = self.states.DEFEND
        end
    end

    if self.isWindingUp then
        self.currentWindUp = self.currentWindUp + 1
        if self.currentWindUp >= self.windUpFrames then
            self.isWindingUp = false
        end
    end
end

function CPUPaddleController:getTargetPosition()
    local targetX, targetY

    if self.currentState == self.states.DEFEND then
        local ballOnP1Side = self.ball.y < VIRTUAL_HEIGHT / 2
        local ballFarFromZone = self.ball.y < self.cpuDefensiveLine - 60
        local ballMovingAway = self.ball.dy < 0

        if ballOnP1Side or ballFarFromZone or ballMovingAway then
            targetX = VIRTUAL_WIDTH / 2
            targetY = self.cpuDefensiveLine
        else
            targetX = self.prediction.x
            targetY = math.max(self.prediction.y, self.cpuDefensiveLine)
            targetY = math.min(targetY, VIRTUAL_HEIGHT / 2 - self.paddle.width)
        end

    elseif self.currentState == self.states.ATTACK then
        targetX = self.prediction.x
        if self.isWindingUp then
            local progress = self.currentWindUp / self.windUpFrames
            targetY = self.prediction.y + 15 * (1 - progress)
        else
            targetY = self.prediction.y - 10
        end

    elseif self.currentState == self.states.RECOVER then
        local ballBehindPaddle = self.ball.y < self.paddle.y - 5
        local ballMovingAway = self.ball.dy < 0

        if ballBehindPaddle and not ballMovingAway then
            targetX = self.ball.x
            targetY = self.ball.y
        else
            targetX = VIRTUAL_WIDTH / 2
            targetY = self.cpuDefensiveLine
        end
    end

    return targetX, targetY
end

function CPUPaddleController:moveTowardsTarget(dt, targetX, targetY)
    local dx = targetX - self.paddle.x
    local dy = targetY - self.paddle.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance <= 1 then
        self.currentSpeedX = self.currentSpeedX * 0.85
        self.currentSpeedY = self.currentSpeedY * 0.85
        self.paddle.dx = self.currentSpeedX
        self.paddle.dy = self.currentSpeedY
        return
    end

    local dirX = dx / distance
    local dirY = dy / distance
    local desiredSpeed = self.maxSpeed

    if self.currentState == self.states.DEFEND then
        desiredSpeed = self.maxSpeed * 0.7
        if distance < 20 then
            desiredSpeed = desiredSpeed * (distance / 20)
        end
    elseif self.currentState == self.states.ATTACK then
        if self.isWindingUp then
            local progress = self.currentWindUp / self.windUpFrames
            desiredSpeed = self.maxSpeed * (progress * progress)
        end
    elseif self.currentState == self.states.RECOVER then
        local ballBehindPaddle = self.ball.y < self.paddle.y - 5
        if not ballBehindPaddle then
            desiredSpeed = self.maxSpeed * 0.6
        end
    end

    local desiredVelX = dirX * desiredSpeed
    local desiredVelY = dirY * desiredSpeed

    local accelX = desiredVelX - self.currentSpeedX
    local accelY = desiredVelY - self.currentSpeedY
    local accelMag = math.sqrt(accelX * accelX + accelY * accelY)

    if accelMag > self.acceleration * dt then
        local scale = (self.acceleration * dt) / accelMag
        accelX = accelX * scale
        accelY = accelY * scale
    end

    self.currentSpeedX = self.currentSpeedX + accelX
    self.currentSpeedY = self.currentSpeedY + accelY

    if distance < 5 then
        self.currentSpeedX = self.currentSpeedX * 0.9
        self.currentSpeedY = self.currentSpeedY * 0.9
    end

    self.paddle.dx = self.currentSpeedX
    self.paddle.dy = self.currentSpeedY
end

function CPUPaddleController:calculateStrikeTarget(opponentPaddle)
    local opponentX = opponentPaddle.x
    local centerX = VIRTUAL_WIDTH / 2

    if opponentX < centerX - 30 then
        self.currentStrikeTarget = self.strikeTargets.RIGHT_CORNER
    elseif opponentX > centerX + 30 then
        self.currentStrikeTarget = self.strikeTargets.LEFT_CORNER
    else
        self.currentStrikeTarget = math.random() > 0.5 and self.strikeTargets.LEFT_CORNER or self.strikeTargets.RIGHT_CORNER
    end
end

function CPUPaddleController:getStrikeAngle()
    if self.currentStrikeTarget == self.strikeTargets.LEFT_CORNER then
        return math.random(-140, -110) * math.pi / 180
    elseif self.currentStrikeTarget == self.strikeTargets.RIGHT_CORNER then
        return math.random(110, 140) * math.pi / 180
    else
        return math.random(165, 195) * math.pi / 180
    end
end

function CPUPaddleController:reset()
    self.currentState = self.states.DEFEND
    self.currentSpeedX = 0
    self.currentSpeedY = 0
    self.isWindingUp = false
    self.currentWindUp = 0
end

function CPUPaddleController:renderDebug()
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.circle('line', self.debugTargetX, self.debugTargetY, 4)
    love.graphics.line(self.paddle.x, self.paddle.y, self.debugTargetX, self.debugTargetY)

    love.graphics.setFont(smallFont)
    local stateText = "DEFEND"
    if self.currentState == self.states.ATTACK then
        stateText = "ATTACK"
    elseif self.currentState == self.states.RECOVER then
        stateText = "RECOVER"
    end

    if self.isWindingUp then
        stateText = stateText .. " (WINDUP)"
    end

    love.graphics.print(stateText, 10, 50)
    love.graphics.print("Bounces: " .. self.bounceCount, 10, 60)
end
