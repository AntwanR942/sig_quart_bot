CommandManager.Command("iss", function(Args, Payload)
    local Suc, Telemetry = HTTP.request("GET", "https://api.wheretheiss.at/v1/satellites/25544")
    assert(Suc.code == 200, "API request unsuccessful.")

    Telemetry = JSON.decode(Telemetry)
    local ISSEmbed = {
        ["title"] = "Current telemetry of the International Space Station",
        ["url"] = "https://api.wheretheiss.at/v1/satellites/25544",
        ["color"] = Config.EmbedColour,
        ["thumbnail"] = {
            ["url"] = "https://cdn.vox-cdn.com/thumbor/dvob-_vamMcKbSo4ZUw9feM1930=/0x0:3500x2625/1200x800/filters:focal(0x0:3500x2625)/cdn.vox-cdn.com/uploads/chorus_image/image/38675506/115569517.0.0.jpg"
        },
        ["fields"] = {
            {
                ["name"] = "NORAT ID",
                ["value"] = "``25544``"
            },
            {
                ["name"] = "🌐 Latitude & Longitude",
                ["value"] = "``LAT: "..Round(Telemetry.longitude, 1).."° LNG: "..Round(Telemetry.latitude, 1).."°``"
            },
            {
                ["name"] = "Altitude",
                ["value"] = "``"..Round(Telemetry.altitude, 1).."km``",
                ["inline"] = true
            },
            {
                ["name"] = "Velocity",
                ["value"] = "``"..Round(Telemetry.altitude, 1).."km/h``",
                ["inline"] = true
            },
            {
                ["name"] = "Visibility",
                ["value"] = "``"..Telemetry.visibility:sub(1, 1):upper()..Telemetry.visibility:sub(2, #Telemetry.visibility).."``",
                ["inline"] = true
            }
        }
    }

    local GEOSuc, GEOLoc = HTTP.request("GET", "https://api.opencagedata.com/geocode/v1/json?q="..tostring(Telemetry.latitude).."+"..Telemetry.longitude.."&key=425fce8d7d5b499cbe5098e9b5a59dec")
    if GEOSuc.code == 200 then
        GEOLoc = JSON.decode(GEOLoc)
        if GEOLoc.results[1].components.continent then
            table.insert(ISSEmbed.fields, { ["name"] = "Continent", ["value"] = "``"..GEOLoc.results[1].components.continent.."``", ["inline"] = true })
        end
        if GEOLoc.results[1].components.country then
            table.insert(ISSEmbed.fields, { ["name"] = "Country", ["value"] = "``"..GEOLoc.results[1].components.country.." ("..GEOLoc.results[1].components.country_code:upper()..")``", ["inline"] = true })
        end
        if GEOLoc.results[1].components.city then
            table.insert(ISSEmbed.fields, { ["name"] = "City", ["value"] = "``"..GEOLoc.results[1].components.city.."``", ["inline"] = true })
        end
        table.insert(ISSEmbed.fields, { ["name"] = "What3Words", ["value"] = "["..GEOLoc.results[1].annotations.what3words.words.."](https://what3words.com/"..GEOLoc.results[1].annotations.what3words.words..")", ["inline"] = false })
        table.insert(ISSEmbed.fields, { ["name"] = "Time Zone", ["value"] = "``"..GEOLoc.results[1].annotations.timezone.name.." ("..GEOLoc.results[1].annotations.timezone.short_name..")``", ["inline"] = true })
    end

    Payload:reply {
        embed = ISSEmbed
    }
end):SetCategory("Fun Commands"):SetDescription("Get current telemetry and location of the I.S.S.")
