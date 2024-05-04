-- button api

local buttonAPI = {}
buttonAPI.Buttons = {} ---@type table<string, Button>

function buttonAPI.draw()
	for _, button in pairs(buttonAPI.Buttons) do
		button:draw()
	end
end

function buttonAPI.clear()
	term.clear()
	
	buttonAPI.Buttons = {}
end

---Creates a button.
---@param name string
---@param pX integer
---@param pY integer
---@param width integer
---@param height integer
---@param color integer
---@param callback function
---@return Button button
function buttonAPI.addButton(name, pX, pY, width, height, color, callback)
	---@class Button
	local newButton = {}
	newButton.Name = name
	newButton.X = pX
	newButton.Y = pY
	newButton.Width = width
	newButton.Height = height
	newButton.Color = color
	newButton.Callback = callback
	
	---Checks if the position is within the button.
	---@param x integer
	---@param y integer
	function newButton:inBounds(x, y)
		if (x >= self.X) and (x <= self.X + self.Width) then
			if (y >= self.Y) and (y <= self.Y + self.Height) then
				self.Callback()
				
				return true
			end
		end
		
		return false
	end
	
	function newButton:draw()
		paintutils.drawFilledBox(self.X, self.Y, self.X + self.Width - 1, self.Y + self.Height - 1, self.Color)
		term.setCursorPos(self.X + math.floor(self.Width / 2) - math.floor(string.len(self.Name) / 2), self.Y + math.floor(self.Height / 2))
		term.write(self.Name)
		
		term.setBackgroundColor(colors.black)
	end
	
	buttonAPI.Buttons[name] = newButton
	
	newButton:draw()
	
	return newButton
end

---Removes a button.
---@param name string
function buttonAPI.removeButton(name)
	buttonAPI.Buttons[name] = nil
end

---Checks all buttons and returns the one that was clicked.
---@param x integer
---@param y integer
---@return Button? clickedButton
function buttonAPI.click(x, y)
	for _, button in pairs(buttonAPI.Buttons) do
		local wasPressed = button:inBounds(x, y)
		
		if wasPressed then
			return button
		end
	end
	
	return nil
end

return buttonAPI