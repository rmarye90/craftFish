local toastFrame

local function buildToast()
    if toastFrame then
        return toastFrame
    end

    toastFrame = CreateFrame("Frame", "CraftFishToastFrame", UIParent)
    toastFrame:SetSize(362, 100)
    toastFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
    toastFrame:Hide()

    local background = toastFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Background")
    toastFrame.background = background

    local icon = toastFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(54, 54)
    icon:SetPoint("LEFT", toastFrame, "LEFT", 20, 0)
    toastFrame.icon = icon

    local title = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    title:SetText("Tour de force !")
    title:SetTextColor(1, 0.82, 0)
    toastFrame.title = title

    local nameText = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    nameText:SetWidth(250)
    nameText:SetJustifyH("LEFT")
    toastFrame.nameText = nameText

    local descriptionText = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    descriptionText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    descriptionText:SetWidth(250)
    descriptionText:SetJustifyH("LEFT")
    toastFrame.descriptionText = descriptionText

    local rewardText = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontGreenSmall")
    rewardText:SetPoint("TOPLEFT", descriptionText, "BOTTOMLEFT", 0, -2)
    rewardText:SetWidth(250)
    rewardText:SetJustifyH("LEFT")
    toastFrame.rewardText = rewardText

    local showGroup = toastFrame:CreateAnimationGroup()
    local showSlide = showGroup:CreateAnimation("Translation")
    showSlide:SetDuration(0.3)
    showSlide:SetOffset(220, 0)
    showSlide:SetSmoothing("OUT")
    showSlide:SetOrder(1)

    local showAlpha = showGroup:CreateAnimation("Alpha")
    showAlpha:SetDuration(0.2)
    showAlpha:SetFromAlpha(0)
    showAlpha:SetToAlpha(1)
    showAlpha:SetOrder(1)

    toastFrame.showGroup = showGroup

    local hideGroup = toastFrame:CreateAnimationGroup()
    local hideAlpha = hideGroup:CreateAnimation("Alpha")
    hideAlpha:SetDuration(0.4)
    hideAlpha:SetFromAlpha(1)
    hideAlpha:SetToAlpha(0)
    hideAlpha:SetOrder(1)

    hideGroup:SetScript("OnFinished", function()
        toastFrame:Hide()
    end)

    toastFrame.hideGroup = hideGroup
    return toastFrame
end

function CraftFish.UI.ShowToast(fakeAchievement)
    if not fakeAchievement then
        return
    end

    local frame = buildToast()
    frame.icon:SetTexture(fakeAchievement.icon or "Interface\\Icons\\INV_Misc_Fish_04")
    frame.nameText:SetText(fakeAchievement.name or "")
    frame.descriptionText:SetText(fakeAchievement.description or "")
    frame.rewardText:SetText(fakeAchievement.reward or "")

    frame:SetAlpha(0)
    frame:Show()
    frame.showGroup:Play()

    if SOUNDKIT and SOUNDKIT.UI_ACHIEVEMENT_DEFAULT_TOAST_ESTABLISHED then
        PlaySound(SOUNDKIT.UI_ACHIEVEMENT_DEFAULT_TOAST_ESTABLISHED, "Master")
    end

    C_Timer.After(4, function()
        if frame:IsShown() then
            frame.hideGroup:Play()
        end
    end)
end
