-- pastebin version:

-- shrug client

local UpdateTime = 0.2

-- alpha goes from 0 to 255, 255 being fully opaque

local SaveMaxRenderDistance = 50
local SaveScanned = true
local TracerAlpha = 20
local ESPAlpha = 50

local flightEnabled = false
local flightPower = 4

local link = peripheral.find("neuralInterface")

if not link then error("No neural interface found!", 0) end
if not link.hasModule("plethora:scanner") then error("No block scanner found!", 0) end
if not link.hasModule("plethora:glasses") then error("No overlay glasses found!", 0) end
if not link.hasModule("plethora:sensor") then error("No entity sensor found!", 0) end
if not link.hasModule("plethora:chat") then error("No chat recorder found!", 0) end
if not link.hasModule("plethora:kinetic") then error("No kinetic augentation found!", 0) end

local modem = peripheral.find("modem")
local hasgps = (gps.locate() ~= nil)

link.canvas3d().clear()
local canvas3d = link.canvas3d().create()
local canvas = link.canvas()

canvas.clear()

local carrierID = nil
local metaData = {}

for i, v in pairs(link.sense()) do
    if v.x == 0 and v.y == 0 and v.z == 0 then
        carrierID = v.id
        break
    end
end

local scannable = {}
local scanned = {}
local broadcastedScanned = {}

local colorremap = {
    red = 0xFF0000FF,
    green = 0x009900FF,
    blue = 0x0000FFFF,
    purple = 0x9900FFFF,
    pink = 0xF478FFFF,
    orange = 0xFF8000FF,
    yellow = 0xFFFF00FF,
    teal = 0x00FFEAFF,
    magenta = 0xF200EEFF,
    brown = 0x804B24FF,
    black = 0x0D0D0DFF,
    white = 0xE9E9E9FF,
    lime = 0x00FF00FF,
    cyan = 0x094D4AFF,
    maroon = 0x520808FF,
    gray = 0x55555555FF,
    grey = 0x55555555FF,
    dark_gray = 0x111111FF,
    dark_grey = 0x111111FF
}

local texts = {}

local function Split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end

    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function getGPSLocation()
    local gx, gy, gz = gps.locate()

    if gx ~= nil then
        hasgps = true
        local fx, fy, fz = math.floor(gx), math.floor(gy - 1.62), math.floor(gz)

        return { x = fx, y = fy, z = fz }
    else
        hasgps = false
        return { x = 0, y = 0, z = 0 }
    end
end

local function load(dir)
    if fs.exists(dir) then
        local toScan = {}

        local file = fs.open(dir, "r")

        repeat
            local line = file.readLine()

            if line then
                local args = Split(line, "->")

                local color = tonumber(args[1])
                local block = args[2]
                local alias = args[3]
                local order = tonumber(args[4])
                local lookfortag = args[5]
                local type = args[6]

                print("Loading scannable with args: ", color, block, alias, order, lookfortag, type)

                if color and block and alias and order then
                    toScan[color] = { name = block, alias = alias, order = order,
                        lookfortag = lookfortag, type = type }
                end
            end
        until line == nil

        scannable = toScan

        for alias, text in pairs(texts) do
            text.remove()

            texts[alias] = nil
        end

        for color, v in pairs(scannable) do
            local text = canvas.addText({ 0, v.order * 6 }, v.alias .. ": 0")
            text.setShadow(true)
            text.setColour(color)
            text.setScale(0.6)

            texts[v.alias] = text
        end

        local lastLoadedFile = fs.open("shrug_saved/lastloaded.txt", "w")

        lastLoadedFile.write(dir)

        lastLoadedFile.close()

        link.tell("Successfully loaded file " .. dir .. " into scan list.")
    else
        link.tell("File " .. dir .. " doesn't exist.")
    end
end

local function drawLine(object, blockDesync)
    local w = metaData.withinBlock

    if not blockDesync then
        w = { x = 0, y = 0, z = 0 }
    end

    local line = canvas3d.addLine({ 0, -1, 0 }, { object.x - w.x + 0.5, object.y - w.y + 0.5, object.z - w.z + 0.5 },
        object.thicc,
        object.color)
    line.setDepthTested(false)
    line.setAlpha(TracerAlpha)

    local box = canvas3d.addBox(object.x - w.x, object.y - w.y, object.z - w.z, 1, 1, 1, object.color)
    box.setDepthTested(false)
    box.setAlpha(ESPAlpha)
end

local function drawLines(vList)
    canvas3d.clear()

    for i, v in pairs(vList) do
        drawLine(v, true)
    end
end

local function drawCounts(cList)
    for alias, count in pairs(cList) do
        if texts[alias] then
            texts[alias].setText(alias .. ": " .. count)
        end
    end
