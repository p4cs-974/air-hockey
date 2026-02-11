Goal = Class {}

-- @param player number -> 1 or 2
function Goal:init(player)
    -- assert((type(player) == "number") & (player == 1 | player == 2), "player must be a number = 1 or 2")
    self.x = -1
    self.gap = 70
    self.height = 11
    self.width = self.gap
    if player == 1 then
        self.y = -1
        self.owner = 1
    elseif player == 2 then
        self.y = VIRTUAL_HEIGHT - self.height
        self.owner = 2
    end
    print(string.format("Goal for player %d initialized", self.owner))
end

function Goal:collides(object)
    nearest_x_to_left = math.max(self.x, math.min(object.x, self.x + self.width))
    nearest_y = math.max(self.y, math.min(object.y, self.y + self.height))

    nearest_x_to_right = math.max(VIRTUAL_WIDTH - self.width, math.min(object.x, VIRTUAL_WIDTH))

    dist_x_left = object.x - nearest_x_to_left
    dist_x_right = object.x - nearest_x_to_right
    dist_y = object.y - nearest_y

    dist_left = dist_x_left ^ 2 + dist_y ^ 2
    dist_right = dist_x_right ^ 2 + dist_y ^ 2

    if dist_left <= object.width ^ 2 then
        return "left"
    end
    if dist_right <= object.width ^ 2 then
        return "right"
    end
end

function Goal:collidesWithPlayer(player)
    -- Helper function to check collision between circle (player) and rectangle
    local function checkCircleRectCollision(circleX, circleY, radius, rectX, rectY, rectW, rectH)
        -- Find the closest point on the rectangle to the circle's center
        local closestX = math.max(rectX, math.min(circleX, rectX + rectW))
        local closestY = math.max(rectY, math.min(circleY, rectY + rectH))

        -- Calculate the distance squared from the circle's center to the closest point
        local distX = circleX - closestX
        local distY = circleY - closestY
        local distanceSquared = distX * distX + distY * distY

        -- Check if the distance is less than or equal to the radius squared
        return distanceSquared <= radius * radius
    end

    -- Check collision with left rectangle
    if checkCircleRectCollision(player.x, player.y, player.width, self.x, self.y, self.width, self.height) then
        return true
    end

    -- Check collision with right rectangle
    if checkCircleRectCollision(player.x, player.y, player.width, VIRTUAL_WIDTH - self.width, self.y, self.width, self.height) then
        return true
    end

    return false
end

function Goal:render()
    if self.owner == 1 then
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.rectangle("fill", VIRTUAL_WIDTH - self.width, self.y, self.width, self.height)
    elseif self.owner == 2 then
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.rectangle("fill", VIRTUAL_WIDTH - self.width, self.y, self.width, self.height)
    end
end
