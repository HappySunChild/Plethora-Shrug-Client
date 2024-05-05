local usersettings = require('ShrugModules.usersettings')
usersettings.Settings.Client = {
	HostName = nil,
	Username = nil,
	Token = nil
}

local client = {}
client.SERVER_PROTOCOL = 'SHRUG_SERVER'
client.SERVER_ID = nil

client.LastMetadataPing = -1

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
	if usersettings.Settings.Client.HostName == nil or isRetry then
		write('Host Name: ')
		
		usersettings.Settings.Client.HostName = read()
	end
	
	local id = rednet.lookup(client.SERVER_PROTOCOL, usersettings.Settings.Client.HostName)
	
	if id then
		print('Valid host name.')
		
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
		Token = usersettings.get('Token'),
		Body = data,
	}
	
	return encoded
end

function client.invoke(protocol, data)
	local taskId = math.random(0, 9e6)
	
	rednet.send(client.SERVER_ID, encode(data, taskId), protocol)
	
	return receive(taskId, 8)
end

function client.isTokenValid()
	local responseData = client.invoke('VerifyToken')
	
	return responseData.IsValid
end

function client.login(isRetry)
	if usersettings.get('Username') == nil or isRetry then
		write('Enter Username: ')
		
		usersettings.set('Username', read())
	end
	
	local loginData = {
		Username = usersettings.get('Username')
	}
	
	local response = client.invoke('Login', loginData)
	
	if response then
		if not response.Success then
			printError(response.Message)
			
			return client.login(true)
		end
		
		local token = response.Body.Token
		
		print(string.format('\nLogin success!\nToken: %d', token))
		
		usersettings.set('Token', token)
	else
		printError('Timed out.')
		
		return client.login(true)
	end
end

---@return EntitySensor.EntityMetadata?
function client.getMetadata()
	if (os.clock() - client.LastMetadataPing) <= 0.2 then
		return
	end
	
	client.LastMetadataPing = os.clock()
	
	local response = client.invoke('GetMetadata')
	
	if response.Success then
		return response.Body.Metadata
	end
	
	printError(response.Message)
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