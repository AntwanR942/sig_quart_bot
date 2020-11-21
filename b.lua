--[[ External Librarys ]]
JSON = require("json")
Routine = require("timer")
HTTP = require("coro-http")
Query = require("querystring")
Spawn = require("coro-spawn")
FileReader = require("fs")
PP = require("pretty-print")

--[[ Config ]]
Config, ConfigErr = FileReader.readFileSync("Config.json")
if not Config then 
	print(os.date("%F @ %T", os.time()).." | [WARNING] | Reverting to default config "..(ConfigErr ~= nil and (": "..ConfigErr) or ""))
	Config = {
		["EmbedColour"] = "3092790",
		["Prefix"] = ".",
		["ModuleDir"] = "./modules",
		["_DEBUG"] = false
	}
else
	Config = assert(JSON.decode(Config), "failed to parse Config.json.")
end

--[[ Discord Utils ]]
Discordia = require("discordia")
BOT = Discordia.Client {
	cacheAllMembers = true,
	dateTime = "%F @ %T",
	logLevel = (Config._DEBUG == false and 3 or 4)
}
Discordia.extensions()

--[[ Command Handler ]]
CommandManager = require("CM")

--[[ Logger ]]
Logger = Discordia.Logger((Config._DEBUG == false and 3 or 4), "%F @ %T")
Log = function(Level, ...) if Config._DEBUG == false and Level > 2 then return end Logger:log(Level, ...) end

--[[ Functions ]]
function SimpleEmbed(Payload, Description)
	local Embed = {
		["description"] = Description,
		["color"] = Config.EmbedColour
	}

	return (Payload ~= nil and Payload:reply {
		embed = Embed
	} or Embed)
end

function ReturnRestOfCommand(AllArgs, StartIndex, Seperator, EndIndex)
    return table.concat(AllArgs, (Seperator ~= nil and type(Seperator) == "string" and Seperator or " "), StartIndex, EndIndex)
end

function KillBOT()
	_G = nil

	process:exit(1)
end

--[[ Module Func ]]
function LoadModule(Module)
	local FilePath = Config.ModuleDir.."/"..Module..".lua"
	local Code = assert(FileReader.readFileSync(FilePath))
	local Func = assert(loadstring(Code, "@"..Module, "t", ModuleENV))

	return (Func() or {})
end

--[[ Init ]]
do
	local _Token = assert(FileReader.readFileSync("./.token"), "Could not find bot token. Please create a file called .token in the directory of your bot and put your bot token inside of it.")

	ModuleENV = setmetatable({
		require = require,

		LoadModule = LoadModule,

		Discordia = Discordia,
		BOT = BOT,

		JSON = JSON,
		Routine = Routine,
		HTTP = HTTP,
		Spawn = Spawn,
		FileReader = FileReader,
		PP = PP,
		Query = Query,

		Config = Config,

		CommandManager = CommandManager,

		Log = Log, 
		Logger = Logger,
		Round = math.round,
		SimpleEmbed = SimpleEmbed,
		ReturnRestOfCommand = ReturnRestOfCommand,

		ModuleDir = Config.ModuleDir
	}, {__index = _G})

	assert(FileReader.existsSync(Config.ModuleDir), "Could not find module directory, are you sure it is valid?")

	for File, Type in FileReader.scandirSync(Config.ModuleDir) do
		if Type == "file" then
			local FileName = File:match("(.*)%.lua")
			if FileName then
				local Suc, Err = pcall(LoadModule, FileName)

				if Suc == true then
					Log(3, "Module loaded: "..FileName)
				else
					Log(1, "Failed to load module "..FileName.." ["..Err.."]")

					if Err:lower():find("fatal") ~= nil then
						KillBOT()
					end
				end
			end
		end
	end

	BOT:run("Bot ".._Token)
end