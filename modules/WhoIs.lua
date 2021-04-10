CommandManager.Command("whois", function(Args, Payload)
    local Member = Payload.member
    if Payload.mentionedUsers and Payload.mentionedUsers.first then
        Member = assert(Payload.guild:getMember(Payload.mentionedUsers.first), "failed to get mentioned member")
    elseif Args[2] and tonumber(Args[2]) ~= nil then
        Member = assert(Payload.guild:getMember(Args[2]), "failed to get member from ID")
    end

    assert(Member.name and Member.user.discriminator and Member.id and Member.status and Member.joinedAt and Member.roles, "there was an issue getting some required information.")

    local AllRoleNames = {}

    Member.roles:forEach(function(Role)
        table.insert(AllRoleNames, Role.mentionString)
    end)

    Payload:reply {
        embed = {
            ["color"] = Config.EmbedColour,
            ["fields"] = {
                {
                    ["name"] = "Name",
                    ["value"] = Member.name,
                    ["inline"] = true
                },
                {
                    ["name"] = "Discriminator",
                    ["value"] = Member.user.discriminator,
                    ["inline"] = true
                },
                {
                    ["name"] = "ID",
                    ["value"] = Member.id,
                    ["inline"] = true
                },
                {
                    ["name"] = "Status",
                    ["value"] = Member.status,
                    ["inline"] = true
                },
                {
                    ["name"] = "Joined Guild",
                    ["value"] = (Member.joinedAt and Member.joinedAt:gsub("%..*", ""):gsub("T", " @ ") or "?"),
                    ["inline"] = true
                },
                {
                    ["name"] = "Joined Discord",
                    ["value"] = Discordia.Date().fromSnowflake(Member.id):toISO(" @ ", ""),
                    ["inline"] = true
                },
                {
                    ["name"] = "Roles",
                    ["value"] = table.concat(AllRoleNames, ", ")
                }
            }
        }
    }
end):SetCategory("Fun Commands"):SetDescription("Get info about a user.")