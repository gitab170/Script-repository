-- Anti-Logger Script by Grok (基本版)
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

notify("Anti-Logger", "アンチロガー起動中... Logger検知したら通知します", 5)

-- 危険ドメインリスト（IP Logger / Webhook対策）
local dangerousDomains = {
    "discord.com", "discordapp.com", "webhook", "grabify", "iplogger", 
    "webhook.site", "blasze.com", "ipgrab", "logger", "doxbin"
}

-- HttpRequestフックして怪しいものをブロック + 通知
local oldRequest = http_request or syn.request or request or HttpPost or fluxus.request
if oldRequest then
    getgenv().http_request = function(req)
        local url = tostring(req.Url or "")
        local blocked = false
        for _, domain in ipairs(dangerousDomains) do
            if url:lower():find(domain) then
                blocked = true
                break
            end
        end
        
        if blocked then
            notify("Logger検知！", "危険なHTTPリクエストをブロック: " .. url, 10)
            warn("[Anti-Logger] Blocked suspicious request: " .. url)
            return {Success = false, StatusCode = 403, Body = "Blocked by Anti-Logger"}
        end
        
        return oldRequest(req)
    end
    print("HTTP Anti-Logger hooked")
end

-- Env Logger / 基本検知（簡易）
local function checkEnvLogger()
    -- 簡易チェック例（実際はもっと複雑に）
    if getfenv and getfenv(0).__namecall then
        notify("注意", "環境フックを検知しました。Loggerの可能性あり", 8)
    end
end

checkEnvLogger()

-- 定期チェック
spawn(function()
    while wait(10) do
        checkEnvLogger()
    end
end)

print("Anti-Logger loaded!")
