local bounding = {}

---@param map NodeMap
local function getBoundings(map)
	---@param originNode Node
	local function expand(originNode)
		local count = 1
		local name = originNode.Name
		
		local minZ, maxZ = originNode.Z, originNode.Z
		local minX, maxX = originNode.X, originNode.X
		local minY, maxY = originNode.Y, originNode.Y
		
		local queue = {originNode} ---@type Node[]
		
		while #queue > 0 do
			local currentNode = table.remove(queue, 1) ---@type Node
			currentNode.Visited = true
			
			local curX, curY, curZ = currentNode.X, currentNode.Y, currentNode.Z
			
			for z = -1, 1 do
				for x = -1, 1 do
					for y = -1, 1 do
						local offset = {x, y, z}
						local adjacentNode = map:GetNode(curX + offset[1], curY + offset[2], curZ + offset[3])
						
						if adjacentNode and not adjacentNode.Visited and adjacentNode.Name == name and adjacentNode ~= currentNode then
							adjacentNode.Visited = true
							count = count + 1
							
							minZ, maxZ = math.min(minZ, adjacentNode.Z), math.max(maxZ, adjacentNode.Z)
							minX, maxX = math.min(minX, adjacentNode.X), math.max(maxX, adjacentNode.X)
							minY, maxY = math.min(minY, adjacentNode.Y), math.max(maxY, adjacentNode.Y)
							
							table.insert(queue, adjacentNode)
						end
					end
				end
			end
		end
		
		return minZ, maxZ, minX, maxX, minY, maxY, count
	end
	
	local meshed = {}
	
	for _, node in ipairs(map:GetNodes()) do
		if not node.Visited then
			local minZ, maxZ, minX, maxX, minY, maxY, count = expand(node)
			
			local sizeX = maxX - minX + 1
			local sizeY = maxY - minY + 1
			local sizeZ = maxZ - minZ + 1
			
			---@type DisplayData
			local displayData = {
				X = minX,
				Y = minY,
				Z = minZ,
				
				SizeX = sizeX,
				SizeY = sizeY,
				SizeZ = sizeZ,
				Count = count,
				
				Alias = node.Data.WhitelistData.Alias,
				Color = node.Data.WhitelistData.Color
			}
			
			table.insert(meshed, displayData)
		end
	end
	
	return meshed
end

function bounding.newMap()
	---@class NodeMap
	local map = {}
	map.Nodes = {} ---@type table<integer, table<integer, table<integer, Node>>>
	
	---@return Node?
	function map:GetNode(x, y, z)
		local nodes = self.Nodes
		
		return nodes[y] and nodes[y][x] and nodes[y][x][z]
	end
	
	---@return Node[]
	function map:GetNodes()
		local nodes = {}
		
		for _, y in pairs(self.Nodes) do
			for _, x in pairs(y) do
				for _, node in pairs(x) do
					table.insert(nodes, node)
				end
			end
		end
		
		return nodes
	end
	
	---@param x integer
	---@param y integer
	---@param z integer
	---@param data ScannedBlockData
	function map:CreateNode(x, y, z, data)
		---@class Node
		local newNode = {}
		newNode.X = x
		newNode.Y = y
		newNode.Z = z
		newNode.Visited = false
		newNode.Data = data
		newNode.Name = data.WhitelistData.Alias
		
		map.Nodes[y] = self.Nodes[y] or {}
		map.Nodes[y][x] = self.Nodes[y][x] or {}
		map.Nodes[y][x][z] = newNode
	end
	
	return map
end

---@param objects ScannedBlockData[]
---@return DisplayData[]
function bounding.mesh(objects)
	local map = bounding.newMap()
	
	for _, object in ipairs(objects) do
		map:CreateNode(object.X, object.Y, object.Z, object)
	end
	
	return getBoundings(map)
end

return bounding