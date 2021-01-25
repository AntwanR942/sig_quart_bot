-- [[ Variables ]]
local BOTConnection
local Queue = {}
local LastMessage = nil

--[[ Functions ]]
function YTJSON(URL, SearchFor, Payload)
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

    if not YoutubeDLData then return { ["Error"] = "I couldn't find what you were looking for." } end

    local VideoData = {}

    for _, Format in pairs(YoutubeDLData.formats) do
        if Format.acodec == nil or Format.acodec ~= "none" then
            if Format and Format.format and Format.url then
                VideoData.FFmpegURL = Format.url

                break
            end
        end
    end

    if not VideoData.FFmpegURL or not YoutubeDLData.duration then return { ["Error"] = "I couldn't find suitable information for your request." } end

    VideoData.Title = (YoutubeDLData.title or "Unknown Title")
    VideoData.Thumbnail = (YoutubeDLData.thumbnail or "")
	VideoData.VideoURL = (YoutubeDLData.webpage_url or "")
	VideoData.Duration = YoutubeDLData.duration
	VideoData.Playerr = Payload.author.mentionString
	VideoData.Channel = Payload.channel
	VideoData.Seeks = 0
	VideoData.Paused = false
	VideoData.PauseTime = 0

    return VideoData
end

function SecondsToClock(Seconds)
	local Seconds = tonumber(Seconds)

    if Seconds > 0 then
        if Seconds < 3600 then
            return os.date('!%M:%S', Seconds)
        end

        return os.date('!%H:%M:%S', Seconds)
    end
    
    return "N/A"
end

function CheckSeekFormat(Seek)
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

