-- Memory access verification
if not pcall(memory_read, "int", game.Address) then 
    pcall(notify, "UnsafeLua is disabled in executor.", "SC", 5) 
    return 
end

-- Wait for game and player loading
if not game:IsLoaded() then game.Loaded:Wait() end

local LP = game:GetService("Players").LocalPlayer
while not LP do
    task.wait(0.5)
    LP = game:GetService("Players").LocalPlayer
end

-- Validate game universe
if game.GameId ~= 6035872082 then return end

local char = LP.Character or LP.CharacterAdded:Wait()
if char then pcall(function() char:WaitForChild("HumanoidRootPart", 10) end) end

-- Locate weapon models in player assets
local A = LP:WaitForChild("PlayerScripts", 15):WaitForChild("Assets", 15)
local vm = A and A:WaitForChild("ViewModels", 15)
local wf = vm and vm:WaitForChild("Weapons", 15)

if wf then
    local retries = 0
    while #wf:GetChildren() < 10 and retries < 20 do
        task.wait(0.2)
        retries = retries + 1
    end
end

-- Memory read/write wrappers and offsets
local mrd, mwr, pcall, ipairs, pairs = memory_read, memory_write, pcall, ipairs, pairs

local rd = function(a) 
    local o, v = pcall(mrd, "uintptr_t", a)
    return o and v or nil 
end

local wr = function(a, v) 
    pcall(mwr, "uintptr_t", a, v) 
end

local OFF = {
    Parent = 104,
    NameContainer = 112,
    Children = 120,
    Transparency = 304
}

-- Instance child array pointer helper
local ga = function(f) 
    if not f or not f.Address then return end
    local n = rd(f.Address + OFF.Children)
    if not n or n == 0 then return end
    local b, e = rd(n), rd(n + 8)
    if b and e then return b, e end 
end

-- Dynamic weapon slot resolution in memory vector
local function findSlotAddressForWeapon(weaponModel, targetFolder)
    local f = targetFolder or wf
    local b, e = ga(f)
    if not b or not e then return nil end
    for slotAddr = b, e - 16, 16 do
        if rd(slotAddr) == weaponModel.Address then
            return slotAddr
        end
    end
    return nil
end

