-- [[ Variables ]]
local Connections = {}
local CurrentlyPlaying = {}
local Queue = {}

--[[ Functions ]]
local function YTJSON(URL, SearchFor, Payload)
    local TempArgs = (SearchFor ~= nil and SearchFor == true and 
        { "--default-search", "ytsearch", "--dump-json", URL, "--external-downloader", "aria2c", "--external-downloader-args", '"-x -s 8 -k 1M"' } or 
        {                                 "--dump-json", URL, "--external-downloader", "aria2c", "--external-downloader-args", '"-x -s 8 -k 1M"' })

    local YoutubeDL = Spawn("youtube-dl", {
        args = TempArgs,
        stdio = { 0, true, 2 }
    })

    local YoutubeDLOut = YoutubeDL.stdout.read
    local YoutubeDLData

    for Res in YoutubeDLOut do
        if not Res:find("ERROR") then
            YoutubeDLData = JSON.decode(Res)
            
            break
        end
	end

    if not YoutubeDLData then 
        return false, "I couldn't find what you were looking for."
    end

    local VideoData = {}

    for _, Format in pairs(YoutubeDLData.formats) do
        if Format.acodec == nil or Format.acodec ~= "none" then
            if Format and Format.format and Format.url then
                VideoData.FFmpegURL = Format.url

                break
            end
        end
    end

    if not VideoData.FFmpegURL or not YoutubeDLData.duration then 
        return false, "I couldn't find suitable information for your request." 
    end

    VideoData.Title = (YoutubeDLData.title or "Unknown Title")
    VideoData.Thumbnail = (YoutubeDLData.thumbnail or "")
	VideoData.VideoURL = (YoutubeDLData.webpage_url or "")
	VideoData.Duration = YoutubeDLData.duration
	VideoData.Playerr = Payload.author.mentionString
	VideoData.Channel = Payload.channel
	VideoData.Seeks = 0
	VideoData.Paused = false
	VideoData.PauseTime = 0

    return true, VideoData
end

local function SecondsToClock(Seconds)
	local Seconds = tonumber(Seconds)

    if Seconds > 0 then
        if Seconds < 3600 then
            return os.date('!%M:%S', Seconds)
        end

        return os.date('!%H:%M:%S', Seconds)
    end
    
    return "??:??"
end

local function CheckSeekFormat(Seek)
    local Formatted = (Seek:match("^(%d+:%d+)$") or Seek:match("^(%d+:%d+:%d+)$"))
    if Formatted then
        if #Formatted == 5 then
            Formatted = "00:"..Formatted
        end
        
        if #Formatted == 8 then
			local Times = Formatted:split(":")
			local Seconds = 0
			for i = #Times, 1, -1 do
				local TimeN = tonumber(Times[i])
				if  TimeN ~= nil then
					if #Times[i] > 2 then 
						return false, 0
					end

					if i ~= 3 then
     					TimeN = TimeN * (60^(i == 2 and 1 or 2))
					end

					Seconds = Seconds + TimeN
				end
			end

			return Formatted, Seconds
        end
    end

    return false, 0
end

local function CalculateTimeElapsed(AudioData)
    local TimeElapsed 

    if AudioData.Seeks > 0 and AudioData.SeekStart ~= nil and AudioData.SeekTime ~= nil then
        TimeElapsed = AudioData.SeekTime + (os.time() - AudioData.SeekStart)
    else
        TimeElapsed = os.time() - AudioData.StartTime
    end
    
    local TimeElapsed = TimeElapsed - AudioData.PauseTime 
    
    if AudioData.Paused == true then
        TimeElapsed = TimeElapsed - (os.time() - AudioData.PauseStart)
    end

    return TimeElapsed
end

--[[ Commands ]]
CommandManager.Command("summon", function(Args, Payload)
    assert(Connections[Payload.guild.id] == nil, "I'm already connected to a channel.")

    Connections[Payload.guild.id] = Payload.member.voiceChannel:join()
end):SetCategory("Music Commands")

