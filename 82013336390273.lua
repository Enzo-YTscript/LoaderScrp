local RayfieldLoaded = pcall(function()
    Rayfield:Notify({})
end)
if not RayfieldLoaded then
    local Rayfield
    local success, errorMsg = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if not success then
        warn("Failed to load Rayfield for notification: " .. tostring(errorMsg))
    end
end

-- Check if key validation flag is set with unique run ID
if not _G.KeyValidatedRunId or _G.KeyValidated ~= _G.KeyValidatedRunId then
    if Rayfield then
        Rayfield:Notify({ Title = "Access Denied", Content = "Script must be loaded through key validation system.", Duration = 30 })
    end
    warn("Access denied: Script must be loaded through key validation system.")
    return
end
-- ================================================================= --

-- Rayfield (Sirius)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Mendapatkan nama game secara otomatis
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

-- Services & Remotes
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Paper = RS:WaitForChild("Paper")
local Remotes = Paper:WaitForChild("Remotes")
local RemoteEvent = Remotes:WaitForChild("__remoteevent")
local RemoteFunction = Remotes:WaitForChild("__remotefunction")

-- Window
local Window = Rayfield:CreateWindow({
    Name = gameName,
    Icon = 0,
    LoadingTitle = gameName,
    LoadingSubtitle = "by ENZO-YT",
    Theme = "DarkBlue",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PickaxeSimulatorSaving",
        FileName = "PickaxeSimulatorSaving"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = false
    },
    KeySystem = false,
    KeySettings = {
        Title = gameName .. " Key System",
        Subtitle = "Enter Your Key",
        Note = "Key In Description or Join discord.gg/WFjWKwBv8p",
        FileName = "MyScriptKey",
        SaveKey = true,
        GrabKeyFromSite = true,
        Key = {"https://pastebin.com/raw/vTu6rCev"}
    }
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- Helpers
local function normalizeOption(opt)
    if type(opt) == "table" then
        -- Rayfield kadang return { "Option" } atau dictionary; ambil elemen pertama
        return opt[1] or opt.Option or opt.Name or (next(opt) and opt[next(opt)]) or tostring(opt)
    end
    return opt
end

local function parseNumberFromName(name)
    if type(name) == "number" then return name end
    name = tostring(name or "")
    local n = tonumber(name)
    if n then return n end
    local digits = name:match("(%d+)")
    return digits and tonumber(digits) or nil
end

----------------------------------------------------------------
-- Toggle: Auto Mine (server toggle)
----------------------------------------------------------------
local function ToggleAutoMineRemote()
    local args = { "Toggle Setting", "AutoMine" }
    RemoteEvent:FireServer(unpack(args))
end

MainTab:CreateToggle({
    Name = "Auto Mine (Server Toggle)",
    CurrentValue = false,
    Callback = function(state)
        local ok, err = pcall(ToggleAutoMineRemote)
        if not ok then warn("Auto Mine toggle error:", err) end
    end
})

----------------------------------------------------------------
-- Toggle: Auto Claim Time Reward (20 detik)
----------------------------------------------------------------
local autoClaim = false
MainTab:CreateToggle({
    Name = "Auto Claim Time Reward (20s)",
    CurrentValue = false,
    Callback = function(state)
        autoClaim = state
        if autoClaim then
            task.spawn(function()
                while autoClaim do
                    pcall(function()
                        RemoteFunction:InvokeServer("Claim Time Reward")
                    end)
                    for i = 1, 200 do
                        if not autoClaim then break end
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
})

----------------------------------------------------------------
-- Toggle: Auto Equip Best (5 detik)
----------------------------------------------------------------
local autoEquip = false
MainTab:CreateToggle({
    Name = "Auto Equip Best (5s)",
    CurrentValue = false,
    Callback = function(state)
        autoEquip = state
        if autoEquip then
            task.spawn(function()
                while autoEquip do
                    pcall(function()
                        RemoteFunction:InvokeServer("Pet", { Action = "EquipBest" })
                    end)
                    for i = 1, 50 do
                        if not autoEquip then break end
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
})

----------------------------------------------------------------
-- Toggle: Auto Sell All Ores (15 detik) — ditempatkan tepat di bawah Auto Equip Best
----------------------------------------------------------------
local autoSell = false
MainTab:CreateToggle({
    Name = "Auto Sell All Ores (15s)",
    CurrentValue = false,
    Callback = function(state)
        autoSell = state
        if autoSell then
            task.spawn(function()
                while autoSell do
                    pcall(function()
                        RemoteFunction:InvokeServer("Sell All Ores")
                    end)
                    for i = 1, 150 do
                        if not autoSell then break end
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
})

----------------------------------------------------------------
-- Section: Upgrade
-- Dropdown dari PlayerGui.Menus.Upgrades.Frame.Main.List (hanya Frame, exclude "Line")
-- Auto Upgrade: InvokeServer("Upgrade", <nama upgrade STRING>)
----------------------------------------------------------------
task.spawn(function()
    local plr = Players.LocalPlayer
    local PlayerGui = plr:WaitForChild("PlayerGui")

    -- Tunggu UI Upgrades ada
    local Menus = PlayerGui:WaitForChild("Menus")
    local UpgradesGui = Menus:WaitForChild("Upgrades")
    local UFrame = UpgradesGui:WaitForChild("Frame")
    local UMain = UFrame:WaitForChild("Main")
    local UList = UMain:WaitForChild("List")

    local function collectUpgradeNames()
        local names = {}
        for _, child in ipairs(UList:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "Line" then
                table.insert(names, child.Name)
            end
        end
        table.sort(names)
        return names
    end

    local upgradeNames = collectUpgradeNames()
    if #upgradeNames == 0 then
        table.insert(upgradeNames, "No Upgrades Found")
    end

    local selectedUpgrade = (#upgradeNames > 0 and upgradeNames[1] ~= "No Upgrades Found") and upgradeNames[1] or nil
    local autoUpgrade = false
    local upgradeDelay = 1 -- detik

    MainTab:CreateSection("Upgrade")

    MainTab:CreateDropdown({
        Name = "Upgrade",
        Options = upgradeNames,
        CurrentOption = selectedUpgrade or "No Upgrades Found",
        Callback = function(option)
            option = normalizeOption(option)
            if option ~= "No Upgrades Found" then
                selectedUpgrade = tostring(option)
            else
                selectedUpgrade = nil
            end
        end
    })

    MainTab:CreateToggle({
        Name = "Auto Upgrade",
        CurrentValue = false,
        Callback = function(state)
            autoUpgrade = state
            if autoUpgrade then
                task.spawn(function()
                    while autoUpgrade do
                        if selectedUpgrade then
                            -- Kirim STRING murni sebagai argumen kedua (BUKAN table)
                            pcall(function()
                                local ohString1 = "Upgrade"
                                local ohString2 = selectedUpgrade
                                RemoteFunction:InvokeServer(ohString1, ohString2)
                            end)
                        end
                        for i = 1, math.max(1, math.floor(upgradeDelay / 0.1)) do
                            if not autoUpgrade then break end
                            task.wait(0.1)
                        end
                    end
                end)
            end
        end
    })
end)

----------------------------------------------------------------
-- Section: Rebirths
-- Dropdown dari PlayerGui.Menus.Rebirth.Frame.Main.List (ambil Name setiap Frame)
-- Auto Rebirths: langsung InvokeServer("Rebirth", <angka dari dropdown>) tanpa cek Cost/Power
----------------------------------------------------------------
task.spawn(function()
    local plr = Players.LocalPlayer
    local PlayerGui = plr:WaitForChild("PlayerGui")

    -- Tunggu UI Rebirths ada
    local Menus = PlayerGui:WaitForChild("Menus")
    local RebirthGui = Menus:WaitForChild("Rebirth")
    local RFrame = RebirthGui:WaitForChild("Frame")
    local RMain = RFrame:WaitForChild("Main")
    local RList = RMain:WaitForChild("List")

    local function collectRebirthNames()
        local names = {}
        for _, child in ipairs(RList:GetChildren()) do
            if child:IsA("Frame") then
                table.insert(names, child.Name)
            end
        end
        table.sort(names, function(a,b)
            local na, nb = tonumber(a), tonumber(b)
            if na and nb then return na < nb end
            return tostring(a) < tostring(b)
        end)
        return names
    end

    local rebirthNames = collectRebirthNames()
    if #rebirthNames == 0 then
        table.insert(rebirthNames, "No Rebirths Found")
    end

    local selectedRebirth = (#rebirthNames > 0 and rebirthNames[1] ~= "No Rebirths Found") and rebirthNames[1] or nil
    local autoRebirth = false
    local rebirthDelay = 1 -- detik (interval eksekusi)

    MainTab:CreateSection("Rebirths")

    MainTab:CreateDropdown({
        Name = "Rebirths",
        Options = rebirthNames,
        CurrentOption = selectedRebirth or "No Rebirths Found",
        Callback = function(option)
            option = normalizeOption(option)
            if option ~= "No Rebirths Found" then
                selectedRebirth = tostring(option)
            else
                selectedRebirth = nil
            end
        end
    })

    MainTab:CreateToggle({
        Name = "Auto Rebirths",
        CurrentValue = false,
        Callback = function(state)
            autoRebirth = state
            if autoRebirth then
                task.spawn(function()
                    while autoRebirth do
                        if selectedRebirth then
                            local ohString1 = "Rebirth"
                            local ohNumber2 = parseNumberFromName(selectedRebirth) -- cari angka dari dropdown
                            if ohNumber2 then
                                pcall(function()
                                    RemoteFunction:InvokeServer(ohString1, ohNumber2)
                                end)
                            else
                                warn("Gagal parse angka Rebirth dari pilihan:", selectedRebirth)
                            end
                        end
                        for i = 1, math.max(1, math.floor(rebirthDelay / 0.1)) do
                            if not autoRebirth then break end
                            task.wait(0.1)
                        end
                    end
                end)
            end
        end
    })
end)