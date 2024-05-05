local usersettings = require('ShrugModules.usersettings')
usersettings.Settings.Scan = {
	DrawTracers = true,
	
	ScanInterval = 0.1,
	
	BoxAlpha = 100,
	TracerAlpha = 100
}

local scan = {}
scan.Enabled = false
scan.LastScan = 0

scan._whitelist = {} ---@type table<string, WhitelistData>

local function getTagData(name)
	local tagName, tagValue = string.match(name, '<([^=:]+)[=:](.-)>')
	
	if tagName and tagValue then
		return {
			Name = tagName,
			Value = tagValue
		}
	end
	
	return nil
end

function scan.getWhitelist()
	local list = {}
	
	for _, data in pairs(scan._whitelist) do
		table.insert(list, data)
	end
	
	return list
end

function scan.isWhitelisted(name)
	local data = scan._whitelist[name]
	
	if not data then
		for _, whitelistData in pairs(scan._whitelist) do
			if whitelistData.Name == name then
				data = whitelistData
				
				break
			end
		end
	end
	
	return data ~= nil, data
end

---@param blockData BlockScanner.BlockData
function scan.isBlockWhitelisted(blockData)
	local data = nil
	
	for _, whitelistData in pairs(scan._whitelist) do
		if blockData.name == whitelistData.Name then
			local tagData = whitelistData.Tag
			
			if not tagData then
				data = whitelistData
				
				break
			end
			
			if tostring(blockData.state[tagData.Name]):lower() == tagData.Value:lower() then
				data = whitelistData
				
				break
			end
		end
	end
	
	return data ~= nil, data
end

---@param canvas OverlayGlasses.Canvas2d
---@param name string
---@param alias? string
---@param color? string
function scan.addWhitelist(canvas, name, alias, color)
	local blockName = string.match(name, '[^<]+')
	local blockAlias = alias or blockName
	
	local blockColor = tonumber(tostring(color), 16) or 0xFF0000FF
	
	if scan.isWhitelisted(blockAlias) then
		return string.format('Block `%s` is already in whitelist.', name)
	end
	
	local tagData = getTagData(name)
	
	local label = canvas.addText({x=0,y=0}, '')
	label.setColor(blockColor)
	label.setShadow(true)
	label.setScale(0.6)
	
	local whitelistData = {
		RawName = name,
		Name = blockName,
		Alias = blockAlias,
		Color = blockColor,
		
		Tag = tagData,
		
		Count = 0,
		Label = label,
	}
	
	scan._whitelist[blockAlias] = whitelistData
	scan.updateLabels()
	
	return string.format('Successfully added `%s` to whitelist.', name)
end

---@param name string
function scan.removeWhitelist(name)
	local isWhitelisted, whitelistData = scan.isWhitelisted(name)
	
	if not isWhitelisted then
		return string.format('`%s` not found.', name)
	end
	
	whitelistData.Label.remove()
	scan._whitelist[name] = nil
	
	scan.updateLabels()
	
	return string.format('Successfully removed `%s` from whitelist.', name)
end

function scan.clearWhitelist()
	for index, _ in pairs(scan._whitelist) do
		scan.removeWhitelist(index)
	end
end

function scan.canScan()
	return (os.clock() - scan.LastScan) >= usersettings.Settings.Scan.ScanInterval
end

function scan.resetCounts()
	for _, target in pairs(scan._whitelist) do
		target.Count = 0
	end
end

function scan.updateLabels()
	for i, data in ipairs(scan.getWhitelist()) do
		data.Label.setPosition(1, 1 + (i - 1) * 6)
		
		if scan.Enabled then
			data.Label.setText(string.format('%s: %d', data.Alias, data.Count))
		else
			data.Label.setText('') -- clear text
		end
	end
end

return scan