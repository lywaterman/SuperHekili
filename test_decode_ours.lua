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

-- 读取完整文件
local f = io.open("Wrath/APLs/DruidFeral_compiled.txt", "r")
local content = f:read("*a")
f:close()

-- 提取Hekili行
local pack_str = content:match("(Hekili:[%w%+%/%=%.%(%)]+)")
print("Pack string:", pack_str and pack_str:sub(1,50) or "nil")
print("Pack length:", pack_str and #pack_str or 0)

if pack_str then
    local encoded = pack_str:sub(8)  -- 去掉 "Hekili:"
    print("Encoded:", encoded:sub(1,30))
    
    local decoded = LibDeflate:DecodeForPrint(encoded)
    print("Decoded:", decoded and #decoded or "nil")
    
    if decoded then
        local decompressed = LibDeflate:DecompressDeflate(decoded)
        print("Decompressed:", decompressed and #decompressed or "nil")
        
        if decompressed then
            local success, data = AceSerializer:Deserialize(decompressed)
            print("Deserialize:", success and "ok" or "fail")
            
            if success then
                print("\n=== Action Structure ===")
                local lists = data.payload.lists
                if lists.cat then
                    print("cat[1] keys:")
                    for k,v in pairs(lists.cat[1]) do
                        print("  ", k, "=", type(v) == "string" and v:sub(1,40) or v)
                    end
                end
            end
        end
    end
end
