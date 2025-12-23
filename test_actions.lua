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

local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()

-- 提取pack
for line in content:gmatch("[^\n]+") do
    if line:match('野性%(黑科研%)') and line:match("RegisterPack") and not line:match("^%s*%-%-") and not line:match("RegisterPackSelector") then
        local hekili = line:match("%[%[(Hekili:[^%]]+)%]%]")
        local data = decode_pack(hekili)
        
        if data then
            print("=== default list (主循环) ===")
            for i, action in ipairs(data.payload.lists.default or {}) do
                print(i .. ". " .. action.action)
                for k, v in pairs(action) do
                    if k ~= "action" and k ~= "enabled" then
                        local val = tostring(v)
                        if #val > 60 then val = val:sub(1,57) .. "..." end
                        print("   " .. k .. " = " .. val)
                    end
                end
            end
            
            print("\n=== cat list (猫形态) ===")
            for i, action in ipairs(data.payload.lists.cat or {}) do
                print(i .. ". " .. action.action)
                for k, v in pairs(action) do
                    if k ~= "action" and k ~= "enabled" then
                        local val = tostring(v)
                        if #val > 60 then val = val:sub(1,57) .. "..." end
                        print("   " .. k .. " = " .. val)
                    end
                end
            end
        end
        break
    end
end
