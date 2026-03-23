local skinnedRow
local categoryTicker
local isDebugEnabled = false
local fosCategoryNameFromGlobal = _G.ACHIEVEMENT_CATEGORY_FEATS_OF_STRENGTH
local fosCategoryNames = {
    ["Tour de force"] = true,
    ["Tours de force"] = true,
    ["Feats of Strength"] = true,
}
if type(fosCategoryNameFromGlobal) == "string" and fosCategoryNameFromGlobal ~= "" then
    fosCategoryNames[fosCategoryNameFromGlobal] = true
end

local function debugPrint(message)
    if isDebugEnabled then
        print("craftFish debug: " .. tostring(message))
    end
end

local function getAchievementCategoryList()
    if C_AchievementInfo and type(C_AchievementInfo.GetCategoryList) == "function" then
        local categoryIds = C_AchievementInfo.GetCategoryList()
        if type(categoryIds) == "table" then
            return categoryIds
        end
    end

    if type(GetCategoryList) == "function" then
        local categoryIds = GetCategoryList()
        if type(categoryIds) == "table" then
            return categoryIds
        end
    end

    return nil
end

local function getAchievementCategoryName(categoryId)
    if not categoryId then
        return nil
    end

    if C_AchievementInfo and type(C_AchievementInfo.GetCategoryInfo) == "function" then
        local info = C_AchievementInfo.GetCategoryInfo(categoryId)
        if type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            return info.name
        end
    end

    if type(GetCategoryInfo) == "function" then
        local categoryName = GetCategoryInfo(categoryId)
        if type(categoryName) == "string" and categoryName ~= "" then
            return categoryName
        end
    end

    return nil
end

local function normalizeCategoryName(value)
    if type(value) ~= "string" then
        return nil
    end

    local normalized = string.lower((value:gsub("^%s+", ""):gsub("%s+$", "")))
    if normalized == "" then
        return nil
    end

    return normalized
end

local function isLikelyFosCategoryName(categoryName)
    if not categoryName then
        return false
    end

    if fosCategoryNames[categoryName] then
        return true
    end

    local normalized = normalizeCategoryName(categoryName)
    if not normalized then
        return false
    end

    if normalized:find("feats of strength", 1, true) then
        return true
    end

    if normalized:find("tour de force", 1, true) or normalized:find("tours de force", 1, true) then
        return true
    end

    return false
end

local function detectFosCategoryId()
    local categoryIds = getAchievementCategoryList()
    if not categoryIds then
        debugPrint("Impossible de recuperer la liste des categories.")
        return
    end

    for _, categoryId in ipairs(categoryIds) do
        local categoryName = getAchievementCategoryName(categoryId)
        if isLikelyFosCategoryName(categoryName) then
            CraftFish.Data.FosCategoryId = categoryId
            debugPrint("Categorie Tour de force detectee avec id " .. tostring(categoryId))
            return
        end
    end

    debugPrint("Aucune categorie Tour de force detectee.")
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

local function getCategoryName(categoryId)
    return getAchievementCategoryName(categoryId)
end

local function isFosCategorySelected()
    local currentCategoryId = getCurrentCategoryId()

    if not currentCategoryId then
        if CraftFish.Data.FosCategoryId then
            debugPrint("Categorie courante introuvable, fallback d'affichage actif.")
            return true
        end
        return false
    end

    if CraftFish.Data.FosCategoryId and currentCategoryId == CraftFish.Data.FosCategoryId then
        return true
    end

    local categoryName = getCategoryName(currentCategoryId)
    if isLikelyFosCategoryName(categoryName) then
        return true
    end

    return false
end

local function getFirstExistingMember(frame, names)
    if not frame then
        return nil
    end

    for _, name in ipairs(names) do
        local member = frame[name]
        if member then
            return member
        end
    end

    return nil
end

