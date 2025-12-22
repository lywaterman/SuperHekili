#!/usr/bin/env luajit
--[[
    编译 .simc 并自动更新对应 .lua 文件中的 RegisterPack
    用法: luajit compile_and_update.lua <simc文件> <lua文件> <spec_id> <pack名称> [作者]

    示例:
        luajit compile_and_update.lua "Wrath/APLs/DruidFeral.simc" "Wrath/Druid.lua" 11 "野性(黑科研)" "风雪"
]]

-- WoW API 兼容层
strmatch = string.match
strfind = string.find
strlen = string.len
strsub = string.sub
strupper = string.upper
strlower = string.lower
strbyte = string.byte
strchar = string.char
format = string.format
gsub = string.gsub
gmatch = string.gmatch
tinsert = table.insert
tremove = table.remove
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G = _G or {}

local script_path = arg[0]
local HEKILI_PATH = script_path:match("(.*/)") or "./"

dofile(HEKILI_PATH .. "Libs/LibStub/LibStub.lua")
local LibStub = _G.LibStub
dofile(HEKILI_PATH .. "Libs/AceSerializer-3.0/AceSerializer-3.0.lua")
local AceSerializer = LibStub("AceSerializer-3.0")
dofile(HEKILI_PATH .. "Libs/LibDeflate/LibDeflate.lua")
local LibDeflate = LibStub("LibDeflate")

-- 解析 simc 文件
local function parse_simc_file(filepath)
    local lists = {}
    local file = io.open(filepath, "r")
    if not file then error("Cannot open: " .. filepath) end
    local content = file:read("*all")
    file:close()

    for line in content:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            local list_name, action_str = line:match("^actions%.?([%w_]*)%+?=/(.+)$")
            if action_str then
                list_name = (list_name == "" or not list_name) and "default" or list_name

                -- 解析 action
                local parts = {}
                local current, depth = {}, 0
                for i = 1, #action_str do
                    local ch = action_str:sub(i, i)
                    if ch == "(" then depth = depth + 1; table.insert(current, ch)
                    elseif ch == ")" then depth = depth - 1; table.insert(current, ch)
                    elseif ch == "," and depth == 0 then
                        table.insert(parts, table.concat(current)); current = {}
                    else table.insert(current, ch) end
                end
                if #current > 0 then table.insert(parts, table.concat(current)) end

                if #parts > 0 then
                    local result = { action = parts[1]:match("^%s*(.-)%s*$"), enabled = true }
                    for i = 2, #parts do
                        local eq = parts[i]:find("=")
                        if eq then
                            local key = parts[i]:sub(1, eq-1):match("^%s*(.-)%s*$")
                            local val = parts[i]:sub(eq+1):match("^%s*(.-)%s*$")
                            if key == "if" or key == "condition" then key = "criteria" end
                            local num = tonumber(val)
                            if num and (key == "cycle_targets" or key == "max_cycle_targets" or key == "line_cd") then
                                val = num
                            end
                            result[key] = val
                        end
                    end
                    if not lists[list_name] then lists[list_name] = {} end
                    table.insert(lists[list_name], result)
                end
            end
        end
    end

    if not lists["default"] then lists["default"] = {} end
    if not lists["precombat"] then lists["precombat"] = {} end
    return lists
end

-- 创建 pack 结构
local function create_pack(lists, spec_id, pack_name, author)
    local date_num = tonumber(os.date("%Y%m%d"))
    return {
        payload = {
            source = "", lists = lists, builtIn = false, spec = spec_id,
            hidden = false, desc = "Compiled by Claude " .. os.date("%Y-%m-%d"),
            date = date_num, author = author or "Claude", profile = "",
            warnings = "", version = date_num
        },
        name = pack_name,
        date = tonumber(os.date("%Y%m%d.%H%M%S")),
        type = "package"
    }
end

-- 编码 pack
local function encode_pack(pack)
    local serialized = AceSerializer:Serialize(pack)
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 5})
    return "Hekili:" .. LibDeflate:EncodeForPrint(compressed)
end

-- 更新 lua 文件中的 RegisterPack
local function update_lua_file(lua_path, pack_name, new_encoded)
    local file = io.open(lua_path, "r")
    if not file then error("Cannot open: " .. lua_path) end
    local content = file:read("*all")
    file:close()

    -- 匹配 RegisterPack 调用
    local pattern = 'spec:RegisterPack%( "' .. pack_name:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. '", %d+, %[%[Hekili:[^%]]+%]%] %)'
    local date_str = os.date("%Y%m%d")
    local replacement = 'spec:RegisterPack( "' .. pack_name .. '", ' .. date_str .. ', [[' .. new_encoded .. ']] )'

    local new_content, count = content:gsub(pattern, replacement)

    if count == 0 then
        print("警告: 未找到 RegisterPack(\"" .. pack_name .. "\")，尝试宽松匹配...")
        -- 尝试更宽松的匹配
        pattern = 'spec:RegisterPack%( "' .. pack_name:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. '"[^%)]+%)'
        new_content, count = content:gsub(pattern, replacement)
    end

    if count == 0 then
        error("未找到 RegisterPack(\"" .. pack_name .. "\") 在 " .. lua_path)
    end

    local out = io.open(lua_path, "w")
    out:write(new_content)
    out:close()

    return count
end

-- 主函数
local function main()
    if #arg < 4 then
        print([[
用法: luajit compile_and_update.lua <simc文件> <lua文件> <spec_id> <pack名称> [作者]

示例:
    luajit compile_and_update.lua "Wrath/APLs/DruidFeral.simc" "Wrath/Druid.lua" 11 "野性(黑科研)" "风雪"
    luajit compile_and_update.lua "Wrath/APLs/DruidBalance.simc" "Wrath/Druid.lua" 11 "平衡(黑科研)" "风雪"
    luajit compile_and_update.lua "Wrath/APLs 2.0/MageFire.simc" "Wrath/Mage.lua" 8 "火焰(黑科研)" "风雪"
]])
        os.exit(1)
    end

    local simc_file = arg[1]
    local lua_file = arg[2]
    local spec_id = tonumber(arg[3])
    local pack_name = arg[4]
    local author = arg[5] or "Claude"

    print("=== 编译并更新 " .. pack_name .. " ===")
    print("SIMC: " .. simc_file)
    print("LUA:  " .. lua_file)

    -- 编译
    print("\n解析 " .. simc_file .. "...")
    local lists = parse_simc_file(simc_file)
    local action_count = 0
    for name, actions in pairs(lists) do
        print("  " .. name .. ": " .. #actions .. " actions")
        action_count = action_count + #actions
    end

    local pack = create_pack(lists, spec_id, pack_name, author)
    local encoded = encode_pack(pack)
    print("\n编码完成: " .. #encoded .. " 字节")

    -- 更新
    print("\n更新 " .. lua_file .. "...")
    local count = update_lua_file(lua_file, pack_name, encoded)
    print("✓ 成功更新 " .. count .. " 处 RegisterPack")

    print("\n=== 完成 ===")
end

main()
