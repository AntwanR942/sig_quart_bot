--[[ Variables ]]
TagArchiveFile = FileReader.readFileSync(ModuleDir.."/Tag.json")
if not TagArchiveFile then Log(2, "Couldn't load tag cache file, creating a new one..."); FileReader.writeFileSync(ModuleDir.."/Tag.json", "[]") end
TagArchive = (TagArchiveFile ~= nil and TagArchiveFile ~= false and assert(JSON.decode(TagArchiveFile), "Failed to parse reminder cache.") or {})

TagLengthLimit = 200
TagNameLimit = 50

--[[ Funcs ]]

function GetTag(Args, Index)
    local SArgs = ReturnRestOfCommand(Args, (Index ~= nil and Index or 3))

    if SArgs:sub(1, 1) == [["]] then
        local Tag = SArgs:match([["(.-)"]])
        assert(Tag ~= nil and #Tag > 0, "you incorrectly formatted the tag name.")

        local TagEndArgIndex = assert(#Tag:split(" "), "failed to find the number of words in tag name")

        return { Tag, 3 + TagEndArgIndex }
    end

    return { Args[(Index ~= nil and 2 or 3)], 4 }
end

function SaveTagFile()
    assert(FileReader.writeFileSync(ModuleDir.."/Tag.json", JSON.encode(TagArchive, { indent = Config.PrettyJSON })), "failed to save tag file.")
end

--[[ Command ]]
Tag = CommandManager.Command("tag", function(Args, Payload)
    assert(Args[2], "")

    local Tag = ReturnRestOfCommand(Args, 2)
    assert(TagArchive[Tag], "tag ``"..Tag.."`` does not exist.\nTo create a tag use, \n``"..Config.Prefix.."tag add name value`` or ``"..Config.Prefix..'tag add "long name" value``')

    Payload:reply(TagArchive[Tag].Value)
    TagArchive[Tag].Uses = TagArchive[Tag].Uses + 1
    
    SaveTagFile()
end):SetCategory("Fun Commands"):SetDescription("Tag System, i.e. ``"..Config.Prefix.."tag tag_name`` or ``"..Config.Prefix..'tag "tag name"``')

--[[ Sub-Commands ]]
Tag:AddSubCommand("add", function(Args, Payload)
    assert(Args[3], "")   

    local TagInfo = assert(GetTag(Args), "there was an issue formatting the tag name")
    local Tag, TagEndArgIndex = TagInfo[1], TagInfo[2]

    assert(not TagArchive[Tag], "tag ``"..Tag.."`` already exists.\nUse ``"..Config.Prefix.."tag edit`` to change it.")
    assert(Args[TagEndArgIndex], "you need to provide a value for the tag.")

    local TagValue = ReturnRestOfCommand(Args, TagEndArgIndex)
    assert(#TagValue <= TagLengthLimit and #Tag <= TagNameLimit, "your tag value or name is too long.")

    TagArchive[Tag] = { ["OwnerID"] = Payload.author.id, ["Value"] = TagValue, ["Uses"] = 0 }
    SaveTagFile()

    SimpleEmbed(Payload, "Successfully added tag ``"..Tag.."``.")
end):SetDescription("Add your own tag, ``i.e. "..Config.Prefix.."tag add foo bar`` or ``"..Config.Prefix..'add "foo bar" hello world``')

Tag:AddSubCommand("remove", function(Args, Payload)
    assert(Args[3], "") 

    local TagInfo = assert(GetTag(Args), "there was an issue formatting the tag name")
    local Tag = TagInfo[1]
    assert(TagArchive[Tag], "tag ``"..Tag.."`` doesn't exist.")
    assert(TagArchive[Tag].OwnerID == Payload.author.id or Payload.author.id == Payload.guild.owner.id, "you do not have permission to remove tag ``"..Tag.."``. You must be the tag owner.")

    TagArchive[Tag] = nil
    SaveTagFile()

    SimpleEmbed(Payload, "Successfully removed tag ``"..Tag.."``.")
end):SetDescription("Remove a tag that you own.")

Tag:AddSubCommand("edit", function(Args, Payload)
    assert(Args[3], "")   

    local TagInfo = assert(GetTag(Args), "there was an issue formatting the tag name")
    local Tag, TagEndArgIndex = TagInfo[1], TagInfo[2]

    assert(TagArchive[Tag], "tag ``"..Tag.."`` doesn't exist.")
    assert(TagArchive[Tag].OwnerID == Payload.author.id or Payload.author.id == Payload.guild.owner.id, "you do not have permission to edit tag ``"..Tag.."``. You must be the tag owner.")

    local TagValue = ReturnRestOfCommand(Args, TagEndArgIndex)
    assert(#TagValue <= TagLengthLimit and #Tag <= TagNameLimit, "your tag value or name is too long.")

    TagArchive[Tag] = { ["OwnerID"] = Payload.author.id, ["Value"] = TagValue, ["Uses"] = TagArchive[Tag].Uses }
    SaveTagFile()

    SimpleEmbed(Payload, "Successfully edited tag ``"..Tag.."``.")
end):SetDescription("Edit a tag that you own, ``i.e. "..Config.Prefix.."tag edit tag_name value`` or ``"..Config.Prefix..'tag edit "tag name" value``')