-- Skin to folder and internal model name mapping
local EXACT_SKIN_MAP = {
    ["Box of Chocolates"] = {folder = "Bundles", name = "Medkit"},
    ["Balloon Launcher"] = {folder = "Bundles", name = "Grenade Launcher"},
    ["Balloon Axe"] = {folder = "Bundles", name = "Battle Axe"},
    ["Balloon Bow"] = {folder = "Bundles", name = "Bow"},
    ["Balloon Shorty"] = {folder = "Bundles", name = "Too Shorty"},
    ["Balloon Shotgun"] = {folder = "Bundles", name = "Shotgun"},
    ["Rocket Launcher"] = {folder = "Bundles", name = "Rocket Launcher"},
    ["Cuddle Bomb"] = {folder = "Bundles", name = "Grenade"},
    ["Ice Maul"] = {folder = "Bundles", name = "Ice Maul"},
    ["Ban Hammer"] = {folder = "Bundles", name = "Maul"},
    ["Giant Pencil"] = {folder = "Bundles", name = "Spear"},
    ["10B Visits"] = {folder = "Bundles", name = "10B Visits"},
    ["Event Horizon"] = {folder = "Bundles", name = "Event Horizon"},
    ["Fighter Jet"] = {folder = "Bundles", name = "Fighter Jet"},
    ["Aces"] = {folder = "Skin Case 2", name = "Aces"},
    ["Apex Pistols"] = {folder = "Bundles", name = "Apex Pistols"},
    ["Apex Rifle"] = {folder = "Bundles", name = "Apex Rifle"},
    ["Crystal Katana"] = {folder = "Bundles", name = "Crystal Katana"},
    ["Pixel Katana"] = {folder = "Bundles", name = "Pixel Katana"},
    ["Linked Sword"] = {folder = "Bundles", name = "Linked Sword"},
    ["Caladbolg"] = {folder = "Bundles", name = "Caladbolg"},
    ["Cutlass"] = {folder = "Bundles", name = "Cutlass"},
    ["Riptide Katana"] = {folder = "Bundles", name = "Riptide Katana"},
    ["Blaster"] = {folder = "Skin Case", name = "Handgun"},
    ["Advanced Satchel"] = {folder = "Skin Case", name = "Satchel"},
    ["Boomstick"] = {folder = "Skin Case", name = "Shotgun"},
    ["Blobsaw"] = {folder = "Skin Case", name = "Chainsaw"},
    ["Boxing Gloves"] = {folder = "Skin Case", name = "Fists"},
    ["Door"] = {folder = "Skin Case", name = "Door"},
    ["Saber"] = {folder = "Skin Case", name = "Saber"},
    ["Chancla"] = {folder = "Skin Case", name = "Chancla"},
    ["Stick"] = {folder = "Skin Case", name = "Stick"},
    ["Water Uzi"] = {folder = "Skin Case", name = "Water Uzi"},
    ["Lasergun 3000"] = {folder = "Skin Case", name = "Lasergun 3000"},
    ["Pixel Flamethrower"] = {folder = "Skin Case", name = "Pixel Flamethrower"},
    ["Nuke Launcher"] = {folder = "Skin Case", name = "Nuke Launcher"},
    ["Emoji Cloud"] = {folder = "Skin Case", name = "Emoji Cloud"},
    ["Coffee"] = {folder = "Skin Case", name = "Coffee"},
    ["Disco Ball"] = {folder = "Skin Case", name = "Disco Ball"},
    ["AK-47"] = {folder = "Skin Case", name = "AK-47"},
    ["Compound Bow"] = {folder = "Skin Case", name = "Compound Bow"},
    ["Not So Shorty"] = {folder = "Skin Case", name = "Not So Shorty"},
    ["Don't Press"] = {folder = "Skin Case", name = "Don't Press"},
    ["Singularity"] = {folder = "Skin Case", name = "Singularity"},
    ["Temporal Ray"] = {folder = "Skin Case", name = "Temporal Ray"},
    ["Hacker Pistols"] = {folder = "Skin Case", name = "Hacker Pistols"},
    ["Lovely Spray"] = {folder = "Skin Case", name = "Lovely Spray"},
    ["Electro Rifle"] = {folder = "Skin Case", name = "Electro Rifle"},
    ["Warpstone"] = {folder = "Skin Case", name = "Warpstone"},
    ["The Shred"] = {folder = "Skin Case", name = "The Shred"},
    ["Scythe of Death"] = {folder = "Skin Case", name = "Scythe of Death"},
    ["Sandwich"] = {folder = "Skin Case", name = "Sandwich"},
    ["Trampoline"] = {folder = "Skin Case", name = "Trampoline"},
    ["Hyper Gunblade"] = {folder = "Skin Case", name = "Hyper Gunblade"},
    ["Pixel Sniper"] = {folder = "Skin Case", name = "Pixel Sniper"},
    ["Swashbuckler"] = {folder = "Skin Case", name = "Swashbuckler"},
    ["Plasma Distortion"] = {folder = "Skin Case", name = "Plasma Distortion"},
    ["Glitter Warper"] = {folder = "Skin Case", name = "Glitter Warper"},
    ["Trumpet"] = {folder = "Skin Case", name = "Trumpet"},
    ["Camera"] = {folder = "Skin Case 2", name = "Flashbang"},
    ["Balance"] = {folder = "Skin Case 2", name = "Smoke Grenade"},
    ["Garden Shovel"] = {folder = "Skin Case 2", name = "Trowel"},
    ["Aqua Burst"] = {folder = "Skin Case 2", name = "Burst Rifle"},
    ["Bounce House"] = {folder = "Skin Case 2", name = "Jump Pad"},
    ["Energy Shield"] = {folder = "Skin Case 2", name = "Energy Shield"},
    ["Notebook Satchel"] = {folder = "Skin Case 2", name = "Notebook Satchel"},
    ["Nail Gun"] = {folder = "Skin Case 2", name = "Nail Gun"},
    ["Hydro Rifle"] = {folder = "Skin Case 2", name = "Hydro Rifle"},
    ["Void Pistols"] = {folder = "Skin Case 2", name = "Void Pistols"},
    ["Megaphone"] = {folder = "Skin Case 2", name = "Megaphone"},
    ["Hyper Sniper"] = {folder = "Skin Case 2", name = "Hyper Sniper"},
    ["Magma Distortion"] = {folder = "Skin Case 2", name = "Magma Distortion"},
    ["Goalpost"] = {folder = "Skin Case 2", name = "Goalpost"},
    ["Raven Bow"] = {folder = "Skin Case 2", name = "Raven Bow"},
    ["Hyper Shotgun"] = {folder = "Skin Case 2", name = "Hyper Shotgun"},
    ["Dynamite Gun"] = {folder = "Skin Case 2", name = "Dynamite Gun"},
    ["Pixel Minigun"] = {folder = "Skin Case 2", name = "Pixel Minigun"},
    ["Water Balloon"] = {folder = "Skin Case 2", name = "Water Balloon"},
    ["Crude Gunblade"] = {folder = "Skin Case 2", name = "Crude Gunblade"},
    ["Lamethrower"] = {folder = "Skin Case 2", name = "Lamethrower"},
    ["Spring"] = {folder = "Skin Case 2", name = "Spring"},
    ["Brass Knuckles"] = {folder = "Skin Case 2", name = "Brass Knuckles"},
    ["Electro Uzi"] = {folder = "Skin Case 2", name = "Electro Uzi"},
    ["Lovely Shorty"] = {folder = "Skin Case 2", name = "Lovely Shorty"},
    ["Ray Gun"] = {folder = "Skin Case 2", name = "Ray Gun"},
    ["Lightning Bolt"] = {folder = "Skin Case 2", name = "Lightning Bolt"},
    ["Torch"] = {folder = "Skin Case 2", name = "Torch"},
    ["Spaceship Launcher"] = {folder = "Skin Case 2", name = "Spaceship Launcher"},
    ["Sheriff"] = {folder = "Skin Case 2", name = "Sheriff"},
    ["Arcane Warper"] = {folder = "Skin Case 2", name = "Arcane Warper"},
    ["Laptop"] = {folder = "Skin Case 2", name = "Laptop"},
    ["Karambit"] = {folder = "Skin Case 2", name = "Karambit"},
    ["Uranium Launcher"] = {folder = "Skin Case 2", name = "Uranium Launcher"},
    ["Teleport Disc"] = {folder = "Skin Case 2", name = "Teleport Disc"},
    ["Ban Axe"] = {folder = "Skin Case 2", name = "Ban Axe"},
    ["Paper Planes"] = {folder = "Skin Case 2", name = "Paper Planes"},
    ["Harpoon Crossbow"] = {folder = "Skin Case 2", name = "Harpoon Crossbow"},
    ["Handsaws"] = {folder = "Skin Case 2", name = "Handsaws"},
    ["Hand Gun"] = {folder = "Skin Case 2", name = "Hand Gun"},
    ["Balisong"] = {folder = "Skin Case 3", name = "Knife"},
    ["DIY Tripmine"] = {folder = "Skin Case 3", name = "Subspace Tripmine"},
    ["Air Horn"] = {folder = "Skin Case 3", name = "War Horn"},
    ["Banana Flare"] = {folder = "Skin Case 3", name = "Flare Gun"},
    ["Tommy Gun"] = {folder = "Skin Case 3", name = "Tommy Gun"},
    ["FAMAS"] = {folder = "Skin Case 3", name = "FAMAS"},
    ["Dream Bow"] = {folder = "Skin Case 3", name = "Dream Bow"},
    ["Stellar Katana"] = {folder = "Skin Case 3", name = "Stellar Katana"},
    ["Peppergun"] = {folder = "Skin Case 3", name = "Peppergun"},
    ["Squid Launcher"] = {folder = "Skin Case 3", name = "Squid Launcher"},
    ["Glitterthrower"] = {folder = "Skin Case 3", name = "Glitterthrower"},
    ["Medkitty"] = {folder = "Skin Case 3", name = "Medkitty"},
    ["Cerulean Axe"] = {folder = "Skin Case 3", name = "Cerulean Axe"},
    ["Repulsor"] = {folder = "Skin Case 3", name = "Repulsor"},
    ["Hotel Bell"] = {folder = "Skin Case 3", name = "Hotel Bell"},
    ["Cactus Shotgun"] = {folder = "Skin Case 3", name = "Cactus Shotgun"},
    ["Shady Chicken Sandwich"] = {folder = "Skin Case 3", name = "Shady Chicken Sandwich"},
    ["Bag o' Money"] = {folder = "Skin Case 3", name = "Bag o' Money"},
    ["Gunsaw"] = {folder = "Skin Case 3", name = "Gunsaw"},
    ["Electropunk Warpstone"] = {folder = "Skin Case 3", name = "Electropunk Warpstone"},
    ["Masterpiece"] = {folder = "Skin Case 3", name = "Masterpiece"},
    ["Spray Bottle"] = {folder = "Skin Case 3", name = "Spray Bottle"},
    ["Shurikens"] = {folder = "Skin Case 3", name = "Shurikens"},
    ["Gearnade Launcher"] = {folder = "Skin Case 3", name = "Gearnade Launcher"},
    ["Cyber Distortion"] = {folder = "Skin Case 3", name = "Cyber Distortion"},
    ["Void Rifle"] = {folder = "Skin Case 3", name = "Void Rifle"},
    ["Fists of Hurt"] = {folder = "Skin Case 3", name = "Fists of Hurt"},
    ["Boneclaw Revolver"] = {folder = "Spooky Skin Case", name = "Revolver"},
    ["Boneclaw Spray"] = {folder = "Spooky Skin Case", name = "Spray"},
    ["Crossbone"] = {folder = "Spooky Skin Case", name = "Crossbow"},
    ["Boneblade"] = {folder = "Spooky Skin Case", name = "Gunblade"},
    ["Exogourd"] = {folder = "Spooky Skin Case", name = "Exogun"},
    ["Boneshot"] = {folder = "Spooky Skin Case", name = "Slingshot"},
    ["Demon Uzi"] = {folder = "Spooky Skin Case", name = "Demon Uzi"},
    ["Trick or Treat"] = {folder = "Spooky Skin Case", name = "Trick or Treat"},
    ["Bat Bow"] = {folder = "Spooky Skin Case", name = "Bat Bow"},
    ["Vexed Candle"] = {folder = "Spooky Skin Case", name = "Vexed Candle"},
    ["Bucket of Candy"] = {folder = "Spooky Skin Case", name = "Bucket of Candy"},
    ["Pumpkin Claws"] = {folder = "Spooky Skin Case", name = "Pumpkin Claws"},
    ["Buzzsaw"] = {folder = "Spooky Skin Case", name = "Buzzsaw"},
    ["Skullbang"] = {folder = "Spooky Skin Case", name = "Skullbang"},
    ["Jack O'Thrower"] = {folder = "Spooky Skin Case", name = "Jack O'Thrower"},
    ["Machete"] = {folder = "Spooky Skin Case", name = "Machete"},
    ["Evil Trident"] = {folder = "Spooky Skin Case", name = "Evil Trident"},
    ["Boneclaw Rifle"] = {folder = "Spooky Skin Case", name = "Boneclaw Rifle"},
    ["Pumpkin Launcher"] = {folder = "Spooky Skin Case", name = "Pumpkin Launcher"},
    ["Vexed Flare Gun"] = {folder = "Spooky Skin Case", name = "Vexed Flare Gun"},
    ["Spectral Burst"] = {folder = "Spooky Skin Case", name = "Spectral Burst"},
    ["Boneclaw Horn"] = {folder = "Spooky Skin Case", name = "Boneclaw Horn"},
    ["Brain Gun"] = {folder = "Spooky Skin Case", name = "Brain Gun"},
    ["Eyething Sniper"] = {folder = "Spooky Skin Case", name = "Eyething Sniper"},
    ["Pumpkin Handgun"] = {folder = "Spooky Skin Case", name = "Pumpkin Handgun"},
    ["Eyeball"] = {folder = "Spooky Skin Case", name = "Eyeball"},
    ["Demon Shorty"] = {folder = "Spooky Skin Case", name = "Demon Shorty"},
    ["Bat Scythe"] = {folder = "Spooky Skin Case", name = "Bat Scythe"},
    ["Pumpkin Carver"] = {folder = "Spooky Skin Case", name = "Pumpkin Carver"},
    ["Broomstick"] = {folder = "Spooky Skin Case", name = "Broomstick"},
    ["Skull Launcher"] = {folder = "Spooky Skin Case", name = "Skull Launcher"},
    ["Soul Grenade"] = {folder = "Spooky Skin Case", name = "Soul Grenade"},
    ["Bat Daggers"] = {folder = "Spooky Skin Case", name = "Bat Daggers"},
    ["Mimic Axe"] = {folder = "Spooky Skin Case", name = "Mimic Axe"},
    ["Potion Satchel"] = {folder = "Spooky Skin Case", name = "Potion Satchel"},
    ["Tombstone Shield"] = {folder = "Spooky Skin Case", name = "Tombstone Shield"},
    ["Soul Pistols"] = {folder = "Spooky Skin Case", name = "Soul Pistols"},
    ["Experiment D15"] = {folder = "Spooky Skin Case", name = "Experiment D15"},
    ["Experiment W4"] = {folder = "Spooky Skin Case", name = "Experiment W4"},
    ["Spider Web"] = {folder = "Spooky Skin Case", name = "Spider Web"},
    ["Warpeye"] = {folder = "Spooky Skin Case", name = "Warpeye"},
    ["Warpbone"] = {folder = "Spooky Skin Case", name = "Warpbone"},
    ["Soul Rifle"] = {folder = "Spooky Skin Case", name = "Soul Rifle"},
    ["Pumpkin Minigun"] = {folder = "Spooky Skin Case", name = "Pumpkin Minigun"},
    ["Bubblethrower"] = {folder = "Summer Skin Case", name = "Flamethrower"},
    ["Campfire Stick"] = {folder = "Summer Skin Case", name = "Molotov"},
    ["Bubble Ray"] = {folder = "Summer Skin Case", name = "Freeze Ray"},
    ["Boba Gun"] = {folder = "Summer Skin Case", name = "Paintball Gun"},
    ["Pearl Rifle"] = {folder = "Summer Skin Case", name = "Pearl Rifle"},
    ["Plastic Flamingo"] = {folder = "Summer Skin Case", name = "Plastic Flamingo"},
    ["Bubbler"] = {folder = "Summer Skin Case", name = "Bubbler"},
    ["Scooper"] = {folder = "Summer Skin Case", name = "Scooper"},
    ["Sol"] = {folder = "Summer Skin Case", name = "Sol"},
    ["Lifeguard Whistle"] = {folder = "Summer Skin Case", name = "Lifeguard Whistle"},
    ["Beach Ball"] = {folder = "Summer Skin Case", name = "Beach Ball"},
    ["Pocket Volcano"] = {folder = "Summer Skin Case", name = "Pocket Volcano"},
    ["Sharkbite"] = {folder = "Summer Skin Case", name = "Sharkbite"},
    ["Chark Kebab"] = {folder = "Summer Skin Case", name = "Chark Kebab"},
    ["Warp Juice"] = {folder = "Summer Skin Case", name = "Warp Juice"},
    ["Hazard Sign"] = {folder = "Summer Skin Case", name = "Hazard Sign"},
    ["Palmshot"] = {folder = "Summer Skin Case", name = "Palmshot"},
    ["Broken Surfboard"] = {folder = "Summer Skin Case", name = "Broken Surfboard"},
    ["Cruise Revolver"] = {folder = "Summer Skin Case", name = "Cruise Revolver"},
    ["Crab Claws"] = {folder = "Summer Skin Case", name = "Crab Claws"},
    ["Campfire Crossbow"] = {folder = "Summer Skin Case", name = "Campfire Crossbow"},
    ["Giant Popsicle"] = {folder = "Summer Skin Case", name = "Giant Popsicle"},
    ["Bubble Shorty"] = {folder = "Summer Skin Case", name = "Bubble Shorty"},
    ["Palm Bow"] = {folder = "Summer Skin Case", name = "Palm Bow"},
    ["Starfish"] = {folder = "Summer Skin Case", name = "Starfish"},
    ["Bubble Distortion"] = {folder = "Summer Skin Case", name = "Bubble Distortion"},
    ["Lifeguard Grappler"] = {folder = "Summer Skin Case", name = "Lifeguard Grappler"},
    ["Pearl Exogun"] = {folder = "Summer Skin Case", name = "Pearl Exogun"},
    ["Sundae Launcher"] = {folder = "Summer Skin Case", name = "Sundae Launcher"},
    ["Ducky Uzi"] = {folder = "Summer Skin Case", name = "Ducky Uzi"},
    ["Sol Rifle"] = {folder = "Summer Skin Case", name = "Sol Rifle"},
    ["Sol Pistols"] = {folder = "Summer Skin Case", name = "Sol Pistols"},
    ["Lifeguard Satchel"] = {folder = "Summer Skin Case", name = "Lifeguard Satchel"},
    ["Sandgun"] = {folder = "Summer Skin Case", name = "Sandgun"},
    ["Swordfish"] = {folder = "Summer Skin Case", name = "Swordfish"},
    ["Campfire Sniper"] = {folder = "Summer Skin Case", name = "Campfire Sniper"},
    ["Shark Tooth"] = {folder = "Summer Skin Case", name = "Shark Tooth"},
    ["Shark Shotgun"] = {folder = "Summer Skin Case", name = "Shark Shotgun"},
    ["Cooler"] = {folder = "Summer Skin Case", name = "Cooler"},
    ["Flamingo Floatie"] = {folder = "Summer Skin Case", name = "Flamingo Floatie"},
    ["Ice Cream"] = {folder = "Summer Skin Case", name = "Ice Cream"},
    ["Tiki Axe"] = {folder = "Summer Skin Case", name = "Tiki Axe"},
    ["Coconut Launcher"] = {folder = "Summer Skin Case", name = "Coconut Launcher"},
    ["Campfire Spray"] = {folder = "Summer Skin Case", name = "Campfire Spray"},
    ["Sharksaw"] = {folder = "Summer Skin Case", name = "Sharksaw"},
    ["Shark Minigun"] = {folder = "Summer Skin Case", name = "Shark Minigun"},
    ["Fizz Bomb"] = {folder = "Summer Skin Case", name = "Fizz Bomb"},
    ["Lemonade Gun"] = {folder = "Summer Skin Case", name = "Lemonade Gun"},
    ["Sand FAMAS"] = {folder = "Summer Skin Case", name = "Sand FAMAS"},
    ["Permasand"] = {folder = "Summer Skin Case", name = "Permasand"},
    ["Arch Katana"] = {folder = "Seasons", name = "Katana"},
    ["Arch Uzi"] = {folder = "Seasons", name = "Uzi"},
    ["Spy Gloves"] = {folder = "Seasons", name = "Spy Gloves"},
    ["Phoenix Rifle"] = {folder = "Seasons", name = "Phoenix Rifle"},
    ["Frozen Grenade"] = {folder = "Seasons", name = "Frozen Grenade"},
    ["Electropunk Warper"] = {folder = "Seasons", name = "Electropunk Warper"},
    ["Electropunk Distortion"] = {folder = "Seasons", name = "Electropunk Distortion"},
    ["Unstable Warpstone"] = {folder = "Seasons", name = "Unstable Warpstone"},
    ["Firework Launcher"] = {folder = "Festive Skin Case", name = "RPG"},
    ["Pine Burst"] = {folder = "Festive Skin Case", name = "Pine Burst"},
    ["Snowball Launcher"] = {folder = "Festive Skin Case", name = "Snowball Launcher"},
    ["Wrapped Shorty"] = {folder = "Festive Skin Case", name = "Wrapped Shorty"},
    ["Frostbite Bow"] = {folder = "Festive Skin Case", name = "Frostbite Bow"},
    ["Candy Cane"] = {folder = "Festive Skin Case", name = "Candy Cane"},
    ["Wrapped Flare Gun"] = {folder = "Festive Skin Case", name = "Wrapped Flare Gun"},
    ["Suspicious Gift"] = {folder = "Festive Skin Case", name = "Suspicious Gift"},
    ["Wrapped Freeze Ray"] = {folder = "Festive Skin Case", name = "Wrapped Freeze Ray"},
    ["Nordic Axe"] = {folder = "Festive Skin Case", name = "Nordic Axe"},
    ["Frostbite Crossbow"] = {folder = "Festive Skin Case", name = "Frostbite Crossbow"},
    ["Midnight Festive Exogun"] = {folder = "Festive Skin Case", name = "Midnight Festive Exogun"},
    ["Pine Spray"] = {folder = "Festive Skin Case", name = "Pine Spray"},
    ["Mammoth Horn"] = {folder = "Festive Skin Case", name = "Mammoth Horn"},
    ["Dev-in-the-Box"] = {folder = "Festive Skin Case", name = "Dev-in-the-Box"},
    ["Jingle Grenade"] = {folder = "Festive Skin Case", name = "Jingle Grenade"},
    ["Reindeer Slingshot"] = {folder = "Festive Skin Case", name = "Reindeer Slingshot"},
    ["Snow Shovel"] = {folder = "Festive Skin Case", name = "Snow Shovel"},
    ["Festive Buzzsaw"] = {folder = "Festive Skin Case", name = "Festive Buzzsaw"},
    ["Wrapped Minigun"] = {folder = "Festive Skin Case", name = "Wrapped Minigun"},
    ["New Year Katana"] = {folder = "Festive Skin Case", name = "New Year Katana"},
    ["Hot Coals"] = {folder = "Festive Skin Case", name = "Hot Coals"},
    ["Snowblower"] = {folder = "Festive Skin Case", name = "Snowblower"},
    ["New Year Energy Pistols"] = {folder = "Festive Skin Case", name = "New Year Energy Pistols"},
    ["Cryo Scythe"] = {folder = "Festive Skin Case", name = "Cryo Scythe"},
    ["Gingerbread Handgun"] = {folder = "Festive Skin Case", name = "Gingerbread Handgun"},
    ["Pine Uzi"] = {folder = "Festive Skin Case", name = "Pine Uzi"},
    ["Shining Star"] = {folder = "Festive Skin Case", name = "Shining Star"},
    ["New Year Energy Rifle"] = {folder = "Festive Skin Case", name = "New Year Energy Rifle"},
    ["Milk & Cookies"] = {folder = "Festive Skin Case", name = "Milk & Cookies"},
    ["Wrapped Shotgun"] = {folder = "Festive Skin Case", name = "Wrapped Shotgun"},
    ["Snowball Gun"] = {folder = "Festive Skin Case", name = "Snowball Gun"},
    ["Gingerbread Sniper"] = {folder = "Festive Skin Case", name = "Gingerbread Sniper"},
    ["Cookies"] = {folder = "Festive Skin Case", name = "Cookies"},
    ["Snowman Permafrost"] = {folder = "Festive Skin Case", name = "Snowman Permafrost"},
    ["Elf's Gunblade"] = {folder = "Festive Skin Case", name = "Elf's Gunblade"},
    ["Sled"] = {folder = "Festive Skin Case", name = "Sled"},
    ["Snowglobe"] = {folder = "Festive Skin Case", name = "Snowglobe"},
    ["Jolly Man"] = {folder = "Festive Skin Case", name = "Jolly Man"},
    ["Sleighstortion"] = {folder = "Festive Skin Case", name = "Sleighstortion"},
    ["Frost Warper"] = {folder = "Festive Skin Case", name = "Frost Warper"},
    ["Warpstar"] = {folder = "Festive Skin Case", name = "Warpstar"},
    ["Sleigh Maul"] = {folder = "Festive Skin Case", name = "Sleigh Maul"},
    ["Peppermint Sheriff"] = {folder = "Festive Skin Case", name = "Peppermint Sheriff"}
}

