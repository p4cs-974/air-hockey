Goal = Class {}

-- @param player number -> 1 or 2
function Goal:init(player)
    -- assert((type(player) == "number") & (player == 1 | player == 2), "player must be a number = 1 or 2")
    self.x = -1
    self.gap = 70
    self.height = 10
    self.width = self.gap
    if player == 1 then
        self.y = 0
        self.owner = 1
    elseif player == 2 then
        self.y = VIRTUAL_HEIGHT - self.height
        self.owner = 2
    end
    print(string.format("Goal for player %d initialized", self.owner))
end

function Goal:collides(object)
    nearest_x_to_left = math.max(self.x, math.min(object.x, self.x + self.width))
    nearest_y = math.max(self.y, math.min(object.x, self.y + self.height))

    nearest_x_to_right = math.max(VIRTUAL_WIDTH - self.width, math.min(object.x, VIRTUAL_WIDTH))

    dist_x_left = object.x - nearest_x_to_left
    dist_x_right = object.x - nearest_x_to_right
    dist_y = object.y - nearest_y

    dist_left = dist_x_left ^ 2 + dist_y ^ 2
    dist_right = dist_x_right ^ 2 + dist_y ^ 2

    return dist_left <= object.width ^ 2 or dist_right <= object.width ^ 2
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
