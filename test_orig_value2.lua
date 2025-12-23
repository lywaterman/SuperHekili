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
    local encoded = str:match("Hekili:([%w%+%/%=]+)")
    if not encoded then return nil, "no match" end
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return nil, "decode fail" end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "decompress fail" end
    local success, data = AceSerializer:Deserialize(decompressed)
    return success and data or nil, "deserialize fail"
end

-- 原版
local f = io.open("/tmp/druid_orig.lua", "r")
local content = f:read("*a")
f:close()

-- 找到所有 Hekili: 开头的字符串
local count = 0
for match in content:gmatch('spec:RegisterPack%( "([^"]+)"') do
    count = count + 1
    print(count, match)
end

print("\n寻找野性pack...")
-- 找野性pack的位置
local start_pos = content:find('spec:RegisterPack%( "野性%(黑科研%)"')
if start_pos then
    print("找到位置:", start_pos)
    -- 检查这行是不是注释
    local line_start = content:sub(1, start_pos):match(".*\n()") or 1
    local line = content:sub(line_start, start_pos + 100)
    print("行内容预览:", line:sub(1, 80))
end