-- Bundle and special case aliases
EXACT_SKIN_MAP["AKEY-47"] = {folder = "Bundles", name = "Assault Rifle"}
EXACT_SKIN_MAP["Key Bow"] = {folder = "Bundles", name = "Bow"}
EXACT_SKIN_MAP["Key Spray"] = {folder = "Bundles", name = "Spray"}
EXACT_SKIN_MAP["Keylisong"] = {folder = "Bundles", name = "Knife"}
EXACT_SKIN_MAP["Keynade"] = {folder = "Bundles", name = "Grenade"}
EXACT_SKIN_MAP["Keynais"] = {folder = "Bundles", name = "Daggers"}
EXACT_SKIN_MAP["Keyper"] = {folder = "Bundles", name = "Sniper"}
EXACT_SKIN_MAP["Keyst Rifle"] = {folder = "Bundles", name = "Burst Rifle"}
EXACT_SKIN_MAP["Keythe"] = {folder = "Bundles", name = "Scythe"}
EXACT_SKIN_MAP["Keythrower"] = {folder = "Bundles", name = "Flamethrower"}
EXACT_SKIN_MAP["Keyttle Axe"] = {folder = "Bundles", name = "Battle Axe"}
EXACT_SKIN_MAP["RPKEY"] = {folder = "Bundles", name = "RPG"}
EXACT_SKIN_MAP["Keyshot"] = {folder = "Bundles", name = "Slingshot"}
EXACT_SKIN_MAP["Keyblade"] = {folder = "Bundles", name = "Gunblade"}
EXACT_SKIN_MAP["Pot o' Keys"] = {folder = "Bundles", name = "Subspace Tripmine"}
EXACT_SKIN_MAP["Arch Crossbow"] = {folder = "Seasons", name = "Crossbow"}
EXACT_SKIN_MAP["Arch Katana"] = {folder = "Seasons", name = "Katana"}
EXACT_SKIN_MAP["Arch Uzi"] = {folder = "Seasons", name = "Uzi"}
EXACT_SKIN_MAP["Handsaws"] = {folder = "Skin Case 2", name = "Chainsaw"}
EXACT_SKIN_MAP["Void Pistols"] = {folder = "Skin Case 2", name = "Energy Pistols"}
EXACT_SKIN_MAP["Void Rifle"] = {folder = "Skin Case 3", name = "Energy Rifle"}
EXACT_SKIN_MAP["Singularity"] = {folder = "Skin Case", name = "Exogun"}
EXACT_SKIN_MAP["Temporal Ray"] = {folder = "Skin Case", name = "Freeze Ray"}
EXACT_SKIN_MAP["Boneclaw Revolver"] = {folder = "Spooky Skin Case", name = "Revolver"}
EXACT_SKIN_MAP["Boneclaw Horn"] = {folder = "Spooky Skin Case", name = "War Horn"}
EXACT_SKIN_MAP["Brain Gun"] = {folder = "Spooky Skin Case", name = "Paintball Gun"}
EXACT_SKIN_MAP["Warpeye"] = {folder = "Spooky Skin Case", name = "Warpstone"}
EXACT_SKIN_MAP["Masterpiece"] = {folder = "Skin Case 3", name = "Riot Shield"}
EXACT_SKIN_MAP["Paintbrush"] = {folder = "Skin Case 3", name = "Trowel"}
EXACT_SKIN_MAP["Laptop"] = {folder = "Skin Case 2", name = "Medkit"}
EXACT_SKIN_MAP["Shady Chicken Sandwich"] = {folder = "Skin Case 3", name = "Jump Pad"}
EXACT_SKIN_MAP["Camera"] = {folder = "Skin Case 2", name = "Flashbang"}
EXACT_SKIN_MAP["Fist"] = {folder = "Other", name = "Fist"}
EXACT_SKIN_MAP["Squid Flare"] = {folder = "Skin Case 3", name = "Banana Flare"}
EXACT_SKIN_MAP["Uranium Launcher"] = {folder = "Skin Case 2", name = "Grenade Launcher"}
EXACT_SKIN_MAP["Harpoon"] = {folder = "Summer Skin Case", name = "Broken Surfboard"}

