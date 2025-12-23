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

-- 对比原版和我们编译的 cat list 第一个action
local function decode_pack(str)
    local encoded = str:match("^Hekili:(.+)$")
    local decoded = LibDeflate:DecodeForPrint(encoded)
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    local success, data = AceSerializer:Deserialize(decompressed)
    return success and data or nil
end

-- 原版
local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()
local orig_str = content:match('spec:RegisterPack%( "野性%(黑科研%)", %d+, %[%[(Hekili:.-)%]%] %)')
local orig = decode_pack(orig_str)

-- 我们的
local f2 = io.open("Wrath/APLs/DruidFeral_compiled.txt", "r")
local our_content = f2:read("*a")
f2:close()
local our_str = our_content:match("(Hekili:[^\n]+)")
local ours = decode_pack(our_str)

print("=== 比较 cat list ===")
print("原版 cat 数量:", orig and #orig.payload.lists.cat or "nil")
print("我们 cat 数量:", ours and #ours.payload.lists.cat or "nil")

print("\n=== 比较 cat[1] ===")
if orig and ours then
    local o = orig.payload.lists.cat[1]
    local u = ours.payload.lists.cat[1]
    print("原版:", o.action, "|", o.criteria and o.criteria:sub(1,50))
    print("我们:", u.action, "|", u.criteria and u.criteria:sub(1,50))
end

print("\n=== payload 字段对比 ===")
if orig and ours then
    for k,v in pairs(orig.payload) do
        local ov = type(v) == "string" and #v or (type(v) == "table" and "table" or v)
        local uv = ours.payload[k]
        uv = type(uv) == "string" and #uv or (type(uv) == "table" and "table" or uv)
        print(k, ":", ov, "vs", uv or "MISSING")
    end
end
