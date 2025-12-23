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
    local decoded = LibDeflate:DecodeForPrint(encoded)
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    local success, data = AceSerializer:Deserialize(decompressed)
    return success and data or nil
end

-- 更新后的
local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()
local pack_str = content:match('spec:RegisterPack%( "野性%(黑科研%)", %d+, %[%[(Hekili:[^%]]+)%]%] %)')
local data = decode_pack(pack_str)

if data then
    local c = data.payload.lists.cat[1]
    print("更新后的 cat[1].criteria:")
    print(c.criteria)
end
