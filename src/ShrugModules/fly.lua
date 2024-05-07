local usersettings = require('ShrugModules.usersettings')
usersettings.set('Fly', {
	RequiresTool = true,
	Power = 1,
	Tools = {
		['plethora:neuralconnector'] = true
	}
})

local fly = {}
fly.Enabled = false

function fly.setPower(power)
	power = tonumber(power)
	
	if not power then
		return string.format('Current fly power is %.2f', usersettings.get('Fly/Power'))
	end
	
	if power < 0 or power > 4 then
		return string.format('Power `%.2f` is out of range! (0-4)', power)
	end
	
	--fly.Settings.Power = power
	usersettings.set('Fly/Power', power)
	
	return string.format('Fly power is now %.2f', power)
end

---@return string[]
function fly.getTools()
	local tools = {}
	
	for tool, _ in pairs(usersettings.get('Fly/Tools')) do
		table.insert(tools, tool)
	end
	
	return tools
end

---@param toolName string
function fly.addTool(toolName)
	if fly.isTool(toolName) then
		return string.format('Fly tool `%s` already exists.', toolName)
	end
	
	local settingPath = usersettings.path('Fly/Tools', toolName)
	usersettings.set(settingPath, true)
	
	return string.format('Successfully added fly tool `%s`.', toolName)
end

---@param toolName string
function fly.removeTool(toolName)
	if not fly.isTool(toolName) then
		return string.format('`%s` not found.', toolName)
	end
	
	local settingPath = usersettings.path('Fly/Tools', toolName)
	usersettings.set(settingPath, nil)
	
	return string.format('Successfully removed fly tool `%s`.', toolName)
end

function fly.clearTools()
	usersettings.set('Fly/Tools', {
		['plethora:neuralconnector'] = true
	})
end

---@param toolName string
---@return boolean isTool
function fly.isTool(toolName)
	local settingPath = usersettings.path('Fly/Tools', toolName)
	
	return usersettings.get(settingPath) ~= nil
end

return fly