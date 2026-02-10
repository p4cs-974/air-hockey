Goal = Class {}

-- @param player number -> 1 or 2
function Goal:init(player)
    -- assert((type(player) == "number") & (player == 1 | player == 2), "player must be a number = 1 or 2")
    self.x = VIRTUAL_WIDTH / 2
    if player == 1 then
        self.y = 30
        self.owner = 1
    elseif player == 2 then
        self.y = VIRTUAL_HEIGHT - 30
        self.owner = 2
    end
    print(string.format("Goal for player %d initialized", self.owner))
    self.width = 60
    self.height = 20
    self.border = 1
end

function Goal:render()
    if self.owner == 1 then
        love.graphics.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.border, self.border)
    elseif self.owner == 2 then
    end
end
