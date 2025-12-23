_G.strmatch = string.match
_G.strfind = string.find
_G.format = string.format
_G.tinsert = table.insert
_G.tremove = table.remove
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.geterrorhandler = function() return print end

dofile("Libs/LibStub/LibStub.lua")
dofile("Libs/AceSerializer-3.0/AceSerializer-3.0.lua")
dofile("Libs/LibDeflate/LibDeflate.lua")

local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

local function decode_pack(str)
    local encoded = str:match("^Hekili:(.+)$")
    if not encoded then return nil end
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return nil end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil end
    local success, data = AceSerializer:Deserialize(decompressed)
    return success and data or nil
end

-- 原版
local f = io.open("/tmp/druid_orig.lua", "r")
local content = f:read("*a")
f:close()

local pack_str = content:match('spec:RegisterPack%( "野性%(黑科研%)", %d+, %[%[(Hekili:[^%]]+)%]%] %)')
local orig = decode_pack(pack_str)

print("=== 原版 bear_tank_init 的 variable action ===")
for i, action in ipairs(orig.payload.lists.bear_tank_init) do
    if action.action == "variable" then
        print("action:", action.action)
        print("name:", action.name)
        print("value:", action.value)
        print("---")
    end
end
