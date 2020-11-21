--[[ Command ]]
CommandManager.Command("ping", function(Args, Payload)
    Payload:reply {
        embed = {
            ["title"] = "Pong",
            ["image"] = {
                ["url"] = "https://media1.tenor.com/images/6f1d20bb80a1c3f7fbe3ffb80e3bbf4e/tenor.gif"
            },
            ["color"] = Config.EmbedColour
        }
    }
end):SetCategory("Fun Commands"):SetDescription("Pong.")