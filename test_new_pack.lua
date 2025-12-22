#!/usr/bin/env luajit
-- 测试新生成的pack字符串

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
local HEKILI_PATH = script_path:match("(.*/)")
if not HEKILI_PATH then HEKILI_PATH = "./" end

dofile(HEKILI_PATH .. "Libs/LibStub/LibStub.lua")
local LibStub = _G.LibStub

dofile(HEKILI_PATH .. "Libs/AceSerializer-3.0/AceSerializer-3.0.lua")
local AceSerializer = LibStub("AceSerializer-3.0")

dofile(HEKILI_PATH .. "Libs/LibDeflate/LibDeflate.lua")
local LibDeflate = LibStub("LibDeflate")

local function decode_pack(encoded_string)
    local data = encoded_string:match("^Hekili:(.+)$")
    if not data then return nil, "Invalid format" end
    local decoded = LibDeflate:DecodeForPrint(data)
    if not decoded then return nil, "DecodeForPrint failed" end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "DecompressDeflate failed" end
    local success, result = AceSerializer:Deserialize(decompressed)
    if not success then return nil, "Deserialize failed" end
    return result
end

-- 新生成的pack
local new_pack = [[Hekili:nw1pVrnmu8plSubdnQjhTuKGoqNyPlHz77fNxUZQo2bBN746WjHeZivj2ybjgqcwyNpqN63cE2xVCj0MsxA9z)79793FVWszVJL3aRugOmC0zATcKLZYlALk)B1Sc6YguWU4KjS85YYsmExj6eS8Zn1nsfwUEAL1uVEAItwlwpTy16PNRG2sC9uJE90SJYo(W0SdZYiNznvKjbxSeSAPEMlCgA9Znww(nF)Z381Fs8dEKDrWW0SGzkPZ7criyq6FxedCq4LgnfRkW55lHfeTOgkOiI9gwUWk9OvcSCpyNH(KLs)CPo9iMNOoqWEefTvvjvsl6iS0DjTn75Vsb10dw5LdDGsQrUOKDXPbgN0pKkTWmJ2XlSi4N)OcRSajppqspW7tr5vxb2scJpu9RGwLVRqCpgimTAYnuVtP6Y3DpgV15rqDV5tV35cJrvAwQ7YW7Xx1sR1y5YAyg(qjHWux06INjuhpckPyfFbk1UaOtgbuSLWfqta0lgbuJzNVoDeeToKtDJ6OVEzCKyLqH8TDgxO8E3(LxsU2B4Ls8S0SdkX4WJsUGgM5fuoMelyDoP3ldcIA4d8HURp0DjhnUoysnW6cKJASwIUZY6vEbLIV9h8GEzGZ0u9AR6jW5a5tZkRjkHgzmnMEZnEojbq4Ye6pcFKMSXMwj1cVg0aFFliDG(WInkulDZJWgXXHNsAe(x9IOKn959zaxyeWThFqJNS14J7BCqPZFOCU2eAerdpzGHwJZV1AJAmJNPw1mpPdAYoqb2gBwnaSaIAvFyljgelG)o76aRaivAHvQusqlgBLNfKLhe7C3XIKD65S7HyjT1qPqXy52t(Fep4To2sgSdPBXbvdrnhS1HD)Jp81QLVVf3IRJPbtdvgrRJMLMjfJ1uSM2MdUv9uA8j9m51h1Tq6rlkmoxSxrawq7zdgT)7v0L(vny4BRIldBf)NpOLKLn5KJs3jl38XFT5t)(P38NR38JR38TV8mIa2F)d]]

print("=" .. string.rep("=", 59))
print("测试新生成的pack")
print("=" .. string.rep("=", 59))

local result = decode_pack(new_pack)
if result then
    print("✓ 解码成功!\n")
    print("顶层结构:")
    for k, v in pairs(result) do
        if type(v) == "table" then
            print("  " .. k .. " = { ... }")
        else
            print("  " .. k .. " = " .. tostring(v))
        end
    end

    if result.payload then
        print("\npayload 结构:")
        for k, v in pairs(result.payload) do
            if type(v) == "table" then
                if k == "lists" then
                    print("  lists = {")
                    for listName, actions in pairs(v) do
                        print("    " .. listName .. ": " .. #actions .. " actions")
                    end
                    print("  }")
                else
                    print("  " .. k .. " = { ... }")
                end
            else
                print("  " .. k .. " = " .. tostring(v))
            end
        end
    end
else
    print("✗ 解码失败!")
end

print("\n" .. "=" .. string.rep("=", 59))
