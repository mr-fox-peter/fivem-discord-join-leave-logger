local function GetIdentifiers(source)
    local identifiers = {
        discord = "Not Linked",
        fivem = "N/A",
        license = "N/A",
        steam = "N/A"
    }

    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.find(id, "discord:") then identifiers.discord = string.sub(id, 9)
        elseif string.find(id, "fivem:") then identifiers.fivem = string.sub(id, 7)
        elseif string.find(id, "license:") then identifiers.license = string.sub(id, 9)
        elseif string.find(id, "steam:") then identifiers.steam = string.sub(id, 7)
        end
    end
    return identifiers
end

local function SendToDiscord(title, message, color, identifiers, serverId, location)
    local discordTag = identifiers.discord ~= "Not Linked" and "<@" .. identifiers.discord .. ">" or "Not Linked"
    
    local locationText = ""
    if location then
        locationText = string.format("\n📍 **Last Location:** %.2f, %.2f, %.2f", location.x, location.y, location.z)
    end

    local playerDetails = string.format(
        "\n\n**Player Details:**\n" ..
        "🆔 **Server ID:** %s\n" ..
        "💬 **Discord:** %s\n" ..
        "🔗 **FiveM:** %s\n" ..
        "📑 **License:** %s\n" ..
        "🎮 **Steam:** %s%s",
        serverId or "N/A",
        discordTag,
        identifiers.fivem,
        identifiers.license,
        identifiers.steam,
        locationText
    )

    local embed = {
        {
            ["color"] = color,
            ["title"] = "**" .. title .. "**",
            ["description"] = message .. playerDetails,
            ["author"] = {
                ["name"] = Config.AuthorName,
            },
            ["footer"] = {
                ["text"] = "Server Logs • " .. os.date("%Y-%m-%d %H:%M:%S"),
                ["icon_url"] = Config.WebhookAvatar
            },
        }
    }

    PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode({
        username = Config.WebhookName, 
        embeds = embed, 
        avatar_url = Config.WebhookAvatar
    }), { ['Content-Type'] = 'application/json' })
end

-- Event: Player Joining (Fires when ID is assigned)
AddEventHandler('playerJoining', function()
    local src = source
    local playerName = GetPlayerName(src)
    local ids = GetIdentifiers(src)
    
    SendToDiscord("Player Joining", "👤 **" .. playerName .. "** is connecting to the server.", Config.JoinColor, ids, src)
end)

-- Event: Player Dropped
AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerName = GetPlayerName(src)
    local ids = GetIdentifiers(src)
    
    -- Capture last location before the ped is deleted
    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)

    local cleanReason = reason
    if string.find(reason, "Crash") or string.find(reason, "Exiting") then
        cleanReason = "⚠️ " .. reason
    else
        cleanReason = "🚪 " .. reason
    end

    SendToDiscord("Player Left", "❌ **" .. playerName .. "** has left the server.\n**Reason:** " .. cleanReason, Config.LeaveColor, ids, src, coords)
end)