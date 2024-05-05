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
	local settingPath = usersettings.path('Fly/Tools', toolName)
	
	if usersettings.get(settingPath) then
		return string.format('Fly tool `%s` already exists.', toolName)
	end
	
	usersettings.set(settingPath, true)
	
	return string.format('Successfully added fly tool `%s`.', toolName)
end

---@param toolName string
function fly.removeTool(toolName)
	local settingPath = usersettings.path('Fly/Tools', toolName)
	
	if not usersettings.get(settingPath) then
		return string.format('`%s` not found.', toolName)
	end
	
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