-- Memory restore registration
local memoryRestores = {}

local function registerRestore(defSlot, origDefInst, origDefRef, defAddr, origDefNC, skinSlot, origSkinInst, origSkinRef, skinAddr, origSkinNC)
    table.insert(memoryRestores, {
        defSlot = defSlot,
        origDefInst = origDefInst,
        origDefRef = origDefRef,
        defAddr = defAddr,
        origDefNC = origDefNC,
        skinSlot = skinSlot,
        origSkinInst = origSkinInst,
        origSkinRef = origSkinRef,
        skinAddr = skinAddr,
        origSkinNC = origSkinNC
    })
end

-- Revert pointers on place change or game exit to prevent engine crashes
local function restoreAllMemory()
    for _, r in ipairs(memoryRestores) do
        if r.defSlot and r.origDefInst then
            pcall(mwr, "uintptr_t", r.defSlot, r.origDefInst)
            if r.origDefRef then pcall(mwr, "uintptr_t", r.defSlot + 8, r.origDefRef) end
        end
        if r.skinSlot and r.origSkinInst then
            pcall(mwr, "uintptr_t", r.skinSlot, r.origSkinInst)
            if r.origSkinRef then pcall(mwr, "uintptr_t", r.skinSlot + 8, r.origSkinRef) end
        end
        if r.defAddr and r.origDefNC then pcall(mwr, "uintptr_t", r.defAddr + OFF.NameContainer, r.origDefNC) end
        if r.skinAddr and r.origSkinNC then pcall(mwr, "uintptr_t", r.skinAddr + OFF.NameContainer, r.origSkinNC) end
    end
    memoryRestores = {}
