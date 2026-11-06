--[[
    09 - HTTP and JSON
    Fetches this repository's details from the GitHub API when you press a
    button, decodes the JSON and shows the result in the menu.

    Shows: http.request and HttpRequestBuilder, the reply callback,
    utils.json_decode, updating a Label, Button callbacks.
    Requests run in the background; the callback runs on a later frame.
]]

local URL = "https://api.github.com/repos/v1ttxt/VITTLOCK-LUA-API"

local group  = Menu.Create("Examples", "", "HTTP", "", "Settings")
local status = group:Label("Press Fetch.")
local busy   = false

local function on_reply(code, body, success)
    busy = false
    if not success then
        status:ForceLocalization(("Request failed (status %d)."):format(code))
        return
    end
    local ok, data = pcall(utils.json_decode, body)
    if not ok or type(data) ~= "table" then
        status:ForceLocalization("The reply was not valid JSON.")
        return
    end
    status:ForceLocalization(("%s: %d stars, last push %s"):format(
        data.full_name or "?", math.tointeger(data.stargazers_count) or 0, data.pushed_at or "?"))
end

group:Button("Fetch", function()
    if busy then return end
    busy = true
    status:ForceLocalization("Fetching...")
    http.request(URL)
        :get()
        :accept_json()
        :timeout(10)
        :send(on_reply)
end)
