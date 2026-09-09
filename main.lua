-- =========================================================================
--  RIVALS SKIN CHANGER (Updated & Enhanced Icons.lua Edition)
--  Zero-Crash Architecture: Pure One-Way Viewmodel Swapping & Threaded 2D GUI Icons
-- =========================================================================

if not pcall(memory_read, "int", game.Address) then 
    pcall(notify, "UnsafeLua is disabled in executor.", "SC", 5) 
    return 
end

local mrd, mwr, pcall, ipairs, pairs = memory_read, memory_write, pcall, ipairs, pairs
local floor, byte, rnd = math.floor, string.byte, math.random

local rd = function(a) 
    local o, v = pcall(mrd, "uintptr_t", a)
    return o and v or nil 
end

local wr = function(a, v) 
    pcall(mwr, "uintptr_t", a, v) 
end

-- Dual notification engine
local function notifyUser(title, text, duration)
    duration = duration or 6
    if typeof(notify) == "function" then pcall(notify, text, title, duration) end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
end

-- Robust Multi-Format Config Parser
local function parseConfigLine(rawLine)
    local l = rawLine:gsub(string.char(13), ""):gsub(string.char(10), ""):match("^%s*(.-)%s*$")
    if not l or #l == 0 or l:sub(1, 2) == "--" or l:sub(1, 1) == "#" or l == "return {" or l == "}" then
        return nil, nil
    end
    local sep = l:find("=") or l:find(":")
    if not sep then return nil, nil end
    local w = l:sub(1, sep - 1):match("^%s*(.-)%s*$")
    local s = l:sub(sep + 1):match("^%s*(.-)%s*$")
    if not w or not s then return nil, nil end
    s = s:gsub("[,;]+$", ""):match("^%s*(.-)%s*$")
    w = w:gsub('^%["', ''):gsub('"%]$', ''):gsub("^%['", ''):gsub("'%]$", ''):gsub('^%[', ''):gsub('%]$', '')
    w = w:gsub('^"', ''):gsub('"$', ''):gsub("^'", ''):gsub("'$", ''):match("^%s*(.-)%s*$")
    s = s:gsub('^"', ''):gsub('"$', ''):gsub("^'", ''):gsub("'$", ''):match("^%s*(.-)%s*$")
    if w and s and #w > 0 and #s > 0 then return w, s end
    return nil, nil
end

-- Multi-path config discovery
local candidatePaths = {
    "rivals_config.lua",
    "workspace/rivals_config.lua",
    "rivals_config.lua.txt",
    "rivals_config.txt",
    "workspace/rivals_config.txt",
    "rivals_config (1).lua",
    "rivals_config(1).lua",
    "Rivals_Config.lua",
    "rivals_config"
}

if typeof(listfiles) == "function" then
    pcall(function()
        for _, folder in ipairs({"", "workspace"}) do
            local files = listfiles(folder) or {}
            for _, f in ipairs(files) do
                local clean = f:lower():gsub(string.char(92), "/")
                if clean:find("rivals_config") then
                    table.insert(candidatePaths, 1, f)
                end
            end
        end
    end)
end

local targetFile, r2 = nil, nil
for _, path in ipairs(candidatePaths) do
    local ok, exists = pcall(isfile, path)
    if ok and exists then
        local okR, content = pcall(readfile, path)
        if okR and content and #content > 0 then
            targetFile = path
            r2 = content
            break
        end
    end
end

if not r2 then
    warn("[RivalsSkinChanger] ERROR: rivals_config.lua was not found in your executor's workspace folder!")
    notifyUser("Rivals Skin Changer Error", "rivals_config.lua not found in workspace folder!", 8)
    return
end

-- Strip UTF-8 BOM
if r2:sub(1, 3) == string.char(239, 187, 191) then
    r2 = r2:sub(4)
end

