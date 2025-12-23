-- WoW API shims
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

-- 用我们的编译脚本生成一个pack
dofile("compile_simc.lua")

local pack_data = compile_simc("Wrath/APLs/DruidFeral.simc", 11, "野性(黑科研)", "大剑")
print("Our pack length:", pack_data and #pack_data or "nil")

if pack_data then
    local encoded = pack_data:match("^Hekili:(.+)$")
    local decoded = LibDeflate:DecodeForPrint(encoded)
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    local success, data = AceSerializer:Deserialize(decompressed)
    
    if success then
        print("\n=== 我们的Pack结构 ===")
        for k, v in pairs(data) do
            print(k, "->", type(v))
        end
    else
        print("Deserialize failed:", data)
    end
end
