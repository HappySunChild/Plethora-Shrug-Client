local HOST_NAME = ''
local SERVER_PROTOCOL = 'SHRUG_SERVER'

local ID_CACHE = {}
local USER_MODULES = {
	Available = {}, ---@type table<string, UserModule>
	InUse = {}, ---@type table<integer, UserModule>
}

local TIMERS = {}

local function delay(time, callback)
	local id = os.startTimer(time)
	
	TIMERS[id] = function ()
		TIMERS[id] = nil
		
		if callback() == 'rerun' then -- rerun
			delay(time, callback)
		end
	end
end

---@return UserModule? module
---@return string message
local function getModuleFromToken(token)
	if not token then
		return nil, 'Missing token'
	end
	
	local userModule = USER_MODULES.InUse[tonumber(token) or 0]
	
	if not userModule then
		return nil, 'Invalid token'
	end
	
	return userModule, 'Success'
end

---@return UserModule? module
local function getModuleFromUsername(username)
	for _, userModule in pairs(USER_MODULES.InUse) do
		if userModule.Username == username then
			return userModule
		end
	end
	
	return nil
end

---@generic K, V
---@param tbl table<K, V>
---@param callback fun(tbl: table, index: K, value: V)
local function recurse(tbl, callback)
	for index, value in pairs(tbl) do
		if type(value) == 'table' then
			recurse(value, callback)
		end
		
		callback(tbl, index, value)
	end
end

local function newToken()
	local token = math.random(0, 9e6)
	
	if USER_MODULES.InUse[token] then
		return newToken()
	end
	
	return token
end

---@type table<string, ServerProtocol>
local PROTOCOLS = {
	Login = function (request, id)
		if ID_CACHE[id] then
			return true, 'Cache Login success.', {
				Token = ID_CACHE[id]
			}
		end
		
		local username = request.Body.Username or ''
		local userModule = USER_MODULES.Available[username]
		
		if userModule == nil then
			return false, 'Username is not available!'
		end
		
		local token = newToken()
		
		USER_MODULES.Available[username] = nil
		USER_MODULES.InUse[token] = userModule
		ID_CACHE[id] = token
		
		userModule.CurrentID = id
		
		return true, 'Login success.', {
			Token = token
		}
	end,
	VerifyToken = function (request)
		local token = tonumber(request.Token) or 0
		
		return true, 'Success', {
			IsValid = USER_MODULES.InUse[token] ~= nil
		}
	end,
	
	Drop = function (request)
		local userModule, message = getModuleFromToken(request.Token)
		
		if not userModule then
			return false, message
		end
		
		local inventory = userModule.Manipulator.getInventory()
		
		for slot, _ in pairs(inventory.list()) do
			local meta = inventory.getItemMeta(slot)
			
			if (meta.maxCount >= 32 and meta.count > 4 and not meta.saturation) or (meta.count == 1 and meta.damage >= (meta.maxDamage * 0.8) and meta.damage ~= 0) then
				inventory.drop(slot)
			end
		end
		
		return true, 'Success'
	end,
	Suck = function (request)
		local userModule, message = getModuleFromToken(request.Token)
		
		if not userModule then
			return false, message
		end
		
		local inventory = userModule.Manipulator.getInventory()
		
		print(inventory.suck())
		
		return true, 'Success'
	end,
	Give = function (request)
		local userModule, message = getModuleFromToken(request.Token)
		
		if not userModule then
			return false, message
		end
		
		local targetModule = getModuleFromUsername(request.Body.Username)
		
		if not targetModule then
			return false, 'User does not exist.'
		end
		
		local equipment = userModule.Manipulator.getEquipment()
		local inventory = targetModule.Manipulator.getInventory()
		
		equipment.pushItems('bottom', 1)
		inventory.pullItems('bottom', 1)
		
		return true, 'Success'
	end,
	
	GetInventory = function (request)
		local userModule, message = getModuleFromToken(request.Token)
		
		if not userModule then
			return false, message
		end
		
		local inventory = userModule.Manipulator.getInventory()
		
		recurse(inventory.list(), function (_, slot)
			inventory[slot] = inventory.getItemMeta(slot)
		end)
		
		return true, 'Success', {
			Inventory = nil
		}
	end,
}

local function log(...)
	print(...)
	
	local x, y = term.getCursorPos()
	
	term.setTextColor(colors.yellow)
	term.setCursorPos(1, 1)
	term.clearLine()
	term.write(('Hosting %s as "%s"'):format(SERVER_PROTOCOL, HOST_NAME))
	
	term.setTextColor(colors.white)
	term.setCursorPos(x, y)
end

local function setup()
	term.clear()
	term.setCursorPos(1, 1)
	
	write('Host Name: ')
	HOST_NAME = read()
	
	peripheral.find('modem', rednet.open)
	rednet.host(SERVER_PROTOCOL, HOST_NAME)
	
	log('Server is now discoverable via rednet.\n')
	
	local found = {peripheral.find('manipulator')} ---@type (Peripheral.Manipulator | Modules.IntroSensor)[]
	
	for _, manipulator in ipairs(found) do
		local name = manipulator.getName()
		local side = peripheral.getName(manipulator)
		
		---@type UserModule
		local UserModule = {
			Username = name,
			Side = side,
			
			Manipulator = manipulator,
			Settings = {}
		}
		
		USER_MODULES.Available[name] = UserModule
		
		log(('UserModule for `%s` detected on %s.'):format(name, side))
	end
end

------------------------------------------------------

local function rednetHandler()
	while true do
		---@type integer, ClientRequest, string?
		local id, request, protocol = rednet.receive()
		
		local function respond(responseData)
			rednet.send(id, responseData, 'SERVER_RESPONSE')
		end
		
		log(('[%s]: %d (%s)'):format(protocol, id, request.TaskID))
		
		local callback = PROTOCOLS[tostring(protocol)]
		
		if callback then
			local success, message, responseData = callback(request, id)
			
			respond({
				Success = success,
				Message = message,
				TaskID = request.TaskID,
				
				Body = responseData or {}
			})
		else
			respond({
				Success = false,
				Message = 'Invalid protocol.'
			})
		end
	end
end

local function timerHandler()
	while true do
		local _, id = os.pullEvent('timer')
		local callback = TIMERS[id]
		
		if callback then
			callback()
		end
	end
end

setup()

parallel.waitForAll(rednetHandler, timerHandler)