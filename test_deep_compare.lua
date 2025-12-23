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
    if not encoded then return nil, "no Hekili: prefix" end
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return nil, "DecodeForPrint failed" end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "DecompressDeflate failed" end
    local success, data = AceSerializer:Deserialize(decompressed)
    if not success then return nil, "Deserialize failed" end
    return data
end

-- 读取Druid.lua
local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()

-- 提取当前的野性pack
local pack_str = content:match('spec:RegisterPack%( "野性%(黑科研%)", %d+, %[%[(Hekili:[^%]]+)%]%] %)')
if not pack_str then
    print("ERROR: 无法从Druid.lua提取野性pack")
    os.exit(1)
end

print("提取到pack长度:", #pack_str)
local data, err = decode_pack(pack_str)
if not data then
    print("ERROR: 解码失败:", err)
    os.exit(1)
end

print("\n=== Pack 顶层结构 ===")
for k, v in pairs(data) do
    print(k, ":", type(v), type(v) == "string" and (#v < 50 and v or #v.." chars") or "")
end

print("\n=== payload 结构 ===")
for k, v in pairs(data.payload) do
    if type(v) == "table" then
        print(k, ": table with", 0, "entries")
        local count = 0
        for _ in pairs(v) do count = count + 1 end
        print("  ->", count, "entries")
    else
        print(k, ":", type(v), v)
    end
end

print("\n=== lists 内容 ===")
for list_name, actions in pairs(data.payload.lists) do
    print(list_name, ":", #actions, "actions")
    if #actions > 0 then
        print("  第一个action:", actions[1].action)
        for k, v in pairs(actions[1]) do
            if k ~= "action" then
                print("    ", k, "=", type(v) == "string" and v:sub(1,50) or v)
            end
        end
    end
end
