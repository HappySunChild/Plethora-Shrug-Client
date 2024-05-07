local bounding = require('ShrugModules.bounding')
local usersettings = require('ShrugModules.usersettings')

local laser = require('ShrugModules.laser')
local scan = require('ShrugModules.scan')
local fly = require('ShrugModules.fly')
local client = require('ShrugModules.client')

local modules = peripheral.find('neuralInterface') --- @type NeuralInterface

local CANVAS = nil ---@type OverlayGlasses.Canvas2d
local SCANNER_CANVAS = nil ---@type OverlayGlasses.Canvas3d.Canvas

local PLAYER_METADATA = nil --- @type EntitySensor.EntityMetadata
local PLAYER_ID = nil

---@type table<string, CommandHandler>
local CHAT_COMMANDS = {
	scan = {
		Predicate = function ()
			return modules.hasModule('plethora:scanner'), 'This feature requires a block scanner!'
		end,
		Commands = {
			toggle = {
				DisplayOrder = 1,
				Arguments = '',
				Callback = function ()
					scan.Enabled = not scan.Enabled
					
					SCANNER_CANVAS.clear()
					scan.updateLabels()
					
					return ('Scanner %s.'):format(scan.Enabled and 'enabled' or 'disabled')
				end
			},
			list = {
				DisplayOrder = 2,
				Arguments = '[saved]',
				Callback = function (saved)
					if saved == 'saved' then
						return 'saved'
					end
					
					local output = 'Current blocks:\n'
					local whitelist = scan.getWhitelist()
					
					for _, data in ipairs(whitelist) do
						output = output .. ('%s (%s)\n'):format(data.Name, data.Alias)
					end
					
					output = output .. ('Count: %d'):format(#whitelist)
					
					return output
				end
			},
			add = {
				DisplayOrder = 3,
				Arguments = '<block name> [alias] [color hex]',
				Callback = function (name, alias, color)
					return scan.whitelistBlock(CANVAS, name, alias, color)
				end
			},
			remove = {
				DisplayOrder = 4,
				Arguments = '<block name>',
				Callback = function (name)
					return scan.unwhitelistBlock(name)
				end
			},
			saves = {
				DisplayOrder = 5,
				Arguments = '<action> <name>',
				Callback = function (action, whitelistName)
					if action == 'save' then
						return scan.saveWhitelist(whitelistName)
					elseif action == 'load' then
						return scan.loadWhitelist(CANVAS, whitelistName)
					elseif action == 'remove' then
						return scan.removeWhitelist(whitelistName)
					elseif action == 'list' or action == nil then
						local list = {}
						
						for name, whitelist in pairs(usersettings.get('Scan/SavedWhitelists')) do
							local count = 0
							
							for _, _ in pairs(whitelist) do
								count = count + 1
							end
							
							table.insert(list, ('%s (%d entries)'):format(name, count))
						end
						
						return ('Saved whitelists:\n%s'):format(table.concat(list, '\n'))
					end
				end
			},
			clear = {
				DisplayOrder = 10,
				Arguments = '',
				Callback = function ()
					scan.clearWhitelist()
					
					return 'Cleared whitelist.'
				end
			},
			setalpha = {
				DisplayOrder = 20,
				Arguments = '<tracers|boxes> <alpha>',
				Callback = function (mode, alpha)
					local alpha = tonumber(alpha) or 100
					
					if mode == 'tracers' then
						usersettings.set('Scan/TracerAlpha', alpha)
					elseif mode == 'boxes' then
						usersettings.set('Scan/BoxAlpha', alpha)
					else
						return 'Invalid tracer type.'
					end
					
					return ('`%s` alpha is now %d.'):format(mode, alpha)
				end
			},
			setinterval = {
				DisplayOrder = 21,
				Arguments = '<interval>',
				Callback = function (interval)
					local time = tonumber(interval) or 0.2
					
					usersettings.set('Scan/ScanInterval', time)
					
					return ('Scan interval is now %.2f.'):format(time)
				end
			},
		}
	},
	laser = {
		Predicate = function ()
			return modules.hasModule('plethora:laser'), 'This feature requires a laser gun!'
		end,
		Commands = {
			toggle = {
				DisplayOrder = 1,
				Arguments = '',
				Callback = function ()
					laser.Enabled = not laser.Enabled
					
					return ('Laser %s.'):format(laser.Enabled and 'enabled' or 'disabled')
				end
			},
			radius = {
				DisplayOrder = 2,
				Arguments = '[degrees]',
				Callback = function (degrees)
					return laser.setRadius(degrees)
				end
			},
			potency = {
				DisplayOrder = 3,
				Arguments = '[potency 0.5-5]',
				Callback = function (potency)
					return laser.setPotency(potency)
				end
			},
		}
	},
	killaura = {
		Predicate = function ()
			return modules.hasModule('plethora:laser'), 'Thise feature requires a laser gun!'
		end,
		Commands = {
			toggle = {
				DisplayOrder = 1,
				Arguments = '',
				Callback = function ()
					laser.KillAura.Enabled = not laser.KillAura.Enabled
					
					return ('Killaura %s.'):format(laser.KillAura.Enabled and 'enabled' or 'disabled')
				end
			},
			list = {
				DisplayOrder = 2,
				Arguments = '',
				Callback = function ()
					local list = laser.getWhitelist()
					local output = ('Current whitelist:\n%s\nCount: %d'):format(table.concat(list, '\n'), #list)
					
					return output
				end
			},
			add = {
				DisplayOrder = 3,
				Arguments = '<name>',
				Callback = function (name)
					return laser.whitelistEntity(name)
				end
			},
			remove = {
				DisplayOrder = 4,
				Arguments = '<name>',
				Callback = function (name)
					return laser.unwhitelistEntity(name)
				end
			},
			clear = {
				DisplayOrder = 5,
				Arguments = '',
				Callback = function ()
					laser.clearWhitelist()
					
					return 'Cleared whitelist.'
				end
			}
		}
	},
	fly = {
		Predicate = function ()
			return modules.hasModule('plethora:kinetic'), 'This feature requires a kinetic augment!'
		end,
		Commands = {
			toggle = {
				DisplayOrder = 1,
				Arguments = '',
				Callback = function ()
					fly.Enabled = not fly.Enabled
					
					return ('Flight %s.'):format(fly.Enabled and 'enabled' or 'disabled')
				end
			},
			power = {
				DisplayOrder = 3,
				Arguments = '[power 0-4]',
				Callback = function (power)
					return fly.setPower(power)
				end
			},
			list = {
				DisplayOrder = 4,
				Arguments = '',
				Callback = function ()
					return ('Current tools:\n%s'):format(table.concat(fly.getTools(), '\n'))
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
			},
			toggletool = {
				DisplayOrder = 9,
				Arguments = '',
				Callback = function ()
					local newValue = not usersettings.get('Fly/RequiresTool')
					usersettings.set('Fly/RequiresTool', newValue)
					
					return newValue and 'Tools are now required to fly.' or 'Tools are no longer required to fly.'
				end
			}
		}
	},
	remote = {
		Predicate = function ()
			return client.SERVER_ID ~= nil, 'Server is not set up!'
		end,
		Commands = {
			drop = {
				Arguments = '',
				DisplayOrder = 1,
				Callback = function ()
					modules.tell('Requesting drop...')
					
					return client.invoke('Drop').Message
				end
			},
			suck = {
				Arguments = '',
				DisplayOrder = 2,
				Callback = function ()
					modules.tell('Requesting pickup...')
					
					return client.invoke('Suck').Message
				end
			},
			give = {
				Arguments = '<username>',
				DisplayOrder = 3,
				Callback = function (username)
					if not username then
						return 'Missing username'
					end
					
					modules.tell(('Requesting give to %s...'):format(username))
					
					return client.invoke('Give', {
						Username = username
					}).Message
				end
			}
		}
	},
	settings = {
		Commands = {
			save = {
				Arguments = '',
				DisplayOrder = 1,
				Callback = function ()
					usersettings.save()
					
					return 'Successfully saved settings.'
				end
			}
		}
	}
}

---@param base string
---@param seperator string?
---@return string[]
local function split(base, seperator)
	local args = {}
	
	for value in string.gmatch(base, ('[^%s]+'):format(seperator or '%s')) do
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
	term.clear()
	term.setCursorPos(1, 1)
	
	assert(modules.hasModule('plethora:sensor'), 'Missing entity sensor!')
	assert(modules.hasModule('plethora:glasses'), 'Missing overlay glasses!')
	assert(modules.hasModule('plethora:chat'), 'Missing chat recorder!')
	
	modules.canvas3d().clear()
	modules.canvas().clear()
	
	CANVAS = modules.canvas()
	SCANNER_CANVAS = modules.canvas3d().create()
	
	for handlerName, container in pairs(CHAT_COMMANDS) do
		modules.capture(('^[%%.,;:]%s'):format(handlerName))
		
		if not container.Commands.help then
			container.Commands.help = {
				Arguments = '[command]',
				DisplayOrder = -1,
				Callback = function (commandName)
					if commandName then
						local data = container.Commands[commandName]
						
						return ('.%s %s %s'):format(handlerName, commandName, data.Arguments)
					end
					
					local list = {}
					
					for name, command in pairs(container.Commands) do
						table.insert(list, {Name = name, Order = command.DisplayOrder})
					end
					
					table.sort(list, function (a, b)
						return a.Order < b.Order
					end)
					
					local output = ('%s Commands:\n'):format(handlerName)
					
					for _, command in ipairs(list) do
						output = output .. ('%s\n'):format(container.Commands.help.Callback(command.Name))
					end
					
					return output
				end
			}
		end
	end
	
	print('Loading settings...')
	
	usersettings.load()
	
	print('Setting up client...\n')
	
	client.setup()
	
	PLAYER_METADATA = getCarrierMetadata()
end

-------------------------------------

local function main()
	modules.tell('Shrug Client started!')
	
	while true do
		local heldItem = PLAYER_METADATA.heldItem
		local offhandItem = PLAYER_METADATA.offhandItem
		
		if fly.Enabled and PLAYER_METADATA.isSneaking then
			local hasTool = false
			local requiresTool = usersettings.get('Fly/RequiresTool')
			
			if requiresTool then
				if heldItem then
					hasTool = fly.isTool(heldItem.getMetadata().name) or hasTool
				end
				
				if offhandItem then
					hasTool = fly.isTool(offhandItem.getMetadata().name) or hasTool
				end
			end
			
			if hasTool or not requiresTool then
				modules.launch(PLAYER_METADATA.yaw, PLAYER_METADATA.pitch, usersettings.get('Fly/Power'))
			end
		end
		
		if scan.Enabled and scan.canScan() then
			scan.LastScan = os.clock()
			
			local scanned = modules.scan()
			local found = {}
			
			for _, block in ipairs(scanned) do
				local whitelisted, data = scan.isBlockWhitelisted(block)
				
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
			
			SCANNER_CANVAS.recenter()
			SCANNER_CANVAS.clear()
			
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
				
				local box = SCANNER_CANVAS.addBox(position.x, position.y, position.z, data.SizeX, data.SizeY, data.SizeZ, data.Color)
				box.setDepthTested(false)
				box.setAlpha(usersettings.get('Scan/BoxAlpha'))
				
				local frame = SCANNER_CANVAS.addFrame(center)
				frame.setDepthTested(false)
				frame.setRotation()
				frame.addText({x=0, y=0}, ('%s\n(%d)'):format(data.Alias, data.Count), nil, 1.6)
				
				if usersettings.get('Scan/DrawTracers') then
					local line = SCANNER_CANVAS.addLine({x = 0, y = -1, z = 0}, center, 2, data.Color)
					line.setDepthTested(false)
					line.setAlpha(usersettings.get('Scan/TracerAlpha'))
				end
			end
			
			scan.updateLabels()
			scan.resetCounts()
		end
		
		sleep()
	end
end

local function updateMetadata()
	while true do
		local data = getCarrierMetadata()
		
		if data ~= nil then
			PLAYER_METADATA = data
		end
		
		sleep()
	end
end

local function laserHandler()
	if not modules.hasModule('plethora:laser') then
		return
	end
	
	while true do
		if laser.KillAura.Enabled then
			local healthCache = laser.KillAura.HealthCache
			local candidates = {} ---@type EntitySensor.EntityData[]
			
			for _, entity in ipairs(modules.sense()) do
				if laser.isEntityWhitelisted(entity.name) then
					if not healthCache[entity.name] then
						local metadata = modules.getMetaByID(entity.id)
						
						healthCache[entity.name] = metadata.maxHealth
					end
					
					table.insert(candidates, entity)
				end
			end
			
			for _, entity in ipairs(candidates) do
				local calculatedPotency = math.min(math.max(healthCache[entity.name] / 40, 0.5), 5)
				local x, y, z = entity.x, entity.y, entity.z
				
				local yaw = math.deg(-math.atan2(x, z))
				local pitch = math.deg(-math.atan2(y, math.sqrt(x ^ 2 + z ^ 2)))
				
				modules.fire(yaw, pitch, calculatedPotency)
			end
		end
		
		if laser.Enabled then
			local radius = usersettings.get('Laser/Radius')
			local potency = usersettings.get('Laser/Potency')
			
			for i = 1, radius do
				local x = (i / radius) * math.pi
				
				for t = -1, 1, 0.5 do
					if not laser.Enabled then
						break
					end
					
					local yaw = PLAYER_METADATA.yaw + math.sin(x) * radius * t
					local pitch = PLAYER_METADATA.pitch + math.cos(x) * radius * t
					
					modules.fire(yaw, pitch, potency)
				end
			end
		end
		
		sleep()
	end
end

local function eventHandler()
	while true do
		local eventData = {os.pullEventRaw()}
		local event = eventData[1]
		
		if event == 'chat_capture' then
			local messageArgs = split(eventData[2])
			local handlerName = messageArgs[1]:sub(2)
			
			local handler = CHAT_COMMANDS[handlerName]
			
			if handler then
				local runnable, message = true, ''
				
				if handler.Predicate then
					runnable, message = handler.Predicate()
				end
				
				if runnable then
					local index = messageArgs[2] or 'help'
					local command = handler.Commands[index]
					
					local output = nil
						
					if command then
						_, output = pcall(command.Callback, table.unpack(messageArgs, 3))
						
						if output then
							output = split(output, '\n')
						end
					else
						output = {('Invalid command `%s`'):format(index)}
					end
					
					if output then
						for _, text in ipairs(output) do
							modules.tell(text)
						end
					end
				else
					modules.tell(message)
				end
			end
		elseif event == 'terminate' then
			modules.clearCaptures()
			CANVAS.clear()
			SCANNER_CANVAS.clear()
			
			usersettings.save()
			
			modules.tell('Terminating...')
			
			return
		end
	end
end

setup()

parallel.waitForAll(eventHandler, laserHandler, updateMetadata, main)