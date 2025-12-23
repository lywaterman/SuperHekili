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

-- 从编译输出读取pack
local f = io.open("Wrath/APLs/DruidFeral_compiled.txt", "r")
local output = f:read("*a")
f:close()

local pack_str = output:match("Hekili:[^\n]+")
print("Pack string length:", pack_str and #pack_str or "nil")

if pack_str then
    local encoded = pack_str:match("^Hekili:(.+)$")
    print("Encoded length:", encoded and #encoded or "nil")
    local decoded = LibDeflate:DecodeForPrint(encoded)
    print("Decoded length:", decoded and #decoded or "nil")
    
    if decoded then
        local decompressed = LibDeflate:DecompressDeflate(decoded)
        print("Decompressed length:", decompressed and #decompressed or "nil")
        
        if decompressed then
            local success, data = AceSerializer:Deserialize(decompressed)
            
            if success then
                print("\n=== 我们的 Payload Lists ===")
                local payload = data.payload
                if payload.lists then
                    for list_name, actions in pairs(payload.lists) do
                        print(list_name, ":", #actions, "actions")
                        if #actions > 0 then
                            local first = actions[1]
                            print("  First action keys:")
                            for k, v in pairs(first) do
                                local val = type(v) == "string" and v:sub(1,30) or tostring(v)
                                print("    ", k, "=", val)
                            end
                        end
                    end
                end
            end
        end
    end
end