end

-- Find skin model across asset folders
local function findSkinModel(skinTarget)
    if EXACT_SKIN_MAP[skinTarget] then
        local f = vm:FindFirstChild(EXACT_SKIN_MAP[skinTarget].folder)
        local m = f and f:FindFirstChild(EXACT_SKIN_MAP[skinTarget].name)
        if m then return m end
    end
    for _, folder in ipairs(vm:GetChildren()) do
        if folder:IsA("Folder") and folder.Name ~= "Weapons" then
            local m = folder:FindFirstChild(skinTarget)
            if m then return m end
        end
    end
    return nil
end

-- Specialized Crossbow arrow rig to satisfy both _Setup and ViewModel logic
local function fixArrowRig(skinModel)
    local arrow = skinModel:FindFirstChild("Arrow")
    if not arrow then return end
    local children = arrow:GetChildren()
    if #children >= 1 and children[1].Address then
        local nc1 = rd(children[1].Address + OFF.NameContainer)
        if nc1 then pcall(mwr, "string", nc1 + 8, "Primary\0") end
    end
    if #children >= 2 and children[2].Address then
        local nc2 = rd(children[2].Address + OFF.NameContainer)
        if nc2 then pcall(mwr, "string", nc2 + 8, "MeshPart\0") end
    end