--[[ Commands ]]
CommandManager.Command("summon", function(Args, Payload)
    assert(BOTConnection.channel == nil, "I'm already connected to a channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel.id == BOTConnection.channel.id, "you need to be in the same channel as me.")
    local MemberChannel = Payload.member.voiceChannel
    
    BOTConnection = MemberChannel:join()
end):SetCategory("Music Commands")

CommandManager.Command("dc", function(Args, Payload)
    assert(BOTConnection.channel, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel.id == BOTConnection.channel.id, "you need to be in the same channel as me.")

    BOTConnection:close()
end):SetCategory("Music Commands")

CommandManager.Command("play", function(Args, Payload)
    assert(Args[2], "")
    assert(Payload.member.voiceChannel ~= nil, "you need to be connected to a channel.")
    local MemberChannel = Payload.member.voiceChannel

    if BOTConnection and BOTConnection.channel then
        assert(BOTConnection.channel.id == Payload.member.voiceChannel.id, "I'm already connected to a channel.")
    else
        BOTConnection = MemberChannel:join()
    end

    local SearchFor = false
    local Search

    if not Args[3] and Args[2]:match("https?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))") then
        Query = Args[2]
    else
        Query = ReturnRestOfCommand(Args, 2)
        SearchFor = true
        Search, _ = Payload:reply {
            embed = SimpleEmbed(nil, Payload.author.mentionString.." searching for ``"..Query.."``")
        }
    end

    local AudioData = YTJSON(Query, SearchFor, Payload)

    if Search then
        Search:delete()
    end

    if LastMessage then
        LastMessage:delete()
    end

    if AudioData.Error ~= nil then
        LastMessage = SimpleEmbed(Payload, AudioData.Error)

        return
    end

    if not CurrentlyPlaying then
        CurrentlyPlaying = AudioData

        BOTConnection:playFFmpeg(AudioData.FFmpegURL, _, _, function()
            CurrentlyPlaying.StartTime = os.time()

            CurrentlyPlaying.Message, _ = Payload:reply { 
                embed = {
                    ["description"] = "**Now playing**\n["..CurrentlyPlaying.Title.."]("..CurrentlyPlaying.VideoURL..") ["..Payload.author.mentionString.."]",
                    ["color"] = Config.EmbedColour,
                    ["thumbnail"] = {
                        ["url"] = CurrentlyPlaying.Thumbnail
                    }
                }
            }
        end)
    else
        table.insert(Queue, AudioData)

        AudioData.Message, _ = Payload:reply { 
            embed = {
                ["description"] = "**Added to the queue**\n["..AudioData.Title.."]("..AudioData.VideoURL..") ["..Payload.author.mentionString.."]",
                ["thumbnail"] = {
                    ["url"] = AudioData.Thumbnail
                },
                ["color"] = Config.EmbedColour,
                ["footer"] = {
                    ["icon_url"] = Payload.guild.iconURL,
                    ["text"] = "Pos "..(#Queue == 1 and "next" or #Queue).." | "..BOT.user.name
                }
            }
        }
    end
end):SetCategory("Music Commands"):AddAlias("p")

CommandManager.Command("skip", function(Args, Payload)
    assert(BOTConnection ~= nil and BOTConnection.channel ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel.id == BOTConnection.channel.id, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying, "nothing is playing at the moment.")

    if CurrentlyPlaying.Message then
        CurrentlyPlaying.Message:delete()
    end

    if #Queue > 0 then
        CurrentlyPlaying = Queue[1]

        if CurrentlyPlaying.Message then
            CurrentlyPlaying.Message:delete()
        end

        table.remove(Queue, 1)

        BOTConnection:playFFmpeg(CurrentlyPlaying.FFmpegURL, _, _, function()
            CurrentlyPlaying.StartTime = os.time()

            CurrentlyPlaying.Message, _ =  Payload:reply { 
                embed = {
                    ["description"] = "**Now playing**\n["..CurrentlyPlaying.Title.."]("..CurrentlyPlaying.VideoURL..") ["..Payload.author.mentionString.."]",
                    ["color"] = Config.EmbedColour,
                    ["thumbnail"] = {
                        ["url"] = CurrentlyPlaying.Thumbnail
                    }
                }
            }
        end)
    else
        BOTConnection:stopStream()
        CurrentlyPlaying = nil
    end
end):SetCategory("Music Commands"):AddAlias("s")

CommandManager.Command("pause", function(Args, Payload)
    assert(BOTConnection ~= nil and BOTConnection.channel ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel.id == BOTConnection.channel.id, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying ~= nil, "nothing is playing at the moment.")
    assert(CurrentlyPlaying.Paused == false, "")

    BOTConnection:pauseStream()
    CurrentlyPlaying.Paused = true
    CurrentlyPlaying.PauseStart = os.time()
end):SetCategory("Music Commands")

CommandManager.Command("resume", function(Args, Payload)
    assert(BOTConnection ~= nil and BOTConnection.channel ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel.id == BOTConnection.channel.id, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying, "nothing is playing at the moment.")
    assert(CurrentlyPlaying.Paused == true, "")

    BOTConnection:resumeStream()
    CurrentlyPlaying.Paused = false
    CurrentlyPlaying.PauseTime = CurrentlyPlaying.PauseTime + (os.time() - CurrentlyPlaying.PauseStart)
end):SetCategory("Music Commands")

CommandManager.Command("seek", function(Args, Payload)
    assert(BOTConnection.channe ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel.id == BOTConnection.channel.id, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying, "nothing is playing at the moment.")
    
    local Prefix = Config.Prefix
    assert(Args[2], Payload.author.mentionString.."no seek arguments provided.\nI.e. ``"..Prefix.."seek 00:01:30`` or ``"..Prefix.."seek 01:30`` (``HH:MM:SS`` or ``MM:SS``)")

    local SeekFormat, SeekTime = CheckSeekFormat(Args[2])
    assert(SeekFormat, "you did format the seek command properly.\nI.e. ``"..Prefix.."seek 00:01:30`` or ``"..Prefix.."seek 01:30`` (``HH:MM:SS`` or ``MM:SS``)")
    assert(SeekTime <= CurrentlyPlaying.Duration, "the time you requested to seek to is longer than the duration of ["..CurrentlyPlaying.Title.."]("..CurrentlyPlaying.VideoURL..")")

    CurrentlyPlaying.Seeks = CurrentlyPlaying.Seeks + 1
    CurrentlyPlaying.SeekStart = os.time()
    CurrentlyPlaying.SeekTime = SeekTime

    BOTConnection:playFFmpeg(CurrentlyPlaying.FFmpegURL, _, { { "-ss", SeekTime, 7 } }, function()
        CurrentlyPlaying.SeekStart = os.time()
    end)
end):SetCategory("Music Commands")

CommandManager.Command("time", function(Args, Payload)
    assert(BOTConnection ~= nil and BOTConnection.channel ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel.id == BOTConnection.channel.id, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying and CurrentlyPlaying.StartTime, "nothing is playing at the moment.")

    local TimeElapsed = 0
    if CurrentlyPlaying.Seeks > 0 and CurrentlyPlaying.SeekStart ~= nil and CurrentlyPlaying.SeekTime ~= nil then
        TimeElapsed = CurrentlyPlaying.SeekTime + (os.time() - CurrentlyPlaying.SeekStart)
    else
        TimeElapsed = os.time() - CurrentlyPlaying.StartTime
    end

    TimeElapsed = TimeElapsed - CurrentlyPlaying.PauseTime 
    
    if CurrentlyPlaying.Paused == true then
        TimeElapsed = TimeElapsed - (os.time() - CurrentlyPlaying.PauseStart)
    end

    if TimeElapsed > CurrentlyPlaying.Duration then
        TimeElapsed = CurrentlyPlaying.Duration
    end

    Payload:reply{ 
        embed = {
            ["description"] = "["..CurrentlyPlaying.Title.."]("..CurrentlyPlaying.VideoURL..") ["..CurrentlyPlaying.Playerr.."]\n"..string.rep("▬", (TimeElapsed/CurrentlyPlaying.Duration*20)-1).."⚪"..string.rep("▬", (20-(TimeElapsed/CurrentlyPlaying.Duration*20))).." "..SecondsToClock(TimeElapsed).."/"..SecondsToClock(CurrentlyPlaying.Duration),
            ["thumbnail"] = {
                ["url"] = CurrentlyPlaying.Thumbnail
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
    assert(BOTConnection ~= nil and BOTConnection.channel ~= nil, "I'm not connected to any channel.")
    assert(Payload.member.voiceChannel ~= nil and Payload.member.voiceChannel.id == BOTConnection.channel.id, "you need to be in the same channel as me.")
    assert(CurrentlyPlaying ~= nil, "nothing is playing at the moment.")
    local QueueString = "  Title"..string.rep(" ", 35).."| Duration\n"
    for i = 0, #Queue, 1 do
        QueueItem = (i == 0 and CurrentlyPlaying or Queue[i])

        local QueueTitle = (#(QueueItem.Title) > 39 and QueueItem.Title:sub(1, 38).."…" or QueueItem.Title)

        QueueString = 
            QueueString..
            (i == 0 and CurrentlyPlaying.Paused == true and "∥" or i == 0 and CurrentlyPlaying.Paused == false and "→" or "↳")..
            " "..
            QueueTitle..
            string.rep(" ", (39-#QueueTitle))..
            " | "..
            SecondsToClock(QueueItem.Duration)..
            "\n"
    end

    SimpleEmbed(Payload, "```"..QueueString.."```")
end):SetCategory("Music Commands")

ClearQeue = CommandManager.Command("clearqueue", function(Args, Payload)
    Queue = {}

    SimpleEmbed(Payload, Payload.author.mentionString.." queue has been cleared.")
end):SetCategory("Music Commands")


--[[ Voice Channel Events ]]
BOT:on("voiceDisconnect", function(Member)
	coroutine.wrap(function()
		if Member.user and Member.user == BOT.user then
			BOTConnection:stopStream()
            
            if CurrentlyPlaying and CurrentlyPlaying.Message then
                CurrentlyPlaying.Message:delete()
            end
			
			CurrentlyPlaying = nil
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
        if BOTConnection and CurrentlyPlaying and CurrentlyPlaying.StartTime then
            local TimeElapsed 
            if CurrentlyPlaying.Seeks > 0 and CurrentlyPlaying.SeekStart ~= nil and CurrentlyPlaying.SeekTime ~= nil then
                TimeElapsed = CurrentlyPlaying.SeekTime + (os.time()-CurrentlyPlaying.SeekStart)
            else
                TimeElapsed = os.time() - CurrentlyPlaying.StartTime
            end
            
            TimeElapsed = TimeElapsed - CurrentlyPlaying.PauseTime 
            
            if CurrentlyPlaying.Paused == true then
                TimeElapsed = TimeElapsed - (os.time() - CurrentlyPlaying.PauseStart)
            end

            if TimeElapsed ~= nil and TimeElapsed >= CurrentlyPlaying.Duration then
                if CurrentlyPlaying.Message then
                    CurrentlyPlaying.Message:delete()
                end

                if #Queue > 0 and Queue[1] then
                    CurrentlyPlaying = Queue[1]
                    table.remove(Queue, 1)

                    if CurrentlyPlaying.Message then
                        CurrentlyPlaying.Message:delete()
                    end

                    CurrentlyPlaying.Message, _ = CurrentlyPlaying.Channel:send { 
                        embed = {
                            ["description"] = "**Now playing**\n["..CurrentlyPlaying.Title.."]("..CurrentlyPlaying.VideoURL..") ["..CurrentlyPlaying.Playerr.."]",
                            ["color"] = Config.EmbedColour,
                            ["thumbnail"] = {
                                ["url"] = CurrentlyPlaying.Thumbnail
                            }
                        }
                    }

                    BOTConnection:playFFmpeg(CurrentlyPlaying.FFmpegURL, _, _, function()
                        CurrentlyPlaying.StartTime = os.time()
                    end)
                else
                    CurrentlyPlaying = nil
                    BOTConnection:stopStream()
                end
            end
        end
    end)()
end)