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

-- 解码原版
local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()

local pack_str = content:match('spec:RegisterPack%( "野性%(黑科研%)", %d+, %[%[(.-)%]%] %)')
local encoded = pack_str:match("^Hekili:(.+)$")
local decoded = LibDeflate:DecodeForPrint(encoded)
local decompressed = LibDeflate:DecompressDeflate(decoded)
local success, original = AceSerializer:Deserialize(decompressed)

print("=== 原版 cat[1] ===")
local orig_cat1 = original.payload.lists.cat[1]
for k,v in pairs(orig_cat1) do
    print(k, "=", type(v), type(v) == "string" and v:sub(1,60) or v)
end

print("\n=== 原版 default[1] ===")
local orig_def1 = original.payload.lists.default[1]
for k,v in pairs(orig_def1) do
    print(k, "=", type(v), type(v) == "string" and v:sub(1,60) or v)
end