end

-- Specialized Daggers rig for dual blade animations
local function fixDaggersRig(skinModel)
    for _, bodyName in ipairs({"LeftBody", "RightBody"}) do
        local body = skinModel:FindFirstChild(bodyName)
        if body then
            local meshCount = 0
            for _, c in ipairs(body:GetChildren()) do
                if (c:IsA("MeshPart") or c:IsA("BasePart")) and c.Name ~= "_charm_attachment_model" then
                    meshCount = meshCount + 1
                    local nc = rd(c.Address + OFF.NameContainer)
                    if nc then
                        pcall(mwr, "string", nc + 8, "MeshPart" .. meshCount .. "\0")
                    end
                end
            end
        end
    end
end

-- Universal component rigger and primary part validator
local function rigSkinModel(m)
    if not m then return end
    
    -- Ensure all submodels have a Primary part so ClientViewModel._Setup does not crash
    for _, sub in ipairs(m:GetChildren()) do
        if sub:IsA("Model") and not sub:FindFirstChild("Primary") then
            local firstPart = sub:FindFirstChildWhichIsA("BasePart")
            if firstPart and firstPart.Address then
                local nc = rd(firstPart.Address + OFF.NameContainer)
                if nc then pcall(mwr, "string", nc + 8, "Primary\0") end
            end
        end
    end
    
    -- Ensure top-level PrimaryPart is set for Locker and Scene camera
    if m:FindFirstChild("Body") and m.Body:FindFirstChild("Primary") then
        pcall(function() m.PrimaryPart = m.Body.Primary end)
    elseif not m.PrimaryPart then
        pcall(function() m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart", true) end)
    end
    
    -- Hide extraneous decorative parts, limbs, inspect props, and floating items
    for _, c in ipairs(m:GetChildren()) do
        local n = c.Name:lower()
        if n:find("leg") or n:find("shell") or n:find("%.r") or n:find("%.l") or n == "_fake"
           or n:find("arm") or n:find("sleeve") or n:find("juggle")
           or n:find("watermelon") or n:find("banana") or n:find("apple")
           or n:find("fruit") then
            for _, desc in ipairs(c:GetDescendants()) do
                if desc.Address then
                    pcall(mwr, "float", desc.Address + OFF.Transparency, 1.0)
                end
            end
            if c:IsA("BasePart") and c.Address then
                pcall(mwr, "float", c.Address + OFF.Transparency, 1.0)
            end
        end
    end
end

-- ViewModel logic module families mapping
local VM_MODULE_FAMILIES = {
    ["Crossbow"] = "BaseCrossbow",
    ["RPG"] = "BaseRPG",
    ["Bow"] = "BaseBow",
    ["Satchel"] = "BaseSatchel",
    ["Chainsaw"] = "BaseChainsaw",
    ["Daggers"] = "BaseDaggers",
    ["Slingshot"] = "BaseSlingshot"
}

-- Swap specialized ViewModel ModuleScripts to prevent infinite WaitForChild yields
local function swapViewModelModule(baseFolderName, defaultModName, skinModName)
    local vmMods = LP.PlayerScripts.Modules:FindFirstChild("ViewModels")
    if not vmMods then return end
    local baseFolder = vmMods:FindFirstChild(baseFolderName)
    if not baseFolder then return end
    
    local defaultMod = baseFolder:FindFirstChild(defaultModName)
    local skinMod = baseFolder:FindFirstChild(skinModName)
    if not defaultMod or not skinMod or not defaultMod.Address or not skinMod.Address then return end
    
    local n = rd(baseFolder.Address + OFF.Children)
    if not n or n == 0 then return end
    local b, e = rd(n), rd(n + 8)
    if not b or not e then return end
    
    for slot = b, e - 16, 16 do
        if rd(slot) == defaultMod.Address then
            local origSlot = rd(slot)
            local origSkinNC = rd(skinMod.Address + OFF.NameContainer)
            local defNC = rd(defaultMod.Address + OFF.NameContainer)
            
            registerRestore(slot, origSlot, skinMod.Address, origSkinNC)
            
            wr(skinMod.Address + OFF.NameContainer, defNC)
            wr(slot, skinMod.Address)
            break
        end
    end
end
task.spawn(function()
    local pfx = function(n) return n:lower():gsub("[%s%-'%.]+", "") end
    local AL = nil
    for i = 1, 15 do
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            AL = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("AnimationLibrary")
        end)
        if AL then break end
        task.wait(0.5)
    end
    if not AL then return end
    local SC = AL:FindFirstChild("SoundCallbacks")
    if not SC then return end
    
    local abn = {}
    for _, c in ipairs(SC:GetChildren()) do abn[c.Name] = c end
    
    local configFileName = "rivals_config.lua"
    if not isfile or not readfile or not isfile(configFileName) then return end
    local r2 = readfile(configFileName)
    
    for l in r2:gmatch("[^\r\n]+") do
        local q = l:find("=")
        if q then
            local w = l:sub(1, q - 1):match("^%s*(.-)%s*$")
            local s = l:sub(q + 1):match("^%s*(.-)%s*$")
            local wp, sp = pfx(w), pfx(s)
            local spfx = wp .. "_" .. sp .. "_"
            for name, inst in pairs(abn) do
                if name:sub(1, #spfx) == spfx then
                    local di = abn[wp .. "_" .. name:sub(#spfx + 1)]
                    if di and inst.Address and di.Address then
                        local a = rd(di.Address + 0x8)
                        local b = rd(inst.Address + 0x8)
                        if a and b and a ~= b then
                            pcall(mwr, "uintptr_t", di.Address + 0x8, b)
                            pcall(mwr, "uintptr_t", inst.Address + 0x8, a)
                        end
                    end
                end
            end
        end
    end
end)

-- Main skin swapper execution
local function applySkinSwapper()
    local configFileName = "rivals_config.lua"
    if not isfile or not readfile or not isfile(configFileName) then return end
    
    local r2 = readfile(configFileName)
    local swappedCount = 0

    for l in r2:gmatch("[^\r\n]+") do 
        local q = l:find("=")
        if q then 
            local weaponName = l:sub(1, q - 1):match("^%s*(.-)%s*$")
            local skinTarget = l:sub(q + 1):match("^%s*(.-)%s*$")
            
            local defModel = wf:FindFirstChild(weaponName)
            local skinModel = findSkinModel(skinTarget)
            
            if defModel and skinModel and defModel.Address and skinModel.Address then
                local defSlot = findSlotAddressForWeapon(defModel, wf)
                local skinSlot = findSlotAddressForWeapon(skinModel, skinModel.Parent)
                
                if defSlot then
                    rigSkinModel(skinModel)
                    if weaponName == "Crossbow" or skinTarget:find("Crossbow") or skinTarget:find("Bow") then
                        pcall(fixArrowRig, skinModel)
                    elseif weaponName == "Daggers" or skinTarget:find("Daggers") or skinTarget:find("Kunai") then
                        pcall(fixDaggersRig, skinModel)
                    end
                    
                    local origDefInst = rd(defSlot)
                    local origDefRef = rd(defSlot + 8)
                    local origSkinInst = skinSlot and rd(skinSlot) or nil
                    local origSkinRef = skinSlot and rd(skinSlot + 8) or nil
                    local origDefNC = rd(defModel.Address + OFF.NameContainer)
                    local origSkinNC = rd(skinModel.Address + OFF.NameContainer)
                    
                    registerRestore(defSlot, origDefInst, origDefRef, defModel.Address, origDefNC, skinSlot, origSkinInst, origSkinRef, skinModel.Address, origSkinNC)
                    
                    -- Two-Way pointer swap with full std::shared_ptr control blocks
                    wr(defSlot, skinModel.Address)
                    if origSkinRef then wr(defSlot + 8, origSkinRef) end
                    
                    if skinSlot and origDefInst then
                        wr(skinSlot, origDefInst)
                        if origDefRef then wr(skinSlot + 8, origDefRef) end
                    end
                    
                    -- Two-Way name swap (skinModel named as weapon, defModel named as skin)
                    wr(skinModel.Address + OFF.NameContainer, origDefNC)
                    if skinSlot then
                        wr(defModel.Address + OFF.NameContainer, origSkinNC)
                    end
                    
                    if VM_MODULE_FAMILIES[weaponName] then
                        pcall(swapViewModelModule, VM_MODULE_FAMILIES[weaponName], weaponName, skinTarget)
                    end
                    
                    swappedCount = swappedCount + 1
                end
            end
        end 
    end
end

-- Run swapper and display notification
applySkinSwapper()
pcall(notify, "Rivals Skin Changer Active", "SC", 4)

-- Clean up memory on place teardown, game exit, or disconnect
if LP then
    pcall(function()
        LP.AncestryChanged:Connect(function()
            restoreAllMemory()
        end)
    end)
end

if wf then
    pcall(function()
        wf.AncestryChanged:Connect(function()
            restoreAllMemory()
        end)
    end)
end

local TS = game:GetService("TeleportService")
if TS then
    pcall(function()
        TS.TeleportInit:Connect(function()
            restoreAllMemory()
        end)
        if TS.TeleportProcessing then
            TS.TeleportProcessing:Connect(function()
                restoreAllMemory()
            end)
        end
    end)
end

pcall(function()
    game:BindToClose(function()
        restoreAllMemory()
    end)
end)
