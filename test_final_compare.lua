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

-- 原版
local f = io.open("Wrath/Druid.lua", "r")
local content = f:read("*a")
f:close()
local orig_str = content:match('spec:RegisterPack%( "野性%(黑科研%)", %d+, %[%[(Hekili:[^%]]+)%]%] %)')
local orig = decode_pack(orig_str)

-- 我们的
local f2 = io.open("Wrath/APLs/DruidFeral_compiled.txt", "r")
local our_content = f2:read("*a")
f2:close()
local our_str = our_content:match('%[%[(Hekili:[^%]]+)%]%]')
local ours = decode_pack(our_str)

print("原版:", orig and "OK" or "FAIL")
print("我们:", ours and "OK" or "FAIL")

if orig and ours then
    local oc = orig.payload.lists.cat[1]
    local uc = ours.payload.lists.cat[1]
    
    print("\n=== cat[1] 详细对比 ===")
    
    -- 收集所有keys
    local keys = {}
    for k in pairs(oc) do keys[k] = true end
    for k in pairs(uc) do keys[k] = true end
    
    for k in pairs(keys) do
        local ov, uv = oc[k], uc[k]
        local status = "?"
        if ov == nil and uv ~= nil then
            status = "我们多了"
        elseif ov ~= nil and uv == nil then
            status = "我们缺少"
        elseif type(ov) ~= type(uv) then
            status = "类型不同: " .. type(ov) .. " vs " .. type(uv)
        elseif ov == uv then
            status = "✓相同"
        elseif type(ov) == "string" then
            local ov_clean = ov:gsub("%s+", " ")
            local uv_clean = uv:gsub("%s+", " ")
            if ov_clean == uv_clean then
                status = "✓相同(空格不同)"
            else
                status = "✗不同"
            end
        else
            status = "✗不同"
        end
        print(k, ":", status)
        if status:match("不同") then
            print("  原版:", type(ov) == "string" and ov:sub(1,70) or ov)
            print("  我们:", type(uv) == "string" and uv:sub(1,70) or uv)
        end
    end
end
