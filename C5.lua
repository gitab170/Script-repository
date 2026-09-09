-- ============================================
-- ロガーテストスクリプト v2.0 (Solaris UI版)
-- ============================================

local repo = "https://raw.githubusercontent.com/sladkoeshkaogg-svg/XOCU/refs/heads/main/"
local Solaris = loadstring(game:HttpGet(repo .. "XOCU%20FAKELIBRORY.lua"))()

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local Window = Solaris:CreateWindow({
    Title = "ロガーテスト",
    Theme = {
        Main = Color3.fromRGB(25, 25, 30),
        Second = Color3.fromRGB(35, 35, 40),
        Accent = Color3.fromRGB(255, 255, 255),
        ElementAccent = Color3.fromRGB(0, 160, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(170, 170, 170),
        Transparency = 0.25,
        Font = "Gotham",
    },
    ToggleKey = Enum.KeyCode.RightShift,
    Transparency = 0.25,
    ShowWatermark = {Enabled = true, Title = true, User = true, FPS = true, Duration = false, Ping = true},
    AutoSave = true,
    ConfigFolder = "LoggerTest",
    UiScale = 1.0,
})

-- ============================================
-- テスト用URLデータベース
-- ============================================
local TEST_CATEGORIES = {
    ["Discord Webhook"] = {
        {name = "Discord標準", url = "https://discord.com/api/webhooks/123456789012345678/test"},
        {name = "Discord旧API", url = "https://discordapp.com/api/webhooks/123456789012345678/test"},
        {name = "Discord Canary", url = "https://canary.discord.com/api/webhooks/123456789012345678/test"},
        {name = "Discord PTB", url = "https://ptb.discord.com/api/webhooks/123456789012345678/test"},
    },
    
    ["Webhook代替サービス"] = {
        {name = "Webhook.site", url = "https://webhook.site/12345678-1234-1234-1234-123456789012"},
        {name = "Hookbin", url = "https://hookbin.com/abcdefghijklmn"},
        {name = "RequestBin", url = "https://requestbin.com/r/abcdefghijklmn"},
        {name = "NTFY", url = "https://ntfy.sh/abcdefghijklmn"},
        {name = "Webhook.town", url = "https://webhook.town/abcdefghijklmn"},
    },
    
    ["IP取得サービス"] = {
        {name = "ipify", url = "https://api.ipify.org?format=json"},
        {name = "ipinfo.io", url = "https://ipinfo.io/json"},
        {name = "ip-api.com", url = "https://ip-api.com/json"},
        {name = "icanhazip", url = "https://icanhazip.com"},
        {name = "ipapi.co", url = "https://ipapi.co/json"},
        {name = "ifconfig.me", url = "https://ifconfig.me/ip"},
        {name = "ipecho.net", url = "https://ipecho.net/plain"},
        {name = "checkip.amazonaws", url = "https://checkip.amazonaws.com"},
    },
    
    ["ペーストサービス"] = {
        {name = "Pastebin", url = "https://pastebin.com/abcdefgh"},
        {name = "Paste.ee", url = "https://paste.ee/p/abcdefgh"},
        {name = "Rentry", url = "https://rentry.co/abcdefgh"},
        {name = "Hastebin", url = "https://hastebin.com/abcdefgh"},
        {name = "ControlC", url = "https://controlc.com/abcdefgh"},
        {name = "JustPaste.it", url = "https://justpaste.it/abcdefgh"},
    },
    
    ["HTTPテストサービス"] = {
        {name = "httpbin", url = "https://httpbin.org/post"},
        {name = "Postman Echo", url = "https://postman-echo.com/post"},
        {name = "Mocky", url = "https://mocky.io/api/abcdefgh"},
        {name = "Webhook-test", url = "https://webhook-test.com/abcdefgh"},
        {name = "HTTPStat", url = "https://httpstat.us/200"},
    },
    
    ["ローカルネットワーク"] = {
        {name = "localhost", url = "http://localhost:8080/webhook"},
        {name = "127.0.0.1", url = "http://127.0.0.1:8080/webhook"},
        {name = "192.168.1.1", url = "http://192.168.1.1:8080/webhook"},
        {name = "ngrok", url = "https://abcdefgh.ngrok.io/webhook"},
    },
    
    ["難読化URL"] = {
        {name = "ドット置換", url = "https://discord[.]com/api/webhooks/123456789012345678/test"},
        {name = "hxxp", url = "hxxps://discord.com/api/webhooks/123456789012345678/test"},
        {name = "大文字混合", url = "HTTPS://DISCORD.COM/API/WEBHOOKS/123456789012345678/TEST"},
        {name = "スペース入り", url = "https:// discord .com/api/webhooks/123456789012345678/test"},
    },
    
    ["エンコードURL"] = {
        {name = "Base64風", url = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTIzNDU2Nzg5MDEyMzQ1Njc4L3Rlc3Q="},
        {name = "Hex風", url = "68747470733a2f2f646973636f72642e636f6d2f6170692f776562686f6f6b732f3132333435363738393031323334353637382f74657374"},
        {name = "URLエンコード", url = "https%3A%2F%2Fdiscord.com%2Fapi%2Fwebhooks%2F123456789012345678%2Ftest"},
    },
}

-- ============================================
-- テスト結果保存
-- ============================================
local testResults = {
    total = 0,
    blocked = 0,
    bypassed = 0,
    errors = 0,
    details = {},
}

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

-- ============================================
-- リクエスト関数
-- ============================================
local function getRequestFunc()
    if http_request then return http_request end
    if syn and syn.request then return syn.request end
    if request then return request end
    return nil
end

-- ============================================
-- 単一URLテスト
-- ============================================
local function testSingleURL(testData)
    local url = testData.url
    local name = testData.name
    
    print("\n=== テスト: " .. name .. " ===")
    print("URL: " .. url:sub(1, 80))
    
    local requestFunc = getRequestFunc()
    if not requestFunc then
        print("エラー: リクエスト関数が見つかりません")
        return {name = name, url = url, result = "error", error = "リクエスト関数なし"}
    end
    
    local success, result = pcall(function()
        return requestFunc({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                content = "ロガーテスト",
                username = "テストBot"
            })
        })
    end)
    
    if not success then
        print("エラー: " .. tostring(result))
        return {name = name, url = url, result = "error", error = tostring(result)}
    end
    
    if result and result.Success == false and result.StatusCode == 403 then
        print("ブロックされた！")
        return {name = name, url = url, result = "blocked"}
    else
        print("すり抜けた...")
        return {name = name, url = url, result = "bypassed"}
    end
