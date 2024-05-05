local usersettings = {}
usersettings.SAVE_PATH = '.shrugsettings'
usersettings.Settings = {}

local function split(base, seperator)
	local tbl = {}
	
	for str in string.gmatch(base, ('[^%s]+'):format(seperator)) do
		table.insert(tbl, str)
	end
	
	return tbl
end

local function parsePath(path)
	local dirs = split(path, '/')
	
	local current = usersettings.Settings
	local target = table.remove(dirs, #dirs)
	
	for _, dirName in ipairs(dirs) do
		if not current[dirName] then
			current[dirName] = {}
		end
		
		current = current[dirName]
	end
	
	return current, target
end

function usersettings.save()
	settings.set('ShrugSettings', usersettings.Settings)
	settings.save(usersettings.SAVE_PATH)
end

function usersettings.load()
	local exists = settings.load(usersettings.SAVE_PATH)
	
	if exists then
		usersettings.Settings = settings.get('ShrugSettings', usersettings.Settings)
	end
end

function usersettings.path(...)
	return table.concat({...}, '/')
end

function usersettings.get(settingPath)
	local current, index = parsePath(settingPath)
	
	return current[index]
end

function usersettings.set(settingPath, value)
	local current, index = parsePath(settingPath)
	
	current[index] = value
end

return usersettings