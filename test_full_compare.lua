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
    if not encoded then return nil end
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return nil end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil end
    local success, data = AceSerializer:Deserialize(decompressed)
    return success and data or nil
end

-- 原版（从git获取）
os.execute('git show HEAD:Wrath/Druid.lua > /tmp/druid_orig.lua')
local f = io.open("/tmp/druid_orig.lua", "r")
local orig_content = f:read("*a")
f:close()

-- 当前版本
local f2 = io.open("Wrath/Druid.lua", "r")
local curr_content = f2:read("*a")
f2:close()

-- 提取pack（跳过注释行）
local function extract_pack(content, pack_name)
    local escaped = pack_name:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for line in content:gmatch("[^\n]+") do
        if not line:match("^%s*%-%-") then
            local match = line:match('spec:RegisterPack%( "' .. escaped .. '", %d+, %[%[(Hekili:[^%]]+)%]%]')
            if match then return match end
        end
    end
    return nil
end

local orig_str = extract_pack(orig_content, "野性(黑科研)")
local curr_str = extract_pack(curr_content, "野性(黑科研)")

print("原版pack长度:", orig_str and #orig_str or "nil")
print("当前pack长度:", curr_str and #curr_str or "nil")

local orig = orig_str and decode_pack(orig_str)
local curr = curr_str and decode_pack(curr_str)

print("原版解码:", orig and "OK" or "FAIL")
print("当前解码:", curr and "OK" or "FAIL")

if orig and curr then
    -- 深度对比payload字段
    print("\n=== payload 对比 ===")
    local fields = {"spec", "builtIn", "hidden", "author", "desc", "source", "profile", "warnings"}
    for _, field in ipairs(fields) do
        local ov, cv = orig.payload[field], curr.payload[field]
        local match = ov == cv
        print(field .. ":", match and "✓" or "✗", "原版:", tostring(ov), "当前:", tostring(cv))
    end
    
    -- 对比lists
    print("\n=== lists 对比 ===")
    local all_lists = {}
    for k in pairs(orig.payload.lists) do all_lists[k] = true end
    for k in pairs(curr.payload.lists) do all_lists[k] = true end
    
    for list_name in pairs(all_lists) do
        local ol = orig.payload.lists[list_name]
        local cl = curr.payload.lists[list_name]
        if not ol then
            print(list_name .. ": 原版缺少")
        elseif not cl then
            print(list_name .. ": 当前缺少")
        elseif #ol ~= #cl then
            print(list_name .. ": 数量不同 原版=" .. #ol .. " 当前=" .. #cl)
        else
            -- 检查每个action
            local diff = false
            for i = 1, #ol do
                local oa, ca = ol[i], cl[i]
                -- 比较所有字段
                for k, v in pairs(oa) do
                    if ca[k] ~= v then
                        if type(v) == "string" and type(ca[k]) == "string" then
                            -- 忽略空格差异
                            if v:gsub("%s+", "") ~= ca[k]:gsub("%s+", "") then
                                print(list_name .. "[" .. i .. "]." .. k .. " 不同:")
                                print("  原版: " .. tostring(v):sub(1,60))
                                print("  当前: " .. tostring(ca[k]):sub(1,60))
                                diff = true
                            end
                        else
                            print(list_name .. "[" .. i .. "]." .. k .. " 不同: 原版=" .. tostring(v) .. " 当前=" .. tostring(ca[k]))
                            diff = true
                        end
                    end
                end
                for k, v in pairs(ca) do
                    if oa[k] == nil then
                        print(list_name .. "[" .. i .. "]." .. k .. " 当前多出: " .. tostring(v))
                        diff = true
                    end
                end
            end
            if not diff then
                print(list_name .. ": ✓ 相同 (" .. #ol .. " actions)")
            end
        end
    end
end
