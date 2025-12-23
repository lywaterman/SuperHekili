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

-- 直接用简单的方式提取
local line_num = 0
for line in content:gmatch("[^\n]+") do
    line_num = line_num + 1
    if line:match('野性%(黑科研%)') and not line:match("^%s*%-%-") then
        print("Line " .. line_num .. ":")
        print("前50字符:", line:sub(1, 50))
        print("是否包含RegisterPack:", line:match("RegisterPack") and "YES" or "NO")
        
        -- 提取Hekili字符串
        local hekili = line:match("%[%[(Hekili:[^%]]+)%]%]")
        if hekili then
            print("Hekili字符串长度:", #hekili)
            print("前30字符:", hekili:sub(1, 30))
            print("后30字符:", hekili:sub(-30))
            
            -- 尝试解码
            local encoded = hekili:match("^Hekili:(.+)$")
            print("Encoded长度:", encoded and #encoded or "nil")
            
            if encoded then
                local decoded = LibDeflate:DecodeForPrint(encoded)
                print("Decoded:", decoded and #decoded .. " bytes" or "FAIL")
                
                if decoded then
                    local decompressed = LibDeflate:DecompressDeflate(decoded)
                    print("Decompressed:", decompressed and #decompressed .. " bytes" or "FAIL")
                    
                    if decompressed then
                        local success, data = AceSerializer:Deserialize(decompressed)
                        print("Deserialize:", success and "OK" or "FAIL")
                        if success and data.payload then
                            print("Pack name:", data.name)
                            print("Lists count:", 0)
                            local c = 0
                            for _ in pairs(data.payload.lists) do c = c + 1 end
                            print("  ->", c, "lists")
                        end
                    end
                end
            end
        else
            print("未能提取Hekili字符串")
        end
        print("---")
    end
end
