--[[ Command ]]
CommandManager.Command("help", function(Args, Payload)
	local HelpCommands = {}
	local HelpSubCommands = {}
	for CommandName, Command in pairs(CommandManager.GetAllCommands()) do
		local CommandCategory = Command:GetCategory()
		local CommandName = Command:GetName()
		local CommandDescription = Command:GetDescription()

		if CommandCategory then
			if HelpCommands[CommandCategory] == nil then
				HelpCommands[CommandCategory] = {}
			end

			local CommandDescription = (CommandDescription ~= nil and "*"..CommandDescription.."*" or "")

			table.insert(HelpCommands[CommandCategory], "``"..Config.Prefix..CommandName.."``".." "..CommandDescription)
			local SubCommands = CommandManager.GetAllSubCommands(CommandName)
			if SubCommands then
				HelpSubCommands[CommandName] = {}
				for _, SubCommand in pairs(SubCommands) do
					table.insert(HelpSubCommands[CommandName], "\t``↳ "..SubCommand:GetName().."`` "..(SubCommand:GetDescription() ~= nil and "*"..SubCommand:GetDescription().."*" or ""))
				end
			end
		end
	end

	local HelpEmbed = {
		["title"] = "Here are all of my commands",
		["color"] = Config.EmbedColour,
		["description"] = "",
		["footer"] = {
			["icon_url"] = Payload.guild.iconURL,
			["text"] = Payload.guild.name
		}
	}

	for CommandCategory, Commands in pairs(HelpCommands) do
		HelpEmbed.description = HelpEmbed.description.."\n\n"..CommandCategory
		for _, Command in pairs(Commands) do
			local CommandName = Command:match("``"..Config.Prefix.."(%a+)``")
			HelpEmbed.description = HelpEmbed.description.."\n"..Command..(CommandName ~= nil and HelpSubCommands[CommandName] ~= nil and "\n"..table.concat(HelpSubCommands[CommandName], "\n") or "")
		end
	end

	Payload:reply {
		embed = HelpEmbed
	}
end)