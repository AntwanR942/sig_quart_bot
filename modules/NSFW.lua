--[[ Variables ]]
URLExt = {
    ".jpg",
    ".jpeg",
    ".png"
}

NSFWFolder = "NSFW/"
assert(FileReader.existsSync(ModuleDir.."/"..NSFWFolder), "Coulnd't find NSFW folder ("..ModuleDir.."/"..NSFWFolder..").")

--[[ Functions ]]
function GetNSFW(Type, Video)
	local Content = FileReader.readFileSync(ModuleDir.."/"..NSFWFolder..Type..(Video ~= nil and Video or "")..".txt")
	if Content then
		Content = Content:split("\n")
		math.randomseed(os.time())
		local RandomIndex = math.floor(math.random() * #Content)
		local URL = Content[RandomIndex]
		if URL then 
			local IsEmbed = false
            for _, Ext in pairs(URLExt) do
                if URL:find(Ext) then
                    IsEmbed = true
                end
			end

			return URL, IsEmbed
		end
	end

	return nil
end

--[[ Command Generator ]]
for Dirty, _ in FileReader.scandirSync(ModuleDir.."/"..NSFWFolder) do
	if Dirty:find("_") == nil then
		Dirty = Dirty:gsub(".txt", "")
		CommandManager.Command(Dirty:lower(), function(Args, Payload)
			local URL, IsEmbed = GetNSFW(Dirty, (Args[2] ~= nil and Args[2] == "video" and "_videos" or nil))

			assert(URL ~= nil, "failed to retrieve NSFW content.")
			
			if IsEmbed then
				Payload:reply {
					embed = {
						["color"] =   14782639,
						["image"] = {
							["url"] = URL
						}
					}
				}
			else
				Payload:reply(URL)
			end
		end):SetCategory("Dirty Commands"):SetDescription("||**NSFW** "..Dirty.." content.||")
	end
end