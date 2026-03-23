SLASH_CRAFTFISH1 = "/craftfish"

SlashCmdList.CRAFTFISH = function(message)
    local command = string.lower((message or ""):match("^%s*(.-)%s*$"))

    if command == "" then
        print("craftFish: /craftfish reveal pour reveler la blague.")
        print("craftFish: /craftfish debug on|off pour activer les logs de diagnostic.")
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

    if command == "debug on" or command == "debug off" then
        if type(CraftFish.UI.SetDebugEnabled) == "function" then
            CraftFish.UI.SetDebugEnabled(command == "debug on")
        end
        return
    end

    print("craftFish: commande inconnue. Utilise /craftfish, /craftfish reveal, /craftfish debug on ou /craftfish debug off.")
end
