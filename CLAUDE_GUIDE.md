# Hekili APL 修改指南 (Claude Code)

> 最后更新: 2025-12-22
> 作者: Claude + 风雪

---

## 一、项目概述

这是 WoW WLK 怀旧服 Hekili 插件的定制版本（黑科研版），包含针对多个职业的 APL 优化。

### 目录结构
```
Hekili/
├── Wrath/
│   ├── APLs/                    # 原版 APL (simc格式)
│   │   ├── DruidFeral.simc      # 猫德
│   │   ├── DruidBalance.simc    # 平衡德
│   │   ├── WarriorFury.simc     # 狂暴战
│   │   └── WarriorArms.simc     # 武器战
│   ├── APLs 2.0/                # 自定义 APL
│   │   └── MageFire.simc        # 火法
│   ├── Druid.lua                # 德鲁伊职业定义 + RegisterPack
│   ├── Mage.lua                 # 法师职业定义 + RegisterPack
│   └── Warrior.lua              # 战士职业定义 + RegisterPack
├── Libs/                        # 依赖库
│   ├── LibStub/
│   ├── AceSerializer-3.0/
│   └── LibDeflate/
├── compile_simc.lua             # 编译工具 (simc -> pack字符串)
└── compile_and_update.lua       # 编译+自动更新工具
```

---

## 二、已完成的修改 (2025-12-22)

### 1. 火法 (MageFire)
**文件**: `Wrath/APLs 2.0/MageFire.simc`, `Wrath/Mage.lua:1979`

**修改内容**:
- 添加灼烧debuff维护逻辑（强化灼烧3点时）
- 当有术士暗影精通时不需要维护

```simc
# 灼烧debuff维护：强化灼烧天赋满3点时，debuff快掉就补灼烧（有ss暗影精通时不需要）
actions+=/scorch,if=talent.improved_scorch.rank=3&debuff.improved_scorch.remains<3&!debuff.shadow_mastery.up
```

### 2. 猫德 (DruidFeral)
**文件**: `Wrath/Druid.lua`, `Wrath/APLs/DruidFeral.simc`

**修改内容**:

**(a) 添加表达式** (`Druid.lua:319-337`):
```lua
-- 紧急咆哮：咆哮快掉且割裂也快掉时，先补低星咆哮
spec:RegisterStateExpr("emergency_roar", function()
    return buff.savage_roar.remains > 0
        and buff.savage_roar.remains < 3
        and debuff.rip.remains > 0
        and debuff.rip.remains < 6
        and combo_points.current >= 1
        and combo_points.current < 5
end)

-- 偷怒凶猛：高剩余时间时用凶猛配合猛虎偷怒
spec:RegisterStateExpr("bite_for_tiger", function()
    return combo_points.current == 5
        and cooldown.tigers_fury.up
        and buff.savage_roar.remains >= 10
        and debuff.rip.remains >= 10
        and energy.current >= 50
        and not buff.berserk.up
end)
```

**(b) APL 使用新表达式** (`DruidFeral.simc`):
```simc
# 紧急咆哮
actions.cat+=/savage_roar,if=emergency_roar

# 凶猛撕咬（添加bite_for_tiger）
actions.cat+=/ferocious_bite,if=settings.ferociousbite_enabled&!buff.clearcasting.up&(bite_at_end|bite_before_rip|bite_for_tiger)&(!buff.berserk.up|bite_during_berserk)
```

### 3. 平衡德 (DruidBalance)
**文件**: `Wrath/APLs/DruidBalance.simc`

**修改内容**:
- 注释掉月火优先级（ICC前月火DPE低，虫群流不需要）

```simc
# ICC前月火DPE低，虫群流不需要月火 by Claude 2025-12-22
# actions.fish+=/moonfire,if=!debuff.moonfire.up&variable.lunar_fish_now&debuff.moonfire.remains<3
```

### 4. 狂暴战/武器战 (Warrior)
**文件**: `Wrath/Warrior.lua`

**修改内容**:
- 英勇打击阈值从 12 改为 50（避免怒气饥饿）
- 默认怒吼从命令怒吼改为战斗怒吼

```lua
-- 默认怒吼从命令改为战斗 by Claude 2025-12-22
spec:RegisterSetting("shout_spell", "battle_shout", {

-- 英勇打击阈值从12改为50，避免怒气饥饿 by Claude 2025-12-22
spec:RegisterSetting("queueing_threshold", 50, {
```

---

## 三、如何编译和更新 Pack

### 核心概念
Hekili 的 APL 存储方式：
```
.simc 源码 → 解析 → Lua表 → AceSerializer序列化 → LibDeflate压缩 → EncodeForPrint编码 → "Hekili:xxx" 字符串
```

这个字符串存储在各职业的 `.lua` 文件的 `RegisterPack()` 调用中。**修改 .simc 文件后必须重新编译并更新 .lua 文件！**

### 方法1: 使用 compile_and_update.lua (推荐)

```bash
cd "/Applications/World of Warcraft/_classic_titan_/Interface/AddOns/Hekili"

# 编译并更新猫德
luajit compile_and_update.lua "Wrath/APLs/DruidFeral.simc" "Wrath/Druid.lua" 11 "野性(黑科研)" "风雪"

# 编译并更新平衡德
luajit compile_and_update.lua "Wrath/APLs/DruidBalance.simc" "Wrath/Druid.lua" 11 "平衡(黑科研)" "风雪"

# 编译并更新火法
luajit compile_and_update.lua "Wrath/APLs 2.0/MageFire.simc" "Wrath/Mage.lua" 8 "火焰(黑科研)" "风雪"
```

