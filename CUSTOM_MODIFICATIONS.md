# SuperHekili 自定义修改记录

> 基准版本: d14d332 "猫德完美版本" (v414942)
>
> 更新日期: 2025-01-01

本文件记录了 SuperHekili 相对于原版 Hekili 的所有自定义修改，方便后续合并新版本时保留这些修改。

---

## 1. Core.lua - 资源初始化修复 [关键]

**位置**: `OnInitialize()` 函数 (约第177行)

**修改**:
```lua
-- 在 self:RestoreDefaults() 前添加：
-- 先调用 SpecializationChanged 以填充 class.packs，然后再调用 RestoreDefaults
self:SpecializationChanged()
self:RestoreDefaults()
```

**原因**: 确保职业资源(mana/energy等)在选项面板访问前正确初始化，防止 `mana.max nil` 错误

---

## 2. Options.lua - 技能/装备搜索功能

**位置**: `EmbedAbilityOptions()` 和 `EmbedItemOptions()` 函数

**修改内容**:

### 2.1 搜索过滤函数 (约第4450行)
```lua
-- 搜索过滤辅助函数
local function matchesSearchFilter( name, key, filter )
    if not filter or filter == "" then return true end

    local lowerFilter = filter:lower()
    local lowerName = name and name:lower() or ""
    local lowerKey = key and key:lower() or ""

    -- 模糊搜索：检查名称是否包含搜索词
    if lowerName:find( lowerFilter, 1, true ) then return true end
    -- 精确搜索：检查key是否包含搜索词
    if lowerKey:find( lowerFilter, 1, true ) then return true end

    return false
end
```

### 2.2 搜索框UI (在技能选项中)
- `searchHeader` - 搜索标题
- `searchBox` - 搜索输入框
- `searchCount` - 搜索结果计数

### 2.3 Settings表保护 (约第5760行)
```lua
-- 确保 settings 表存在
if specProf and not specProf.settings then
    specProf.settings = {}
end
```

---

## 3. Events.lua - 事件节流优化

**位置**: 文件开头和事件处理函数

**修改内容**:

### 3.1 事件优化配置 (约第37行)
```lua
-- 泰坦重铸版事件优化配置
local EventOptimization = {
    -- 事件节流配置（秒）
    throttle = {
        UNIT_AURA = 0.05,           -- 光环更新节流
        UNIT_POWER_UPDATE = 0.03,   -- 能量更新节流
        UNIT_HEALTH = 0.1,          -- 生命值更新节流
        COMBAT_LOG_EVENT_UNFILTERED = 0.01, -- 战斗日志节流
    },
    lastProcess = {},
    batchQueue = {},
    batchInterval = 0.05,
    lastBatch = 0,
    enabled = true,
}
ns.EventOptimization = EventOptimization
```

### 3.2 节流检查函数
```lua
local function ShouldThrottleEvent( event )
    if not EventOptimization.enabled then return false end

    local throttleTime = EventOptimization.throttle[ event ]
    if not throttleTime then return false end

    local now = GetTime()
    local lastTime = EventOptimization.lastProcess[ event ] or 0

    if now - lastTime < throttleTime then
        return true
    end

    EventOptimization.lastProcess[ event ] = now
    return false
end
```

### 3.3 在事件处理函数中调用节流检查
```lua
-- GenericOnEvent 和 UnitSpecificOnEvent 函数开头添加：
if ShouldThrottleEvent( event ) then return end
```

---

## 4. Classes.lua - 清理无效引用

**位置**: `RestoreDefaults()` 函数

**修改内容**:

### 4.1 总是加载脚本 (约第1048行)
```lua
-- 总是加载脚本，确保技能显示正常
self:LoadScripts()
```

### 4.2 清理无效优先级包引用
```lua
-- 清理无效的优先级选择器引用（在内置包加载完成之后）
self:CleanupInvalidAutoPacks()
```

### 4.3 CleanupInvalidAutoPacks 函数 (约第1100行)
```lua
function Hekili:CleanupInvalidAutoPacks()
    local p = self.DB.profile
    if not p or not p.specs then return end

    local packs = p.packs or {}

    for specID, specData in pairs( p.specs ) do
        if specData and specData.autoPacks then
            for selectorKey, packName in pairs( specData.autoPacks ) do
                if packName and packName ~= "none" and packName ~= "无" then
                    if not rawget( packs, packName ) then
                        specData.autoPacks[ selectorKey ] = "none"
                    end
                end
            end
        end
    end
end
```

---

## 5. Targets.lua - 安全区域检查

**位置**: 目标检测循环

**修改内容**:

### 5.1 安全区域检测函数 (约第340行)
```lua
local function IsInSafeArea()
    if IsInInstance() then return false end
    if IsResting() then return true end

    local pvpType = GetZonePVPInfo()
    if pvpType == "sanctuary" then return true end

    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local cityMaps = {
            [84] = true, [85] = true, [87] = true, [88] = true,
            [89] = true, [90] = true, [103] = true, [110] = true,
            [111] = true, [125] = true, [627] = true, [1670] = true,
        }
        if cityMaps[mapID] then return true end
    end

    return false
end
```