end

local function main()
    link.tell("¯\\_('-')_/¯ client")

    link.capture(".find")
    link.capture(".fly")
    link.capture(".shrug")
    link.capture(".xray")

    if modem then
        if hasgps then
            link.tell("Modem with gps detected.")
        else
            link.tell("Modem without gps detected.")
        end
    else
        link.tell("No modem detected.")
    end

    if not fs.exists("shrug_saved") then
        fs.makeDir("shrug_saved")
    end

    if not fs.exists("shrug_saved/xray_saves") then
        fs.makeDir("shrug_saved/xray_saves")
    end

    if not fs.exists("shrug_saved/findsettings.txt") then
        local file = fs.open("shrug_saved/findsettings.txt", "w")

        file.close()

        link.tell("Last loaded file not detected.")
        link.tell("Assuming first time use. `Use .shrug help` in chat to get further information")
    else
        link.tell("Loading last loaded save...")

        local lastLoaded = fs.open("shrug_saved/findsettings.txt", "r")

        local dir = lastLoaded.readLine()

        lastLoaded.close()

        if dir then
            load(dir)
        else
            link.tell("Could not find last loaded save.")
        end
    end

    if not fs.exists("shrug_saved/flightsettings.txt") then
        local file = fs.open("shrug_saved/flightsettings.txt", "w")

        file.writeLine(tostring(flightPower))
        file.writeLine(tostring(flightEnabled))

        file.close()
    else
        local fsettings = fs.open("shrug_saved/flightsettings.txt", "r")

        flightPower = tonumber(fsettings.readLine()) or 4
        flightEnabled = fsettings.readLine() == "true"

        fsettings.close()
    end

    term.clear()
    term.setCursorPos(1, 1)

    while true do
        local blockList = {}
        local count = {}

        for _, key in pairs(scannable) do
            count[key.alias] = 0
        end

        local t = false

        for i, v in pairs(scannable) do
            if i or v then
                t = true
                break
            end
        end

        if t then
            local p = hasgps and getGPSLocation() or { x = 0, y = 0, z = 0 }

            for _, block in pairs(link.scan()) do
                for col, orename in pairs(scannable) do
                    if block.name == orename.name and
                        (
                        orename.lookfortag ~= nil and (block.state[orename.lookfortag] == orename.type) or
                            orename.lookfortag == nil) then
                        count[orename.alias] = (count[orename.alias] or 0) + 1

                        local blockData = {
                            x = block.x,
                            y = block.y,
                            z = block.z,
                            thicc = 1.5,
                            color = col
                        }

                        if hasgps and SaveScanned then
                            local position = { x = p.x + block.x, y = p.y + block.y, z = p.z + block.z }

                            scanned[("%s:%s:%s"):format(position.x, position.y, position.z)] = { x = position.x,
                                y = position.y, z = position.z, color = col, name = block.name }

                        end

                        table.insert(blockList, blockData)
                        break
                    end
                end

                if hasgps and SaveScanned then
                    local position = { x = p.x + block.x, y = p.y + block.y, z = p.z + block.z }
                    local scannedIndexValue = scanned[("%s:%s:%s"):format(position.x, position.y, position.z)]

                    if scannedIndexValue ~= nil and scannedIndexValue.name ~= block.name then
                        scanned[("%s:%s:%s"):format(position.x, position.y, position.z)] = nil
                    end
                end
            end

            canvas3d.recenter()
            drawLines(blockList)
            drawCounts(count)

            if hasgps and SaveScanned then
                local p = getGPSLocation()

                for coordString, data in pairs(scanned) do
                    local distance = math.sqrt((data.x - p.x) ^ 2 + (data.y - p.y) ^ 2 + (data.z - p.z) ^ 2)

                    if distance > 10 and distance < SaveMaxRenderDistance then
                        local reconstructedData = { x = data.x - p.x, y = data.y - p.y, z = data.z - p.z,
                            color = data.color,
                            thicc = 1.5 }

                        drawLine(reconstructedData, true)
                    end
                end
            end
        end

        sleep(UpdateTime)
    end
end

