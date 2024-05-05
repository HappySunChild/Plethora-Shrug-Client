local usersettings = require('ShrugModules.usersettings')
usersettings.Settings.Client = {
	HostName = nil,
	Username = nil,
	Token = nil
}

local client = {}
client.SERVER_PROTOCOL = 'SHRUG_SERVER'
client.SERVER_ID = nil

local function receive(timeout)
	local id, content = rednet.receive('SERVER_RESPONSE', timeout)
	
	if id ~= client.SERVER_ID and id ~= nil then -- ignore other computers
		return receive(timeout)
	end
	
	return content
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
	
	print('Invalid host name!')
	
	return getServer(true)
end

function client.invoke(protocol, data)
	rednet.send(client.SERVER_ID, data, protocol)
	
	return receive(8)
end

function client.isTokenValid()
	local responseData = client.invoke('VerifyToken', {
		Token = usersettings.Settings.Client.Token
	})
	
	return responseData.IsValid
end

function client.login(isRetry)
	if usersettings.Settings.Client.Username == nil or isRetry then
		write('Enter Username: ')
		
		usersettings.Settings.Client.Username = read()
	end
	
	local loginData = {
		Username = usersettings.Settings.Client.Username
	}
	
	local response = client.invoke('Login', loginData)
	
	if response then
		if not response.Success then
			printError(response.Message)
			
			return client.login(true)
		end
		
		print(string.format('\nLogin success!\nToken: %d', response.Token))
		
		usersettings.Settings.Client.Token = response.Token
	else
		printError('Timed out.')
		
		return client.login(true)
	end
end

---@return EntitySensor.EntityMetadata
function client.getMetadata()
	local token = usersettings.Settings.Client.Token
	
	return client.invoke('GetMetadata', {
		Token = token
	})
end

function client.setup()
	local hasModem = peripheral.find('modem', function (name)
		rednet.open(name)
		
		return true
	end) ~= nil
	
	if not hasModem then
		return
	end
	
	if usersettings.Settings.Client.HostName == nil then
		write('Host Name: ')
		
		usersettings.Settings.Client.HostName = read()
	end
	
	client.SERVER_ID = getServer()
	
	if not client.isTokenValid() then -- if token isn't valid, log in and get a new one
		client.login()
	end
end

return client