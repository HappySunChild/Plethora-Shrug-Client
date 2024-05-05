local HOST_NAME = ''
local SERVER_PROTOCOL = 'SHRUG_SERVER'

local ID_CACHE = {}
local USER_MODULES = {
	Available = {}, ---@type table<integer, Peripheral.Manipulator|Modules.IntroSensor>
	InUse = {}, ---@type table<integer, Peripheral.Manipulator|Modules.IntroSensor>
}

local function newToken()
	local token = math.random(0, 9e6)
	
	if USER_MODULES.InUse[token] then
		return newToken()
	end
	
	return token
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

---@type table<string, ServerProtocol>
local PROTOCOLS = {
	Login = function (request, id)
		if ID_CACHE[id] then
			return true, 'ID Cache Login success.', {
				Token = ID_CACHE[id]
			}
		end
		
		local username = request.Body.Username or ''
		local userModule = USER_MODULES.Available[username]
		
		if userModule == nil then
			return false, 'Username is not available.'
		end
		
		local token = newToken()
		
		USER_MODULES.Available[username] = nil
		USER_MODULES.InUse[token] = userModule
		ID_CACHE[id] = token
		
		return true, 'Success', {
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
		local token = tonumber(request.Token) or 0
		local userModule = USER_MODULES.InUse[token]
		
		if not token or not userModule then
			return false, 'Missing token.'
		end
		
		local inventory = userModule.getInventory()
		
		for slot, _ in pairs(inventory.list()) do
			local meta = inventory.getItemMeta(slot)
			
			if meta.maxCount == 64 and meta.count > 8 then
				inventory.drop(slot)
			end
		end
		
		return true, 'Success'
	end,
	
	GetInventory = function (request)
		local token = tonumber(request.Token) or 0
		local userModule = USER_MODULES.InUse[token]
		
		if not token or not userModule then
			return false, 'Missing token'
		end
		
		local inventory = userModule.getInventory()
		
		recurse(inventory.list(), function (tbl, slot)
			inventory[slot] = inventory.getItemMeta(slot)
		end)
		
		return true, 'Success', {
			Inventory = nil
		}
	end,
	GetMetadata = function (request)
		local token = tonumber(request.Token) or 0
		local userModule = USER_MODULES.InUse[token]
		
		if not token or not userModule then
			return false, 'Missing token'
		end
		
		local metadata = userModule.getMetaOwner()
		
		recurse(metadata, function (tbl, index, value)
			if index == 'getMetadata' then
				tbl.metadata = value()
			end
		end)
		
		return true, 'Success', {
			Metadata = metadata
		}
	end,
}

local function setup()
	term.clear()
	term.setCursorPos(1, 1)
	
	write('Host Name: ')
	HOST_NAME = read()
	
	print(('\nHosting %s as "%s"'):format(SERVER_PROTOCOL, HOST_NAME))
	
	peripheral.find('modem', rednet.open)
	rednet.host(SERVER_PROTOCOL, HOST_NAME)
	
	print('Server is now discoverable via rednet.\n')
	
	local modules = {peripheral.find('manipulator')} ---@type (Peripheral.Manipulator | Modules.IntroSensor)[]
	
	for _, userModule in ipairs(modules) do
		local name = userModule.getName()
		local side = peripheral.getName(userModule)
		
		USER_MODULES.Available[name] = userModule
		
		print(('UserModule for `%s` detected on %s.'):format(name, side))
	end
end

setup()

while true do
	---@type integer, ClientRequest, string?
	local id, request, protocol = rednet.receive()
	
	local function respond(responseData)
		rednet.send(id, responseData, 'SERVER_RESPONSE')
	end
	
	--print(string.format('%s:%d %s (%s)', protocol, id, request, request.TaskID))
	
	local callback = PROTOCOLS[tostring(protocol)]
	
	if callback then
		local success, message, responseData = callback(request, id)
		
		respond({
			Success = success,
			Message = message,
			TaskID = request.TaskID,
			
			Body = responseData or {}
		})
	end
end