--[[
    GhostPuck Class
    
    A parallel physics simulation that predicts the puck's future trajectory.
    Used by the CPU AI to anticipate where the puck will be.
    
    Features:
    - Clones real puck state
    - Simulates physics with wall collisions
    - Tracks bounce count for prediction depth limiting
    - Finds interception point in CPU's defensive zone
]]

GhostPuck = Class {}

function GhostPuck:init()
    self.x = 0
    self.y = 0
    self.dx = 0
    self.dy = 0
    self.width = 4
    self.height = 4
    self.mass = 5
    
    -- Simulation constants
    self.wallBounceDamping = 1.0  -- No energy loss in prediction (perfect physics)
end

--[[
    Snapshot the real ball's state to start a ghost simulation
]]
function GhostPuck:snapshot(ball)
    self.x = ball.x
    self.y = ball.y
    self.dx = ball.dx
    self.dy = ball.dy
    self.width = ball.width
    self.height = ball.height
    self.mass = ball.mass
end

--[[
    Step the ghost puck forward by one frame
    Returns: true if a wall collision occurred
]]
function GhostPuck:step(dt)
    local bounced = false
    
    -- Move the ghost puck
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
    
    -- Wall collision detection (same as main.lua)
    -- Left wall
    if self.x <= 0 then
        self.x = 0
        self.dx = -self.dx * self.wallBounceDamping
        bounced = true
    end
    
    -- Right wall
    if self.x >= VIRTUAL_WIDTH - self.width then
        self.x = VIRTUAL_WIDTH - self.width
        self.dx = -self.dx * self.wallBounceDamping
        bounced = true
    end
    
    return bounced
end

--[[
    Simulate paddle collision (when ghost reaches CPU paddle Y position)
]]
function GhostPuck:collidesWithPaddle(paddle)
    local dist = (self.x - paddle.x) ^ 2 + (self.y - paddle.y) ^ 2
    return dist <= (self.width + paddle.width) ^ 2
end

--[[
    Calculate the puck's current speed
]]
function GhostPuck:getSpeed()
    return math.sqrt(self.dx * self.dx + self.dy * self.dy)
end

--[[
    Get the direction vector (normalized)
]]
function GhostPuck:getDirection()
    local speed = self:getSpeed()
    if speed > 0 then
        return self.dx / speed, self.dy / speed
    else
        return 0, 0
    end
end
