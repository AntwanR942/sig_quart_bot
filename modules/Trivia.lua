--[[ Variables ]]
local Categories = {
    ["General Knowledge"] = "9",
    ["Books"] = "10",
    ["Film"] = "11",
    ["Music"] = "12",
    ["Musicals & Theatres"] = "13",
    ["Television"] = "14",
    ["Video Games"] = "15",
    ["Board Games"] = "16",
    ["Science & Nature"] = "17",
    ["Computers"] = "18",
    ["Mathematics"] = "19",
    ["Mythology"] = "20",
    ["Sports"] = "21",
    ["Geography"] = "22",
    ["History"] = "23",
    ["Politics"] = "24",
    ["Art"] = "25",
    ["Celebrities"] = "26",
    ["Animals"] = "27",
    ["Vehicles"] = "28",
    ["Comics"] = "29",
    ["Gadgets"] = "30",
    ["Japanese Anime & Manga"] = "31",
    ["Cartoon & Animations"] = "32"
}

local CategoriesIndexMap = {
    "General Knowledge",
    "Books",
    "Film",
    "Music",
    "Musicals & Theatres",
    "Television",
    "Video Games",
    "Board Games",
    "Science & Nature",
    "Computers",
    "Mathematics",
    "Mythology",
    "Sports",
    "Geography",
    "History",
    "Politics",
    "Art",
    "Celebrities",
    "Animals",
    "Vehicles",
    "Comics",
    "Gadgets",
    "Japanese Anime & Manga",
    "Cartoon & Animations"
}

local IndexToAnswer = {
    "a",
    "b",
    "c",
    "d"
}

local AnswerToIndex = {
    ["a"] = 1,
    ["b"] = 2,
    ["c"] = 3,
    ["d"] = 4
}

--[[ Functions ]]
local function ShuffleAnswers(Answers)
    local UsedIndexes = {}
 
    for i = 1, 4, 1 do
        RInt = math.random(1, #Answers)
        local This, New = Answers[i], Answers[RInt]

        Answers[i] = New
        Answers[RInt] = This
    end

    return Answers
end

local function DecodeBody(Body)
    Body.results[1].category = Query.urldecode(Body.results[1].category)
    Body.results[1].question = Query.urldecode(Body.results[1].question)
    Body.results[1].correct_answer = Query.urldecode(Body.results[1].correct_answer)
    
    for i = 1, #Body.results[1].incorrect_answers, 1 do
        Body.results[1].incorrect_answers[i] = Query.urldecode(Body.results[1].incorrect_answers[i])
    end 

    return Body
end

--[[ Command ]]
local TriviaCommand = CommandManager.Command("trivia", function(Args, Payload)
    local TriviaArgs = "&type=multiple&encode=url3986"

    if Args[2] ~= nil then
        Args[2] = tonumber(Args[2])
        assert(Args[2] ~= nil and CategoriesIndexMap[Args[2]] ~= nil, F("that is an invalid category, use ``%strivia categories`` to list them all.", Config.Prefix)) 

        TriviaArgs = TriviaArgs.."&category="..Categories[CategoriesIndexMap[Args[2]]]
    end

    local Res, Body = HTTP.request("GET", "https://opentdb.com/api.php?amount=1"..TriviaArgs)
    Body = JSON.decode(Body)

    assert(Res.code == 200 and Body.response_code == 0, "there was an error fetching a question, please try again.")

    Body = DecodeBody(Body)

    local QA = F("**%s**\n \n", Body.results[1].question)

    table.insert(Body.results[1].incorrect_answers, Body.results[1].correct_answer)

    local Answers = ShuffleAnswers(Body.results[1].incorrect_answers)

    local TriviaEmbed = {
        ["author"] = {
            ["name"] = F("%s's trivia question!", Payload.author.name),
            ["url"] = Payload.author.avatarURL,
        },
        ["description"] = QA,
        ["fields"] = {
            {
                ["name"] = "Difficulty",
                ["value"] = F("``%s``", Body.results[1].difficulty),
                ["inline"] = true
            },
            {
                ["name"] = "Category",
                ["value"] = F("``%s``", Body.results[1].category),
                ["inline"] = true
            }
        },
        ["color"] = Config.EmbedColour
    }

    for i = 1, 4 do
        TriviaEmbed.description = TriviaEmbed.description..F("%s) %s\n", IndexToAnswer[i], Answers[i])
    end

    Payload:reply {
        embed = TriviaEmbed
    }

    local Suc, Payload2 = BOT:waitFor("messageCreate", 20000, function(Payload2)
        if Payload.author == Payload2.author and #Payload2.content == 1 and AnswerToIndex[Payload2.content] ~= nil then
            return Payload2
        end
    end)

    assert(Suc == true, "you took too long to answer.")

    assert(Answers[AnswerToIndex[Payload2.content]] == Body.results[1].correct_answer, "that is not the correct answer!\n \nCorrect Answer: ``"..Body.results[1].correct_answer.."``")

    SimpleEmbed(Payload2, Payload2.author.mentionString.." you got the answer correct, well done!")
end):SetCategory("Fun Commands")

TriviaCommand:AddSubCommand("categories", function(Args, Payload)
    local CategoryString = ""
    for i = 1, #CategoriesIndexMap, 1 do
        CategoryString = CategoryString..F("\n``%s``: %s", i, CategoriesIndexMap[i])
    end
    
    SimpleEmbed(Payload, F("%s\n \nSimple do ``%strivia [Cateogry Number]`` to get a question from a specific category.", CategoryString, Config.Prefix))
end)