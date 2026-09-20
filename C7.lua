-- // Webhook Notify on Load v1.0
-- 起動したらDiscord Webhookにメッセージ送信

-- ==========================================
-- 設定
-- ==========================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1551183993678991502/CS2wbN6nhsxWx6DaF0kYKLJKSJ_3otBABFO0kk-dmMpaktJv4-CJW7Hl60MpCofPvgQB"  -- ←ここに自分のWebhook URL
local MESSAGE = "スクリプト起動完了"                        -- ←送信する文章
local USE_EMBED = true                                           -- Embed形式で送るか

-- ==========================================
-- 送信ペイロード組み立て
-- ==========================================
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local function buildPayload()
    if USE_EMBED then
        return {
            embeds = {
                {
                    title = "Script Loaded",
                    description = MESSAGE,
                    color = 0x64FF96,
                    fields = {
                        { name = "Player", value = LP.Name .. " (@" .. LP.DisplayName .. ")", inline = true },
                        { name = "UserId", value = tostring(LP.UserId), inline = true },
                        { name = "PlaceId", value = tostring(game.PlaceId), inline = true },
                        { name = "JobId", value = tostring(game.JobId), inline = false },
                        { name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false },
                    },
                    footer = { text = "Webhook Notify v1.0" }
                }
            }
        }
    else
        return { content = MESSAGE }
    end
end

-- ==========================================
-- 送信（executorのrequest系を自動判定）
-- ==========================================
local function sendWebhook(url, payload)
    local body = game:GetService("HttpService"):JSONEncode(payload)
    local headers = { ["Content-Type"] = "application/json" }

    -- エグゼキュータのrequest関数を探す
    local req = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)

    if req then
        local ok, res = pcall(function()
            return req({
                Url = url,
                Method = "POST",
                Headers = headers,
                Body = body
            })
        end)
        return ok, res
    end

    -- フォールバック：HttpService（自鯖かつHttpEnabled=trueなら通る）
    local ok, err = pcall(function()
        game:GetService("HttpService"):PostAsync(url, body)
    end)
    return ok, err
end

-- ==========================================
-- 実行
-- ==========================================
task.spawn(function()
    local ok, res = sendWebhook(WEBHOOK_URL, buildPayload())
    if not ok then
        warn("[Webhook] 送信失敗: " .. tostring(res))
    else
        print("[Webhook] 送信完了")
    end
end)