CommandManager.Command("dc", function(Args, Payload)
    assert(Connections[Payload.guild.id] ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel and Connections[Payload.guild.id].channel and Payload.member.voiceChannel == Connections[Payload.guild.id].channel, "you need to be in the same channel as me.")

    Connections[Payload.guild.id]:close()
end):SetCategory("Music Commands")

CommandManager.Command("play", function(Args, Payload)
    assert(Args[2], "")
    assert(Payload.member.voiceChannel ~= nil, "you need to be connected to a channel.")
    local MemberChannel = Payload.member.voiceChannel

    assert(not Connections[Payload.guild.id] or Connections[Payload.guild.id].channel and Connections[Payload.guild.id].channel == MemberChannel, "I'm connected to another channel at the moment.")
    if not Connections[Payload.guild.id] then
        Connections[Payload.guild.id] = MemberChannel:join()
    end

    local BOTConnection = Connections[Payload.guild.id]

    local SearchFor = false
    local Search

    if not Args[3] and Args[2]:match("https?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))") then
        Query = Args[2]
    else
        Query = ReturnRestOfCommand(Args, 2)
        SearchFor = true
        Search, _ = Payload:reply {
            embed = SimpleEmbed(nil, F("%s searching for ``%s``", Payload.author.mentionString, Query))
        }
    end

    local Suc, AudioData = YTJSON(Query, SearchFor, Payload)

    assert(Suc == true, AudioData)

    if Search then
        Search:delete()
    end

    if not CurrentlyPlaying[Payload.guild.id] then
        CurrentlyPlaying[Payload.guild.id] = AudioData

        BOTConnection:playFFmpeg(AudioData.FFmpegURL, _, _, function()
            CurrentlyPlaying[Payload.guild.id].StartTime = os.time()

            CurrentlyPlaying[Payload.guild.id].Message, _ = Payload:reply { 
                embed = {
                    ["description"] = F("**Now playing**\n[%s](%s) [%s]", AudioData.Title, AudioData.VideoURL, Payload.author.mentionString),
                    ["color"] = Config.EmbedColour,
                    ["thumbnail"] = {
                        ["url"] = AudioData.Thumbnail
                    }
                }
            }
        end)
    else
        table.insert(Queue, AudioData)

        AudioData.Message, _ = Payload:reply { 
            embed = {
                ["description"] = F("**Added to the queue**\n[%s](%s) [%s]", AudioData.Title, AudioData.VideoURL, Payload.author.mentionString),
                ["thumbnail"] = {
                    ["url"] = AudioData.Thumbnail
                },
                ["color"] = Config.EmbedColour,
                ["footer"] = {
                    ["icon_url"] = Payload.guild.iconURL,
                    ["text"] = F("Pos %s | %s", #Queue == 1 and "next" or tostring(#Queue), BOT.user.name)
                }
            }
        }
    end
end):SetCategory("Music Commands"):AddAlias("p")

CommandManager.Command("skip", function(Args, Payload)
    assert(Connections[Payload.guild.id] ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel == Connections[Payload.guild.id].channel, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying[Payload.guild.id] ~= nil, "nothing is playing at the moment.")

    local BOTConnection = Connections[Payload.guild.id]
    local AudioData = CurrentlyPlaying[Payload.guild.id]

    if AudioData.Message then
        AudioData.Message:delete()
    end

    if #Queue > 0 then
        CurrentlyPlaying[Payload.guild.id] = Queue[1]
        local AudioData = CurrentlyPlaying[Payload.guild.id]

        if AudioData.Message then
            AudioData.Message:delete()
        end

        table.remove(Queue, 1)

        BOTConnection:playFFmpeg(AudioData.FFmpegURL, _, _, function()
            AudioData.StartTime = os.time()

            AudioData.Message, _ =  Payload:reply { 
                embed = {
                    ["description"] = F("**Now playing**\n[%s](%s) [%s]", AudioData.Title, AudioData.VideoURL, Payload.author.mentionString),
                    ["color"] = Config.EmbedColour,
                    ["thumbnail"] = {
                        ["url"] = AudioData.Thumbnail
                    }
                }
            }
        end)
    else
        BOTConnection:stopStream()
        CurrentlyPlaying[Payload.guild.id] = nil
    end
end):SetCategory("Music Commands"):AddAlias("s")

CommandManager.Command("pause", function(Args, Payload)
    assert(Connections[Payload.guild.id] ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel == Connections[Payload.guild.id].channel, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying[Payload.guild.id] ~= nil, "nothing is playing at the moment.")
    assert(CurrentlyPlaying[Payload.guild.id].Paused == false, "")

    Connections[Payload.guild.id]:pauseStream()
    CurrentlyPlaying[Payload.guild.id].Paused = true
    CurrentlyPlaying[Payload.guild.id].PauseStart = os.time()
end):SetCategory("Music Commands")

CommandManager.Command("resume", function(Args, Payload)
    assert(Connections[Payload.guild.id] ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel == Connections[Payload.guild.id].channel, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying[Payload.guild.id] ~= nil, "nothing is playing at the moment.")
    assert(CurrentlyPlaying[Payload.guild.id].Paused == true, "")

    local AudioData = CurrentlyPlaying[Payload.guild.id]

    Connections[Payload.guild.id]:resumeStream()
    AudioData.Paused = false
    AudioData.PauseTime = AudioData.PauseTime + (os.time() - AudioData.PauseStart)
end):SetCategory("Music Commands")

CommandManager.Command("seek", function(Args, Payload)
    assert(Connections[Payload.guild.id] ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel == Connections[Payload.guild.id].channel, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying[Payload.guild.id] ~= nil, "nothing is playing at the moment.")
    
    local Prefix = Config.Prefix
    assert(Args[2], F("%s no seek arguments provided.\nI.e. ``%sseek 00:01:30`` or ``%sseek 01:30`` (``HH:MM:SS`` or ``MM:SS``)", Payload.author.mentionString, Prefix, Prefix))

    local SeekFormat, SeekTime = CheckSeekFormat(Args[2])
    local AudioData = CurrentlyPlaying[Payload.guild.id]
    assert(SeekFormat, F("you did format the seek command properly.\nI.e. ``%sseek 00:01:30`` or ``%sseek 01:30`` (``HH:MM:SS`` or ``MM:SS``)", Payload.author.mentionString, Prefix, Prefix))
    assert(SeekTime <= AudioData.Duration, F("the time you requested to seek to is longer than the duration of [%s](%s)", AudioData.Title, AudioData.VideoURL))

    AudioData.Seeks = AudioData.Seeks + 1
    AudioData.SeekTime = SeekTime

    Connections[Payload.guild.id]:playFFmpeg(AudioData.FFmpegURL, _, { { "-ss", SeekTime, 7 } }, function()
        AudioData.SeekStart = os.time()
    end)
end):SetCategory("Music Commands")

CommandManager.Command("time", function(Args, Payload)
    assert(Connections[Payload.guild.id] ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel == Connections[Payload.guild.id].channel, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying[Payload.guild.id] ~= nil, "nothing is playing at the moment.")

    local AudioData = CurrentlyPlaying[Payload.guild.id]
    local TimeElapsed = CalculateTimeElapsed(AudioData)
    
    if TimeElapsed > AudioData.Duration then
        TimeElapsed = AudioData.Duration
    end

    Payload:reply{ 
        embed = {
            ["description"] = F("[%s](%s) [%s]\n%s⚪%s %s/%s", AudioData.Title, AudioData.VideoURL, AudioData.Playerr, ("▬"):rep((TimeElapsed/AudioData.Duration*20)-1), ("▬"):rep((20-(TimeElapsed/AudioData.Duration*20))), SecondsToClock(TimeElapsed), SecondsToClock(AudioData.Duration)),
            ["thumbnail"] = {
                ["url"] = AudioData.Thumbnail
            },
            ["color"] = Config.EmbedColour,
            ["footer"] = {
                ["icon_url"] = Payload.guild.iconURL,
            }
        }
    }
end):SetCategory("Music Commands")

CommandManager.Command("queue", function(Args, Payload) 
    -- TODO: Add pages for a long queue
    -- TODO: Make use of string padding.
    assert(Connections[Payload.guild.id] ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel == Connections[Payload.guild.id].channel, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying[Payload.guild.id] ~= nil, "nothing is playing at the moment.")

    local AudioData = CurrentlyPlaying[Payload.guild.id]
    local QueueString = F("  Title%s| Duration\n", (" "):rep(35))
    for i = 0, #Queue, 1 do
        local QueueItem = (i == 0 and AudioData or Queue[i])
        local QueueTitle = (#QueueItem.Title > 39 and QueueItem.Title:sub(1, 38).."…" or QueueItem.Title)

        QueueString = 
            QueueString..
            (i == 0 and AudioData.Paused == true and "∥" or i == 0 and AudioData.Paused == false and "→" or "↳")..
            " "..
            QueueTitle..
            string.rep(" ", (39-#QueueTitle))..
            " | "..
            SecondsToClock(QueueItem.Duration)..
            "\n"
    end

    SimpleEmbed(Payload, F("```%s```", QueueString))
end):SetCategory("Music Commands")

ClearQeue = CommandManager.Command("clearqueue", function(Args, Payload)
    Queue = {}

    SimpleEmbed(Payload, Payload.author.mentionString.." queue has been cleared.")
end):SetCategory("Music Commands")


--[[ Voice Channel Events ]]
BOT:on("voiceDisconnect", function(Member)
	coroutine.wrap(function()
		if Member.user and Member.user == BOT.user then

            if Connections[Member.guild.id] then
			    Connections[Member.guild.id] = nil
            end
            
            local AudioData = CurrentlyPlaying[Member.guild.id]

            if AudioData and AudioData.Message then
                AudioData.Message:delete()
            end

			CurrentlyPlaying[Member.guild.id] = nil
			Queue = {}
		end
	end)()
end)

BOT:on("voiceChannelJoin", function(Member, Channel)
	coroutine.wrap(function()
		if Member.user == BOT.user then
			Member:deafen()
		end
	end)()
end)

--[[ Queue Manager ]]
Routine.setInterval(1000, function()
    coroutine.wrap(function()
        for _, BOTConnection in pairs(Connections) do
            if BOTConnection.channel then
                local AudioData = CurrentlyPlaying[BOTConnection.channel.guild.id]

                if AudioData and AudioData.StartTime then
                    if CalculateTimeElapsed(AudioData) >= AudioData.Duration then
                        if AudioData.Message then
                            AudioData.Message:delete()
                        end

                        if #Queue > 0 then
                            CurrentlyPlaying[BOTConnection.channel.guild.id] = Queue[1]
                            table.remove(Queue, 1)

                            local AudioData = CurrentlyPlaying[BOTConnection.channel.guild.id]
        
                            if AudioData.Message then
                                AudioData.Message:delete()
                            end
        
                            AudioData.Message, _ = BOTConnection.Channel:send { 
                                embed = {
                                    ["description"] = F("**Now playing**\n[%s](%s) [%s]", AudioData.Title, AudioData.VideoURL, AudioData.Playerr),
                                    ["color"] = Config.EmbedColour,
                                    ["thumbnail"] = {
                                        ["url"] = AudioData.Thumbnail
                                    }
                                }
                            }
        
                            BOTConnection:playFFmpeg(AudioData.FFmpegURL, _, _, function()
                                AudioData.StartTime = os.time()
                            end)
                        else
                            CurrentlyPlaying[BOTConnection.channel.guild.id] = nil
                            BOTConnection:stopStream()
                        end
                    end
                end 
            end
        end
    end)()
end)