local en = {}
for _, rawLine in ipairs(r2:split(string.char(10))) do
    local w, s = parseConfigLine(rawLine)
    if w and s then
        en[#en + 1] = {w, s}
    end
end

if #en == 0 then
    warn("[RivalsSkinChanger] ERROR: Config file is empty or contains no valid Weapon=Skin lines!")
    notifyUser("Rivals Skin Changer Error", "Config file has 0 valid Weapon=Skin entries!", 8)
    return
end

-- Native SoundCallbacks Redirection
task.spawn(function()
    local pfx = function(n) return n:lower():gsub("[%s%-'%.]+", "") end
    local AL
    for i = 1, 30 do
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            AL = rs:FindFirstChild("Modules") and rs.Modules:FindFirstChild("AnimationLibrary")
        end)
        if AL then break end
        task.wait(1)
    end
    if not AL then return end
    local SC = AL:FindFirstChild("SoundCallbacks")
    if not SC then return end
    local abn = {}
    for _, c in ipairs(SC:GetChildren()) do abn[c.Name] = c end
    for _, e in ipairs(en) do
        local wp, sp = pfx(e[1]), pfx(e[2])
        local spfx = wp .. "_" .. sp .. "_"
        for name, inst in pairs(abn) do
            if name:sub(1, #spfx) == spfx then
                local di = abn[wp .. "_" .. name:sub(#spfx + 1)]
                if di and inst and di.Address and inst.Address then
                    local a, b = mrd("uintptr_t", di.Address + 0x8), mrd("uintptr_t", inst.Address + 0x8)
                    if a and b and a ~= b then
                        mwr("uintptr_t", di.Address + 0x8, b)
                        mwr("uintptr_t", inst.Address + 0x8, a)
                    end
                end
            end
        end
    end
end)

local LP = game:GetService("Players").LocalPlayer
while not LP do
    task.wait(0.5)
    LP = game:GetService("Players").LocalPlayer
end

if game.GameId ~= 6035872082 then return end

-- Confirmed 64-bit offsets with dynamic fallback
local OFF = {
    Parent = 104,
    Children = 120,
    Name = 112
}

pcall(function()
    local hs = game:GetService("HttpService")
    local raw = game:HttpGet("https://offsets.imtheo.lol/Offsets.json")
    if raw and #raw > 100 then
        local o2 = hs:JSONDecode(raw).Offsets
        if o2 and o2.Instance then
            if o2.Instance.Parent then OFF.Parent = o2.Instance.Parent OFF.Children = o2.Instance.Parent + 8 end
            if o2.Instance.NameContainer then OFF.Name = o2.Instance.NameContainer
            elseif o2.Instance.Name then OFF.Name = o2.Instance.Name end
        end
    end
end)

local A, vm, wf, mi
repeat
    task.wait(0.5)
    pcall(function()
        A = LP.PlayerScripts:FindFirstChild("Assets")
        vm = A and A:FindFirstChild("ViewModels")
        wf = vm and vm:FindFirstChild("Weapons")
        mi = A and A:FindFirstChild("Misc")
    end)
until wf

local tf = A:FindFirstChild("Throwables")
local pf = A:FindFirstChild("Projectiles")
local PG = LP:FindFirstChild("PlayerGui")

local sc, aW = {}, {}
local ff = function(p, n) return p and p:FindFirstChild(n) end

for _, f in ipairs(vm:GetChildren()) do
    if f.ClassName == "Folder" and f.Name ~= "Weapons" then
        for _, x in ipairs(f:GetChildren()) do
            sc[x.Name] = x
        end
    end
end
for _, w in ipairs(wf:GetChildren()) do
    aW[w.Name] = w
end

-- Embedded official icons database (49 Weapons & 470 Skins)
local IL = {
    ["Assault Rifle"] = {
        ["Standard"] = "rbxassetid://17160682738",
        ["10B Visits"] = "rbxassetid://122165086598560",
        ["AK-47"] = "rbxassetid://17691132793",
        ["AKEY-47"] = "rbxassetid://80017496220683",
        ["Augmented Rifle"] = "rbxassetid://18770192853",
        ["Boneclaw Rifle"] = "rbxassetid://100015754284323",
        ["Drum Gun"] = "rbxassetid://111251887761435",
        ["Gingerbread Augmented Rifle"] = "rbxassetid://85584922619813",
        ["Glorious Assault Rifle"] = "rbxassetid://130669996688265",
        ["Pearl Rifle"] = "rbxassetid://135277426561503",
        ["Phoenix Rifle"] = "rbxassetid://140228738718621",
    },
    ["Battle Axe"] = {
        ["Standard"] = "rbxassetid://93390542043222",
        ["Balloon Axe"] = "rbxassetid://102429983628211",
        ["Ban Axe"] = "rbxassetid://111046431576859",
        ["Cerulean Axe"] = "rbxassetid://76353832683350",
        ["Glorious Battle Axe"] = "rbxassetid://87227212476138",
        ["Keyttle Axe"] = "rbxassetid://122117068984402",
        ["Mimic Axe"] = "rbxassetid://111717370450373",
        ["Nordic Axe"] = "rbxassetid://80052264197135",
        ["Street Sign"] = "rbxassetid://121743888148209",
        ["The Shred"] = "rbxassetid://71234381808727",
        ["Tiki Axe"] = "rbxassetid://87247443182820",
    },
    ["Bow"] = {
        ["Standard"] = "rbxassetid://17160802080",
        ["Balloon Bow"] = "rbxassetid://128957010941029",
        ["Bat Bow"] = "rbxassetid://108984987378619",
        ["Beloved Bow"] = "rbxassetid://110219131386799",
        ["Compound Bow"] = "rbxassetid://17672234242",
        ["Dream Bow"] = "rbxassetid://101089313144218",
        ["Frostbite Bow"] = "rbxassetid://121895626623160",
        ["Glorious Bow"] = "rbxassetid://84201415206621",
        ["Key Bow"] = "rbxassetid://122525140091212",
        ["Palm Bow"] = "rbxassetid://82899577710787",
        ["Raven Bow"] = "rbxassetid://18766861627",
    },
    ["Burst Rifle"] = {
        ["Standard"] = "rbxassetid://17160801983",
        ["Aqua Burst"] = "rbxassetid://18837670807",
        ["Bullpup Burst"] = "rbxassetid://74974560606812",
        ["Electro Rifle"] = "rbxassetid://132227459821018",
        ["Glorious Burst Rifle"] = "rbxassetid://78517330608597",
        ["Keyst Rifle"] = "rbxassetid://78377522426003",
        ["Pine Burst"] = "rbxassetid://132753732294083",
        ["Pixel Burst"] = "rbxassetid://102648809593259",
        ["Sand Bullpup Burst"] = "rbxassetid://130731663986683",
        ["Spectral Burst"] = "rbxassetid://135012309412679",
    },
    ["Chainsaw"] = {
        ["Standard"] = "rbxassetid://17160801873",
        ["Blobsaw"] = "rbxassetid://17825963589",
        ["Buzzsaw"] = "rbxassetid://74057448201836",
        ["Festive Buzzsaw"] = "rbxassetid://80811854818775",
        ["Glorious Chainsaw"] = "rbxassetid://122622447397834",
        ["Handsaws"] = "rbxassetid://18766864583",
        ["Mega Drill"] = "rbxassetid://76663867023998",
        ["Sharksaw"] = "rbxassetid://136881251000627",
    },
    ["Crossbow"] = {
        ["Standard"] = "rbxassetid://140211832612284",
        ["Arch Crossbow"] = "rbxassetid://94981733362451",
        ["Campfire Crossbow"] = "rbxassetid://76911697867059",
        ["Crossbone"] = "rbxassetid://103469183638638",
        ["Frostbite Crossbow"] = "rbxassetid://101536997945363",
        ["Glorious Crossbow"] = "rbxassetid://70875146419725",
        ["Harpoon Crossbow"] = "rbxassetid://107460405492001",
        ["Pixel Crossbow"] = "rbxassetid://115931961841903",
        ["Violin Crossbow"] = "rbxassetid://74401302514014",
    },
    ["Daggers"] = {
        ["Standard"] = "rbxassetid://91885384580845",
        ["Aces"] = "rbxassetid://139089881483398",
        ["Bat Daggers"] = "rbxassetid://92001964015225",
        ["Broken Hearts"] = "rbxassetid://74156924296351",
        ["Cookies"] = "rbxassetid://114482325531769",
        ["Crystal Daggers"] = "rbxassetid://126221748659600",
        ["Glorious Daggers"] = "rbxassetid://76023189104485",
        ["Keynais"] = "rbxassetid://84562761142610",
        ["Paper Planes"] = "rbxassetid://84003122595879",
        ["Shurikens"] = "rbxassetid://135574097643275",
        ["Starfish"] = "rbxassetid://114567820096083",
        ["Toaster"] = "rbxassetid://103344379002564",
    },
    ["Distortion"] = {
        ["Standard"] = "rbxassetid://115712150398379",
        ["Bubble Distortion"] = "rbxassetid://73319804282513",
        ["Cyber Distortion"] = "rbxassetid://88995062151276",
        ["Electropunk Distortion"] = "rbxassetid://109544539643046",
        ["Experiment D15"] = "rbxassetid://103446773933340",
        ["Glorious Distortion"] = "rbxassetid://134722661973710",
        ["Magma Distortion"] = "rbxassetid://81103807698156",
        ["Plasma Distortion"] = "rbxassetid://126813935337091",
        ["Sleighstortion"] = "rbxassetid://111242141481650",
    },
    ["Energy Pistols"] = {
        ["Standard"] = "rbxassetid://79471670126710",
        ["Apex Pistols"] = "rbxassetid://136156057859453",
        ["Enerkey Pistols"] = "rbxassetid://132955794587057",
        ["Glorious Energy Pistols"] = "rbxassetid://114418789647547",
        ["Hacker Pistols"] = "rbxassetid://140621407555872",
        ["Hydro Pistols"] = "rbxassetid://115281889984097",
        ["Hyperlaser Guns"] = "rbxassetid://106947526362970",
        ["New Year Energy Pistols"] = "rbxassetid://126589959779039",
        ["Sol Pistols"] = "rbxassetid://115012735954576",
        ["Soul Pistols"] = "rbxassetid://72213738067158",
        ["Void Pistols"] = "rbxassetid://111278471262300",
    },
    ["Energy Rifle"] = {
        ["Standard"] = "rbxassetid://110259279810005",
        ["Apex Rifle"] = "rbxassetid://88144772234151",
        ["Enerkey Rifle"] = "rbxassetid://80940171527853",
        ["Glorious Energy Rifle"] = "rbxassetid://72632815443247",
        ["Hacker Rifle"] = "rbxassetid://122816271917525",
        ["Hydro Rifle"] = "rbxassetid://73690448730060",
        ["New Year Energy Rifle"] = "rbxassetid://111446782522703",
        ["Sol Rifle"] = "rbxassetid://96272849525291",
        ["Soul Rifle"] = "rbxassetid://129351366788323",
        ["Void Rifle"] = "rbxassetid://95985016411441",
    },
    ["Exogun"] = {
        ["Standard"] = "rbxassetid://17344796376",
        ["Exogourd"] = "rbxassetid://137140750597688",
        ["Glorious Exogun"] = "rbxassetid://129125201034206",
        ["Midnight Festive Exogun"] = "rbxassetid://127612442529810",
        ["Pearl Exogun"] = "rbxassetid://77698515863000",
        ["Ray Gun"] = "rbxassetid://18766861454",
        ["Repulsor"] = "rbxassetid://109263387714628",
        ["Singularity"] = "rbxassetid://17676876756",
        ["Wondergun"] = "rbxassetid://17672060360",
    },
    ["Fists"] = {
        ["Standard"] = "rbxassetid://17160801745",
        ["Boxing Gloves"] = "rbxassetid://17672060486",
        ["Brass Knuckles"] = "rbxassetid://106879679389340",
        ["Crab Claws"] = "rbxassetid://127492118111080",
        ["Festive Fists"] = "rbxassetid://102757458529795",
        ["Fist"] = "rbxassetid://109585706680035",
        ["Fists of Hurt"] = "rbxassetid://140103672289959",
        ["Glorious Fists"] = "rbxassetid://112839297231399",
        ["Pirate Hook"] = "rbxassetid://116717593932616",
        ["Pumpkin Claws"] = "rbxassetid://90996407819750",
        ["Spy Gloves"] = "rbxassetid://117198095640784",
    },
    ["Flamethrower"] = {
        ["Standard"] = "rbxassetid://89455038280473",
        ["Bubblethrower"] = "rbxassetid://76812523297712",
        ["Extinguisher"] = "rbxassetid://95815875434568",
        ["Glitterthrower"] = "rbxassetid://88920581735649",
        ["Glorious Flamethrower"] = "rbxassetid://71676635953177",
        ["Jack O'Thrower"] = "rbxassetid://140280020818514",
        ["Keythrower"] = "rbxassetid://130308634220965",
        ["Lamethrower"] = "rbxassetid://18766862822",
        ["Pixel Flamethrower"] = "rbxassetid://17771752104",
        ["Rainbowthrower"] = "rbxassetid://102070206928252",
        ["Snowblower"] = "rbxassetid://128743586418880",
    },
    ["Flare Gun"] = {
        ["Standard"] = "rbxassetid://17160801627",
        ["Banana Flare"] = "rbxassetid://123589213761955",
        ["Dynamite Gun"] = "rbxassetid://18766865384",
        ["Firework Gun"] = "rbxassetid://17691132917",
        ["Glorious Flare Gun"] = "rbxassetid://115324763672074",
        ["Pocket Volcano"] = "rbxassetid://133260045254190",
        ["Vexed Flare Gun"] = "rbxassetid://116287930550049",
        ["Wrapped Flare Gun"] = "rbxassetid://135638020129378",
    },
    ["Flashbang"] = {
        ["Standard"] = "rbxassetid://17160801529",
        ["Camera"] = "rbxassetid://18766865640",
        ["Disco Ball"] = "rbxassetid://17672061796",
        ["Glorious Flashbang"] = "rbxassetid://96760506528185",
        ["Lightbulb"] = "rbxassetid://125489177573287",
        ["Pixel Flashbang"] = "rbxassetid://132815625474597",
        ["Shining Star"] = "rbxassetid://108392227354212",
        ["Skullbang"] = "rbxassetid://73796957224972",
        ["Sol"] = "rbxassetid://124026864365877",
    },
    ["Freeze Ray"] = {
        ["Standard"] = "rbxassetid://18429552328",
        ["Bubble Ray"] = "rbxassetid://18766865819",
        ["Cooler"] = "rbxassetid://117258208589940",
        ["Glorious Freeze Ray"] = "rbxassetid://120211873831101",
        ["Gum Ray"] = "rbxassetid://121504417727123",
        ["Spider Ray"] = "rbxassetid://136838810668332",
        ["Temporal Ray"] = "rbxassetid://18429552503",
        ["Wrapped Freeze Ray"] = "rbxassetid://76183738050112",
    },
    ["Grappler"] = {
        ["Standard"] = "rbxassetid://103255844976245",
        ["Arcade Claw"] = "rbxassetid://81529455948004",
        ["Fishing Rod"] = "rbxassetid://86648406311812",
        ["Genie Lamp"] = "rbxassetid://118514051859760",
        ["Glorious Grappler"] = "rbxassetid://113576961532090",
        ["Lasso"] = "rbxassetid://77061966583531",
        ["Lifeguard Grappler"] = "rbxassetid://91214316625102",
    },
    ["Grenade"] = {
        ["Standard"] = "rbxassetid://17160801411",
        ["Cuddle Bomb"] = "rbxassetid://116801887274189",
        ["Dynamite"] = "rbxassetid://119066463640901",
        ["Fizz Bomb"] = "rbxassetid://123256093694497",
        ["Frozen Grenade"] = "rbxassetid://96120996159611",
        ["Glorious Grenade"] = "rbxassetid://103034870490455",
        ["Jingle Grenade"] = "rbxassetid://97646859596860",
        ["Keynade"] = "rbxassetid://102785971311114",
        ["Soul Grenade"] = "rbxassetid://85903097459179",
        ["Water Balloon"] = "rbxassetid://18766859819",
        ["Whoopee Cushion"] = "rbxassetid://17672062933",
    },
    ["Grenade Launcher"] = {
        ["Standard"] = "rbxassetid://17250453814",
        ["Balloon Launcher"] = "rbxassetid://137862701599991",
        ["Coconut Launcher"] = "rbxassetid://77621998397460",
        ["Gearnade Launcher"] = "rbxassetid://133756750612042",
        ["Glorious Grenade Launcher"] = "rbxassetid://134130354519919",
        ["Skull Launcher"] = "rbxassetid://103257281022910",
        ["Snowball Launcher"] = "rbxassetid://112349955391111",
        ["Swashbuckler"] = "rbxassetid://17821233828",
        ["Uranium Launcher"] = "rbxassetid://18766860114",
    },
    ["Gunblade"] = {
        ["Standard"] = "rbxassetid://131231034374465",
        ["Boneblade"] = "rbxassetid://126327381608481",
        ["Crude Gunblade"] = "rbxassetid://126996645502136",
        ["Elf's Gunblade"] = "rbxassetid://114103306647123",
        ["Glorious Gunblade"] = "rbxassetid://88003799126136",
        ["Gunsaw"] = "rbxassetid://102700915422689",
        ["Hyper Gunblade"] = "rbxassetid://134415898983004",
        ["Keyblade"] = "rbxassetid://117153249348040",
        ["Sharkbite"] = "rbxassetid://85479471132931",
    },
    ["Handgun"] = {
        ["Standard"] = "rbxassetid://17160801282",
        ["Blaster"] = "rbxassetid://17821234554",
        ["Gingerbread Handgun"] = "rbxassetid://95881238590412",
        ["Glorious Handgun"] = "rbxassetid://85129427786041",
        ["Gumball Handgun"] = "rbxassetid://106890990556815",
        ["Hand Gun"] = "rbxassetid://18837670624",
        ["Pixel Handgun"] = "rbxassetid://82199841278177",
        ["Pumpkin Handgun"] = "rbxassetid://88495685924653",
        ["Sandgun"] = "rbxassetid://111746039012812",
        ["Stealth Handgun"] = "rbxassetid://124919185835138",
        ["Towerstone Handgun"] = "rbxassetid://88654252790032",
        ["Warp Handgun"] = "rbxassetid://102974911528828",
    },
    ["Jump Pad"] = {
        ["Standard"] = "rbxassetid://79459600453621",
        ["Bounce House"] = "rbxassetid://71226436012588",
        ["Flamingo Floatie"] = "rbxassetid://127511599700842",
        ["Glorious Jump Pad"] = "rbxassetid://71803398862947",
        ["Jolly Man"] = "rbxassetid://97375473537804",
        ["Shady Chicken Sandwich"] = "rbxassetid://86361684164972",
        ["Spider Web"] = "rbxassetid://84204578032332",
        ["Trampoline"] = "rbxassetid://103567857194140",
    },
    ["Katana"] = {
        ["Standard"] = "rbxassetid://17160801158",
        ["Arch Katana"] = "rbxassetid://94679283541658",
        ["Crystal Katana"] = "rbxassetid://88872493010693",
        ["Cutlass"] = "rbxassetid://77773371747122",
        ["Evil Trident"] = "rbxassetid://101234805269080",
        ["Glorious Katana"] = "rbxassetid://75588958786035",
        ["Keytana"] = "rbxassetid://118899310989170",
        ["Lightning Bolt"] = "rbxassetid://18768968241",
        ["Linked Sword"] = "rbxassetid://83575725004177",
        ["New Year Katana"] = "rbxassetid://102866488046710",
        ["Pixel Katana"] = "rbxassetid://127922483074145",
        ["Riptide Katana"] = "rbxassetid://136245206320139",
        ["Saber"] = "rbxassetid://17672062341",
        ["Stellar Katana"] = "rbxassetid://72617738655198",
        ["Swordfish"] = "rbxassetid://105748422389590",
    },
    ["Knife"] = {
        ["Standard"] = "rbxassetid://17160800983",
        ["Armature.001"] = "rbxassetid://104026327618871",
        ["Balisong"] = "rbxassetid://93303458333011",
        ["Birthday Candle"] = "rbxassetid://74148583096733",
        ["Caladbolg"] = "rbxassetid://101180142582964",
        ["Candy Cane"] = "rbxassetid://124021545052910",
        ["Chancla"] = "rbxassetid://17672060795",
        ["Glorious Knife"] = "rbxassetid://77448895595314",
        ["Karambit"] = "rbxassetid://18766863586",
        ["Keylisong"] = "rbxassetid://100084654831857",
        ["Keyrambit"] = "rbxassetid://108512337101248",
        ["Machete"] = "rbxassetid://84364955819899",
        ["Pencil"] = "rbxassetid://131450909376802",
        ["Shark Tooth"] = "rbxassetid://124265657652842",
        ["Trophy Knife"] = "rbxassetid://78822531823097",
    },
    ["Maul"] = {
        ["Standard"] = "rbxassetid://81478141693597",
        ["Ban Hammer"] = "rbxassetid://126491383967029",
        ["Clown Hammer"] = "rbxassetid://95487416883384",
        ["Excalibur"] = "rbxassetid://81905348145140",
        ["Giant Popsicle"] = "rbxassetid://91916939347642",
        ["Glorious Maul"] = "rbxassetid://125917253783002",
        ["Ice Maul"] = "rbxassetid://100001888078290",
        ["Sleigh Maul"] = "rbxassetid://114892026951995",
        ["Starforge Maul"] = "rbxassetid://113691709735527",
    },
    ["Medkit"] = {
        ["Standard"] = "rbxassetid://17160800734",
        ["Box of Chocolates"] = "rbxassetid://132421415091712",
        ["Briefcase"] = "rbxassetid://18142172067",
        ["Bucket of Candy"] = "rbxassetid://93791981490691",
        ["Glorious Medkit"] = "rbxassetid://73358160718523",
        ["Ice Cream"] = "rbxassetid://131246559128209",
        ["Laptop"] = "rbxassetid://18770164868",
        ["Medkitty"] = "rbxassetid://125732280509514",
        ["Milk & Cookies"] = "rbxassetid://99156135330432",
        ["Sandwich"] = "rbxassetid://17838232333",
    },
    ["Minigun"] = {
        ["Standard"] = "rbxassetid://17250458611",
        ["Fighter Jet"] = "rbxassetid://70780739230558",
        ["Glorious Minigun"] = "rbxassetid://84246894288637",
        ["Lasergun 3000"] = "rbxassetid://103437974285778",
        ["Pixel Minigun"] = "rbxassetid://18766861798",
        ["Pumpkin Minigun"] = "rbxassetid://77388785880854",
        ["Shark Minigun"] = "rbxassetid://89295703576175",
        ["Wrapped Minigun"] = "rbxassetid://127077702465909",
    },
    ["Molotov"] = {
        ["Standard"] = "rbxassetid://109264750627289",
        ["Arch Molotov"] = "rbxassetid://96589300342777",
        ["Campfire Stick"] = "rbxassetid://83823494489693",
        ["Coffee"] = "rbxassetid://17672061538",
        ["Glorious Molotov"] = "rbxassetid://108930340066987",
        ["Hot Coals"] = "rbxassetid://110423024723304",
        ["Lava Lamp"] = "rbxassetid://79616583726432",
        ["Ship In A Bottle"] = "rbxassetid://125699268308415",
        ["Torch"] = "rbxassetid://115586189235552",
        ["Vexed Candle"] = "rbxassetid://78128648928195",
    },
    ["Paintball Gun"] = {
        ["Standard"] = "rbxassetid://17160853798",
        ["Boba Gun"] = "rbxassetid://18768830660",
        ["Brain Gun"] = "rbxassetid://85970592668118",
        ["Glorious Paintball Gun"] = "rbxassetid://86297318955856",
        ["Ketchup Gun"] = "rbxassetid://76083615050939",
        ["Lemonade Gun"] = "rbxassetid://119390099120478",
        ["Paintballoon Gun"] = "rbxassetid://100129918948246",
        ["Slime Gun"] = "rbxassetid://17672062472",
        ["Snowball Gun"] = "rbxassetid://113685354916533",
    },
    ["Permafrost"] = {
        ["Standard"] = "rbxassetid://74353733133888",
        ["Glorious Permafrost"] = "rbxassetid://119977291442329",
        ["Ice Permafrost"] = "rbxassetid://83722160119335",
        ["Permafrost.rbxm"] = "rbxassetid://77732280270853",
        ["Permasand"] = "rbxassetid://108398272946629",
        ["Snowman Permafrost"] = "rbxassetid://100890626643184",
        ["Starforge Permafrost"] = "rbxassetid://105290041968367",
        ["Temporal Permafrost"] = "rbxassetid://124975247676715",
    },
    ["RPG"] = {
        ["Standard"] = "rbxassetid://17160802243",
        ["Cupcake Launcher"] = "rbxassetid://100541838356180",
        ["Firework Launcher"] = "rbxassetid://75233372670156",
        ["Glorious RPG"] = "rbxassetid://130506879885802",
        ["Nuke Launcher"] = "rbxassetid://17672061995",
        ["Pencil Launcher"] = "rbxassetid://106934516693548",
        ["Pumpkin Launcher"] = "rbxassetid://94648176067808",
        ["Rocket Launcher"] = "rbxassetid://116931956715309",
        ["RPKEY"] = "rbxassetid://108438721125410",
        ["Spaceship Launcher"] = "rbxassetid://18766860860",
        ["Squid Launcher"] = "rbxassetid://130764310743404",
        ["Sundae Launcher"] = "rbxassetid://70578055340962",
    },
    ["Revolver"] = {
        ["Standard"] = "rbxassetid://17160800299",
        ["Boneclaw Revolver"] = "rbxassetid://119174697609264",
        ["Cruise Revolver"] = "rbxassetid://72223124823807",
        ["Desert Eagle"] = "rbxassetid://17821234372",
        ["Glorious Revolver"] = "rbxassetid://118135542031794",
        ["Keyvolver"] = "rbxassetid://87974031410344",
        ["Peppergun"] = "rbxassetid://124178691056979",
        ["Peppermint Sheriff"] = "rbxassetid://95859403750768",
        ["Sheriff"] = "rbxassetid://18770192507",
    },
    ["Riot Shield"] = {
        ["Standard"] = "rbxassetid://121172272442833",
        ["Broken Surfboard"] = "rbxassetid://114987869792187",
        ["Door"] = "rbxassetid://79242603995428",
        ["Energy Shield"] = "rbxassetid://90215439337413",
        ["Glorious Riot Shield"] = "rbxassetid://132866851386509",
        ["Masterpiece"] = "rbxassetid://79914271483818",
        ["Sled"] = "rbxassetid://73881731607231",
        ["Tombstone Shield"] = "rbxassetid://125895528641243",
    },
    ["Satchel"] = {
        ["Standard"] = "rbxassetid://82237471151891",
        ["Advanced Satchel"] = "rbxassetid://113860326910548",
        ["Bag o' Money"] = "rbxassetid://129192426700659",
        ["Glorious Satchel"] = "rbxassetid://100521994805910",
        ["Lifeguard Satchel"] = "rbxassetid://105277357472003",
        ["Notebook Satchel"] = "rbxassetid://124817464748150",
        ["Pizza Box"] = "rbxassetid://99166555665247",
        ["Potion Satchel"] = "rbxassetid://76787046046890",
        ["Suspicious Gift"] = "rbxassetid://76209303162814",
    },
    ["Scythe"] = {
        ["Standard"] = "rbxassetid://17160800186",
        ["Anchor"] = "rbxassetid://18766866743",
        ["Bat Scythe"] = "rbxassetid://131711174838548",
        ["Bug Net"] = "rbxassetid://115620701626004",
        ["Cryo Scythe"] = "rbxassetid://119930754357379",
        ["Crystal Scythe"] = "rbxassetid://73971549402646",
        ["Glorious Scythe"] = "rbxassetid://115811939422419",
        ["Keythe"] = "rbxassetid://114560926055433",
        ["Palm Scythe"] = "rbxassetid://97379805071194",
        ["Plastic Flamingo"] = "rbxassetid://112023194890462",
        ["Sakura Scythe"] = "rbxassetid://133811689655966",
        ["Scythe of Death"] = "rbxassetid://17825996537",
    },
    ["Shorty"] = {
        ["Standard"] = "rbxassetid://17160800091",
        ["Balloon Shorty"] = "rbxassetid://75590262133322",
        ["Bubble Shorty"] = "rbxassetid://111294137896866",
        ["Cannon Shorty"] = "rbxassetid://137616738436928",
        ["Demon Shorty"] = "rbxassetid://116443498278384",
        ["Glorious Shorty"] = "rbxassetid://105834197552222",
        ["Lovely Shorty"] = "rbxassetid://18766862000",
        ["Not So Shorty"] = "rbxassetid://17672062572",
        ["Too Shorty"] = "rbxassetid://18129531276",
        ["Wrapped Shorty"] = "rbxassetid://136522183669611",
    },
    ["Shotgun"] = {
        ["Standard"] = "rbxassetid://17160800007",
        ["Balloon Shotgun"] = "rbxassetid://17821234823",
        ["Broomstick"] = "rbxassetid://118061559757082",
        ["Cactus Shotgun"] = "rbxassetid://131606483507460",
        ["Glorious Shotgun"] = "rbxassetid://71704618059601",
        ["Hyper Shotgun"] = "rbxassetid://18768968419",
        ["Shark Shotgun"] = "rbxassetid://116415689080224",
        ["Shotkey"] = "rbxassetid://93004214983981",
        ["Wrapped Shotgun"] = "rbxassetid://74894345245237",
    },
    ["Slingshot"] = {
        ["Standard"] = "rbxassetid://17160799888",
        ["Boneshot"] = "rbxassetid://86606957688341",
        ["Glorious Slingshot"] = "rbxassetid://101195664167288",
        ["Goalpost"] = "rbxassetid://17672063165",
        ["Harp"] = "rbxassetid://80850043664453",
        ["Keyshot"] = "rbxassetid://74006265601388",
        ["Lucky Horseshoe"] = "rbxassetid://131242126669282",
        ["Palmshot"] = "rbxassetid://109640024736812",
        ["Reindeer Slingshot"] = "rbxassetid://121612921203624",
        ["Stick"] = "rbxassetid://17672063048",
    },
    ["Smoke Grenade"] = {
        ["Standard"] = "rbxassetid://17160799767",
        ["Balance"] = "rbxassetid://18766866168",
        ["Beach Ball"] = "rbxassetid://98068366944697",
        ["Emoji Cloud"] = "rbxassetid://17821234077",
        ["Eyeball"] = "rbxassetid://135911399763146",
        ["Glorious Smoke Grenade"] = "rbxassetid://139714146508398",
        ["Hourglass"] = "rbxassetid://108311418974073",
        ["Snowglobe"] = "rbxassetid://119390465944051",
    },
    ["Sniper"] = {
        ["Standard"] = "rbxassetid://17160799574",
        ["Campfire Sniper"] = "rbxassetid://127790438907599",
        ["Event Horizon"] = "rbxassetid://80749667426815",
        ["Eyething Sniper"] = "rbxassetid://103915302076013",
        ["Gingerbread Sniper"] = "rbxassetid://99943841952995",
        ["Glorious Sniper"] = "rbxassetid://118012090175286",
        ["Hyper Sniper"] = "rbxassetid://18766864081",
        ["Keyper"] = "rbxassetid://85472935605264",
        ["Kraken Sniper"] = "rbxassetid://95011666797584",
        ["Light Fifty"] = "rbxassetid://138029440298487",
        ["Pixel Sniper"] = "rbxassetid://17676081196",
    },
    ["Spear"] = {
        ["Standard"] = "rbxassetid://122801133017271",
        ["Chark Kebab"] = "rbxassetid://74005839754537",
        ["Fork"] = "rbxassetid://105821360943308",
        ["Giant Pencil"] = "rbxassetid://107812045486260",
        ["Glorious Spear"] = "rbxassetid://98259628954838",
        ["Plunger"] = "rbxassetid://82393330699241",
        ["Studio Light"] = "rbxassetid://70443632958263",
        ["Thunderpike"] = "rbxassetid://137630900832105",
    },
    ["Spray"] = {
        ["Standard"] = "rbxassetid://92882887485248",
        ["Boneclaw Spray"] = "rbxassetid://114078818081911",
        ["Campfire Spray"] = "rbxassetid://129294699009828",
        ["Glorious Spray"] = "rbxassetid://138246745001490",
        ["Key Spray"] = "rbxassetid://94061940442700",
        ["Lovely Spray"] = "rbxassetid://131203015026683",
        ["Nail Gun"] = "rbxassetid://110577809934251",
        ["Pine Spray"] = "rbxassetid://128285758736343",
        ["Spray Bottle"] = "rbxassetid://137955019285700",
    },
    ["Subspace Tripmine"] = {
        ["Standard"] = "rbxassetid://17160799418",
        ["Dev-in-the-Box"] = "rbxassetid://125056115146240",
        ["DIY Tripmine"] = "rbxassetid://85747991601740",
        ["Don't Press"] = "rbxassetid://17821233203",
        ["Glorious Subspace Tripmine"] = "rbxassetid://112555928142930",
        ["Hazard Sign"] = "rbxassetid://73264353773454",
        ["Pot o' Keys"] = "rbxassetid://125355191847719",
        ["Spring"] = "rbxassetid://18766860615",
        ["Trick or Treat"] = "rbxassetid://101693036028491",
    },
    ["Trowel"] = {
        ["Standard"] = "rbxassetid://17160799172",
        ["Garden Shovel"] = "rbxassetid://18766864873",
        ["Glorious Trowel"] = "rbxassetid://100888500368219",
        ["Paintbrush"] = "rbxassetid://84687920829755",
        ["Plastic Shovel"] = "rbxassetid://17672062201",
        ["Pumpkin Carver"] = "rbxassetid://78827307308671",
        ["Scooper"] = "rbxassetid://100816728062854",
        ["Snow Shovel"] = "rbxassetid://78271338778848",
    },
    ["Uzi"] = {
        ["Standard"] = "rbxassetid://17160798908",
        ["Arch Uzi"] = "rbxassetid://139852585731073",
        ["Demon Uzi"] = "rbxassetid://132973040482576",
        ["Ducky Uzi"] = "rbxassetid://133780419950894",
        ["Electro Uzi"] = "rbxassetid://96806694653207",
        ["Glorious Uzi"] = "rbxassetid://120045334159124",
        ["Keyzi"] = "rbxassetid://100392703246534",
        ["Money Gun"] = "rbxassetid://100705725115757",
        ["Pine Uzi"] = "rbxassetid://82545206964916",
        ["Water Uzi"] = "rbxassetid://17821233590",
    },
    ["War Horn"] = {
        ["Standard"] = "rbxassetid://104600246515190",
        ["Air Horn"] = "rbxassetid://111168146142976",
        ["Boneclaw Horn"] = "rbxassetid://138360812591331",
        ["Glorious War Horn"] = "rbxassetid://96293355496772",
        ["Lifeguard Whistle"] = "rbxassetid://93791958663348",
        ["Mammoth Horn"] = "rbxassetid://93076834584542",
        ["Megaphone"] = "rbxassetid://107074211847347",
        ["Trumpet"] = "rbxassetid://88975601634708",
    },
    ["Warper"] = {
        ["Standard"] = "rbxassetid://88033795039891",
        ["Arcane Warper"] = "rbxassetid://83632373572638",
        ["Bubbler"] = "rbxassetid://106002684466857",
        ["Electropunk Warper"] = "rbxassetid://75386728379756",
        ["Experiment W4"] = "rbxassetid://126884960764998",
        ["Frost Warper"] = "rbxassetid://70539216094396",
        ["Glitter Warper"] = "rbxassetid://94607497565715",
        ["Glorious Warper"] = "rbxassetid://95823647035211",
        ["Hotel Bell"] = "rbxassetid://117742703173821",
    },
    ["Warpstone"] = {
        ["Standard"] = "rbxassetid://94035693279005",
        ["Cyber Warpstone"] = "rbxassetid://133002984228937",
        ["Electropunk Warpstone"] = "rbxassetid://75299042976369",
        ["Glorious Warpstone"] = "rbxassetid://137583560042806",
        ["Teleport Disc"] = "rbxassetid://104608154111107",
        ["Unstable Warpstone"] = "rbxassetid://110083777654388",
        ["Warp Juice"] = "rbxassetid://74381576761026",
        ["Warpbone"] = "rbxassetid://96452209607150",
        ["Warpeye"] = "rbxassetid://127023603234857",
        ["Warpstar"] = "rbxassetid://102652397897598",
    },
    ["Wildcat"] = {
        ["Standard"] = "rbxassetid://77401164737509",
        ["Glorious Wildcat"] = "rbxassetid://115657943825380",
        ["Plasma Wildcat"] = "rbxassetid://86238922896100",
    },
}


local IS = {
    ["rbxassetid://17160682738"] = "Assault Rifle",
    ["rbxassetid://93390542043222"] = "Battle Axe",
    ["rbxassetid://17160802080"] = "Bow",
    ["rbxassetid://17160801983"] = "Burst Rifle",
    ["rbxassetid://17160801873"] = "Chainsaw",
    ["rbxassetid://140211832612284"] = "Crossbow",
    ["rbxassetid://91885384580845"] = "Daggers",
    ["rbxassetid://115712150398379"] = "Distortion",
    ["rbxassetid://79471670126710"] = "Energy Pistols",
    ["rbxassetid://110259279810005"] = "Energy Rifle",
    ["rbxassetid://17344796376"] = "Exogun",
    ["rbxassetid://17160801745"] = "Fists",
    ["rbxassetid://89455038280473"] = "Flamethrower",
    ["rbxassetid://17160801627"] = "Flare Gun",
    ["rbxassetid://17160801529"] = "Flashbang",
    ["rbxassetid://18429552328"] = "Freeze Ray",
    ["rbxassetid://103255844976245"] = "Grappler",
    ["rbxassetid://17160801411"] = "Grenade",
    ["rbxassetid://17250453814"] = "Grenade Launcher",
    ["rbxassetid://131231034374465"] = "Gunblade",
    ["rbxassetid://17160801282"] = "Handgun",
    ["rbxassetid://79459600453621"] = "Jump Pad",
    ["rbxassetid://17160801158"] = "Katana",
    ["rbxassetid://17160800983"] = "Knife",
    ["rbxassetid://81478141693597"] = "Maul",
    ["rbxassetid://17160800734"] = "Medkit",
    ["rbxassetid://17250458611"] = "Minigun",
    ["rbxassetid://109264750627289"] = "Molotov",
    ["rbxassetid://17160853798"] = "Paintball Gun",
    ["rbxassetid://74353733133888"] = "Permafrost",
    ["rbxassetid://17160802243"] = "RPG",
    ["rbxassetid://17160800299"] = "Revolver",
    ["rbxassetid://121172272442833"] = "Riot Shield",
    ["rbxassetid://82237471151891"] = "Satchel",
    ["rbxassetid://17160800186"] = "Scythe",
    ["rbxassetid://17160800091"] = "Shorty",
    ["rbxassetid://17160800007"] = "Shotgun",
    ["rbxassetid://17160799888"] = "Slingshot",
    ["rbxassetid://17160799767"] = "Smoke Grenade",
    ["rbxassetid://17160799574"] = "Sniper",
    ["rbxassetid://122801133017271"] = "Spear",
    ["rbxassetid://92882887485248"] = "Spray",
    ["rbxassetid://17160799418"] = "Subspace Tripmine",
    ["rbxassetid://17160799172"] = "Trowel",
    ["rbxassetid://17160798908"] = "Uzi",
    ["rbxassetid://104600246515190"] = "War Horn",
    ["rbxassetid://88033795039891"] = "Warper",
    ["rbxassetid://94035693279005"] = "Warpstone",
    ["rbxassetid://77401164737509"] = "Wildcat",
}



-- Vector slot navigation
local ga = function(f)
    if not f or not f.Address then return end
    local n = rd(f.Address + OFF.Children)
    if not n or n == 0 then return end
    local b, e = rd(n), rd(n + 8)
    if b and e then return b, e end
end

local fs = function(b, e, t)
    if not b or not e then return end
    for i = 0, floor((e - b) / 16) - 1 do
        local a = b + i * 16
        if rd(a) == t then return a end
    end
end

-- One-way pointer replacement (icons.lua architecture)
local function swc(parent, default, skin)
    local b, e = ga(parent)
    if not b then return end
    local sl = fs(b, e, default.Address)
    if not sl then return end
    wr(skin.Address + OFF.Name, rd(default.Address + OFF.Name))
    wr(skin.Address + OFF.Parent, parent.Address)
    wr(sl, skin.Address)
end

local function swe(fn, cn, ba)
    local f = ff(mi, fn)
    if not f then return end
    local d, k = ff(f, ba or "Default"), ff(f, cn)
    if not d or not k then return end
    if cn == (ba or "Default") then return end
    swc(f, d, k)
end

-- Special Misc Effects (Particles, JumpPads, Portals, Vortexes, Flames)
local S = {
    Snowglobe = { SmokeClouds = "Snowglobe" },
    ["Emoji Cloud"] = { SmokeClouds = "Emoji Cloud" },
    Balance = { SmokeClouds = "Balance" },
    Eyeball = { SmokeClouds = "Eyeball" },
    Hourglass = { SmokeClouds = "Hourglass" },
    ["Temporal Ray"] = { FreezeEffects = "Temporal" },
    ["Bubble Ray"] = { FreezeEffects = "Bubble" },
    ["Spider Ray"] = { FreezeEffects = "Cocoon" },
    ["Wrapped Freeze Ray"] = { FreezeEffects = "Wrapped" },
    ["Gum Ray"] = { FreezeEffects = "Gum" },
    ["Pixel Flamethrower"] = { BurningEffects = "Pixel Flamethrower", FlamethrowerFlames = "Pixel Flamethrower", FlamethrowerAirblasts = "Pixel Flamethrower" },
    ["Jack O'Thrower"] = { BurningEffects = "Jack O'Thrower", FlamethrowerFlames = "Jack O'Thrower" },
    Keythrower = { BurningEffects = "Keythrower", FlamethrowerFlames = "Keythrower", FlamethrowerAirblasts = "Keythrower" },
    Snowblower = { BurningEffects = "Snowblower", FlamethrowerFlames = "Snowblower" },
    Blobsaw = { ChainsawParticles = "Chainsaw" },
    Megaphone = { WarHornEffects = "Megaphone" },
    Trampoline = { JumpPads = "Trampoline" },
    ["Bounce House"] = { JumpPads = "Bounce House" },
    ["Shady Chicken Sandwich"] = { JumpPads = "Shady Chicken Sandwich" },
    ["Glorious Jump Pad"] = { JumpPads = "Glorious Jump Pad" },
    ["Spider Web"] = { JumpPads = "Spider Web" },
    ["Jolly Man"] = { JumpPads = "Jolly Man" },
    ["Electropunk Warper"] = { Portals = "Electropunk Warper" },
    ["Experiment W4"] = { Portals = "Experiment W4" },
    ["Glitter Warper"] = { Portals = "Glitter Warper" },
    ["Frost Warper"] = { Portals = "Frost Warper" },
    ["Arcane Warper"] = { Portals = "Arcane Warper" },
    ["Hotel Bell"] = { Portals = "Hotel Bell" },
    ["Experiment D15"] = { Vortexes = "Distortion" },
    ["Cyber Distortion"] = { Vortexes = "Cyber Distortion" },
    Sleighstortion = { Vortexes = "Sleighstortion" },
    ["Magma Distortion"] = { Vortexes = "Magma Distortion" },
    ["Plasma Distortion"] = { Vortexes = "Plasma Distortion" },
    ["Teleport Disc"] = { BlipEffects = "Teleport Disc" },
    Warpeye = { BlipEffects = "Warpeye" },
    ["Evil Trident"] = { _d = "Evil Trident" },
    Saber = { _d = "Saber" },
    ["Lightning Bolt"] = { _d = "Lightning Bolt" },
    ["New Year Katana"] = { _d = "New Year Katana" },
    ["Stellar Katana"] = { _d = "Stellar Katana" },
    ["Pixel Katana"] = { _d = "Default", DeflectActiveEffects = "Pixel Katana" },
    ["Crystal Katana"] = { _d = "Crystal Katana" },
    Coffee = { MolotovExplosionEffects = "Coffee", BurningEffects = "Coffee", FireHitboxes = "Coffee" },
    ["Vexed Candle"] = { MolotovExplosionEffects = "Vexed Candle", BurningEffects = "Vexed Candle", FireHitboxes = "Vexed Candle" },
    ["Arch Molotov"] = { BurningEffects = "Arch Molotov", MolotovExplosionEffects = "Arch Molotov", FireHitboxes = "Arch Molotov" },
    ["Ship In A Bottle"] = { BurningEffects = "Ship In A Bottle", MolotovExplosionEffects = "Ship In A Bottle", FireHitboxes = "Ship In A Bottle" },
    ["Lava Lamp"] = { MolotovExplosionEffects = "Lava Lamp", FireHitboxes = "Lava Lamp" },
    ["Hot Coals"] = { FireHitboxes = "Hot Coals" },
    ["Arch Katana"] = { _d = "Arch Katana" },
    Keytana = { _d = "Keytana" },
    Rainbowthrower = { BurningEffects = "Rainbowthrower", FlamethrowerFlames = "Rainbowthrower" },
    Glitterthrower = { BurningEffects = "Glitterthrower", FlamethrowerFlames = "Glitterthrower" },
    ["Electropunk Warpstone"] = { BlipEffects = "Electropunk Warpstone" },
    Warpstar = { BlipEffects = "Warpstar" },
    Warpbone = { BlipEffects = "Warpbone" },
    ["Cyber Warpstone"] = { BlipEffects = "Cyber Warpstone" },
    Wondergun = { _m = "Wondergun" },
    Singularity = { _m = "Singularity" },
    ["Midnight Festive Exogun"] = { _m = "Midnight Festive Exogun" },
    Repulsor = { _m = "Repulsor" },
    Extinguisher = { BurningEffects = "Extinguisher", FlamethrowerFlames = "Extinguisher" }
}

-- Explosion particle mappings
local EX = {
    Wondergun = "WondergunExplosionParticles",
    Singularity = "SingularityExplosionParticles",
    ["Midnight Festive Exogun"] = "MidnightFestiveExogunExplosionParticles",
    Repulsor = "RepulsorExplosionParticles",
    Exogourd = "ExogourdExplosionParticles",
    ["Ray Gun"] = "RayGunExplosionParticles",
    Advanced = "AdvancedExplosionParticles",
    ["Cyber Distortion"] = "CyberExplosionParticles",
    Sleighstortion = "SleighstortionExplosionParticles",
    ["Magma Distortion"] = "MagmaDistortionExplosionParticles",
    ["Plasma Distortion"] = "PlasmaDistortionExplosionParticles",
    ["Experiment D15"] = "ExperimentD15ExplosionParticles",
    ["Gum Ray"] = "GumRayExplosionEffect",
    ["Bubble Ray"] = "BubbleRayExplosionEffect",
    ["Spider Ray"] = "SpiderRayExplosionEffect",
    ["Temporal Ray"] = "TemporalRayExplosionEffect",
    ["Wrapped Freeze Ray"] = "WrappedFreezeRayExplosionEffect"
}

local EXB = {
    Exogun = "ExogunExplosionParticles",
    Distortion = "DistortionExplosionParticles",
    ["Freeze Ray"] = "FreezeRayExplosionEffect"
}

local TH = { Flashbang = 1, Grenade = 1, Molotov = 1, ["Smoke Grenade"] = 1, Satchel = 1, Warpstone = 1 }
local PR = { RPG = 1, Bow = 1, ["Grenade Launcher"] = 1, Slingshot = 1, ["Freeze Ray"] = 1, Daggers = 1, Crossbow = 1, ["Flare Gun"] = 1, Distortion = 1, Permafrost = 1 }

local ops, ct = {}, 0
for _, e in ipairs(en) do
    local w, s = e[1], e[2]
    local wI, sI = aW[w], sc[s]
    if wI and sI then
        -- Skip Satchel & RPG viewmodels to prevent engine vector desync
        if w ~= "Satchel" and w ~= "RPG" then
            ops[#ops + 1] = function() swc(wf, wI, sI); ct = ct + 1 end
        end
        local m = S[s]
        if m then
            for fn, cn in pairs(m) do
                if fn == "_d" then
                    ops[#ops + 1] = function() swe("DeflectHitEffects", cn); swe("DeflectActiveEffects", cn); ct = ct + 1 end
                elseif fn == "_m" then
                    ops[#ops + 1] = function() swe("MuzzleFlashes", cn, "Exogun"); ct = ct + 1 end
                else
                    ops[#ops + 1] = function() swe(fn, cn); ct = ct + 1 end
                end
            end
        end
        local xn = EX[s]
        local xb = EXB[w]
        if xn and xb then
            ops[#ops + 1] = function()
                local sx, dx = ff(mi, xn), ff(mi, xb)
                if sx and dx then swc(mi, dx, sx); ct = ct + 1 end
            end
        end
        if TH[w] and tf then
            local tb, ts = ff(tf, w), ff(tf, s)
            if tb and ts then ops[#ops + 1] = function() swc(tf, tb, ts); ct = ct + 1 end end
        end
        if PR[w] and pf then
            local pb, p2 = ff(pf, w), ff(pf, s)
            if pb and p2 then ops[#ops + 1] = function() swc(pf, pb, p2); ct = ct + 1 end end
        end
    end
end

-- MuzzleFlashes
local mff = ff(mi, "MuzzleFlashes")
if mff then
    local MFB = {
        Handgun = "Hand Gun", Spray = "Spray", Minigun = "Minigun",
        ["Energy Pistols"] = "Energy Pistols", ["Energy Rifle"] = "Energy Rifle",
        ["Paintball Gun"] = "Paintball Gun", Crossbow = "Crossbow", Warper = "Warper", Permafrost = "Permafrost"
    }
    for _, e in ipairs(en) do
        local w, s = e[1], e[2]
        local mb = MFB[w]
        if mb then
            local md, mk = ff(mff, mb), ff(mff, s)
            if md and mk and md ~= mk and md.Address and mk.Address then
                local a, b = mrd("uintptr_t", md.Address + 0x8), mrd("uintptr_t", mk.Address + 0x8)
                if a and b and a ~= b then
                    ops[#ops + 1] = function()
                        mwr("uintptr_t", md.Address + 0x8, b)
                        mwr("uintptr_t", mk.Address + 0x8, a)
                        ct = ct + 1
                    end
                end
            end
        end
    end
end

-- Execute all memory operations
for _, op in ipairs(ops) do
    pcall(op)
end

print("[RivalsSkinChanger] Successfully applied " .. tostring(ct) .. " skin swaps!")
notifyUser("Rivals Skin Changer", "Applied " .. tostring(ct) .. " skin swaps!", 4)

-- 2D HUD & Equipment Icon Engine (icons.lua architecture)
local SP = {
    ["Pixel Sniper"] = {"rbxassetid://18171031143", "rbxassetid://18171045114"},
    Keyper = {"rbxassetid://129335242148588", "rbxassetid://81498448678518"}
}

local ic, pi, spd = {}, {}, nil
for _, e in ipairs(en) do
    local w, s = e[1], e[2]
    if IL[w] and IL[w][s] then
        local id = IL[w][s]
        local b = {}
        for j = 1, #id do b[j] = byte(id, j) end
        ic[#ic + 1] = {w = w, id = id, b = b, l = #id}
    end
    if w == "Sniper" and SP[s] and not spd then
        local bl, cl = SP[s][1], SP[s][2]
        local bb, cb = {}, {}
        for j = 1, #bl do bb[j] = byte(bl, j) end
        for j = 1, #cl do cb[j] = byte(cl, j) end
        spd = {bb = bb, bl = #bl, cb = cb, cl = #cl, bi = bl, ci = cl}
    end
end

for sid, w in pairs(IS) do
    for _, e in ipairs(en) do
        if e[1] == w and IL[w] and IL[w][e[2]] then
            local id = IL[w][e[2]]
            local b = {}
            for j = 1, #id do b[j] = byte(id, j) end
            pi[sid] = {b = b, l = #id}
            break
        end
    end
end

local ni = #ic

-- In-place 4-byte fast integer string writer
local function wr2(a, p, b, l)
    local i = 1
    while i + 3 <= l do
        mwr("int", p + i - 1, b[i] + b[i+1]*256 + b[i+2]*65536 + b[i+3]*16777216)
        i = i + 4
    end
    while i <= l do
        mwr("uint8_t", p + i - 1, b[i])
        i = i + 1
    end
    mwr("uint8_t", p + l, 0)
    mwr("int", a + 0xA20, l)
    mwr("int", a + 0xA28, l)
end

local function swi(t)
    if not t or not t.Address then return end
    local a = t.Address
    local p = mrd("uintptr_t", a + 0xA18)
    if not p or p == 0 then return end
    local c = mrd("string", p)
    if not c then return end
    local d = pi[c]
    if not d then return end
    local cp = mrd("int", a + 0xA30)
    if not cp or d.l > cp then return end
    wr2(a, p, d.b, d.l)
end

local ln = LP.Name
local hbc, hbr, hbd = {}, nil, {}
local mf = nil

-- Threaded 0ms loop that safely halts on place unload / leave without crashing
task.spawn(function()
    while not mf do
        pcall(function()
            local pg = LP:FindFirstChild("PlayerGui")
            mf = pg and pg.MainGui.MainFrame
        end)
        task.wait(0.5)
    end

    while true do
        task.wait(0)
        
        -- 1. Hotbar Slots & EquippedDisplay
        pcall(function()
            local fi = mf:FindFirstChild("FighterInterfaces")
            local lni = fi and fi:FindFirstChild(ln)
            local sub = lni and (lni:FindFirstChild("BottomRight") or lni:FindFirstChild("BottomCenter") or lni:FindFirstChild("BottomLeft"))
            local c = sub and sub:FindFirstChild("Container")
            local hb = c and c:FindFirstChild("Hotbar") and c.Hotbar:FindFirstChild("Container")
            if not hb then
                local directHb = lni and lni:FindFirstChild("Hotbar") and lni.Hotbar:FindFirstChild("Container")
                hb = directHb
            end
            
            if hb and hb ~= hbr then
                hbr = hb
                hbc = {}
                hbd = {}
                for i = 1, ni do
                    local s = ff(hb, ic[i].w)
                    if s then hbc[i] = ff(s, "Icon") end
                end
            end
            
            if hb then
                for i = 1, ni do
                    if not hbd[i] then
                        local k = hbc[i]
                        if k and k.Address then
                            local a = k.Address
                            local p = mrd("uintptr_t", a + 0xA18)
                            if p and p ~= 0 then
                                local cur = mrd("string", p)
                                if cur == ic[i].id then
                                    hbd[i] = true
                                elseif cur then
                                    local cp = mrd("int", a + 0xA30)
                                    if cp and ic[i].l <= cp then
                                        wr2(a, p, ic[i].b, ic[i].l)
                                        hbd[i] = true
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Also update EquippedDisplay
                local eqDisp = ff(hb, "EquippedDisplay")
                if eqDisp then
                    local w2 = eqDisp:FindFirstChild("Container") and eqDisp.Container:FindFirstChild("Weapon")
                    local iconLabel = w2 and w2:FindFirstChild("Icon")
                    if iconLabel then swi(iconLabel) end
                end
            end
        end)

        -- 2. PickWeapons Page
        pcall(function()
            local pw = mf.Pages:FindFirstChild("PickWeapons")
            if pw and pw.Visible then
                local list = pw:FindFirstChild("List") and pw.List:FindFirstChild("Container")
                if list then
                    for _, f in ipairs(list:GetChildren()) do
                        if f.ClassName == "Frame" and ff(f, "Button") and f.Button:FindFirstChild("Icon") then
                            pcall(function() swi(f.Button.Icon.Picture) end)
                        end
                    end
                end
                local chosen = pw:FindFirstChild("ChosenWeapons")
                if chosen then
                    for _, f in ipairs(chosen:GetChildren()) do
                        if f.ClassName == "Frame" and ff(f, "Button") then
                            pcall(function() swi(f.Button.Picture) end)
                        end
                    end
                end
            end
        end)

        -- 3. PickWeaponsList Page
        pcall(function()
            local pw2 = mf.Pages:FindFirstChild("PickWeaponsList")
            if pw2 and pw2.Visible then
                local lc = pw2:FindFirstChild("ListContainer") and pw2.ListContainer:FindFirstChild("List") and pw2.ListContainer.List:FindFirstChild("Container")
                if lc then
                    for _, s in ipairs(lc:GetChildren()) do
                        if s.Name == "PickWeaponListSlot" and ff(s, "Button") and s.Button:FindFirstChild("Icon") then
                            pcall(function() swi(s.Button.Icon.Picture) end)
                        end
                    end
                end
                local ch = pw2:FindFirstChild("ChosenWeapons")
                if ch then
                    for _, s in ipairs(ch:GetChildren()) do
                        if s.Name == "PickWeaponListChosenSlot" and ff(s, "Button") then
                            pcall(function() swi(s.Button.Picture) end)
                        end
                    end
                end
            end
        end)

        -- 4. Equipment Page
        pcall(function()
            local eq = mf:FindFirstChild("Equipment")
            if eq and eq.Visible then
                for _, d in ipairs(eq:GetDescendants()) do
                    if d.ClassName == "ImageLabel" or d.ClassName == "ImageButton" then
                        pcall(swi, d)
                    end
                end
            end
        end)

        -- 5. Custom Sniper Scope
        if spd then
            pcall(function()
                local ii = mf:FindFirstChild("ItemInterfaces")
                local si = ii and ii:FindFirstChild(ln .. " - Sniper")
                if not si then return end
                local sc2 = si.Mouse.Scope
                local bi, ci = sc2.Blur.ImageLabel, sc2.Circle.ImageLabel
                local ba, ca = bi.Address, ci.Address
                local bp = mrd("uintptr_t", ba + 0xA18)
                if bp and bp ~= 0 then
                    local cur = mrd("string", bp)
                    if cur ~= spd.bi then
                        local bc = mrd("int", ba + 0xA30)
                        if bc and spd.bl <= bc then wr2(ba, bp, spd.bb, spd.bl) end
                    end
                end
                local cp2 = mrd("uintptr_t", ca + 0xA18)
                if cp2 and cp2 ~= 0 then
                    local cur = mrd("string", cp2)
                    if cur ~= spd.ci then
                        local cc = mrd("int", ca + 0xA30)
                        if cc and spd.cl <= cc then wr2(ca, cp2, spd.cb, spd.cl) end
                    end
                end
            end)
        end
    end
end)
