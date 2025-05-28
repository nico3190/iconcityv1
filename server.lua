ESX = exports["es_extended"]:getSharedObject()

local function GetPlayerIdentifiers(src)
    local identifiers = {}
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        table.insert(identifiers, id)
    end
    return identifiers
end

local function GetPlayerDiscord(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "discord:") then
            return "<@" .. string.gsub(id, "discord:", "") .. ">"
        end
    end
    return "Nicht verfügbar"
end

local function SendDiscordLog(src, targetType, targetInfo, coords, success)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local playerName = GetPlayerName(src)
    local identifiers = GetPlayerIdentifiers(src)
    local discordPing = GetPlayerDiscord(src)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    local resultText = success and "Erfolgreich" or "Fehlgeschlagen"
    local title = ""
    local description = ""
    
    if targetType == "vehicle" then
        title = Config.DiscordLogs['vehicle_lockpick_attempt']
        description = success and Config.DiscordLogs['vehicle_success_desc'] or Config.DiscordLogs['vehicle_failed_desc']
    elseif targetType == "door" then
        title = Config.DiscordLogs['door_lockpick_attempt']
        description = success and Config.DiscordLogs['door_success_desc'] or Config.DiscordLogs['door_failed_desc']
    end
    
    local typeText = targetType == "vehicle" and "Fahrzeug" or "Tür"
    
    local codeBlock = "```"
    
    local embed = {
        {
            title = title,
            description = playerName .. " (ID: " .. src .. ") " .. description,
            color = success and 65280 or 16711680,
            fields = {
                {
                    name = Config.DiscordLogs['coordinates'],
                    value = codeBlock .. "vec3(" .. coords.x .. ", " .. coords.y .. ", " .. coords.z .. ")" .. codeBlock,
                    inline = false
                },
                {
                    name = Config.DiscordLogs['target_type'],
                    value = codeBlock .. typeText .. codeBlock,
                    inline = true
                },
                {
                    name = Config.DiscordLogs['target_info'],
                    value = codeBlock .. targetInfo .. codeBlock,
                    inline = true
                },
                {
                    name = Config.DiscordLogs['result'],
                    value = codeBlock .. resultText .. codeBlock,
                    inline = true
                },
                {
                    name = Config.DiscordLogs['player_identifiers'],
                    value = codeBlock .. table.concat(identifiers, ",\n") .. codeBlock,
                    inline = false
                },
                {
                    name = Config.DiscordLogs['discord_ping'],
                    value = discordPing,
                    inline = true
                }
            },
            footer = {
                text = timestamp .. " (" .. Config.DiscordLogs['time'] .. ")."
            }
        }
    }

    PerformHttpRequest(Config.Discord.webhook, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Discord.botName,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

RegisterServerEvent('nico_dietrich:removeLockpick')
AddEventHandler('nico_dietrich:removeLockpick', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer then
        xPlayer.removeInventoryItem('dietrich', 1)
    end
end)

RegisterServerEvent('nico_dietrich:sendLog')
AddEventHandler('nico_dietrich:sendLog', function(targetType, targetInfo, coords, success)
    local src = source
    SendDiscordLog(src, targetType, targetInfo, coords, success)
end)

RegisterServerEvent('nico_dietrich:unlockDoor')
AddEventHandler('nico_dietrich:unlockDoor', function(doorId)
    local src = source
    print("Server: Unlocking door", doorId, "for player", src)
    
    exports["doors_creator"]:setDoorState(doorId, 0)
    TriggerEvent("doors_creator:doorHasBeenLockpicked", src, doorId)
    
    print("Server: Door", doorId, "should now be unlocked")
end)

RegisterServerEvent('nico_dietrich:checkDoorState')
AddEventHandler('nico_dietrich:checkDoorState', function(doorId)
    local src = source
    local doorData = exports["doors_creator"]:getDoorIdData(doorId)
    print("Server: Door", doorId, "state check:", json.encode(doorData))
end)

RegisterServerEvent('nico_dietrich:getDoorData')
AddEventHandler('nico_dietrich:getDoorData', function(doorId)
    local src = source
    local doorData = exports["doors_creator"]:getDoorIdData(doorId)
    TriggerClientEvent('nico_dietrich:receiveDoorData', src, doorData)
end)

ESX.RegisterUsableItem('dietrich', function(source)
    TriggerClientEvent('nico_dietrich:useLockpick', source)
end)