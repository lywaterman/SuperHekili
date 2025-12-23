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
    local encoded = str:match("Hekili:([%w%+%/%=%.%(%)]+)")
    if not encoded then return nil, "no match" end
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return nil, "decode failed" end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "decompress failed" end
    local success, data = AceSerializer:Deserialize(decompressed)
    if not success then return nil, "deserialize failed" end
    return data
end

-- 原版
local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()
local orig, err1 = decode_pack(content)
print("原版解码:", orig and "OK" or err1)

-- 我们的
local f2 = io.open("Wrath/APLs/DruidFeral_compiled.txt", "r")
local our_content = f2:read("*a")
f2:close()
local ours, err2 = decode_pack(our_content)
print("我们解码:", ours and "OK" or err2)

if orig and ours then
    print("\n=== 关键对比 ===")
    print("原版 builtIn:", orig.payload.builtIn)
    print("我们 builtIn:", ours.payload.builtIn)
    print("原版 spec:", orig.payload.spec)
    print("我们 spec:", ours.payload.spec)
    
    print("\n=== cat list 对比 ===")
    local orig_cat = orig.payload.lists.cat
    local our_cat = ours.payload.lists.cat
    print("原版 cat 数量:", #orig_cat)
    print("我们 cat 数量:", #our_cat)
    
    -- 对比第一个action的每个字段
    print("\n=== cat[1] 详细对比 ===")
    local o1, u1 = orig_cat[1], our_cat[1]
    local all_keys = {}
    for k in pairs(o1) do all_keys[k] = true end
    for k in pairs(u1) do all_keys[k] = true end
    
    for k in pairs(all_keys) do
        local ov = o1[k]
        local uv = u1[k]
        local match = (type(ov) == type(uv)) and (ov == uv or (type(ov) == "string" and ov:gsub("%s+","") == uv:gsub("%s+","")))
        print(k .. ":", match and "✓" or "✗", "|", type(ov), "vs", type(uv))
        if not match and type(ov) == "string" and type(uv) == "string" then
            print("  原版:", ov:sub(1,60))
            print("  我们:", uv:sub(1,60))
        end
    end
end
