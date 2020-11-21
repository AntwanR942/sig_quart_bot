--[[ Sandbox ]]
LuaSandbox = setmetatable({
    require = require,
    Discordia = Discordia,

    JSON = JSON,
    Routine = Routine,
    HTTP = HTTP,
    Spawn = Spawn,
    FileReader = FileReader,
    PP = PP,

    Config = Config,

    Log = Log, 
    Logger = Logger,
    Round = Round,
    SimpleEmbed = SimpleEmbed,
    ReturnRestOfCommand = ReturnRestOfCommand,
}, { __index = _G })

--[[ Function ]]
function PrintLine(...)
	local Temp = {}

	for i = 1, select("#", ...) do
		table.insert(Temp, tostring(select(i, ...)))
    end
    
	return table.concat(Temp, "\t")
end

--[[ Command ]]
CommandManager.Command("lua", function(Args, Payload)
    if Args[2] then
        local ArgString = ReturnRestOfCommand(Args, 2):gsub("```lua\n?", ""):gsub("```\n?", "")

        local ReturnLines = {}
    
        LuaSandbox.Payload = Payload
        LuaSandbox.ChannelOBJ = Payload.channel
        LuaSandbox.GuildOBJ = Payload.guild
        LuaSandbox.print = function(...) 
            table.insert(ReturnLines, PrintLine(...)) 
        end
        LuaSandbox.p = function(...) 
            table.insert(ReturnLines, PrintLine(...)) 
        end
    
        local Func, Err = loadstring(ArgString, "@Lua", "t", LuaSandbox)
        if not Func then 
            return Payload:reply { content = Err, code = "md" }
        end
    
        local Success, RuntimeErr = pcall(function() table.pack(Func()) end)
        if not Success then
            return Payload:reply { content = RuntimeErr, code = "md" }
        end

        ReturnLines = table.concat(ReturnLines, "\n")
        
        if #ReturnLines > 2048 then
            return Payload:reply {
                embed = SimpleEmbed(_, Payload.author.mentionString.." the output of the code you ran is too large, check file attached."),
                file = { "out.txt",  ReturnLines}
            }
        end
    
        SimpleEmbed(Payload, "**Output**\n \n```lua\n"..(#ReturnLines == 0 and "nil" or ReturnLines).."```")
    end
end)