### 方法2: 使用 compile_simc.lua (手动)

```bash
# 只编译，输出pack字符串
luajit compile_simc.lua "Wrath/APLs/DruidFeral.simc" 11 "野性(黑科研)" "风雪"

# 然后手动复制输出的字符串到对应的 .lua 文件
```

### Spec ID 参考
| 职业 | Spec ID |
|------|---------|
| 德鲁伊 (全专精) | 11 |
| 法师 (火焰) | 8 |
| 战士 (全专精) | 1 |

### Pack 结构 (重要!)
正确的 pack 结构必须是：
```lua
{
    payload = {
        lists = { ... },      -- APL action lists
        spec = 11,            -- spec ID
        builtIn = false,      -- 必须是 false！
        desc = "...",
        author = "...",
        date = 20251222,
        version = 20251222
    },
    name = "野性(黑科研)",
    date = 20251222.223000,
    type = "package"
}
```

---

## 四、SIMC 语法参考

### 基本格式
```simc
actions[.list_name]+=/ability_name,key=value,key=value
```

### 常用条件
```simc
if=条件表达式          # 使用条件
cycle_targets=1        # 循环目标
max_cycle_targets=3    # 最大循环目标数
line_cd=8              # 技能冷却
use_off_gcd=1          # 非GCD技能
```

### 条件表达式语法
- 比较用单个 `=`，不是 `==`
- 布尔与用 `&`
- 布尔或用 `|`
- 布尔非用 `!`

```simc
# 正确
talent.improved_scorch.rank=3
buff.hot_streak.react
debuff.rip.remains<3
!debuff.shadow_mastery.up

# 错误
talent.improved_scorch.rank==3  # 错！用单=
```

### 常用变量
```simc
buff.xxx.up              # buff存在
buff.xxx.remains         # buff剩余时间
debuff.xxx.up            # debuff存在
debuff.xxx.remains       # debuff剩余时间
talent.xxx.enabled       # 天赋已学
talent.xxx.rank          # 天赋点数
combo_points.current     # 当前连击点
energy.current           # 当前能量
rage.current             # 当前怒气
mana.pct                 # 法力百分比
cooldown.xxx.up          # 技能CD好了
cooldown.xxx.remains     # 技能CD剩余
target.time_to_die       # 目标存活时间
active_enemies           # 敌人数量
moving                   # 是否移动中
```

---

## 五、添加新表达式

在职业 `.lua` 文件中使用 `RegisterStateExpr`:

```lua
spec:RegisterStateExpr("my_condition", function()
    return buff.xxx.up and debuff.yyy.remains < 3
end)
```

然后在 `.simc` 中使用:
```simc
actions+=/ability,if=my_condition
```

---

## 六、测试和调试

### 清除缓存
修改后必须清除 Hekili 的保存数据：
```bash
rm -f "/Applications/World of Warcraft/_classic_titan_/WTF/Account/*/SavedVariables/Hekili.lua"*
```

### 游戏内重载
```
/reload
```

### 验证 Pack 编码
```bash
luajit test_decode.lua
```

---

## 七、常见问题

### Q: 修改 .simc 后游戏内没变化？
A: 必须重新编译并更新 RegisterPack，然后删除 SavedVariables 缓存。

### Q: Hekili 界面消失了？
A: Pack 编码格式错误。检查：
1. pack 结构是否正确（必须有 payload 包装）
2. builtIn 必须是 false
3. spec ID 是否正确

### Q: 条件不生效？
A: 检查 SIMC 语法，比较用单 `=` 不是 `==`。

---

## 八、文件修改清单

| 文件 | 行号 | 修改内容 |
|------|------|----------|
| `Wrath/Druid.lua` | 319-337 | 添加 emergency_roar, bite_for_tiger 表达式 |
| `Wrath/Druid.lua` | ~3143 | 更新平衡德 RegisterPack |
| `Wrath/Druid.lua` | ~3145 | 更新野性德 RegisterPack |
| `Wrath/Mage.lua` | 1979 | 更新火法 RegisterPack |
| `Wrath/Warrior.lua` | 2166-2167 | 默认怒吼改为战斗 |
| `Wrath/Warrior.lua` | 2184-2185 | 英勇打击阈值改为50 |
| `Wrath/APLs/DruidFeral.simc` | 22-26 | 添加紧急咆哮和偷怒凶猛 |
| `Wrath/APLs/DruidBalance.simc` | 27-28 | 注释月火优先级 |
| `Wrath/APLs 2.0/MageFire.simc` | 25-26 | 添加灼烧维护 |

---

## 九、后续维护建议

1. **修改 APL 时**: 先改 .simc，再用 `compile_and_update.lua` 编译更新
2. **添加表达式时**: 在 .lua 中添加 RegisterStateExpr，然后在 .simc 中使用
3. **测试时**: 记得删除 SavedVariables 缓存
4. **备份**: 定期同步到 GitHub

---

*本文档由 Claude Code 生成，用于指导后续的 Hekili APL 开发工作。*
