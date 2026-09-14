function love.load()
    x = 400
    y = 300
    speed = 200
end

function love.update(dt)
    if love.keyboard.isDown("right") then x = x + speed * dt end
    if love.keyboard.isDown("left") then x = x - speed * dt end
    if love.keyboard.isDown("down") then y = y + speed * dt end
    if love.keyboard.isDown("up") then y = y - speed * dt end
end

function love.draw()
    love.graphics.print("Welcome to {{PROJECT_NAME}}!", 10, 10)
    love.graphics.circle("fill", x, y, 20)
end
