-- AutoTrain_96274223071227.lua
-- Modul Auto Train berdiri sendiri, dipanggil dari Loader

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local Workspace  = game:GetService("Workspace")
local LocalPlayer= Players.LocalPlayer

-- Gunakan referensi buffer global (JANGAN dipanggil, tidak pakai "()")
local bufferLib = buffer

local AutoTrain = {
    Enabled = false,
    Thread  = nil,
}

-- Cari RemoteEvent di ReplicatedStorage dari path table
local function findRemote(path)
    local current = RS
    for _, name in ipairs(path) do
        current = current and current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

-- Ambil folder world Training
local function getTrainingWorldFolder(worldName)
    local training = Workspace:FindFirstChild("Training")
    if not training then return nil end
    local models = training:FindFirstChild("Models")
    if not models then return nil end
    return models:FindFirstChild(worldName)
end

function AutoTrain:Stop()
    self.Enabled = false
    if self.Thread then
        pcall(task.cancel, self.Thread)
        self.Thread = nil
    end
end

function AutoTrain:Start(initialWorld)
    -- stop dulu jika ada thread lama
    self:Stop()

    self.Enabled = true
    local selectedWorld = initialWorld or "World1"

    self.Thread = task.spawn(function()
        local trainRemote = findRemote({"Modules","Network","Network","RemoteEvent"})
        if not trainRemote then
            warn("[AutoTrain] Train Remote tidak ditemukan")
            AutoTrain.Enabled = false
            return
        end

        if type(bufferLib) ~= "table" or type(bufferLib.fromstring) ~= "function" then
            warn("[AutoTrain] buffer.fromstring tidak tersedia")
            AutoTrain.Enabled = false
            return
        end

        while AutoTrain.Enabled do
            -- world bisa diganti dari script utama lewat _G.SelectedTrainWorld
            if type(_G.SelectedTrainWorld) == "string" then
                selectedWorld = _G.SelectedTrainWorld
            end

            local worldFolder = getTrainingWorldFolder(selectedWorld)
            if not worldFolder then
                warn("[AutoTrain] World tidak ditemukan: "..tostring(selectedWorld))
                task.wait(2)
                goto continue
            end

            -- Cari dummy "Train" dengan angka tertinggi
            local bestDummy, bestLevel = nil, -1

            for _, dummy in ipairs(worldFolder:GetChildren()) do
                if dummy:IsA("Model") then
                    local hrp     = dummy:FindFirstChild("HumanoidRootPart")
                    local display = hrp and hrp:FindFirstChild("Display")
                    local req     = display and display:FindFirstChild("Requirement")

                    if req and req:IsA("TextLabel") and req.Text == "Train" then
                        local level = tonumber(dummy.Name:match("%d+")) or 0
                        if level > bestLevel then
                            bestLevel = level
                            bestDummy = dummy
                        end
                    end
                end
            end

            if bestDummy then
                local name = bestDummy.Name
                local len  = #name

                -- Payload ke remote: 0, len, lalu nama dummy
                local payload = string.char(0, len) .. name

                local ok, err = pcall(function()
                    trainRemote:FireServer(bufferLib.fromstring(payload))
                end)
                if not ok then
                    warn("[AutoTrain] FireServer error:", err)
                end

                task.wait(0.1)
            else
                task.wait(1)
            end

            ::continue::
        end
    end)
end

return AutoTrain