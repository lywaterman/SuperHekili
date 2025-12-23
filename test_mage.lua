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

local f = io.open("Wrath/Mage.lua", "r")
local content = f:read("*a")
f:close()

for line in content:gmatch("[^\n]+") do
    if line:match('火焰%(黑科研%)') and line:match("RegisterPack") and not line:match("^%s*%-%-") and not line:match("RegisterPackSelector") then
        local hekili = line:match("%[%[(Hekili:[^%]]+)%]%]")
        local data = decode_pack(hekili)
        
        if data then
            print("=== 火法 default list ===")
            for i, action in ipairs(data.payload.lists.default or {}) do
                print(i .. ". " .. action.action)
                if action.action == "run_action_list" or action.action == "call_action_list" then
                    print("   list_name = " .. tostring(action.list_name))
                    print("   name = " .. tostring(action.name))
                end
            end
        end
        break
    end
end
