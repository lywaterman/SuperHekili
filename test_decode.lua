#!/usr/bin/env luajit
--[[
    Hekili Pack 解码测试脚本
    用于验证pack字符串的编码格式是否正确
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
-- 解码函数
-- ============================================================================
local function decode_pack(encoded_string)
    -- 去掉 "Hekili:" 前缀
    local data = encoded_string:match("^Hekili:(.+)$")
    if not data then
        return nil, "Invalid format: missing 'Hekili:' prefix"
    end

    print("Step 1: Removed prefix, data length = " .. #data)

    -- Step 2: DecodeForPrint
    local decoded = LibDeflate:DecodeForPrint(data)
    if not decoded then
        return nil, "DecodeForPrint failed"
    end
    print("Step 2: DecodeForPrint success, length = " .. #decoded)

    -- Step 3: DecompressDeflate
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return nil, "DecompressDeflate failed"
    end
    print("Step 3: DecompressDeflate success, length = " .. #decompressed)

    -- Step 4: Deserialize
    local success, result = AceSerializer:Deserialize(decompressed)
    if not success then
        return nil, "Deserialize failed: " .. tostring(result)
    end
    print("Step 4: Deserialize success")

    return result
end

-- ============================================================================
-- 打印表格内容
-- ============================================================================
local function print_table(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)

    if type(t) ~= "table" then
        print(prefix .. tostring(t))
        return
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. " = {")
            if indent < 2 then  -- 限制深度
                print_table(v, indent + 1)
            else
                print(prefix .. "  ... (深层内容省略)")
            end
            print(prefix .. "}")
        else
            local val = tostring(v)
            if #val > 60 then val = val:sub(1, 60) .. "..." end
            print(prefix .. tostring(k) .. " = " .. val)
        end
    end
end

-- ============================================================================
-- 主测试
-- ============================================================================
print("=" .. string.rep("=", 59))
print("Hekili Pack 解码测试")
print("=" .. string.rep("=", 59))

-- 原始火法pack字符串
local original_pack = [[Hekili:DEvtVnory4FlCH2kKSAs6xGaKGlOUcLd4UIBE8y7jXJQ9mUZmUHShSkArIpoSIkT329asCyflibCzVSc(ZS0nQ)l49DCs84M4KcQsnPZ8opVFmpVpVtd6fCwGFc1Wcg2F)(hU)j933RxVd2VxVaFZ0cwGFbn(C6y4lcAo87zF9Vo7B(JDV91xp7fxp7NE6EOftZK0eejTSufdwf4hvYZmNkcIAb)XdaC1fS4GHNe4NYtsy1MW0Xb(V95)2n)9lN9KFF2t)ZAhCZp8mWhZ(Lx92V)Q3C1pE7p)KBF2lFZvxFZ39Q)5VEEvydOfk5iEM11xYuAUu46YjuLGlgRd8)Yp5lgE6Wp7dQcRcplLvfYZlKktv4iPQkCNe2iAzMzNQqf7IsUILufQL5GD0sJmhYeyH4uQymt7v9GpNlGTocq7HcDzbIeAan2abaa3OmOOrIPf7agx9GtZxyXGgJY4AdIvGp4IuPkWVond8T7GL1(N1BF4ZH9w8ltGptqJYyjbFAGFSIBykonWF3ewu5OrEz8lH0LejZJ8uSCkxORc)yisRcX0CnwLiNi2Rk8DRc31UxrPof30KYiz8CUPfo7gt1gIHJfM3ldQkI4PWPDbiLrniaLfwSRD8kBvwyps9YsdrBum65ZpbIiuvS1Pa)rWTrenlds(H9xFHyHPftvYOmieDRn3txxwaGAqkPLjSHYEPMrMKcKocwnaurJwgdcUrjHAReVdT2khnImooXAvtyb(bHWqvJzgcxtGUS5z4sSILLcWCOXbsFNqaSBaA3AkbwB1ggnd5rcigtCxKelLzyvgX4GoWiNRusfHNB7)Dc55N7WURlU5AtwKhvQN)9wGvtB2o39(WERPyxustGCuXADndjcpMKqXeIWfXWfUgTypx2zZrx69pSk84THY8qaXzdw5MqhwBD9npYmZmPEfXgR)gC0Eyj(ixAapEk5sgC87Wbo21OLso3XOtCnQqw)zllE)oOb49jCBLRR1Pv8I61FOgLfftHuqXfNZmqAzsPq8tvmXoWNsq9qnHJ2HI(8rCwIh6kRCMRVAbmqpMgVSNqBjr50VI0EvFhcqD(UiGD2WLPnVqJQweJKKWz2RHE9TxTDWQSrBp3OnYHrdYrK6)GGI1UEdx(sgHjy5Cw9fE)AjDs9KuQ02O3RdTSwvKzF7JN94xGb49Z52uPPFdf1CDTtNigbd22yLv1i3w3qtRZUlM05Tqa3BndpAP03iFJr3bBwRFRLHvNKDNQHD6k6Pd7ObydJtUZCJH9oQdmWKNSci5sKTzp4XDDqfmbP(0YSwhEC20IuVL77T4WiANSHWWoe1bN65DfkgslOlN41jz0NvaQbrmL99xdAaNQIPWKMifplJtfXTgAOO8KgwZkMUSzRFhr(8tWHbHzzS4wvI3bEU29a(v2Fjyl9ExJtZHAptqOQC8bA3Hfuk4xuYQ30BBdvhjJlHH8yxtRltLCEx1CHJePXZX2QWpQkC)6Rku5ynxsl8GLLrMqVKTg1VjCd0nut47QuBhHa0A(5SvYvKaPbSG1M3hn)TfNSPYxIIowk0Wfc8(R0UdR(lRCnjd)rpIQsApRY0sdR7NOTaLu4FLbF(elbKkIzzmfTz2MZBv6(PL)FEh5AF669uS9)e(Tem7qVCJkxRhj333TQas77J6Fc(3p]]

print("\n测试原始火法pack字符串:")
print("-" .. string.rep("-", 59))

local result, err = decode_pack(original_pack)
if result then
    print("\n✓ 解码成功!")
    print("\nPack 内容:")
    print_table(result)
else
    print("\n✗ 解码失败: " .. tostring(err))
end

print("\n" .. "=" .. string.rep("=", 59))
