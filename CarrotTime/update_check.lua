--[[
update_check.lua - tells you in chat when a newer version of this addon is on GitHub.

The addon's main file starts it once:

    require('update_check').start({
        name    = 'CarrotTime',
        version = _addon.version,
        url     = 'https://raw.githubusercontent.com/Valdimar/CarrotTime/main/CarrotTime/CarrotTime.lua',
        page    = 'github.com/Valdimar/CarrotTime',
    })

`url` is the addon's main file on GitHub. The check reads `_addon.version` from it, so
pushing a new version to GitHub is all it takes for everyone else to be told about it.

It checks once per load, a few seconds after you're logged in, and always says the result
in chat:
  - Up to date (version X)
  - UPDATE AVAILABLE: version X is out (in a different colour, 167)
  - Version X is newer than GitHub (not released yet)
  - Couldn't check for updates (no HTTPS support, or GitHub didn't answer)
`//lua reload` the addon to check again.
]]

local M = {}

M.delay   = 8   -- seconds after login before checking
M.timeout = 3   -- seconds to wait for GitHub (the game pauses while it waits)
M.color   = 207 -- chat color

local checked = false

-- "3.1" -> {3, 1}; "v1.31" -> {1, 31}
local function parts(v)
    local t = {}
    for n in tostring(v):gmatch('%d+') do t[#t + 1] = tonumber(n) end
    return t
end

-- true when version a is newer than version b, comparing piece by piece (1.31 > 1.29, 2.0 > 1.9)
function M.is_newer(a, b)
    local x, y = parts(a), parts(b)
    for i = 1, math.max(#x, #y) do
        local p, q = x[i] or 0, y[i] or 0
        if p ~= q then return p > q end
    end
    return false
end

function M.check(opts)
    if checked then return end
    checked = true

    local function say(color, text)
        windower.add_to_chat(color, ('[%s] %s'):format(opts.name, text))
    end

    local ok, https = pcall(require, 'ssl.https')
    if not ok then
        say(M.color, "Couldn't check for updates (no HTTPS support).")
        return
    end
    https.TIMEOUT = M.timeout

    local ok2, body, code = pcall(https.request, opts.url)
    local latest = ok2 and code == 200 and type(body) == 'string'
        and body:match('_addon%.version%s*=%s*[\'"]([^\'"]+)[\'"]')
    if not latest then
        say(M.color, "Couldn't check for updates (GitHub didn't answer). Try again with a reload.")
    elseif M.is_newer(latest, opts.version) then
        say(167, ('UPDATE AVAILABLE: version %s is out (you have %s). Get it from %s')
            :format(latest, opts.version, opts.page))
    elseif M.is_newer(opts.version, latest) then
        say(M.color, ('Version %s is newer than GitHub (%s), so it hasn\'t been released yet.')
            :format(opts.version, latest))
    else
        say(M.color, ('Up to date (version %s).'):format(opts.version))
    end
end

function M.start(opts)
    local function later()
        coroutine.schedule(function() M.check(opts) end, M.delay)
    end
    windower.register_event('login', later)
    local info = windower.ffxi.get_info()
    if info and info.logged_in then later() end
end

return M