### 5.2 战斗状态检查
```lua
local inSafeArea = IsInSafeArea()
local playerInCombat = UnitAffectingCombat("player")
local shouldCheckCombat = not inSafeArea and playerInCombat

-- 在目标循环中：
if shouldCheckCombat then
    local unitInCombat = UnitAffectingCombat(unit)
    local threatStatus = UnitThreatSituation("player", unit)
    combatCheck = unitInCombat or (threatStatus and threatStatus > 0)
end
```

---

## 6. Wrath/Druid.lua - 猫德白皮书优化

**位置**: StateExpr 注册区域

### 6.1 should_rake 斜掠优先 (约第285行)
```lua
spec:RegisterStateExpr("should_rake", function()
    -- 如果勾选了"斜掠优先"，始终打斜掠（适合P1/P2或手动控制）
    if settings.rake_priority then
        return true
    end
    -- 否则只在有2T9或4T10时打（白皮书：无套装时斜掠移出循环）
    return set_bonus.tier9feral_2pc == 1 or set_bonus.tier10feral_4pc == 1
end)
```

### 6.2 should_bite 能量限制 (约第315行)
```lua
-- 在 should_bite 函数中添加能量限制：
return buff.berserk.up and energy.current <= settings.max_bite_energy
-- 或
return energy.current <= 67
```

### 6.3 emergency_roar 紧急咆哮 (约第324行)
```lua
spec:RegisterStateExpr("emergency_roar", function()
    -- 紧急咆哮条件（保持offset不同步）：
    -- 1. 咆哮快掉(<3秒)
    -- 2. 割裂还有时间（比咆哮多至少3秒，说明还没同步）
    -- 3. 有连击点但不够5星
    return buff.savage_roar.remains > 0
        and buff.savage_roar.remains < 3
        and debuff.rip.remains > buff.savage_roar.remains + 3
        and combo_points.current >= 1
        and combo_points.current < 5
end)
```

### 6.4 bite_for_tiger 偷怒凶猛 (约第336行)
```lua
spec:RegisterStateExpr("bite_for_tiger", function()
    -- 偷怒凶猛条件：
    -- 1. 5星连击点
    -- 2. 猛虎CD好了
    -- 3. 咆哮安全(>10秒)
    -- 4. 割裂安全(>10秒)
    -- 5. 能量在50-67之间（打完撕咬后能接猛虎）
    -- 6. 非狂暴期间
    return combo_points.current == 5
        and cooldown.tigers_fury.ready
        and buff.savage_roar.remains >= 10
        and debuff.rip.remains >= 10
        and energy.current >= 50
        and energy.current <= 67
        and not buff.berserk.up
end)
```

---

## 7. Wrath/APLs/DruidFeral.simc - APL优化

### 7.1 撕碎 excess_e 条件 (第30行)
```simc
actions.cat+=/shred,if=!wait_for_ff&(excess_e>=action.shred.spend|buff.clearcasting.up|buff.berserk.up|(cooldown.faerie_fire_feral.remains<=1&energy.current>77|energy.current=100))
```
注意：删除了无条件的 `actions.cat+=/shred`

### 7.2 斜掠清晰预兆处理 (第25-26行)
```simc
actions.cat+=/rake,if=buff.clearcasting.up&!debuff.bleed.up&ttd>9
actions.cat+=/rake,if=!debuff.rake.up&!buff.clearcasting.up&(should_rake|!debuff.bleed.up)&ttd>9&!wait_for_ff
```

### 7.3 AOE idol神像判断 (第35-37行)
```simc
actions.cat_aoe+=/mangle_cat,if=(set_bonus.idol_of_the_corruptor=1|set_bonus.idol_of_mutilation=1)&combo_points.current=0&buff.savage_roar.remains<=1
actions.cat_aoe+=/shred,if=set_bonus.idol_of_mutilation=1&combo_points.current=0&buff.savage_roar.remains<=1&(ttd>buff.savage_roar.remains+1+latency)
actions.cat_aoe+=/rake,if=!set_bonus.idol_of_mutilation=1&combo_points.current=0&buff.savage_roar.remains<=1&(ttd>buff.savage_roar.remains+1+latency)
```

### 7.4 AOE swipe excess_e (第38行)
```simc
actions.cat_aoe+=/swipe_cat,if=excess_e>=action.swipe_cat.spend|buff.clearcasting.up
```

---

## 合并新版本指南

当需要合并原版 Hekili 更新时：

1. **不要直接同步覆盖**，使用 `git diff` 查看变更
2. **优先保留上述修改**，特别是 Core.lua 的 SpecializationChanged 调用
3. **逐个文件合并**，测试每个修改是否兼容
4. **测试清单**:
   - [ ] 打开选项面板无报错
   - [ ] 猫德循环正常
   - [ ] 搜索功能正常
   - [ ] 主城不误判目标
