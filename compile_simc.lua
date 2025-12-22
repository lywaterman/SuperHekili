#!/usr/bin/env luajit
--[[
    Hekili SIMC Compiler - 编译 .simc 文件为 RegisterPack 格式
    使用 Hekili 原生库 (AceSerializer, LibDeflate) 确保 100% 兼容

    用法:
        luajit compile_simc.lua <input.simc> [spec_id] [pack_name]

    示例:
        luajit compile_simc.lua "Wrath/APLs 2.0/MageFire.simc" 63 "火焰(黑科研)"
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

-- 获取脚本目录
local script_path = arg[0]
local HEKILI_PATH = script_path:match("(.*/)")
if not HEKILI_PATH then HEKILI_PATH = "./" end

-- 加载 LibStub
dofile(HEKILI_PATH .. "Libs/LibStub/LibStub.lua")
local LibStub = _G.LibStub

-- 加载 AceSerializer
dofile(HEKILI_PATH .. "Libs/AceSerializer-3.0/AceSerializer-3.0.lua")
local AceSerializer = LibStub("AceSerializer-3.0")

-- 加载 LibDeflate
dofile(HEKILI_PATH .. "Libs/LibDeflate/LibDeflate.lua")
local LibDeflate = LibStub("LibDeflate")

-- ============================================================================
-- SIMC 解析器
-- ============================================================================
local function parse_simc_line(line)
    -- 移除注释
    local comment = nil
    local hash_pos = line:find("#")
    if hash_pos then
        comment = line:sub(hash_pos + 1):match("^%s*(.-)%s*$")
        line = line:sub(1, hash_pos - 1):match("^%s*(.-)%s*$")
    end

    if not line or line == "" then
        return nil, comment
    end

    -- 解析 action 行: actions[.list]+=/ability,key=value,key=value
    local list_name, action_str = line:match("^actions%.?([%w_]*)%+?=/(.+)$")
    if not action_str then
        return nil, comment
    end

    list_name = (list_name == "" or not list_name) and "default" or list_name

    -- 按逗号分割，处理括号
    local parts = {}
    local current = {}
    local depth = 0
    for i = 1, #action_str do
        local ch = action_str:sub(i, i)
        if ch == "(" then
            depth = depth + 1
            table.insert(current, ch)
        elseif ch == ")" then
            depth = depth - 1
            table.insert(current, ch)
        elseif ch == "," and depth == 0 then
            table.insert(parts, table.concat(current))
            current = {}
        else
            table.insert(current, ch)
        end
    end
    if #current > 0 then
        table.insert(parts, table.concat(current))
    end

    if #parts == 0 then
        return nil, comment
    end

    -- 第一部分是 action 名称
    local action_name = parts[1]:match("^%s*(.-)%s*$")

    local result = {
        action = action_name,
        enabled = true,
    }

    -- 解析 key=value 对
    for i = 2, #parts do
        local part = parts[i]
        local eq_pos = part:find("=")
        if eq_pos then
            local key = part:sub(1, eq_pos - 1):match("^%s*(.-)%s*$")
            local value = part:sub(eq_pos + 1):match("^%s*(.-)%s*$")

            -- 重命名 'if' 为 'criteria'
            if key == "if" or key == "condition" then
                key = "criteria"
            end

            -- 转换数值
            local num_keys = {
                for_next = true, cycle_targets = true, max_energy = true,
                use_off_gcd = true, use_while_casting = true, strict = true,
                moving = true, max_cycle_targets = true, line_cd = true
            }
            if num_keys[key] then
                local num = tonumber(value)
                if num then value = num end
            end

            result[key] = value
        end
    end

    -- 从注释添加描述
    if comment and comment ~= "" then
        result.description = comment:gsub(",", ";")
    end

    return {list_name, result}, comment
end

local function parse_simc_file(filepath)
    local lists = {}

    local file = io.open(filepath, "r")
    if not file then
        error("Cannot open file: " .. filepath)
    end

    local content = file:read("*all")
    file:close()

    for line in content:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            local parsed, _ = parse_simc_line(line)
            if parsed then
                local list_name, action = parsed[1], parsed[2]
                if not lists[list_name] then
                    lists[list_name] = {}
                end
                table.insert(lists[list_name], action)
            end
        end
    end

    -- 确保 default 和 precombat 存在
    if not lists["default"] then lists["default"] = {} end
    if not lists["precombat"] then lists["precombat"] = {} end

    return lists
end

-- ============================================================================
-- Pack 创建 - 使用正确的结构!
-- ============================================================================
local function create_pack(lists, spec_id, pack_name, author)
    local date_num = tonumber(os.date("%Y%m%d"))
    local full_timestamp = tonumber(os.date("%Y%m%d.%H%M%S"))

    -- 正确的 Hekili pack 结构
    return {
        payload = {
            source = "",
            lists = lists,
            builtIn = false,  -- 不是 true!
            spec = spec_id,
            hidden = false,
            desc = "Compiled from .simc by Claude on " .. os.date("%Y-%m-%d"),
            date = date_num,
            author = author or "Claude",
            profile = "",
            warnings = "",
            version = date_num
        },
        name = pack_name,
        date = full_timestamp,
        type = "package"
    }
end

-- ============================================================================
-- 主函数
-- ============================================================================
local function main()
    if #arg < 1 then
        print([[
Hekili SIMC Compiler - 编译 .simc 文件为 RegisterPack 格式

用法:
    luajit compile_simc.lua <input.simc> [spec_id] [pack_name] [author]

示例:
    luajit compile_simc.lua "Wrath/APLs 2.0/MageFire.simc" 63 "火焰(黑科研)" "风雪"
]])
        os.exit(1)
    end

    local input_file = arg[1]
    local spec_id = tonumber(arg[2]) or 8
    local pack_name = arg[3] or "Custom Pack"
    local author = arg[4] or "Claude"

    print("解析 " .. input_file .. "...")
    local lists = parse_simc_file(input_file)

    print("找到的 action lists:")
    for name, actions in pairs(lists) do
        print("  - " .. name .. ": " .. #actions .. " 个 actions")
    end

    local pack = create_pack(lists, spec_id, pack_name, author)

    print("序列化...")
    local serialized = AceSerializer:Serialize(pack)
    print("序列化长度: " .. #serialized .. " 字节")

    print("压缩...")
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 5})
    print("压缩后长度: " .. #compressed .. " 字节")

    print("编码...")
    local encoded = LibDeflate:EncodeForPrint(compressed)
    local result = "Hekili:" .. encoded
    print("编码后长度: " .. #result .. " 字节")

    print("")
    print(string.rep("=", 60))
    print("编码后的 PACK 字符串 (复制到 RegisterPack):")
    print(string.rep("=", 60))
    print("[[" .. result .. "]]")
    print(string.rep("=", 60))

    -- 验证：尝试解码
    print("\n验证解码...")
    local data = result:match("^Hekili:(.+)$")
    local decoded = LibDeflate:DecodeForPrint(data)
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    local success, decoded_pack = AceSerializer:Deserialize(decompressed)
    if success then
        print("✓ 验证成功! Pack 名称: " .. tostring(decoded_pack.name))
    else
        print("✗ 验证失败!")
    end

    -- 保存到文件
    local output_file = input_file:gsub("%.simc$", "_compiled.txt")
    local out = io.open(output_file, "w")
    if out then
        out:write("-- Pack: " .. pack_name .. "\n")
        out:write("-- Spec ID: " .. spec_id .. "\n")
        out:write("-- Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        out:write("-- Source: " .. input_file .. "\n")
        out:write("\n")
        out:write('spec:RegisterPack( "' .. pack_name .. '", ' .. os.date("%Y%m%d") .. ', [[' .. result .. ']] )\n')
        out:close()
        print("\n保存到: " .. output_file)
    end
end

main()
