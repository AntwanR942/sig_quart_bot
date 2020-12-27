--[[ Variables ]]
ReminderCacheFile = FileReader.readFileSync(ModuleDir.."/Reminder.json")
if not ReminderCacheFile then Log(2, "Couldn't load reminder cache file, creating a new one..."); FileReader.writeFileSync(ModuleDir.."/Reminder.json", "[]") end
ReminderCache = (ReminderCacheFile ~= nil and ReminderCacheFile and assert(JSON.decode(ReminderCacheFile), "failed to parse Reminder.json, command "..Config.Prefix.."remind will not work.") or {})

MaxReminderLength = 500

function SaveReminderFile()
    assert(FileReader.writeFileSync(ModuleDir.."/Reminder.json", JSON.encode(ReminderCache)), "failed to save Reminder.json file.")
end


--[[ Init ]]
for k, Reminder in pairs(ReminderCache) do
    if Reminder.Time <= os.time() then
        Log(2, "Reminder ended when during offline period.")

        ReminderCache[k] = nil
    else
        Log(2, "Restarted reminder...")

        Routine.setTimeout((Reminder.Time-os.time())*1000, coroutine.wrap(function()
            BOT:getChannel(Reminder.ReminderCID):send {
                embed = SimpleEmbed(_, "<@"..Reminder.Owner.."> your reminder from ``"..os.date("%d/%m/%y @ %X", Reminder.StartTime).."``\n \n"..Reminder.Text)
            }
        
            ReminderCache[k] = nil
            SaveReminderFile()
        end))
    end
end 

SaveReminderFile()

--[[ Command ]]
CommandManager.Command("remind", function(Args, Payload)
    assert(Args[2] ~= nil, "")

    local CommandS = ReturnRestOfCommand(Args, 2, " ", 4).." "
    local Days = CommandS:match("(%d+)d ")
    local Hours = CommandS:match("(%d+)h ")
    local Minutes = CommandS:match("(%d+)m ")
    local ArgIgnore = 0
    
    if Days then 
        Days = tonumber(Days)
        assert(Days > 0 and Days <= 365, "you specified too many or too few days.")
        ArgIgnore = ArgIgnore + 1
    end

    if Hours then
        Hours = tonumber(Hours)
        assert(Hours > 0 and Hours <= 24, "you specified too many or too few hours.")
        ArgIgnore = ArgIgnore + 1
    end

    if Minutes then
        Minutes = tonumber(Minutes)
        assert(Minutes > 0 and Minutes <= 60, "you specified too many or too few Minutes.")
        ArgIgnore = ArgIgnore + 1
    end

    assert(ArgIgnore ~= 0, "please provide a valid time for your reminder.")

    local ReminderText = ReturnRestOfCommand(Args, 2+ArgIgnore)
    assert(ReminderText and (#ReminderText > 0) and (#ReminderText <= MaxReminderLength), "your reminder is either too short or too long.")

    local RemindTime = (Minutes ~= nil and (Minutes * 60) or 0) + (Hours ~= nil and (Hours * 60 * 60) or 0) + (Days ~= nil and (Days * 24 * 60 * 60) or 0)
    local ReminderCacheIndex = (#ReminderCache + 1)

    local Reminder = {
        ["Text"] = ReminderText,
        ["Time"] = (os.time() + RemindTime),
        ["StartTime"] = os.time(),
        ["Owner"] = Payload.author.id,
        ["ReminderCID"] = Payload.channel.id
    }
    ReminderCache[ReminderCacheIndex] = Reminder

    assert(Routine.setTimeout(RemindTime*1000, coroutine.wrap(function()
        Payload.channel:send {
            embed = SimpleEmbed(nil, "<@"..ReminderCache[ReminderCacheIndex].Owner.."> your reminder from ``"..os.date("%d/%m/%y @ %X", ReminderCache[ReminderCacheIndex].StartTime).."``\n \n"..ReminderCache[ReminderCacheIndex].Text)
        }
    
        ReminderCache[ReminderCacheIndex] = nil
        SaveReminderFile()
    end)), "failed to set timeout for reminder")

    SimpleEmbed(Payload, "Reminder set for ``"..os.date("%d/%m/%y @ %X", Reminder.Time).."``")

    SaveReminderFile()
end):SetCategory("Fun Commands"):SetDescription("Set a reminder, ``i.e. "..Config.Prefix.."remind 4d 20m hand in homework``.")