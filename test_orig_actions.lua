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

-- 读取git原版
os.execute("git show HEAD:Wrath/Druid.lua > /tmp/druid_git.lua 2>/dev/null")
local f = io.open("/tmp/druid_git.lua", "r")
local content = f:read("*a")
f:close()

print("原版文件大小:", #content)

-- 提取pack
for line in content:gmatch("[^\n]+") do
    if line:match('野性%(黑科研%)') and line:match("RegisterPack") and not line:match("^%s*%-%-") and not line:match("RegisterPackSelector") then
        local hekili = line:match("%[%[(Hekili:[^%]]+)%]%]")
        print("Hekili长度:", hekili and #hekili or "nil")
        
        if hekili then
            local data = decode_pack(hekili)
            if data then
                print("\n=== 原版 default list ===")
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
                
                print("\n=== 原版 cat list ===")
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
            else
                print("解码失败")
            end
        end
        break
    end
end
