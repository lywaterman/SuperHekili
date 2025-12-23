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

-- 直接提取野性pack
local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()

-- 使用更精确的pattern
local pack_str = content:match('spec:RegisterPack%( "野性%(黑科研%)", %d+, %[%[(Hekili:[^%]]+)%]%] %)')
print("Extracted pack length:", pack_str and #pack_str or "nil")
print("Pack prefix:", pack_str and pack_str:sub(1,30) or "nil")

if pack_str then
    local encoded = pack_str:match("^Hekili:(.+)$")
    print("Encoded length:", encoded and #encoded or "nil")
    print("Encoded prefix:", encoded and encoded:sub(1,20) or "nil")
    
    if encoded then
        local decoded = LibDeflate:DecodeForPrint(encoded)
        print("Decoded length:", decoded and #decoded or "nil")
        
        if decoded then
            local decompressed = LibDeflate:DecompressDeflate(decoded)
            print("Decompressed length:", decompressed and #decompressed or "nil")
        end
    end
end