local function onterminate()
    while true do
        local event, message, pattern, uuid = os.pullEventRaw()

        if event == "terminate" then
            print("Clearing canvases and captures")

            canvas.clear()
            canvas3d.clear()
            link.clearCaptures()
            break
        elseif event == "chat_capture" then
            local args = Split(message)

            local com = args[2]
            local block = args[3]
            local alias = args[4]
            local color = args[5]
            local metadataTag = args[6]
            local type = args[7]

            if args[1] == ".find" then
                if com == "add" then
                    if block and alias and color then
                        if colorremap[color] then
                            color = colorremap[color]
                        end

                        color = tonumber(color)

                        if color == nil then link.tell("Unacceptable color!") else
                            if not scannable[color] then
                                if not texts[alias] then
                                    local hasBlock = false

                                    for i, v in pairs(scannable) do
                                        if v.name == block and v.lookfortag ~= nil and
                                            (v.lookfortag == metadataTag and v.type == type) then
                                            hasBlock = true
                                            break
                                        end
                                    end

                                    if not hasBlock then
                                        local c = 0

                                        for i, v in pairs(scannable) do
                                            c = c + 1
                                        end

                                        scannable[color] = { name = block, alias = alias, order = c,
                                            lookfortag = metadataTag,
                                            type = type }

                                        local text = canvas.addText({ 0, scannable[color].order * 6 },
                                            scannable[color].alias .. ": 0")
                                        text.setShadow(true)
                                        text.setColour(color)
                                        text.setScale(0.6)

                                        texts[alias] = text
                                        link.tell("Successfully added " .. block .. " to scan list.")
                                    else
                                        link.tell("Can't scan for the same block multiple times!")
                                    end
                                else
                                    link.tell("Alias already taken!")
                                end
                            else
                                link.tell("Color already taken!")
                            end
                        end
                    end
                elseif com == "remove" then
                    if block then
                        local found = nil

                        for color, v in pairs(scannable) do
                            if v.name == block then
                                found = scannable[color]
                                scannable[color] = nil
                            end
                        end

                        if found then
                            for color, v in pairs(scannable) do
                                if v.order > found.order then
                                    scannable[color].order = v.order - 1

                                    if texts[v.alias] then
                                        texts[v.alias].setPosition(0, v.order * 6)
                                    end
                                end
                            end

                            if texts[found.alias] then
                                texts[found.alias].remove()
                                texts[found.alias] = nil
                            end

                            link.tell("Successfully removed " .. block .. " from scan list.")
                        else
                            link.tell(block .. " not found.")
                        end
                    else
                        link.tell("Missing second argument!")
                    end
                elseif com == "list" then
                    local c = 0

                    for i, v in pairs(scannable) do
                        c = c + 1
                    end

                    if c == 0 then
                        link.tell("There are currently no blocks being tracked.")
                    else
                        local str = "blocks "

                        local i = 0

                        for color, v in pairs(scannable) do
                            if i == 0 then
                                str = str .. ("%s"):format(v.name)
                            elseif i == c - 1 then
                                str = str .. (" and %s"):format(v.name)
                            else
                                str = str .. (", %s"):format(v.name)
                            end

                            i = i + 1
                        end

                        str = str .. " are being tracked."

                        link.tell(str)
                    end

                elseif com == "save" then
                    if not block:lower():find("startup") then
                        if not fs.exists("shrug_saved/xray_saves/" .. block .. ".xray") then
                            local file = fs.open("shrug_saved/xray_saves/" .. block .. ".xray", "w")

                            for color, v in pairs(scannable) do
                                local saveLine = color .. "->" .. v.name .. "->" .. v.alias .. "->" .. v.order

                                if v.lookfortag and v.type then
                                    saveLine = saveLine .. "->" .. v.lookfortag .. "->" .. v.type
                                end

                                file.writeLine(saveLine)
                            end

                            file.close()

                            link.tell("Saved " .. block .. " successfully")
                        else
                            link.tell("Can't overwrite file " .. block)
                        end
                    else
                        link.tell("Can't save as " .. block)
                    end
                elseif com == "delete" then
                    if not block:lower():find("startup") then
                        if fs.exists("shrug_saved/xray_saves/" .. block .. ".xray") then
                            fs.delete("shrug_saved/xray_saves/" .. block .. ".xray")

                            link.tell("File " .. block .. " successfully deleted.")
                        else
                            link.tell("File " .. block .. " doesn't exist.")
                        end
                    else
                        link.tell("Can't delete file " .. block)
                    end
                elseif com == "load" then
                    load("shrug_saved/xray_saves/" .. block .. ".xray")
                elseif com == "help" then
                    link.tell("Use .find add <block name> <block alias> <color hex> to add blocks to be scanned")
                    link.tell("Use .find remove <block name> to remove block from being scanned")
                    link.tell("Use .find save <filename> to save the current scan list")
                    link.tell("Use .find delete <filename> to delete a save")
                    link.tell("Use .find load <filename> to load a saved scan list into the curernt scan list")
                    link.tell("Use .find clear to clear all canvases and to reset the scan list")
                    link.tell("Use .find alpha <tracers/block> <number> to change the alpha")
                    link.tell("Use .find scantimer <number> to change how frequent it will scan")
                elseif com == "saves" then
                    local list = fs.list("shrug_saved/xray_saves")

                    local c = 0

                    for i, v in pairs(list) do
                        c = c + 1
                    end

                    if c == 0 then
                        link.tell("There are currently no saves.")
                    else
                        local str = "Saves "

                        local i = 0

                        for _, file in pairs(list) do
                            if file ~= "lastloaded.txt" or file ~= "flightsettings.txt" then
                                if i == 0 then
                                    str = str .. ("%s"):format(file)
                                elseif i == c - 1 then
                                    str = str .. (" and %s"):format(file)
                                else
                                    str = str .. (", %s"):format(file)
                                end

                                i = i + 1
                            end
                        end

                        str = str .. " are detected."

                        link.tell(str)
                    end
                elseif com == "clear" then
                    scannable = {}
                    scanned = {}

                    for alias, text in pairs(texts) do
                        text.remove()

                        texts[alias] = nil
                    end

                    canvas.clear()
                    canvas3d.clear()
                elseif com == "alpha" then
                    if tonumber(alias) then
                        if block == "tracers" then
                            TracerAlpha = (tonumber(alias) or 0)
                        elseif block == "block" then
                            ESPAlpha = (tonumber(alias) or 0)
                        else
                            link.tell("Not a valid alpha type.")
                        end
                    else
                        link.tell("Not a valid number.")
                    end
                elseif com == "scantimer" then
                    UpdateTime = math.min(math.max(tonumber(block) or 0.2, 0), 256)
                    link.tell("Changed scan time to " .. UpdateTime)
                elseif com == "savescanned" then
                    if block == "off" then
                        SaveScanned = false
                        link.tell("Turning off saving scanned blocks")
                    elseif block == "on" then
                        SaveScanned = true
                        link.tell("Turning on saving scanned blocks")
                    end
                elseif com == "scanneddistance" then
                    SaveMaxRenderDistance = math.min(math.max(tonumber(block) or 0, 0), 256)
                    link.tell("Changed max render distance for saved to " .. SaveMaxRenderDistance)
                else
                    link.tell("Not a supported command!")
                end
            elseif args[1] == ".fly" then
                if com == "toggle" then
                    flightEnabled = not flightEnabled

                    link.tell("Flight toggled; " .. tostring(flightEnabled))

                    local file = fs.open("shrug_saved/flightsettings.txt", "w")

                    file.writeLine(tostring(flightPower))
                    file.writeLine(tostring(flightEnabled))

                    file.close()
                elseif com == "power" then
                    flightPower = math.min(math.max(tonumber(block) or 1, 0), 4)
                    link.tell("Flight power changed to " .. tostring(flightPower) .. ".")

                    local file = fs.open("shrug_saved/flightsettings.txt", "w")

                    file.writeLine(tostring(flightPower))
                    file.writeLine(tostring(flightEnabled))

                    file.close()
                elseif com == "help" then
                    link.tell("Use `.fly power <number>` to change your fly speed")
                    link.tell("Use `.fly toggle` to toggle flight your flight ability")
                end
            elseif args[1] == ".shrug" then
                if com == "term" then
                    link.tell("Clearing canvases and captures")

                    canvas.clear()
                    canvas3d.clear()
                    link.clearCaptures()
                    break
                elseif com == "help" then
                    link.tell("Use `.find help` for more information on the xray ability")
                    link.tell("Use `.fly help` for more information on the fly ability")
                elseif com == "update" then
                    link.tell("Updating to latest version.")

                    if fs.exists("shrug") then
                        fs.delete("shrug")
                    end

                    shell.run("pastebin get hD94N6dV shrug")
                    break
                end
            end
        end
    end
end

local function getmeta()
    while true do
        if carrierID then
            metaData = link.getMetaByID(carrierID) or metaData
        else
            sleep()
        end
    end
end

local function fly()
    while true do
        if flightEnabled then
            if metaData ~= nil then
                if metaData.heldItem ~= nil then
                    if metaData.heldItem.getMetadata and metaData.isSneaking then
                        local itemData = ((metaData.heldItem and metaData.heldItem.getMetadata) or function()
                            return { name = "minecraft:air", displayName = "Air" }
                        end)()

                        if itemData.name == "plethora:neuralconnector" or itemData.name == "carryon:tile_item" or
                            itemData.name == "carryon:entity_item" then
                            link.launch(metaData.yaw, metaData.pitch, flightPower)
                        end
                    end
                end
            end
        end

        sleep()
    end
end

local function checkGPSStatus()
    while true do
        if not hasgps then
            hasgps = gps.locate() ~= nil
        end

        sleep()
    end
end

local function listenScanned()

end

parallel.waitForAny(onterminate, main, getmeta, fly, checkGPSStatus)
