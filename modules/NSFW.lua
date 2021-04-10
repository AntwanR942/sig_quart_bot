--[[ Variables ]]
local Categories = {
	"Anal",
	"Ass",
	"BDSM",
	"Boobs",
	"Creampie",
	"Fisting",
	"Gang",
	"Gaping",
	"Gay",
	"Lesbian",
	"Oral",
	"Petite",
	"Threesome",
	"Vulva"
}

local StaticExt = {
	["jpg"] = true,
	["jpeg"] = true,
	["png"] = true
}

--[[ Database ]]
local NSFWDB = SQL.open(Config.ModuleDir.."/NSFW")

--[[ Functions ]]
local function GetNSFW(Category, IsVideo)
	local Statement = F("SELECT URL, IsVideo FROM %s %s ORDER BY RANDOM() LIMIT 1;", Category, (IsVideo == true and "WHERE IsVideo = 'Yes'" or ""))

	local URL, IsVideo = NSFWDB:rowexec(Statement)

	if not URL or not IsVideo then return end

	return URL, (IsVideo == "No" and true or false)
end

for _, Category in pairs(Categories) do
	CommandManager.Command(Category:lower(), function(Args, Payload)
		local URL, IsEmbed = GetNSFW(Category, (Args[2] ~= nil and Args[2] == "video" and true or false))

		assert(URL ~= nil, "failed to retrieve NSFW content.")
		
		if IsEmbed then
			return Payload:reply {
				embed = {
					["color"] =   14782639,
					["image"] = {
						["url"] = URL
					}
				}
			}
		end

		Payload:reply(URL)
	end):SetCategory("Dirty Commands"):SetDescription("||**NSFW** "..Category.." content.||")
end