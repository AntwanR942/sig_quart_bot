--[[ Variables ]]
AvatarOverlays = {
    --[[ ["Command Name"] = "Overlay Type"]]
    ["triggered"] = "triggered",
    ["gayp"] = "gay"
}

--[[ Commands ]]
CommandManager.Command("coin", function(Args, Payload)
    math.randomseed(os.time())
    local RInt = math.random(1, 2)

    SimpleEmbed(Payload, (RInt == 1 and "Heads" or "Tails"))
end):SetCategory("Fun Commands"):SetDescription("Flip a coin to decide some stupid thing.")

CommandManager.Command("penis", function(Args, Payload)
    math.randomseed(os.time())
    local Random = math.random(0, 20)

    Payload:reply {
        embed = {
            ["color"] = 16738740,
            ["fields"] = {
                {
                    ["name"] = "Penis Size Machine",
                    ["value"] = Payload.author.mentionString.."'s penis\n8"..string.rep("=", Random).."D"
                }
            },
        }
    }
end):SetCategory("Dirty Commands"):SetDescription("A true penis length detection machine.")

for OverlayCommand, Overlay in pairs(AvatarOverlays) do
    CommandManager.Command(OverlayCommand, function(Args, Payload)
        local Avatar = assert(Payload.author.avatarURL, "could not get your avatar.")
        local Res, Img = HTTP.request("GET", "https://some-random-api.ml/canvas/"..Overlay.."?avatar="..Avatar)
        Res = assert(JSON.decode(JSON.encode(Res)), "failed to format API response.")

        assert(Res.code == 200 and Img ~= nil, "API request failed.")

        Payload:reply {
            ["file"] = { "img.png", Img }
        }
    end):SetCategory("Fun Commands"):SetDescription("Apply a triggered overlay to your avatar.")
end