end

-- ============================================
-- カテゴリテスト
-- ============================================
local function testCategory(categoryName)
    local tests = TEST_CATEGORIES[categoryName]
    if not tests then return end
    
    Solaris:Notify({Title = "テスト開始", Content = categoryName .. " のテスト中...", Duration = 3})
    
    for _, testData in ipairs(tests) do
        local result = testSingleURL(testData)
        testResults.total += 1
        
        if result.result == "blocked" then
            testResults.blocked += 1
        elseif result.result == "bypassed" then
            testResults.bypassed += 1
        else
            testResults.errors += 1
        end
        
        table.insert(testResults.details, result)
        task.wait(0.3)
    end
    
    Solaris:Notify({Title = "完了", Content = categoryName .. " のテスト完了", Duration = 3})
end

-- ============================================
-- 全テスト実行
-- ============================================
local function testAll()
    testResults = {
        total = 0,
        blocked = 0,
        bypassed = 0,
        errors = 0,
        details = {},
    }
    
    Solaris:Notify({Title = "全テスト開始", Content = "全てのカテゴリをテストします", Duration = 5})
    
    for categoryName, tests in pairs(TEST_CATEGORIES) do
        testCategory(categoryName)
        task.wait(1)
    end
    
    local detectionRate = 0
    if testResults.total - testResults.errors > 0 then
        detectionRate = math.floor(testResults.blocked / (testResults.total - testResults.errors) * 100)
    end
    
    Solaris:Notify({
        Title = "テスト完了",
        Content = "合計: " .. testResults.total .. "個\nブロック: " .. testResults.blocked .. "個\nすり抜け: " .. testResults.bypassed .. "個\nエラー: " .. testResults.errors .. "個\n検知率: " .. detectionRate .. "%",
        Duration = 10
    })
end

-- ============================================
-- 結果表示
-- ============================================
local function showResults()
    local lines = {}
    table.insert(lines, "=== テスト結果 ===")
    table.insert(lines, "合計: " .. testResults.total .. "個")
    table.insert(lines, "ブロック: " .. testResults.blocked .. "個")
    table.insert(lines, "すり抜け: " .. testResults.bypassed .. "個")
    table.insert(lines, "エラー: " .. testResults.errors .. "個")
    
    if testResults.total > 0 then
        table.insert(lines, "検知率: " .. math.floor(testResults.blocked / math.max(testResults.total - testResults.errors, 1) * 100) .. "%")
    end
    table.insert(lines, "")
    
    if #testResults.details > 0 then
        table.insert(lines, "--- すり抜けたURL ---")
        for _, result in ipairs(testResults.details) do
            if result.result == "bypassed" then
                table.insert(lines, "すり抜け: " .. result.name .. ": " .. result.url:sub(1, 60))
            end
        end
        
        table.insert(lines, "")
        table.insert(lines, "--- ブロック成功 ---")
        for _, result in ipairs(testResults.details) do
            if result.result == "blocked" then
                table.insert(lines, "成功: " .. result.name)
            end
        end
    end
    
    return table.concat(lines, "\n")
