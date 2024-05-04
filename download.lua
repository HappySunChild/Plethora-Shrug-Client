local function download(link, path)
	local success = shell.execute('wget', link, path)
	
	if not success then
		download(link, path)
	end
end

local baseLink = 'https://raw.githubusercontent.com/HappySunChild/Plethora-Shrug-Client/main/src/%s'
local files = {
	'startup.lua',
	'ShrugModules/bounding.lua',
	'ShrugModules/button.lua',
	'ShrugModules/scan.lua',
	'ShrugModules/fly.lua',
}

for _, path in ipairs(files) do
	if fs.exists(path) then
		print(string.format('Removing old `%s`', path))
		
		fs.delete(path)
	end
	
	download(string.format(baseLink, path), path)
end