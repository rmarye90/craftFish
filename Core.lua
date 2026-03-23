CraftFish = {}
CraftFish.Version = "1.0.0"
CraftFish.UI = {}
CraftFish.Data = {}

CraftFish.Data.FakeAchievements = {
    {
        name = "Faiseur de Oh Waouh !",
        description = "Avoir construit plus de 1 000 escaliers en colimacon.",
        reward = "Titre : Maitre escalier",
        points = 0,
        icon = "Interface\\Icons\\INV_Misc_Fish_04",
    },
}

CraftFish.Data.FosCategoryId = nil
CraftFish.Data.IsRevealed = false

local function onPlayerLogin()
    if type(CraftFish.UI.InitializeFakePanel) == "function" then
        CraftFish.UI.InitializeFakePanel()
    end

    C_Timer.After(5, function()
        if not CraftFish.Data.IsRevealed and type(CraftFish.UI.ShowToast) == "function" then
            CraftFish.UI.ShowToast(CraftFish.Data.FakeAchievements[1])
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "craftFish" then
        print("craftFish: charge (v" .. CraftFish.Version .. ")")
    elseif event == "PLAYER_LOGIN" then
        onPlayerLogin()
    end
end)
