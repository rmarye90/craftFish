local overlayFrame
local categoryTicker

local function detectFosCategoryId()
    if not GetCategoryList or not GetCategoryInfo then
        return
    end

    local categoryIds = GetCategoryList()
    if not categoryIds then
        return
    end

    for _, categoryId in ipairs(categoryIds) do
        local categoryName = GetCategoryInfo(categoryId)
        if categoryName == "Tour de force" or categoryName == "Feats of Strength" then
            CraftFish.Data.FosCategoryId = categoryId
            return
        end
    end
end

local function getCurrentCategoryId()
    if AchievementFrame and AchievementFrame.selectedCategory then
        return AchievementFrame.selectedCategory
    end

    if AchievementFrameCategoriesContainer and AchievementFrameCategoriesContainer.selectedCategory then
        return AchievementFrameCategoriesContainer.selectedCategory
    end

    return nil
end

local function createRow(parent, anchor, fakeAchievement)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(560, 64)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetTexture("Interface\\AchievementFrame\\UI-Achievement-AchievementBackground")
    background:SetTexCoord(0, 1, 0, 0.75)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("LEFT", row, "LEFT", 12, 0)
    icon:SetTexture(fakeAchievement.icon or "Interface\\Icons\\INV_Misc_Fish_04")

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, 8)
    nameText:SetTextColor(1, 0.82, 0)
    nameText:SetText(fakeAchievement.name or "")

    local descriptionText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    descriptionText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    descriptionText:SetWidth(450)
    descriptionText:SetJustifyH("LEFT")
    descriptionText:SetText(fakeAchievement.description or "")

    local rewardText = row:CreateFontString(nil, "OVERLAY", "GameFontGreenSmall")
    rewardText:SetPoint("TOPLEFT", descriptionText, "BOTTOMLEFT", 0, -2)
    rewardText:SetWidth(450)
    rewardText:SetJustifyH("LEFT")
    rewardText:SetText(fakeAchievement.reward or "")

    return row
end

local function createOverlay()
    if overlayFrame or not AchievementFrameAchievements then
        return
    end

    overlayFrame = CreateFrame("Frame", "CraftFishPanelOverlay", AchievementFrameAchievements)
    overlayFrame:SetAllPoints(AchievementFrameAchievements)
    overlayFrame:SetFrameStrata("DIALOG")
    overlayFrame:Hide()

    local header = overlayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", overlayFrame, "TOPLEFT", 28, -32)
    header:SetText("Nouveaux Hauts Faits de Tour de force")

    local anchor = CreateFrame("Frame", nil, overlayFrame)
    anchor:SetSize(1, 1)
    anchor:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -16)

    for _, fakeAchievement in ipairs(CraftFish.Data.FakeAchievements) do
        anchor = createRow(overlayFrame, anchor, fakeAchievement)
    end
end

local function updateOverlayVisibility()
    if not overlayFrame or CraftFish.Data.IsRevealed then
        if overlayFrame then
            overlayFrame:Hide()
        end
        return
    end

    if not AchievementFrame or not AchievementFrame:IsShown() then
        overlayFrame:Hide()
        return
    end

    local currentCategoryId = getCurrentCategoryId()
    if currentCategoryId and currentCategoryId == CraftFish.Data.FosCategoryId then
        overlayFrame:Show()
    else
        overlayFrame:Hide()
    end
end

function CraftFish.UI.HideFakePanel()
    if overlayFrame then
        overlayFrame:Hide()
    end
end

function CraftFish.UI.OnAchievementFrameShow()
    createOverlay()
    updateOverlayVisibility()

    if categoryTicker then
        categoryTicker:Cancel()
        categoryTicker = nil
    end

    categoryTicker = C_Timer.NewTicker(0.5, updateOverlayVisibility)
end

local function onAchievementFrameHide()
    if categoryTicker then
        categoryTicker:Cancel()
        categoryTicker = nil
    end

    if overlayFrame then
        overlayFrame:Hide()
    end
end

local function hookAchievementFrame()
    if not AchievementFrame then
        return false
    end

    AchievementFrame:HookScript("OnShow", CraftFish.UI.OnAchievementFrameShow)
    AchievementFrame:HookScript("OnHide", onAchievementFrameHide)
    return true
end

function CraftFish.UI.InitializeFakePanel()
    detectFosCategoryId()

    if hookAchievementFrame() then
        return
    end

    local loaderFrame = CreateFrame("Frame")
    loaderFrame:RegisterEvent("ADDON_LOADED")
    loaderFrame:SetScript("OnEvent", function(_, _, addonName)
        if addonName ~= "Blizzard_AchievementUI" then
            return
        end

        detectFosCategoryId()
        hookAchievementFrame()
    end)
end
