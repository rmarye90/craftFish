SLASH_CRAFTFISH1 = "/craftfish"

SlashCmdList.CRAFTFISH = function(message)
    local command = string.lower((message or ""):match("^%s*(.-)%s*$"))

    if command == "" then
        print("craftFish: /craftfish reveal pour reveler la blague.")
        return
    end

    if command == "reveal" then
        CraftFish.Data.IsRevealed = true

        if type(CraftFish.UI.HideFakePanel) == "function" then
            CraftFish.UI.HideFakePanel()
        end

        print("craftFish: Poisson d'avril revele. Ces Hauts Faits sont faux.")
        return
    end

    print("craftFish: commande inconnue. Utilise /craftfish ou /craftfish reveal.")
end
