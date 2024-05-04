local button = require('ShrugModules.button')
local bounding = require('ShrugModules.bounding')
local scan = require('ShrugModules.scan')
local fly = require('ShrugModules.fly')

local modules = peripheral.find('neuralInterface') --- @type Shrug.NeuralInterface

modules.canvas3d().clear()
modules.canvas().clear()

local canvas = modules.canvas()
local canvas3d = modules.canvas3d().create()

term.clear()
term.setCursorPos(1, 1)

local PLAYER_METADATA = nil --- @type EntitySensor.EntityMetadata
local PLAYER_ID = nil

---@type table<string, table<string, Shrug.Command>>
local CHAT_COMMANDS = {
	scan = {
		toggle = {
			DisplayOrder = 1,
			Arguments = '',
			Callback = function ()
				scan.Enabled = not scan.Enabled
				
				return string.format('Scanner %s.', scan.Enabled and 'enabled' or 'disabled')
			end
		},
		list = {
			DisplayOrder = 2,
			Arguments = '',
			Callback = function ()
				local output = 'Current blocks:\n'
				local whitelist = scan.BlockWhitelist
				
				for _, data in ipairs(whitelist) do
					output = output .. string.format('%s (%s)\n', data.Name, data.Alias)
				end
				
				output = output .. string.format('Count: %d', #whitelist)
				
				return output
			end
		},
		add = {
			DisplayOrder = 3,
			Arguments = '<block name> [alias] [color hex]',
			Callback = function (name, alias, color)
				return scan.addWhitelist(canvas, name, alias, color)
			end
		},
		remove = {
			DisplayOrder = 4,
			Arguments = '<block name>',
			Callback = function (name)
				return scan.removeWhitelist(name)
			end
		},
		clear = {
			DisplayOrder = 5,
			Arguments = '',
			Callback = function ()
				scan.clearWhitelist()
				
				return 'Cleared whitelist.'
			end
		},
	},
	fly = {
		toggle = {
			DisplayOrder = 1,
			Arguments = '',
			Callback = function ()
				fly.Enabled = not fly.Enabled
				
				return string.format('Flight %s.', fly.Enabled and 'enabled' or 'disabled')
			end
		},
		power = {
			DisplayOrder = 3,
			Arguments = '[power 0-4]',
			Callback = function (power)
				power = tonumber(power)
				
				if not power then
					return string.format('Current fly power is %.2f', fly.Power)
				end
				
				if power < 0 or power > 4 then
					return string.format('Inputted power `%.2f` is out of range! (0-4)', power)
				end
				
				fly.Power = power
				
				return string.format('Successfully set fly power to %.2f', power)
			end
		},
		list = {
			DisplayOrder = 4,
			Arguments = '',
			Callback = function ()
				return string.format('Current tools:\n%s', table.concat(fly.getTools(), '\n'))
			end
		},
		addtool = {
			DisplayOrder = 5,
			Arguments = '[item name]',
			Callback = function (tool)
				if not tool then
					local heldItem = PLAYER_METADATA.heldItem
					
					if heldItem then
						tool = heldItem.getMetadata().name
					end
				end
				
				if not tool then
					return 'No item selected!'
				end
				
				return fly.addTool(tool)
			end
		},
		removetool = {
			DisplayOrder = 6,
			Arguments = '[item name]',
			Callback = function (tool)
				if not tool then
					local heldItem = PLAYER_METADATA.heldItem
					
					if heldItem then
						tool = heldItem.getMetadata().name
					end
				end
				
				if not tool then
					return 'No item selected!'
				end
				
				return fly.removeTool(tool)
			end
		},
		cleartools = {
			DisplayOrder = 7,
			Arguments = '',
			Callback = function ()
				fly.clearTools()
				
				return 'Cleared tools.'
			end
		}
	}
}

---@param base string
---@param seperator string?
---@return string[]
local function split(base, seperator)
	local args = {}
	
	for value in string.gmatch(base, string.format('[^%s]+', seperator or '%s')) do
		table.insert(args, value)
	end
	
	return args
end

local function getCarrierID()
	local entities = modules.sense()
	
	for _, entity in ipairs(entities) do
		if entity.x == 0 and entity.y == 0 and entity.z == 0 then
			return entity.id
		end
	end
end

local function getCarrierMetadata()
	if not PLAYER_ID then
		PLAYER_ID = getCarrierID()
	end
	
	return modules.getMetaByID(PLAYER_ID)
end

local function setup()
	scan.Modules = modules
	fly.Modules = modules
	
	PLAYER_METADATA = getCarrierMetadata()
	
	for handlerName, container in pairs(CHAT_COMMANDS) do
		modules.capture(string.format('%%.(%s)', handlerName))
		
		container.help = {
			Arguments = '[command]',
			DisplayOrder = -1,
			Callback = function (commandName)
				if commandName then
					local data = container[commandName]
					
					return string.format('.%s %s %s', handlerName, commandName, data.Arguments)
				end
				
				local list = {}
				
				for name, command in pairs(container) do
					table.insert(list, {Name = name, Order = command.DisplayOrder})
				end
				
				table.sort(list, function (a, b)
					return a.Order < b.Order
				end)
				
				local output = string.format('%s Commands:\n', handlerName)
				
				for _, command in ipairs(list) do
					output = output .. string.format('%s\n', container.help.Callback(command.Name))
				end
				
				return output
			end
		}
	end
end

-------------------------------------

local function updateMetadata()
	while true do
		local data = getCarrierMetadata()
		
		if data ~= nil then
			PLAYER_METADATA = data
		end
	end
end

local function eventHandler()
	while true do
		local eventData = {os.pullEventRaw()}
		local event = eventData[1]
		
		if event == 'chat_capture' then
			local messageArgs = split(eventData[2])
			local handlerName = messageArgs[1]:sub(2)
			local commandName = messageArgs[2] or 'help'
			
			local output = nil
			local handler = CHAT_COMMANDS[handlerName]
			
			if handler then
				local command = handler[commandName]
					
				if command then
					_, output = pcall(command.Callback, table.unpack(messageArgs, 3))
					
					if output then
						output = split(output, '\n')
					end
				else
					output = {string.format('Invalid command `%s`', commandName)}
				end
			end
			
			if output then
				for _, text in ipairs(output) do
					modules.tell(text)
				end
			end
		elseif event == 'terminate' then
			modules.clearCaptures()
			canvas.clear()
			canvas3d.clear()
			
			modules.tell('Terminating...')
			
			return
		elseif event == 'mouse_click' then
			button.click(eventData[3], eventData[4])
			button.draw()
		end
	end
end

local function main()
	modules.tell('Shrug Client started!')
	
	local dbgText = canvas.addText({x=1,y=1}, '', 0xFF0000FF, 0.6)
	dbgText.setShadow(true)
	
	while true do
		local heldItem = PLAYER_METADATA.heldItem
		
		if fly.Enabled and PLAYER_METADATA.isSneaking and heldItem then
			if fly.isTool(heldItem.getMetadata().name) or not fly.RequiresTool then
				modules.launch(PLAYER_METADATA.yaw, PLAYER_METADATA.pitch, fly.Power)
			end
		end
		
		if scan.Enabled and scan.canScan() then
			scan.LastScan = os.clock()
			
			local scanned = modules.scan()
			local found = {}
			
			for _, block in ipairs(scanned) do
				local whitelisted, data = scan.isWhitelisted(block)
				
				if whitelisted and data then
					data.Count = data.Count + 1
					
					table.insert(found, {
						X = block.x,
						Y = block.y,
						Z = block.z,
						WhitelistData = data
					})
				end
			end
			
			local within = PLAYER_METADATA.withinBlock
			local meshed = bounding.mesh(found)
			
			canvas3d.recenter()
			canvas3d.clear()
			
			for _, data in ipairs(meshed) do
				local position = {
					x = data.X - within.x,
					y = data.Y - within.y,
					z = data.Z - within.z
				}
				
				local center = {
					x = position.x + data.SizeX / 2,
					y = position.y + data.SizeY / 2,
					z = position.z + data.SizeZ / 2
				}
				
				local box = canvas3d.addBox(position.x, position.y, position.z, data.SizeX, data.SizeY, data.SizeZ, data.Color)
				box.setDepthTested(false)
				box.setAlpha(scan.BoxAlpha)
				
				local frame = canvas3d.addFrame(center)
				frame.setDepthTested(false)
				frame.setRotation()
				frame.addText({x=0, y=0}, string.format('%s\n(%d)', data.Alias, data.Count), nil, 1.5)
				
				if scan.Tracers then
					local line = canvas3d.addLine({x = 0, y = -1, z = 0}, center, 2, data.Color)
					line.setDepthTested(false)
					line.setAlpha(scan.TracerAlpha)
				end
			end
			
			scan.updateLabels()
			scan.resetCounts()
		end
		
		sleep()
	end
end

setup()

parallel.waitForAny(eventHandler, updateMetadata, main)
