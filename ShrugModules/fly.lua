local fly = {}
fly.Modules = nil ---@type Shrug.NeuralInterface
fly.Enabled = false
fly.RequiresTool = true
fly.Power = 1
fly.Tools = {
	['plethora:neuralconnector'] = true
}

---Returns a list of currently active fly tools.
---@return string[]
function fly.getTools()
	local tools = {}
	
	for tool, _ in pairs(fly.Tools) do
		table.insert(tools, tool)
	end
	
	return tools
end

---Adds a tool to the list of tools used to fly.
---@param toolName string
function fly.addTool(toolName)
	if fly.Tools[toolName] then
		return string.format('Fly tool `%s` already exists.', toolName)
	end
	
	fly.Tools[toolName] = true
	
	return string.format('Successfully added fly tool `%s`.', toolName)
end

---Removes a tool from the list of tools used to fly.
---@param toolName string
function fly.removeTool(toolName)
	if not fly.Tools[toolName] then
		return string.format('`%s` not found.', toolName)
	end
	
	fly.Tools[toolName] = nil
	
	return string.format('Successfully removed fly tool `%s`.', toolName)
end

---Clears the list of tools used to fly.
function fly.clearTools()
	fly.Tools = {
		['plethora:neuralconnector'] = true
	}
end

---Returns whether the passed tool is in the tools list.
---@param toolName string
---@return boolean isTool
function fly.isTool(toolName)
	return fly.Tools[toolName] ~= nil
end

return fly