--[[ Variables ]]
Adjectives = assert(JSON.decode(FileReader.readFileSync(ModuleDir.."/RName.json")), "failed to open random name file, command "..Config.Prefix.."rname will not work.") 

--[[ Command ]]
CommandManager.Command("rname", function(Args, Payload)
    local Amount = 2
    if Args[2] and tonumber(Args[2]) ~= nil then
        Amount = tonumber(Args[2])
    end

    assert(Amount >= 1 and Amount <= 10, "you specified too many or too few words.")

    local RandomName = {}

    math.randomseed(os.time())

    for i = 1, Amount, 1 do
        repeat
            RandIndex = math.random(1, #Adjectives)
        until (RandomName[Adjectives[RandIndex]] == nil)

        RandomName[Adjectives[RandIndex]] = true
    end

    SimpleEmbed(Payload, "``"..table.concat(table.keys(RandomName), "-").."``")
end):SetCategory("Fun Commands"):SetDescription("Generates 2 (or more if you specify) adjectives.")