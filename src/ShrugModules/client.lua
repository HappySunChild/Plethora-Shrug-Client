local usersettings = require('ShrugModules.usersettings')
usersettings.set('Client', {
	HostName = nil,
	Username = nil,
	Token = nil
})

local client = {}
client.SERVER_PROTOCOL = 'SHRUG_SERVER'
client.SERVER_ID = nil

---@param taskid number
---@param timeout? number
---@return ServerResponse
local function receive(taskid, timeout)
	---@type integer?, ServerResponse?
	local id, content = rednet.receive('SERVER_RESPONSE', timeout)
	
	if id ~= client.SERVER_ID and id ~= nil and content and content.TaskID == taskid then -- ignore other computers
		return receive(taskid, timeout)
	end
	
	return content or {
		Success = false,
		Message = 'Timed out.'
	}
end

local function getServer(isRetry)
	if usersettings.get('Client/HostName') == nil or isRetry then
		write('Host Name: ')
		
		usersettings.set('Client/HostName', read())
	end
	
	local id = rednet.lookup(client.SERVER_PROTOCOL, usersettings.get('Client/HostName'))
	
	if id then
		print(('Valid host name.\nServer ID: %d'):format(id))
		
		return id
	end
	
	print('No response from host name.')
	
	return getServer(true)
end

---@param data any
---@return ClientRequest
local function encode(data, id)
	local encoded = {
		TaskID = id,
		Token = usersettings.get('Client/Token'),
		Body = data,
	}
	
	return encoded
end

function client.invoke(protocol, data, timeout)
	local taskId = math.random(0, 0xFFFFFF)
	
	rednet.send(client.SERVER_ID, encode(data, taskId), protocol)
	
	return receive(taskId, tonumber(timeout) or 8)
end

function client.isTokenValid()
	local responseData = client.invoke('VerifyToken')
	
	return responseData.IsValid
end

function client.login(isRetry)
	if usersettings.get('Client/Username') == nil or isRetry then
		write('Enter Username: ')
		
		usersettings.set('Client/Username', read())
	end
	
	local loginData = {
		Username = usersettings.get('Client/Username')
	}
	
	local response = client.invoke('Login', loginData)
	
	if response then
		if not response.Success then
			printError(response.Message)
			
			return client.login(true)
		end
		
		local token = response.Body.Token
		
		print(string.format('\n%s\nToken: %d', response.Message, token))
		
		usersettings.set('Client/Token', token)
	end
end

---@return table<number, Inventory.ItemMetadata>?
function client.getInventory()
	local response = client.invoke('GetInventory')
	
	if response.Success then
		return response.Body.Inventory
	end
	
	printError(response.Message)
end

function client.setup()
	local hasModem = peripheral.find('modem', function (name)
		rednet.open(name)
		
		return true
	end) ~= nil
	
	if not hasModem then
		return
	end
	
	client.SERVER_ID = getServer()
	
	if not client.isTokenValid() then -- if token isn't valid, log in and get a new one
		client.login()
	end
end

return client