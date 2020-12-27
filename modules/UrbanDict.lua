--[[ Variables ]]
UDAPIKeyFile = FileReader.readFileSync(ModuleDir.."/UrbanDict.txt")
assert(UDAPIKeyFile, "Couldn't load Urban Dictionary API key file. Please create a file in your module directory called UrbanDict.txt and put your Urban Dictionary API key inside.")

--[[ Command ]]
UrbanDict = CommandManager.Command("ud", function(Args, Payload)
    assert(Args[2] ~= nil, "")

    local InputTerm = ReturnRestOfCommand(Args, 2)
    local URLTerm = assert(Query.urlencode(InputTerm), "failed to parse term.")

    local Res, Body = HTTP.request("GET", "https://mashape-community-urban-dictionary.p.rapidapi.com/define?term="..URLTerm, { { "x-rapidapi-host", "mashape-community-urban-dictionary.p.rapidapi.com" }, { "x-rapidapi-key", UDAPIKeyFile }  })
    assert(Res.code == 200, "API request failed, are you sure the term provided is valid?")
    Body = assert(JSON.decode(Body), "failed to parse API response.")
    
    local ThisDefinitionInfo = Body.list[1]
    assert(ThisDefinitionInfo ~= nil and ThisDefinitionInfo.word and ThisDefinitionInfo.definition and ThisDefinitionInfo.permalink and ThisDefinitionInfo.thumbs_up and ThisDefinitionInfo.thumbs_down and ThisDefinitionInfo.example and ThisDefinitionInfo.author, "could not find definition of the term ``"..InputTerm.."``.")
    ThisDefinitionInfo.example = ThisDefinitionInfo.example:split("\n")[1]
    
    local UDEmbed = {
        ["title"] = "Urban dictionary definition of ``"..ThisDefinitionInfo.word.."``",
        ["description"] = "["..ThisDefinitionInfo.definition.."]("..ThisDefinitionInfo.permalink..")",
        ["color"] = Config.EmbedColour,
        ["fields"] = {
            {
                ["name"] = ":thumbsup:",
                ["value"] = tostring(ThisDefinitionInfo.thumbs_up),
                ["inline"] = true
            },
            {
                ["name"] = ":thumbsdown:",
                ["value"] = tostring(ThisDefinitionInfo.thumbs_down),
                ["inline"] = true
            },
            {
                ["name"] = "Example",
                ["value"] = ThisDefinitionInfo.example,
                ["inline"] = false
            },
            {
                ["name"] = "Author",
                ["value"] = ThisDefinitionInfo.author,
                ["inline"] = true
            }
        }
    }

    if ThisDefinitionInfo.sound_urls and ThisDefinitionInfo.sound_urls[1] ~= nil then
        table.insert(UDEmbed.fields, { ["name"] = "Audio pronunciation", ["value"] = "["..ThisDefinitionInfo.word.."]("..ThisDefinitionInfo.sound_urls[1]..")", ["inline"] = true })
    end

    Payload:reply { 
        embed = UDEmbed
    }
end):SetCategory("Fun Commands"):SetDescription("Find Urban Dictionary definition of a term.")