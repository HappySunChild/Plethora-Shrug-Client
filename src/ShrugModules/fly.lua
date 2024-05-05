local usersettings = require('ShrugModules.usersettings')
usersettings.Settings.Fly = {
	RequiresTool = true,
	Power = 1,
	Tools = {
		['plethora:neuralconnector'] = true
	}
}

local fly = {}
fly.Enabled = false

---Returns a list of currently active fly tools.
---@return string[]
function fly.getTools()
	local tools = {}
	
	for tool, _ in pairs(usersettings.Settings.Fly.Tools) do
		table.insert(tools, tool)
	end
	
	return tools
end

---Adds a tool to the list of tools used to fly.
---@param toolName string
function fly.addTool(toolName)
	if usersettings.Settings.Fly.Tools[toolName] then
		return string.format('Fly tool `%s` already exists.', toolName)
	end
	
	usersettings.Settings.Fly.Tools[toolName] = true
	
	return string.format('Successfully added fly tool `%s`.', toolName)
end

---Removes a tool from the list of tools used to fly.
---@param toolName string
function fly.removeTool(toolName)
	if not usersettings.Settings.Fly.Tools[toolName] then
		return string.format('`%s` not found.', toolName)
	end
	
	usersettings.Settings.Fly.Tools[toolName] = nil
	
	return string.format('Successfully removed fly tool `%s`.', toolName)
end

---Clears the list of tools used to fly.
function fly.clearTools()
	usersettings.Settings.Fly.Tools = {
		['plethora:neuralconnector'] = true
	}
end

---Returns whether the passed tool is in the tools list.
---@param toolName string
---@return boolean isTool
function fly.isTool(toolName)
	return usersettings.Settings.Fly.Tools[toolName] ~= nil
end

return fly