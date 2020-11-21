--[[ Variables ]]
PermissionatorFile = FileReader.readFileSync(ModuleDir.."/Permissionator9000.json")
if not PermissionatorFile then Log(2, "Couldn't find Permissionator9000.json, creating a new one... (Remember to add permissions to commands)"); FileReader.writeFileSync(ModuleDir.."/Permissionator9000.json", "[]") end
Permissionator = (PermissionatorFile ~= nil and PermissionatorFile ~= false and assert(JSON.decode(PermissionatorFile), "Failed to parse Permissionator9000.json, this is fatal!") or {})

--[[ External Function ]]
_G.HasPermission = function(Member, Command, Payload)
    if Member.guild.owner and Member.id == Payload.guild.owner.id then return true end
    if Permissionator[Command] == nil then return false end
    if Permissionator[Command].Roles["everyone"] == true then return true end
    if Member == nil or Member.roles == nil then return false end

    if Permissionator[Command].Users[Member.id] then return true end

    for Role in Member.roles:iter() do
        if Permissionator[Command].Roles[Role.id] then
            return true
        end
    end

    return false
end

function AuditPermission(Command, Type, ID, Allow, MRoles, MUsers)
    if Permissionator[Command] == nil then
        Permissionator[Command] = {
            ["Users"] = {},
            ["Roles"] = {}
        }
    end 

    if #MRoles > 0 then
        for Role in MRoles:iter() do
            if Role.id then
                Permissionator[Command]["Roles"][Role.id] = Allow
            end
        end  
    end

    if #MUsers > 0 then 
        for User in MUsers:iter() do
            if User.id then
                Permissionator[Command]["Roles"][User.id] = Allow
            end
        end 
    end
    
    if ID then
        Permissionator[Command][Type][ID] = Allow
    end
end

function GetCommandName(Args, Index)
    local SArgs = table.concat(Args, " ", Index)

    if SArgs:sub(1, 1) == [["]] then
        local Permission = SArgs:match([["(.-)"]])
        
        assert(Permission ~= nil and #Permission > 0, "you incorrectly formatted the permission name or category name.")

        return Permission
    end

    return Args[Index]
end


function SavePermissionatorFile()
    assert(FileReader.writeFileSync(ModuleDir.."/Permissionator9000.json", JSON.encode(Permissionator, { indent = Config.PrettyJSON })), "failed to save permissionator file.")
end

--[[ Command ]]
Permissionator9000 = CommandManager.Command("permissionator", function(Args, Payload)
    assert(Args[2], "you need to provide more information.")
end) 

--[[ Sub-Commands ]]
Permissionator9000:AddSubCommand("add", function(Args, Payload)
    assert(CommandManager.Exists(Args[3]), "that command doesn't exist.")
    assert(#(Payload.mentionedRoles) > 0 or #(Payload.mentionedUsers) > 0 or Payload.mentionsEveryone == true, "you need to provide role(s) and/or user(s) to add to the ``"..Args[3].."`` command permissions.")

    if Payload.mentionsEveryone == true then
        AuditPermission(Args[3], "Roles", "everyone", true, Payload.mentionedRoles, Payload.mentionedUsers)
    else
        AuditPermission(Args[3], _, _, true, Payload.mentionedRoles, Payload.mentionedUsers)
    end
    
    SavePermissionatorFile()

    SimpleEmbed(Payload, Payload.author.mentionString.." updated role(s) and/or user(s) permissions for command, ``"..Args[3].."``.")
end)

Permissionator9000:AddSubCommand("addc", function(Args, Payload)
    local Exists = false 
    local CommandCategory = GetCommandName(Args, 3)

    for _, Command in pairs(CommandManager.GetAllCommands()) do
        if Command:GetCategory() == CommandCategory then
            Exists = true

            break
        end
    end

    assert(Exists == true, "that command category doesn't exist.")
    assert(#(Payload.mentionedRoles) > 0 or #(Payload.mentionedUsers) > 0 or Payload.mentionsEveryone == true, "you need to provide role(s) and/or user(s) to add to the ``"..Args[3].."`` command category permissions.")

    for CommandName, Command in pairs(CommandManager.GetAllCommands()) do
        if Command:GetCategory() == CommandCategory then
            if Permissionator[CommandName] == nil then
                Permissionator[CommandName] = {
                    ["Users"] = {},
                    ["Roles"] = {}
                }
            end

            if Payload.mentionsEveryone == true then
                AuditPermission(CommandName, "Roles", "everyone", true, Payload.mentionedRoles, Payload.mentionedUsers)
            else
                AuditPermission(CommandName, _, _, true, Payload.mentionedRoles, Payload.mentionedUsers)
            end
        end
    end
    
    SavePermissionatorFile()

    SimpleEmbed(Payload, Payload.author.mentionString.." updated role(s) and/or user(s) permissions for command, ``"..CommandCategory.."``.")
end)

Permissionator9000:AddSubCommand("remove", function(Args, Payload)
    assert(CommandManager.Exists(Args[3]), "that command doesn't exist.")
    assert(#(Payload.mentionedRoles) > 0 or #(Payload.mentionedUsers) > 0 or Payload.mentionsEveryone == true, "you need to provide role(s) and/or user(s) to remove from the ``"..Args[3].."`` command permissions.")
    
    if Payload.mentionsEveryone == true then
        AuditPermission(Args[3], "Roles", "everyone", false, Payload.mentionedRoles, Payload.mentionedUsers)
    else
        AuditPermission(Args[3], _, _, false, Payload.mentionedRoles, Payload.mentionedUsers)
    end
    
    SavePermissionatorFile()

    SimpleEmbed(Payload, Payload.author.mentionString.." updated role(s) and/or user(s) permissions for command, ``"..Args[3].."``.")
end)

Permissionator9000:AddSubCommand("removec", function(Args, Payload)
    local Exists = false 
    local CommandCategory = GetCommandName(Args, 3)

    for _, Command in pairs(CommandManager.GetAllCommands()) do
        if Command:GetCategory() == CommandCategory then
            Exists = true

            break
        end
    end

    assert(Exists == true, "that command category doesn't exist.")
    assert(#(Payload.mentionedRoles) > 0 or #(Payload.mentionedUsers) > 0 or Payload.mentionsEveryone == true, "you need to provide role(s) and/or user(s) to remove from2 the ``"..Args[3].."`` command category permissions.")

    for CommandName, Command in pairs(CommandManager.GetAllCommands()) do
        if Command:GetCategory() == CommandCategory then
            if Permissionator[CommandName] == nil then
                Permissionator[CommandName] = {
                    ["Users"] = {},
                    ["Roles"] = {}
                }
            end

            if Payload.mentionsEveryone == true then
                AuditPermission(CommandName, "Roles", "everyone", false, Payload.mentionedRoles, Payload.mentionedUsers)
            else
                AuditPermission(CommandName, _, _, false, Payload.mentionedRoles, Payload.mentionedUsers)
            end
        end
    end
    
    SavePermissionatorFile()

    SimpleEmbed(Payload, Payload.author.mentionString.." updated role(s) and/or user(s) permissions for command, ``"..CommandCategory.."``.")
end)