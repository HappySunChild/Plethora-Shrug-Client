local scan = {}
scan.Modules = nil ---@type Shrug.NeuralInterface
scan.Enabled = false
scan.Tracers = true

scan.LastScan = 0
scan.ScanTime = 0.1
scan.BoxAlpha = 100
scan.TracerAlpha = 100

scan.BlockWhitelist = {} ---@type WhitelistData[]

local function toBlockData(name)
	local blockName = string.match(name, '[^<]+')
	local tagName, tagValue = string.match(name, '<([^=]+)=(.-)>')
	
	return {state = {[tostring(tagName)] = tagValue}, name = blockName}
end

---@param canvas OverlayGlasses.Canvas2d
---@param name string
---@param alias? string
---@param color? string
function scan.addWhitelist(canvas, name, alias, color)
	if scan.isWhitelisted(toBlockData(name)) then
		return string.format('Block `%s` is already in whitelist.', name)
	end
	
	local blockName = string.match(name, '[^<]+')
	local tagName, tagValue = string.match(name, '<([^=]+)=(.-)>')
	
	local tagData = nil
	
	if tagName and tagValue then
		tagData = {
			Name = tagName,
			Value = tagValue
		}
	end
	
	local blockAlias = alias or blockName
	local blockColor = tonumber(tostring(color), 16) or 0xFF0000FF
	
	local label = canvas.addText({x=0,y=0}, '')
	label.setColor(blockColor)
	label.setShadow(true)
	label.setScale(0.6)
	
	local whitelistData = {
		Name = name,
		BlockName = blockName,
		Alias = blockAlias,
		Color = blockColor,
		
		Tag = tagData,
		
		Count = 0,
		Label = label,
	}
	
	table.insert(scan.BlockWhitelist, whitelistData)
	scan.updateLabels()
	
	return string.format('Successfully added `%s` to whitelist.', name)
end

---@param name string
function scan.removeWhitelist(name)
	local isWhitelisted, whitelistData, index = scan.isWhitelisted(toBlockData(name))
	
	if not isWhitelisted or not whitelistData or not index then
		return string.format('`%s` not found.', name)
	end
	
	whitelistData.Label.remove()
	table.remove(scan.BlockWhitelist, index)
	
	scan.updateLabels()
	
	return string.format('Successfully removed `%s` from whitelist.', name)
end

function scan.clearWhitelist()
	while next(scan.BlockWhitelist) do
		local data = scan.BlockWhitelist[1]
		
		scan.removeWhitelist(data.Name)
	end
end

---@param blockData BlockScanner.BlockData
---@return boolean whitelisted
---@return WhitelistData? data
---@return integer? index
function scan.isWhitelisted(blockData)
	for index, whitelistData in ipairs(scan.BlockWhitelist) do
		if whitelistData.BlockName == blockData.name then
			local tagData = whitelistData.Tag
			
			if tagData then
				if tostring(blockData.state[tagData.Name]):lower() == tagData.Value:lower() then
					return true, whitelistData, index
				end
			else
				return true, whitelistData, index
			end
		end
	end
	
	return false
end

function scan.canScan()
	return (os.clock() - scan.LastScan) >= scan.ScanTime
end

function scan.resetCounts()
	for _, target in pairs(scan.BlockWhitelist) do
		target.Count = 0
	end
end

function scan.updateLabels()
	for i, target in ipairs(scan.BlockWhitelist) do
		target.Label.setPosition(0, (i - 1) * 6)
		
		if scan.Enabled then
			target.Label.setText(string.format('%s: %d', target.Alias, target.Count))
		else
			target.Label.setText('') -- clear text
		end
	end
end

return scan