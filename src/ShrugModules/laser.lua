local usersettings = require('ShrugModules.usersettings')
usersettings.set('Laser', {
	Radius = 15,
	Potency = 1,
	
	KillAura = {
		Whitelist = {}
	}
})

local laser = {}
laser.Enabled = false
laser.KillAura = {
	Enabled = false,
	HealthCache = {}
}

function laser.setRadius(radius)
	radius = tonumber(radius)
	
	if not radius then
		return ('Current laser radius is %d degrees.'):format(usersettings.get('Laser/Radius'))
	end
	
	usersettings.set('Laser/Radius', radius)
	
	return ('Laser radius is now %d degrees.'):format(radius)
end

function laser.setPotency(potency)
	potency = tonumber(potency)
	
	if not potency then
		return ('Current laser potency is %.2f.'):format(usersettings.get('Laser/Potency'))
	end
	
	if potency < 0.5 or potency > 5 then
		return ('Potency `%.2f` is out of range! (0.5-5)'):format(potency)
	end
	
	usersettings.set('Laser/Potency', potency)
	
	return ('Laser potency is now %.2f.'):format(potency)
end

--------------------------------------------

function laser.getWhitelist()
	local whitelist = {}
	
	for name, _ in pairs(usersettings.get('Laser/KillAura/Whitelist')) do
		table.insert(whitelist, name)
	end
	
	return whitelist
end

function laser.isEntityWhitelisted(name)
	local path = usersettings.path('Laser/KillAura/Whitelist', string.lower(name))
	
	return usersettings.get(path) ~= nil
end

function laser.whitelistEntity(name)
	name = string.lower(name)
	
	if laser.isEntityWhitelisted(name) then
		return ('Entity `%s` is already whitelisted.'):format(name)
	end
	
	usersettings.set(usersettings.path('Laser/KillAura/Whitelist', name), true)
	
	return ('Successfully whitelisted entity `%s`.'):format(name)
end

function laser.unwhitelistEntity(name)
	name = string.lower(name)
	
	if not laser.isEntityWhitelisted(name) then
		return ('`%s` not found.'):format(name)
	end
	
	usersettings.set(usersettings.path('Laser/KillAura/Whitelist', name), nil)
	
	return ('Successfully unwhitelisted entity `%s`.'):format(name)
end

function laser.clearWhitelist()
	usersettings.set('Laser/KillAura/Whitelist', {})
end

return laser