local function getVisibleChildren(frame)
    if not frame or type(frame.GetChildren) ~= "function" then
        return {}
    end

    local children = { frame:GetChildren() }
    local visibleChildren = {}
    for _, child in ipairs(children) do
        if child and child.IsShown and child:IsShown() then
            visibleChildren[#visibleChildren + 1] = child
        end
    end

    return visibleChildren
end

local function collectVisibleDescendants(frame, out, seen, depth, maxDepth)
    if not frame or seen[frame] then
        return
    end

    seen[frame] = true
    out[#out + 1] = frame

    if depth >= maxDepth then
        return
    end

    for _, child in ipairs(getVisibleChildren(frame)) do
        collectVisibleDescendants(child, out, seen, depth + 1, maxDepth)
    end
end

local function getRegions(frame)
    if not frame or type(frame.GetRegions) ~= "function" then
        return {}
    end
    return { frame:GetRegions() }
end

local function getFallbackRowRegions(row)
    local icon
    local fontStrings = {}

    for _, region in ipairs(getRegions(row)) do
        if region and region.GetObjectType then
            local objectType = region:GetObjectType()
            if objectType == "Texture" and not icon and region.GetSize then
                local width, height = region:GetSize()
                if width and height and width >= 24 and width <= 80 and height >= 24 and height <= 80 then
                    icon = region
                end
            elseif objectType == "FontString" and region.GetText then
                local text = region:GetText()
                if text and text ~= "" then
                    fontStrings[#fontStrings + 1] = region
                end
            end
        end
    end

    table.sort(fontStrings, function(a, b)
        local aTop = (a.GetTop and a:GetTop()) or 0
        local bTop = (b.GetTop and b:GetTop()) or 0
        return aTop > bTop
    end)

    local title = fontStrings[1]
    local description = fontStrings[2]
    local reward = fontStrings[3]
    return icon, title, description, reward
end

local function resolveIconTexture(iconElement)
    if not iconElement then
        return nil
    end

    if type(iconElement.SetTexture) == "function" then
        return iconElement
    end

    for _, name in ipairs({ "texture", "Texture", "Icon", "icon" }) do
        local sub = iconElement[name]
        if sub and type(sub.SetTexture) == "function" then
            return sub
        end
    end

    if type(iconElement.GetNormalTexture) == "function" then
        local normalTex = iconElement:GetNormalTexture()
        if normalTex and type(normalTex.SetTexture) == "function" then
            return normalTex
        end
    end

    if type(iconElement.GetRegions) == "function" then
        for _, region in ipairs({ iconElement:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "Texture" and type(region.SetTexture) == "function" then
                return region
            end
        end
    end

    return nil
end

local function getRowRegions(row)
    local iconRaw = getFirstExistingMember(row, { "icon", "Icon", "IconTexture" })
    local icon = resolveIconTexture(iconRaw)
    local title = getFirstExistingMember(row, { "name", "Name", "Label", "title", "Title", "AchievementName" })
    local description = getFirstExistingMember(row, { "description", "Description", "Text", "Summary" })
    local reward = getFirstExistingMember(row, { "reward", "Reward", "DateCompleted", "Status" })

    if not title then
        local fallbackIcon, fallbackTitle, fallbackDescription, fallbackReward = getFallbackRowRegions(row)
        icon = icon or resolveIconTexture(fallbackIcon) or fallbackIcon
        title = title or fallbackTitle
        description = description or fallbackDescription
        reward = reward or fallbackReward
    end

    return icon, title, description, reward
end

local function restoreSkinnedRow()
    if not skinnedRow or not skinnedRow._craftFishOriginal then
        skinnedRow = nil
        return
    end

    local original = skinnedRow._craftFishOriginal
    local icon, title, description, reward = getRowRegions(skinnedRow)

    if icon and original.iconTexture and type(icon.SetTexture) == "function" then
        icon:SetTexture(original.iconTexture)
    end

    if title and original.titleText then
        title:SetText(original.titleText)
    end

    if description and original.descriptionText then
        description:SetText(original.descriptionText)
    end

    if reward and original.rewardText then
        reward:SetText(original.rewardText)
    end
    if reward and original.rewardWasShown == false and reward.Hide then
        reward:Hide()
    end

    skinnedRow._craftFishSkinned = nil
    skinnedRow = nil
end

local function skinRow(row, fakeAchievement)
    if not row or not fakeAchievement then
        return
    end

    local icon, title, description, reward = getRowRegions(row)
    if not title then
        debugPrint("Row candidate sans titre exploitable: " .. tostring(row:GetName() or "<anonymous>"))
        return
    end

    if not row._craftFishOriginal then
        row._craftFishOriginal = {
            iconTexture = icon and icon.GetTexture and icon:GetTexture() or nil,
            titleText = title.GetText and title:GetText() or nil,
            descriptionText = description and description.GetText and description:GetText() or nil,
            rewardText = reward and reward.GetText and reward:GetText() or nil,
            rewardWasShown = reward and reward.IsShown and reward:IsShown() or nil,
        }
    end

    if icon and type(icon.SetTexture) == "function" then
        icon:SetTexture(fakeAchievement.icon or "Interface\\Icons\\INV_Misc_Fish_04")
    end

    if type(title.SetText) ~= "function" then
        return
    end

    local fakeDescription = fakeAchievement.description or ""
    local fakeReward = fakeAchievement.reward or ""

    title:SetText(fakeAchievement.name or "")
    if description and type(description.SetText) == "function" then
        description:SetText(fakeDescription)
    end
    if reward and type(reward.SetText) == "function" then
        reward:SetText(fakeReward)
        if reward.Show and not reward:IsShown() then
            reward:Show()
        end
    end

    row._craftFishSkinned = true
    skinnedRow = row
end

local function addRowsFromTable(rows, sourceTable, seen)
    if type(sourceTable) ~= "table" then
        return
    end

    for _, row in ipairs(sourceTable) do
        if row and row.IsShown and row:IsShown() and not seen[row] then
            rows[#rows + 1] = row
            seen[row] = true
        end
    end
end

local function tryAddCandidateRow(rows, frame, seen)
    if not frame or seen[frame] or not frame.IsShown or not frame:IsShown() then
        return
    end

    if type(frame.GetObjectType) == "function" then
        local objectType = frame:GetObjectType()
        if objectType ~= "Frame" and objectType ~= "Button" then
            return
        end
    end

    local width = frame.GetWidth and frame:GetWidth() or 0
    local height = frame.GetHeight and frame:GetHeight() or 0
    if width < 250 or height < 20 then
        return
    end

    if height > 110 then
        return
    end

    local frameLeft = frame.GetLeft and frame:GetLeft() or nil
    local frameTop = frame.GetTop and frame:GetTop() or nil
    local achievementPanel = AchievementFrameAchievementsContainer or AchievementFrameAchievements
    local panelLeft = achievementPanel and achievementPanel.GetLeft and achievementPanel:GetLeft() or nil
    local panelTop = achievementPanel and achievementPanel.GetTop and achievementPanel:GetTop() or nil
    local panelRight = achievementPanel and achievementPanel.GetRight and achievementPanel:GetRight() or nil
    local panelBottom = achievementPanel and achievementPanel.GetBottom and achievementPanel:GetBottom() or nil
    if frameLeft and frameTop and panelLeft and panelTop and panelRight and panelBottom then
        local frameRight = frame.GetRight and frame:GetRight() or frameLeft
        local frameBottom = frame.GetBottom and frame:GetBottom() or frameTop
        local overlapsPanel = frameRight >= panelLeft and frameLeft <= panelRight and frameTop >= panelBottom and frameBottom <= panelTop
        if not overlapsPanel then
            return
        end
    end

    local icon, title, description = getRowRegions(frame)
    if not title then
        return
    end

    if not icon then
        return
    end

    local hasDescriptionText = description and description.GetText and description:GetText()
    if not hasDescriptionText or hasDescriptionText == "" then
        return
    end

    rows[#rows + 1] = frame
    seen[frame] = true
end

local function collectVisibleAchievementRows()
    local rows = {}
    local seen = {}

    if AchievementFrameAchievementsContainer and AchievementFrameAchievementsContainer.buttons then
        addRowsFromTable(rows, AchievementFrameAchievementsContainer.buttons, seen)
    end

    local scrollBox = AchievementFrameAchievementsContainer and AchievementFrameAchievementsContainer.ScrollBox
    if scrollBox and type(scrollBox.GetFrames) == "function" then
        addRowsFromTable(rows, scrollBox:GetFrames(), seen)
    end

    if scrollBox and scrollBox.ScrollTarget and type(scrollBox.ScrollTarget.GetChildren) == "function" then
        addRowsFromTable(rows, { scrollBox.ScrollTarget:GetChildren() }, seen)
    end

    local container = AchievementFrameAchievementsContainer or AchievementFrameAchievements
    if container then
        for _, child in ipairs(getVisibleChildren(container)) do
            tryAddCandidateRow(rows, child, seen)
            for _, nestedChild in ipairs(getVisibleChildren(child)) do
                tryAddCandidateRow(rows, nestedChild, seen)
            end
        end
    end

    if #rows == 0 and AchievementFrame then
        local descendants = {}
        local descendantsSeen = {}
        collectVisibleDescendants(AchievementFrame, descendants, descendantsSeen, 0, 6)
        for _, frame in ipairs(descendants) do
            tryAddCandidateRow(rows, frame, seen)
        end
    end

    table.sort(rows, function(a, b)
        local aTop = (a.GetTop and a:GetTop()) or 0
        local bTop = (b.GetTop and b:GetTop()) or 0
        return aTop > bTop
    end)

    return rows
end

local function updateRowSkinVisibility()
    if CraftFish.Data.IsRevealed then
        restoreSkinnedRow()
        return
    end

    if not AchievementFrame or not AchievementFrame:IsShown() then
        restoreSkinnedRow()
        return
    end

    if not CraftFish.Data.FosCategoryId then
        detectFosCategoryId()
    end

    if not isFosCategorySelected() then
        restoreSkinnedRow()
        return
    end

    local rows = collectVisibleAchievementRows()
    if #rows == 0 then
        debugPrint("Aucune row visible detectee dans la liste.")
        restoreSkinnedRow()
        return
    end

    debugPrint("Rows candidates detectees: " .. tostring(#rows))

    local targetRow = rows[1]
    debugPrint("Row cible: " .. tostring(targetRow and (targetRow:GetName() or "<anonymous>") or "<nil>"))

    if skinnedRow and skinnedRow ~= targetRow then
        restoreSkinnedRow()
    end

    if targetRow and not targetRow._craftFishSkinned then
        skinRow(targetRow, CraftFish.Data.FakeAchievements[1])
    elseif targetRow and targetRow._craftFishSkinned then
        local _, targetTitle = getRowRegions(targetRow)
        local visibleTitle = targetTitle and targetTitle.GetText and targetTitle:GetText() or ""
        local expectedTitle = CraftFish.Data.FakeAchievements[1] and CraftFish.Data.FakeAchievements[1].name or ""
        if visibleTitle ~= expectedTitle then
            debugPrint("Row marquee skinee mais texte different, re-skin force.")
            targetRow._craftFishSkinned = nil
        end
    end
end

function CraftFish.UI.HideFakePanel()
    restoreSkinnedRow()
end

function CraftFish.UI.OnAchievementFrameShow()
    updateRowSkinVisibility()

    if categoryTicker then
        categoryTicker:Cancel()
        categoryTicker = nil
    end

    categoryTicker = C_Timer.NewTicker(0.2, updateRowSkinVisibility)
end

function CraftFish.UI.SetDebugEnabled(enabled)
    isDebugEnabled = enabled == true
    print("craftFish: debug " .. (isDebugEnabled and "active" or "desactive") .. ".")
end

local function onAchievementFrameHide()
    if categoryTicker then
        categoryTicker:Cancel()
        categoryTicker = nil
    end

    restoreSkinnedRow()
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
