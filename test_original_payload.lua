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

local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()

local pack_str = content:match('spec:RegisterPack%( "野性%(黑科研%)", %d+, %[%[(.-)%]%] %)')
local encoded = pack_str:match("^Hekili:(.+)$")
local decoded = LibDeflate:DecodeForPrint(encoded)
local decompressed = LibDeflate:DecompressDeflate(decoded)
local success, data = AceSerializer:Deserialize(decompressed)

if success then
    print("=== 原版 Payload 结构 ===")
    local payload = data.payload
    for k, v in pairs(payload) do
        if type(v) == "table" then
            print(k, "-> table with keys:")
            for k2, _ in pairs(v) do
                print("    ", k2)
            end
        else
            print(k, "->", type(v), ":", tostring(v):sub(1,50))
        end
    end
    
    -- 检查lists结构
    print("\n=== Lists ===")
    if payload.lists then
        for list_name, actions in pairs(payload.lists) do
            print(list_name, ":", #actions, "actions")
            if #actions > 0 then
                local first = actions[1]
                print("  First action keys:")
                for k, _ in pairs(first) do
                    print("    ", k)
                end
            end
        end
    end
end
