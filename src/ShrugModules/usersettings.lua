local usersettings = {}
usersettings.SAVE_PATH = '.shrugsettings'
usersettings.Settings = {}

local function recurse(tbl, callback)
	local var = nil
	
	for index, value in pairs(tbl) do
		var = callback(tbl, index, value)
		
		if var then
			return var
		end
		
		if type(value) == 'table' then
			var = recurse(value, callback)
		end
		
		if var then
			return var
		end
	end
	
	return var
end

function usersettings.save()
	settings.set('ShrugSettings', usersettings.Settings)
	settings.save(usersettings.SAVE_PATH)
end

function usersettings.load()
	settings.load(usersettings.SAVE_PATH)
	usersettings.Settings = settings.get('ShrugSettings', usersettings.Settings)
end

function usersettings.get(settingName)
	return recurse(usersettings.Settings, function (_, index, value)
		if index == settingName then
			return value
		end
	end)
end

function usersettings.set(settingName, value)
	return recurse(usersettings.Settings, function (tbl, index)
		if index == settingName then
			tbl[index] = value
			
			return true
		end
	end)
end

return usersettings