end

-- ============================================
-- Env Loggerテスト
-- ============================================
local function testEnvLogger()
    local suspiciousCount = 0
    local results = {}
    
    if getfenv and getfenv(0) and getfenv(0).__namecall then
        suspiciousCount += 1
        table.insert(results, "警告: __namecallフック検知")
    else
        table.insert(results, "安全: __namecallフックなし")
    end
    
    local suspiciousNames = {"webhook", "logger", "sendlog", "steal", "grabip"}
    local foundSuspicious = false
    if getgenv then
        for key, value in pairs(getgenv()) do
            if type(key) == "string" then
                local lowerKey = key:lower()
                for _, suspicious in ipairs(suspiciousNames) do
                    if lowerKey:find(suspicious) then
                        suspiciousCount += 1
                        table.insert(results, "警告: 疑わしい変数: " .. key)
                        foundSuspicious = true
                        break
                    end
                end
            end
        end
    end
    if not foundSuspicious then
        table.insert(results, "安全: 怪しい変数なし")
    end
    
    if hookmetamethod and getrawmetatable then
        local mt = getrawmetatable(game)
        if mt and mt.__namecall then
            suspiciousCount += 1
            table.insert(results, "警告: メタメソッドフック検知")
        else
            table.insert(results, "安全: メタメソッドフックなし")
        end
    end
    
    local foundRemote = false
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local lowerName = obj.Name:lower()
            if lowerName:find("log") or lowerName:find("webhook") or lowerName:find("steal") then
                suspiciousCount += 1
                table.insert(results, "警告: 疑わしいリモート: " .. obj.Name)
                foundRemote = true
                break
            end
        end
    end
    if not foundRemote then
        table.insert(results, "安全: 怪しいリモートなし")
    end
    
    return results, suspiciousCount
end

-- ============================================
-- UI作成
-- ============================================
local TestTab = Window:CreateTab("テスト", true, "4483345998")

local TestBlock = TestTab:CreateBlock({Name = "総合テスト", Side = "Left"})

TestBlock:CreateButton({
    Name = "全テスト実行",
    Callback = function()
        testAll()
    end
})

TestBlock:CreateButton({
    Name = "結果を表示",
    Callback = function()
        local resultText = showResults()
        Solaris:Notify({Title = "テスト結果", Content = resultText, Duration = 20})
        print("\n" .. resultText)
    end
})

TestBlock:CreateButton({
    Name = "Env Loggerテスト",
    Callback = function()
        local results, suspiciousCount = testEnvLogger()
        local resultText = table.concat(results, "\n")
        
        Solaris:Notify({Title = "Env Loggerテスト", Content = resultText, Duration = 10})
        
        if suspiciousCount > 0 then
            notify("警告", "Env Loggerの可能性があります！", 5)
        else
            notify("安全", "Env Loggerは検知されませんでした", 3)
        end
    end
})

local CategoryBlock = TestTab:CreateBlock({Name = "カテゴリ別テスト", Side = "Right"})

for categoryName, tests in pairs(TEST_CATEGORIES) do
    CategoryBlock:CreateButton({
        Name = categoryName .. " (" .. #tests .. "個)",
        Callback = function()
            testCategory(categoryName)
        end
    })
end

local InfoTab = Window:CreateTab("情報", true, "4370211644")

local InfoBlock = InfoTab:CreateBlock({Name = "使い方", Side = "Left"})

InfoBlock:CreateButton({
    Name = "使用方法",
    Callback = function()
        Solaris:Notify({
            Title = "使い方",
            Content = "1. アンチロガーを起動\n2. 全テスト実行をクリック\n3. 結果を確認\n\nすり抜けたURLがあれば、アンチロガーのパターンに追加が必要です",
            Duration = 15
        })
    end
})

InfoBlock:CreateButton({
    Name = "テスト内容",
    Callback = function()
        Solaris:Notify({
            Title = "テスト内容",
            Content = "Discord Webhook (4個)\nWebhook代替 (5個)\nIP取得 (8個)\nペースト (6個)\nHTTPテスト (5個)\nローカルネット (4個)\n難読化URL (4個)\nエンコードURL (3個)\n合計: 39個のテスト",
            Duration = 15
        })
    end
})

print("ロガーテストスクリプト v2.0 ロード完了")
