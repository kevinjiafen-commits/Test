--[[
    GRAVITON — Ragebot 完整提取
    來源: graviton_final-2_lua.txt
    模組清單:
      jv  — DirectionToOrientation 工具
      jy  — RiotShield 朝向偵測 (GetShieldSide)
      jz  — 防禦 CFrame / ViewAngles 計算器
      jA  — ShootLock (射擊節奏鎖)
      jB  — TargetSelection (目標篩選 — Hacker 優先)
      jC  — LookAt CFrame 工具
      jD  — HitscanStrategy (霰彈/步槍射擊編碼)
      jE  — MeleeStrategy  (近戰攻擊編碼 / 刀後刺)
      jF  — 隨機 CFrame 採樣器 (亂數橢圓環)
      jG  — 表面法線計算器 (ProjectileBreaker 用)
      jH  — ProjectileBreakerTeleport (彈射破壞傳送)
      jI  — Random 閃避傳送計算器
      jJ  — SpatialLimitGate (OOB 穩定性閘門)
      jK  — Translocate 傳送計算器
      jL  — 安全環坐標生成器 (Normal / Immune 環)
      jM  — WeaponActionSelector (武器輪換 / 換彈邏輯)
      jN  — RiotShieldState 偵測器
      jO  — Ragebot 主控制器 (Update / Plan / EvadePlan / ApplyPlan)
             包含 VoidSpam / HarionVoid / OrbitDesync / Translocate 後端
    
    依賴 (需保留在外部環境):
      v86[]  — 混淆常數表 (原腳本全域)
      v102() — getupvalue 式欄位存取
      v107() — FastFlag 設定器
      v108   — DFIntFlags 儲存
      v112() — workspace 屬性覆蓋
      tbl17  — 模組緩存/路由表 (原腳本全域)
      flag2  — 伺服器/客戶端環境旗標
      flag3  — Immune 環啟用旗標
    
    使用方式:
      local Ragebot = tbl17.jO()          -- 取得主控制器類別
      local rb = Ragebot.new(
          fighters,       -- EnemyByPlayer + StateByPlayer
          playerTags,     -- Hacker 標籤表
          playerContext,  -- 本地 context
          stateHook,      -- IsCrouching 注入器
          partGlue        -- PartGlue 工具
      )
      RunService.Heartbeat:Connect(function(dt)
          rb:Update(dt)
      end)
      rb:Destroy()   -- 清理
--]]

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jv — DirectionToOrientation
-- ════════════════════════════════════════════════════════════════════════════
local OrientationUtils
do
    local tbl18
    tbl18 = {
        DirectionToOrientation = function(l)
            local I, W = CFrame.lookAt(Vector3.zero, l):ToOrientation()
            return I, W
        end,
        OrientationLookingAt = function(I, W)
            return tbl18.DirectionToOrientation(W - I)
        end,
    }
    OrientationUtils = tbl18
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jy — GetShieldSide (Riot Shield 朝向)
-- ════════════════════════════════════════════════════════════════════════════
local function GetShieldSide(fighterState)
    local itemObserver = fighterState.ItemObserver
    local equippedItem = itemObserver:GetEquippedItem()

    if equippedItem ~= nil and equippedItem.Name == "Riot Shield" then
        local deg = math.deg(fighterState:GetCameraRotation().X)
        if deg > 22 and deg < 91 then
            return "Below"
        end
        return "Above"
    end

    for _, item in itemObserver:GetItems() do
        if item.Name == "Riot Shield" then
            local deg = math.deg(fighterState:GetCameraRotation().X)
            if (deg > 315 and deg < 360) or (deg > 0 and deg < 91) then
                return "Above"
            end
            return "Below"
        end
    end

    return nil  -- v86[75] = nil/無盾
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jz — DefenseCFrame / DefensiveViewAngles
-- ════════════════════════════════════════════════════════════════════════════
local DefenseCalc
do
    local rng = Random.new()
    DefenseCalc = {
        -- 根據盾牌狀態計算防禦 CFrame
        -- arg  : serverCFrame (傳送後的位置 CFrame)
        -- shield : "Equipped" | "Unequipped" | "None"
        -- fighterState : 目標的 FighterState
        -- rootPart : 目標的 RootPart
        getDefensiveCFrame = function(serverCF, shield, fighterState, rootPart)
            if shield == "Equipped" then
                return CFrame.new(serverCF.Position, rootPart.Position)
            end
            if shield == "Unequipped" then
                return CFrame.new(
                    serverCF.Position,
                    serverCF.Position + serverCF.Position - rootPart.Position
                )
            end
            local melee = fighterState.ItemObserver:EquippedItemAsMelee()
            if melee ~= nil and melee.Name == "Knife" then
                local cfOri = CFrame.fromOrientation
                local nxt   = rng.NextNumber
                local tau   = math.tau
                return CFrame.new(serverCF.Position)
                    * cfOri(
                        rng:NextNumber(0, tau),
                        rng:NextNumber(0, tau),
                        nxt(rng, 0, tau)
                    )
            end
            return serverCF
        end,

        -- 返回防禦 ViewAngles 表，或 nil（無盾時不送）
        getDefensiveViewAngles = function(shield, fighterState)
            if shield == "None" then
                return nil
            end
            local shieldSide = GetShieldSide(fighterState)
            return {
                Kind  = "Normalized",
                Pitch = (shield == "Equipped") ~= (shieldSide ~= "Below") and 90 or -90,
                Yaw   = rng:NextNumber(0, 360),
            }
        end,
    }
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jA — ShootLock (射擊節奏鎖)
-- ════════════════════════════════════════════════════════════════════════════
local ShootLock = {}
ShootLock.__index = ShootLock

function ShootLock.new()
    return setmetatable({}, ShootLock)
end

-- arg   : 是否本幀應火
-- frames: shootFrames 倍數 (秒)
-- 返回 true 表示「本幀應射擊或在鎖定窗口內」
function ShootLock:ShouldFire(shouldFire, frames)
    local now = os.clock()
    local locked = self._lockedUntil ~= nil and now < self._lockedUntil
    if shouldFire then
        self._lockedUntil = now + frames
    end
    return locked or shouldFire
end

function ShootLock:Reset()
    self._lockedUntil = nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jB — TargetSelection (Ragebot 目標選擇器)
-- ════════════════════════════════════════════════════════════════════════════
local TargetSelection = {}
TargetSelection.__index = TargetSelection

-- fighters   : { EnemyByPlayer={}, StateByPlayer={} }
-- playerTags : { GetPlayersWith(tag)={}, Has(player,tag)=bool }
-- Data       : v115.Data (需含 Data.Ragebot.PrioritizeHackers)
function TargetSelection.new(fighters, playerTags, Data)
    return setmetatable({
        _fighters   = fighters,
        _playerTags = playerTags,
        _Data       = Data,
    }, TargetSelection)
end

local function _isValidTarget(fs)
    if not fs.IsEnemy or fs:IsInvincible() then return false end
    if not fs.Character.State.Alive then return false end
    local melee = fs.ItemObserver:EquippedItemAsMelee()
    if melee ~= nil and melee:IsDeflecting() then return false end
    return true
end

local function _wrap(fs)
    return { FighterState = fs, AliveState = fs.Character.State }
end

function TargetSelection:GetTarget()
    local prioritize = self._Data.Ragebot.PrioritizeHackers
    local fighters   = self._fighters
    local tags       = self._playerTags

    if prioritize then
        for _, plr in tags:GetPlayersWith("Hacker") do
            local fs = fighters.StateByPlayer[plr]
            if fs ~= nil and _isValidTarget(fs) then
                return _wrap(fs)
            end
        end
    end

    for plr, fs in fighters.EnemyByPlayer do
        if prioritize and tags:Has(plr, "Hacker") then
            continue
        end
        if _isValidTarget(fs) then
            return _wrap(fs)
        end
    end

    return nil
end

function TargetSelection:HasTargets()
    for _, fs in self._fighters.EnemyByPlayer do
        if _isValidTarget(fs) then return true end
    end
    return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jC — LevelLookAt CFrame 工具
-- ════════════════════════════════════════════════════════════════════════════
local DOWN  = Vector3.new(0, -1, 0)
local BACK  = Vector3.new(0,  0, -1)

local function LevelLookAt(from, to)
    local n = to - from
    local flat = Vector3.new(n.X, 0, n.Z)
    if flat.Magnitude < 0.001 then
        flat = BACK
    end
    return CFrame.lookAt(from, from + flat, DOWN)
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jD — HitscanStrategy (槍械射擊編碼)
-- ════════════════════════════════════════════════════════════════════════════
local HitscanStrategy = {}
HitscanStrategy.__index = HitscanStrategy

-- 編碼參數 (原腳本 tbl18~tbl22 — 為霰彈/AR 的 ShootEncoded 參數)
local HS_UP_ENCODE    = { ["\0"]=-9e37, ["\1"]=0,         ["\2"]=0, ["\3"]=-1.5707963267948966, ["\4"]=math.pi, ["\5"]=math.pi }
local HS_UP_DIR       = { ["\0"]=0,     ["\1"]=-90000000,  ["\2"]=0, ["\3"]=-1.5707963267948966, ["\4"]=math.pi, ["\5"]=math.pi }
local HS_DOWN_ENCODE  = { ["\0"]=-9e37, ["\1"]=0,          ["\2"]=1, ["\3"]=1.5707963267948966,  ["\4"]=math.pi, ["\5"]=math.pi }
local HS_DOWN_DIR     = { ["\0"]=0,     ["\1"]=90000000,   ["\2"]=1, ["\3"]=1.5707963267948966,  ["\4"]=math.pi, ["\5"]=math.pi }
local HS_TPOSE        = { ["\0"]=0, ["\1"]=1, ["\2"]=1, ["\3"]=1, ["\4"]=0, ["\5"]=0 }

-- offsetAbove/Below — 頭部命中偏移
local HS_OFFSET_ABOVE = Vector3.new(0, -0.7,  0.05)
local HS_OFFSET_BELOW = Vector3.new(0, -3.85, 0.05)

-- partGlue : 原腳本 PartGlue 工具 (Acquire/Free)
function HitscanStrategy.new(partGlue)
    return setmetatable({
        _partGlue  = partGlue,
        _shootLock = ShootLock.new(),
    }, HitscanStrategy)
end

-- arg2  : shootFrames (from Data.Ragebot.ShootFrames)
-- target: { FighterState, AliveState }
-- gun   : 已裝備的 Gun 行為物件
-- ourPart : 本地 RootPart (glue 錨點)
-- flag19  : 是否在 SpatialLimit 外 (可射擊)
-- 返回 aimCFrame, weaponActionFn
function HitscanStrategy:Plan(shootFrames, target, gun, ourPart, flag19)
    local hitboxHead = target.AliveState.HitboxHead
    local shieldSide = GetShieldSide(target.FighterState)
    local above      = shieldSide ~= "Below"
    local offset     = above and HS_OFFSET_ABOVE or HS_OFFSET_BELOW
    local glued      = self._partGlue:Acquire(ourPart, hitboxHead)
    local aimCF

    if above then
        aimCF = glued + offset
    else
        aimCF = LevelLookAt(glued.Position + offset, hitboxHead.Position)
    end

    if not self._shootLock:ShouldFire(flag19, shootFrames) then
        -- 射擊失敗 → 給隨機遠離位置，不觸發 hit
        local r = math.random
        return CFrame.new(r(-1000000,1000000), r(5000,10000), r(-1000000,1000000)), nil
    end

    local encA = above and HS_UP_ENCODE or HS_DOWN_ENCODE
    local encB = above and HS_UP_DIR    or HS_DOWN_DIR

    return aimCF, function()
        gun:ShootEncoded(encA, encB, hitboxHead, HS_TPOSE)
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jE — MeleeStrategy (近戰攻擊 / 刀後刺)
-- ════════════════════════════════════════════════════════════════════════════
local MeleeStrategy = {}
MeleeStrategy.__index = MeleeStrategy

local ME_UP_ENCODE   = { ["\0"]=-9e37, ["\1"]=0, ["\2"]=0, ["\3"]=-1.5707963267948966, ["\4"]=math.pi, ["\5"]=math.pi }
local ME_UP_DIR      = { ["\0"]=0, ["\1"]=-90000000, ["\2"]=0, ["\3"]=-1.5707963267948966, ["\4"]=math.pi, ["\5"]=math.pi }
local ME_DOWN_ENCODE = { ["\0"]=-9e37, ["\1"]=0, ["\2"]=1, ["\3"]=1.5707963267948966, ["\4"]=math.pi, ["\5"]=math.pi }
local ME_DOWN_DIR    = { ["\0"]=0, ["\1"]=90000000, ["\2"]=1, ["\3"]=1.5707963267948966, ["\4"]=math.pi, ["\5"]=math.pi }
local ME_TPOSE       = { ["\0"]=0, ["\1"]=1, ["\2"]=1, ["\3"]=0, ["\4"]=0, ["\5"]=0 }

local ME_OFFSET_ABOVE = Vector3.new(0, -1,    0.05)   -- v86[195] 一般為 1
local ME_OFFSET_BELOW = Vector3.new(0, -3.85, 0.05)

local function ME_MakeOrientation(pitch, yaw, roll)
    return { Kind = "Normalized", Pitch = math.deg(pitch), Yaw = math.deg(yaw) }
end

local function ME_RebuildEncode(base, pitch, yaw, roll)
    return {
        ["\0"] = base["\0"],
        ["\1"] = base["\1"],
        ["\2"] = base["\2"],
        ["\3"] = pitch,
        ["\4"] = yaw,
        ["\5"] = roll,
    }
end

local function ME_RandomFarCF()
    local r = math.random
    return CFrame.new(r(-10000000,-100000), r(5000,10000), r(-10000000,-100000))
end

function MeleeStrategy.new(partGlue)
    return setmetatable({
        _partGlue            = partGlue,
        _shootLock           = ShootLock.new(),
        _hitboxWindowUntil   = -1,
        _attackCooldown      = -1,
        _gluedOurPart        = nil,
    }, MeleeStrategy)
end

-- 返回 aimCF, viewAngles, weaponActionFn
function MeleeStrategy:Plan(shootFrames, target, melee, ourPart, flag19)
    local aliveState = target.AliveState
    local hitboxHead = aliveState.HitboxHead
    local above      = GetShieldSide(target.FighterState) ~= "Below"
    local offset     = above and ME_OFFSET_ABOVE or ME_OFFSET_BELOW
    local glued      = self._partGlue:Acquire(ourPart, hitboxHead)
    self._gluedOurPart = ourPart

    local aimCF
    if above then
        aimCF = glued + offset
    else
        aimCF = LevelLookAt(glued.Position + offset, hitboxHead.Position)
    end

    local pitch, yaw, roll = aliveState.RootPart.CFrame:ToOrientation()
    local n33   = above and -1.5707963267948966 or 1.5707963267948966
    local encA  = ME_RebuildEncode(above and ME_UP_ENCODE or ME_DOWN_ENCODE, n33, yaw, roll)
    local encB  = ME_RebuildEncode(above and ME_UP_DIR    or ME_DOWN_DIR,    n33, yaw, roll)
    local now   = os.clock()

    -- 在後刺窗口內 → 強制重攻擊
    if now < self._hitboxWindowUntil then
        return aimCF, ME_MakeOrientation(pitch, yaw, roll), function()
            melee:HeavyAttackEncoded(encA, encB, hitboxHead, ME_TPOSE)
        end
    end

    if not self._shootLock:ShouldFire(flag19, shootFrames) then
        return ME_RandomFarCF(), nil, nil
    end

    if now < self._attackCooldown then
        return ME_RandomFarCF(), nil, nil
    end

    if melee.Name == "Knife" then
        self:_RecordBackstab()
        return aimCF, ME_MakeOrientation(pitch, yaw, roll), function()
            melee:HeavyAttackEncoded(encA, encB, hitboxHead, ME_TPOSE)
        end
    end

    return aimCF, nil, function()
        melee:AttackEncoded(encA, encB, hitboxHead, ME_TPOSE)
    end
end

function MeleeStrategy:_RecordBackstab()
    local now = os.clock()
    self._hitboxWindowUntil = now + 0.625
    self._attackCooldown    = now + 1.25
end

function MeleeStrategy:ResetState()
    self._hitboxWindowUntil = -1
    self._attackCooldown    = -1
    self._shootLock:Reset()
    local part = self._gluedOurPart
    if part ~= nil then
        self._partGlue:Free(part)
        self._gluedOurPart = nil
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jF — 隨機 CFrame 環形採樣器
-- ════════════════════════════════════════════════════════════════════════════
local _rngF = Random.new()

local function RandomRingCF(anchor, minRadius, maxRadius)
    local angle  = _rngF:NextNumber(0, math.tau)
    local radius = _rngF:NextNumber(minRadius, maxRadius)
    local base   = CFrame.new(
        anchor + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    )
    local nxt = _rngF.NextNumber
    return base * CFrame.fromOrientation(
        _rngF:NextNumber(0, math.tau),
        _rngF:NextNumber(0, math.tau),
        nxt(_rngF, 0, math.tau)
    )
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jG — 表面法線計算器 (ProjectileBreaker 用)
-- ════════════════════════════════════════════════════════════════════════════
local function GetSurfaceNormal(part, testPoint)
    local closest = part:GetClosestPointOnSurface(testPoint)
    local n       = testPoint - closest
    if n.Magnitude < 1e-6 then
        return closest, nil
    end
    local nx = part:GetClosestPointOnSurface(testPoint + Vector3.xAxis * 0.05) - closest
    local ny = part:GetClosestPointOnSurface(testPoint + Vector3.yAxis * 0.05) - closest
    local nz = part:GetClosestPointOnSurface(testPoint + Vector3.zAxis * 0.05) - closest
    local cross = ny:Cross(nx)
    if cross.Magnitude < 1e-6 then cross = ny:Cross(nz) end
    if cross.Magnitude < 1e-6 then cross = nx:Cross(nz) end
    if cross.Magnitude < 1e-6 then return closest, nil end
    if cross:Dot(n) < 0 then cross = -cross end
    return closest, cross.Unit
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jH — ProjectileBreakerTeleport
-- ════════════════════════════════════════════════════════════════════════════
local ProjectileBreakerTeleport = {}
ProjectileBreakerTeleport.__index = ProjectileBreakerTeleport

local PBT_BOX         = Vector3.new(5, 5, 5)
local PBT_OBP_PARAMS  = OverlapParams.new()
PBT_OBP_PARAMS.FilterType               = Enum.RaycastFilterType.Exclude
PBT_OBP_PARAMS.FilterDescendantsInstances = {}
PBT_OBP_PARAMS.BruteForceAllSlow        = false

local CS_SVC = cloneref(game:GetService("CollectionService"))
local _rngPBT = Random.new()

local function PBT_SineDepth(range, freq)
    local period = math.tau * freq
    return range.Min + (range.Max - range.Min) * (math.sin(os.clock() * period) + 1) * 0.5
end

local function PBT_IsForbiddenPart(part)
    return part.Name == "Barriers"
        or part:HasTag("OutOfBoundsPart")
        or part:HasTag("KillBrick")
end

local function PBT_InForbiddenBox(pos)
    for _, p in workspace:GetPartBoundsInBox(CFrame.new(pos), PBT_BOX, PBT_OBP_PARAMS) do
        if PBT_IsForbiddenPart(p) then return true end
    end
    return false
end

local function PBT_MakeSurface(sp, normal, part)
    -- sp = surface position, normal = up unit, part = part for right/fwd derivation
    local nx = part:GetClosestPointOnSurface(sp + Vector3.xAxis * 0.05) - sp
    local ny = part:GetClosestPointOnSurface(sp + Vector3.yAxis * 0.05) - sp
    local nz = part:GetClosestPointOnSurface(sp + Vector3.zAxis * 0.05) - sp
    local right = ny:Cross(nx)
    if right.Magnitude < 1e-6 then right = ny:Cross(nz) end
    if right.Magnitude < 1e-6 then right = nx:Cross(nz) end
    if right.Magnitude < 1e-6 then
        right = Vector3.xAxis
    else
        right = right.Unit
    end
    local fwd = normal:Cross(right).Unit
    return { SurfacePosition = sp, Right = right, Up = normal, Forward = fwd }
end

local function PBT_SurfaceToCF(surf, depthUp, depthFwd)
    return CFrame.fromMatrix(
        surf.SurfacePosition - surf.Up * 0.01 - surf.Up * depthUp + surf.Forward * depthFwd,
        surf.Right, surf.Up, -surf.Forward
    )
end

local function PBT_ScanPart(part)
    if part.Transparency == 1 then return nil end
    local sz = part.Size
    if sz.X * sz.Y * sz.Z < 64 then return nil end
    local mag = sz.Magnitude + 1000
    for _ = 1, 10 do
        local sp, norm = GetSurfaceNormal(part, part.Position + _rngPBT:NextUnitVector() * mag)
        if norm ~= nil and norm.Y >= 0.98 then
            return PBT_MakeSurface(sp, norm, part)
        end
    end
    local sp, norm = GetSurfaceNormal(part, part.Position + Vector3.yAxis * mag)
    if norm ~= nil and norm.Y >= 0.98 then
        return PBT_MakeSurface(sp, norm, part)
    end
    return nil
end

function ProjectileBreakerTeleport.new(fighters, playerContext, Data)
    local self = setmetatable({
        _fighters              = fighters,
        _Data                  = Data,
        _nextPositionCooldown  = -1,
        _poolEnvironmentId     = nil,
        _pool                  = {},
        _processedPartSet      = {},
        _lastBreakSurface      = nil,
    }, ProjectileBreakerTeleport)

    -- bind environment change via playerContext observation
    playerContext:ObserveContext("ragebot.ProjectileBreakerTeleport", function(ctx, trove)
        self:_BindEnvironment(ctx.FighterState.EnvironmentId)
        trove:Connect(ctx.FighterState.EnvironmentIdChanged, function(id)
            self:_BindEnvironment(id)
        end)
    end)
    playerContext.ContextRemoved:Connect(function()
        self:_BindEnvironment(nil)
    end)

    return self
end

function ProjectileBreakerTeleport:_BindEnvironment(envId)
    self._poolEnvironmentId = envId
    self._pool              = {}
    self._processedPartSet  = {}
end

function ProjectileBreakerTeleport:_HasSlingshot()
    for _, fs in self._fighters.EnemyByPlayer do
        local gun = fs.ItemObserver:EquippedItemAsGun()
        if gun ~= nil and not gun.IsRaycast and gun.Name == "Slingshot" then
            return true
        end
    end
    return false
end

function ProjectileBreakerTeleport:_FallbackCF(rootPart)
    local cfg         = self._Data.Ragebot.Evasion.ProjectileBreaker
    local base        = cfg.FallbackBaseRadius
    local n           = base + base * cfg.FallbackRadiusRandomFactor
    local anchor      = cfg.FallbackAnchorFromCharacter and rootPart.Position
        or Vector3.new(0, rootPart.Position.Y, 0)
    local sample      = RandomRingCF(anchor, base, n)
    local pos         = sample.Position
    local x, y, z    = pos.X, pos.Y, pos.Z
    local axis        = _rngPBT:NextInteger(1, 3)
    if axis == 1 then x = 1073741824
    elseif axis == 2 then y = 1073741824
    else z = 1073741824 end
    return sample - pos + Vector3.new(x, y, z)
end

function ProjectileBreakerTeleport:_ScanBatch(envId)
    local cfg  = self._Data.Ragebot.Evasion.ProjectileBreaker
    local depU = (cfg.DepthUp.Min    + cfg.DepthUp.Max)    * 0.5
    local depF = (cfg.DepthForward.Min + cfg.DepthForward.Max) * 0.5
    local count = 0

    local function tryPart(part)
        if not part:IsA("BasePart") or self._processedPartSet[part] then return end
        self._processedPartSet[part] = true
        count += 1
        local surf = PBT_ScanPart(part)
        if surf == nil then return end
        if PBT_InForbiddenBox(PBT_SurfaceToCF(surf, depU, depF).Position) then return end
        table.insert(self._pool, surf)
    end

    for _, part in CS_SVC:GetTagged("RaycastWhitelist" .. envId) do
        if PBT_IsForbiddenPart(part) then continue end
        tryPart(part)
        if count >= 64 or #self._pool >= 30 then return end
        for _, desc in part:GetDescendants() do
            if PBT_IsForbiddenPart(desc) then continue end
            tryPart(desc)
            if count >= 64 or #self._pool >= 30 then return end
        end
    end
end

function ProjectileBreakerTeleport:_BreakLine()
    local envId = self._poolEnvironmentId
    if envId == nil then return nil end
    if #self._pool < 30 then self:_ScanBatch(envId) end
    if #self._pool < 30 then return nil end
    local cfg = self._Data.Ragebot.Evasion.ProjectileBreaker
    self._nextPositionCooldown = os.clock() + cfg.RepositionInterval
    return self._pool[_rngPBT:NextInteger(1, #self._pool)]
end

function ProjectileBreakerTeleport:Compute(rootPart)
    local cfg = self._Data.Ragebot.Evasion.ProjectileBreaker
    if os.clock() < self._nextPositionCooldown then
        local surf = self._lastBreakSurface
        if surf ~= nil then
            return PBT_SurfaceToCF(surf,
                PBT_SineDepth(cfg.DepthUp,      cfg.DepthUpFrequency),
                PBT_SineDepth(cfg.DepthForward, cfg.DepthForwardFrequency)
            )
        end
    end
    if not self:_HasSlingshot() then
        self._lastBreakSurface = nil
        return self:_FallbackCF(rootPart)
    end
    local surf = self:_BreakLine()
    if surf ~= nil then
        self._lastBreakSurface = surf
        return PBT_SurfaceToCF(surf,
            PBT_SineDepth(cfg.DepthUp,      cfg.DepthUpFrequency),
            PBT_SineDepth(cfg.DepthForward, cfg.DepthForwardFrequency)
        )
    end
    return self:_FallbackCF(rootPart)
end

function ProjectileBreakerTeleport:ResetState()
    self._nextPositionCooldown = -1
    self._lastBreakSurface     = nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jI — Random 閃避傳送計算器
-- ════════════════════════════════════════════════════════════════════════════
local _rngI = Random.new()

local function RandomEvasionCF(rootPart, Data)
    local cfg    = Data.Ragebot.Evasion.Random
    local base   = cfg.BaseRadius
    local n      = base + base * cfg.RadiusRandomFactor
    local anchor = cfg.AnchorFromCharacter
        and rootPart.Position
        or Vector3.new(0, rootPart.Position.Y, 0)
    local sample = RandomRingCF(anchor, base, n)
    local pos    = sample.Position
    local x, y, z = pos.X, pos.Y, pos.Z
    -- 只往 Y 方向極端化（天空方向不觸發 OOB kill zone）
    y = 1073741824
    return sample - pos + Vector3.new(x, y, z)
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jJ — SpatialLimitGate (OOB 穩定性閘門)
-- ════════════════════════════════════════════════════════════════════════════
local SpatialLimitGate = {}
SpatialLimitGate.__index = SpatialLimitGate

local SPATIAL_THRESHOLD = 4194304  -- 2^22

local function _isInOOB(pos)
    return math.abs(pos.X) >= SPATIAL_THRESHOLD
        or math.abs(pos.Y) >= SPATIAL_THRESHOLD
        or math.abs(pos.Z) >= SPATIAL_THRESHOLD
end

function SpatialLimitGate.new(fighters, Data)
    local self = setmetatable({
        _fighters   = fighters,
        _Data       = Data,
        _byFighter  = {},
    }, SpatialLimitGate)
    -- 監聽敵人加入/離開
    fighters:ObserveRemoteStates(function(fs)
        self._byFighter[fs] = { ExpectedDuration = 1 }
    end, function(fs)
        self._byFighter[fs] = nil
    end)
    return self
end

-- 返回 true 表示「目前在 OOB 且尚未達穩定時間 → 壓制射擊」
function SpatialLimitGate:Tick(target)
    local now     = os.clock()
    local fs      = target.FighterState
    local measure = self._byFighter[fs]
    local hasAmmo = fs.ItemObserver:GetEquippedAmmoState() ~= false

    if not _isInOOB(target.AliveState.RootPart.Position) then
        if measure.LimitEntryTime ~= nil then
            if hasAmmo then
                measure.ExpectedDuration = now - measure.LimitEntryTime
            end
            measure.LimitEntryTime = nil
        end
        return false
    end

    if measure.LimitEntryTime == nil then
        measure.LimitEntryTime = now
    end

    if hasAmmo then
        local stability = self._Data.Ragebot.Stability
        if measure.ExpectedDuration - stability <= now - measure.LimitEntryTime then
            return false
        end
    end

    return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jK — Translocate 傳送計算器
-- ════════════════════════════════════════════════════════════════════════════
local function TranslocateCF(rootPart, hasTargets, Data)
    local offset = Data.Ragebot.Evasion.Translocate.Offset
    -- 找到 KillDelay == 0 的 OOB 傳送板
    local best = nil
    for _, part in CS_SVC:GetTagged("OutOfBoundsPart") do
        if part:GetAttribute("KillDelay") == 0 then
            best = part
            break
        else
            best = nil
        end
    end
    if best == nil then
        return RandomRingCF(rootPart.Position, 10000, 1e9)
    end
    return best.CFrame * CFrame.new(0, -best.Size.Y / 2 + offset, 0)
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jM — WeaponActionSelector (武器輪換 / 換彈邏輯)
-- ════════════════════════════════════════════════════════════════════════════
local function _weaponClass(item)
    local idx = item.Index
    if idx == 1 then return "Primary"
    elseif idx == 2 then return "Secondary"
    elseif idx == 3 then return "Melee"
    end
    return nil
end

local function GetWeaponAction(innerContext, Data)
    local cfg     = Data.Ragebot.Weapons
    local onEmpty = cfg.OnEmpty
    local rawPri  = cfg.Priority
    local pri
    if type(rawPri) == "table" then
        pri = rawPri
    elseif rawPri == "Secondary First" then
        pri = {"Secondary","Primary","Melee"}
    elseif rawPri == "Melee First" then
        pri = {"Melee","Primary","Secondary"}
    else
        pri = {"Primary","Secondary","Melee"}
    end

    local bestItem, bestPri    = nil, math.huge
    local reloadItem, reloadPri = nil, math.huge
    local anyEnabled = false

    for _, item in innerContext.ItemBehaviors:GetItems() do
        local cls = _weaponClass(item)
        if cls == nil or not cfg.Enabled[cls] then continue end
        anyEnabled = true
        local rank = table.find(pri, cls) or math.huge

        if item.__type == "Gun" and item:GetAmmo() == 0 then
            if item:GetAmmoReserve() > 0 then
                if rank < reloadPri then
                    if onEmpty == "Reload" then
                        bestItem, bestPri = item, rank
                    else
                        reloadItem, reloadPri = item, rank
                    end
                end
            end
        elseif bestItem == nil or rank < bestPri then
            bestItem, bestPri = item, rank
        end
    end

    if not anyEnabled then return nil end

    if bestItem ~= nil then
        local isEmpty = bestItem.__type == "Gun" and bestItem:GetAmmo() == 0
        if bestItem:IsEquipped() then
            if isEmpty then return { Type = "Reload", Item = bestItem } end
            return { Type = "Attack", Item = bestItem }
        end
        return { Type = "Swap", Item = bestItem }
    end

    if onEmpty == "Swap" then return nil end

    if reloadItem ~= nil then
        if reloadItem:IsEquipped() then
            return { Type = "Reload", Item = reloadItem }
        end
        return { Type = "Swap", Item = reloadItem }
    end

    return nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jN — RiotShieldState 偵測器
-- ════════════════════════════════════════════════════════════════════════════
local function GetRiotShieldState(itemBehaviors)
    local shield = itemBehaviors:FindMeleeByName and itemBehaviors:FindMeleeByName("Riot Shield")
    if shield == nil then return "None" end
    return shield:IsEquipped() and "Equipped" or "Unequipped"
end

-- ════════════════════════════════════════════════════════════════════════════
-- 模組 jO — Ragebot 主控制器
-- ════════════════════════════════════════════════════════════════════════════
-- 外部依賴:
--   Data             — v115.Data (含 Ragebot / Aimbot / 其他欄位)
--   getEstimatedReplicationDelay() / getEstimatedRemoteDelay()
--   ObserveEnabledKeybind        (keybind helper)
--   SetFallenPartsDestroyHeight  (workspace patch)
--   SetFastFlag                  (DFInt patch)
--   GetImmuneCFrame()            — jL 安全環
-- ════════════════════════════════════════════════════════════════════════════

local Ragebot = {}
Ragebot.__index = Ragebot

-- 傳入參數:
--   fighters       : { EnemyByPlayer, StateByPlayer, ObserveRemoteStates }
--   playerTags     : hacker tag 表
--   playerContext  : 本地 PlayerContext
--   stateHook      : { SetForced(key,val), ClearForced(key) }
--   partGlue       : { Acquire(ourPart, targetPart)→CFrame, Free(part) }
--   Data           : config 表 (共享 reactive store)
--   networkUtils   : { getEstimatedReplicationDelay, getEstimatedRemoteDelay }
--   immuneCFrameFn : function() → CFrame  (安全環位置)
--   keybindHelper  : { ObserveEnabledKeybind(keys, cb) }
--   fallenDestroyHeight : workspace.FallenPartsDestroyHeight 備份值
function Ragebot.new(
    fighters,
    playerTags,
    playerContext,
    stateHook,
    partGlue,
    Data,
    networkUtils,
    immuneCFrameFn,
    keybindHelper,
    fallenDestroyHeight
)
    local self = setmetatable({
        _enabled                       = false,
        _lastTargetWorld               = nil,
        _lastDefensiveViewAngles       = nil,
        _playerContext                 = playerContext,
        _innerContext                  = nil,
        _targetSelection               = TargetSelection.new(fighters, playerTags, Data),
        _spatialLimitGate              = SpatialLimitGate.new(fighters, Data),
        _hitscanStrategy               = HitscanStrategy.new(partGlue),
        _meleeStrategy                 = MeleeStrategy.new(partGlue),
        _projectileBreakerTeleport     = ProjectileBreakerTeleport.new(fighters, playerContext, Data),
        _stateHook                     = stateHook,
        _Data                          = Data,
        _net                           = networkUtils,
        _immuneCF                      = immuneCFrameFn,
        _fallenDestroyHeight           = fallenDestroyHeight,
        -- reload transport state
        _reloadGun                     = nil,
        _reloadReadyAt                 = nil,
        _reloadAcknowledgementDeadline = nil,
        _pendingDepletionAmmo          = nil,
        -- evasion phase state
        _vsPhaseEnd = nil, _vsHiding   = nil,
        _hvPhaseEnd = nil, _hvHiding   = nil, _hvAttackCF = nil,
        _odAngle    = nil, _odLastT    = nil, _odAttackCF = nil,
        _odCurrentCF = nil, _odRenderBound = nil,
    }, Ragebot)

    -- context 綁定
    playerContext:ObserveContext("ragebot", function(ctx)
        self._innerContext = ctx
        self:_ClearReloadTransport()
    end)
    playerContext.ContextRemoved:Connect(function()
        self:_Reset()
        self._innerContext = nil
    end)

    -- keybind
    keybindHelper:ObserveEnabledKeybind({"Ragebot"}, function(enabled)
        self:SetEnabled(enabled)
        self:_Reset()
    end)

    return self
end

function Ragebot:SetEnabled(enabled)
    if self._enabled == enabled then return end
    self._enabled = enabled

    -- FastFlag 注入 (仿原腳本)
    if enabled then
        workspace.FallenPartsDestroyHeight = 0/0   -- NaN → 禁用掉落銷毀
    else
        workspace.FallenPartsDestroyHeight = self._fallenDestroyHeight
        self:_ClearReloadTransport()
    end
end

local function _immunePlan()
    -- 返回一個「傳送到安全環」的計畫物件
    return { CFrame = nil, ShouldSkipDefense = true, _isImmune = true }
end

function Ragebot:Update(dt)
    local ctx = self._innerContext
    if ctx == nil then self:_Reset(); return end

    local fs = ctx.FighterState
    if fs.EnvironmentId == nil or not self._enabled then self:_Reset(); return end

    local state = fs.Character.State
    if not state.Alive then self:_Reset(); return end

    local cc        = ctx.CharacterController
    local clientCF  = cc:GetClientCFrame()
    local Data      = self._Data
    local mode      = Data.Ragebot.Evasion.Mode
    local action    = GetWeaponAction(ctx, Data)

    -- ── Translocate ──────────────────────────────────────────────────────────
    if mode == "Translocate" and self._reloadGun == nil
        and (action == nil or action.Type ~= "Reload")
    then
        self:_ApplyForcedCrouch(false)
        cc:SetServerCFrame(TranslocateCF(state.RootPart, self._targetSelection:HasTargets(), Data))
        if action ~= nil then
            local tgt = self._targetSelection:GetTarget()
            if tgt ~= nil then
                local plan = self:_Plan(dt, action, tgt, state.RootPart, clientCF, mode)
                if plan.WeaponAction then plan.WeaponAction() end
            end
        end
        return
    end

    -- ── VoidSpam ──────────────────────────────────────────────────────────────
    if mode == "VoidSpam" then
        local now = os.clock()
        local cfg = Data.Ragebot.VoidSpam or {}
        local hide   = type(cfg.HideTime)   == "number" and cfg.HideTime   or 0.25
        local attack = type(cfg.AttackTime) == "number" and cfg.AttackTime or 0.1
        if not self._vsPhaseEnd then
            self._vsPhaseEnd = now + hide
            self._vsHiding   = true
        end
        if now >= self._vsPhaseEnd then
            self._vsHiding   = not self._vsHiding
            self._vsPhaseEnd = now + (self._vsHiding and hide or attack)
        end
        if self._vsHiding then
            local hideCF
            local parts = CS_SVC:GetTagged("OutOfBoundsPart")
            local myPos = clientCF.Position
            local best, bestD = nil, math.huge
            for _, part in ipairs(parts) do
                local kd = part:GetAttribute("KillDelay")
                if kd ~= nil and kd ~= 0 then
                    local d = (part.Position - myPos).Magnitude
                    if d < bestD then best, bestD = part, d end
                end
            end
            hideCF = best and CFrame.new(best.Position) or CFrame.new(0, -5000, 0)
            cc:SetServerCFrame(hideCF)
            return
        end
        -- attack phase: fall through
    end

    -- ── HarionVoid ───────────────────────────────────────────────────────────
    if mode == "HarionVoid" then
        local now = os.clock()
        local cfg  = Data.Ragebot.HarionVoid or {}
        local hide  = type(cfg.HideTime)  == "number" and cfg.HideTime  or 0.25
        local shoot = type(cfg.ShootTime) == "number" and cfg.ShootTime or 0.03
        if not self._hvPhaseEnd then
            self._hvPhaseEnd = now + hide
            self._hvHiding   = true
        end
        if now >= self._hvPhaseEnd then
            self._hvHiding   = not self._hvHiding
            self._hvPhaseEnd = now + (self._hvHiding and hide or shoot)
        end
        if self._hvHiding then
            cc:SetServerCFrame(CFrame.new(0, 1073741824, 0) * CFrame.Angles(math.pi, math.pi, math.pi))
            self._hvAttackCF = nil
            return
        end
        -- attack phase: compute behind-target CFrame
        local hvTgt = self._targetSelection:GetTarget()
        if hvTgt then
            local hvChar = hvTgt.AliveState.Character
            local hvRoot = hvChar and hvChar:FindFirstChild("HumanoidRootPart")
            local hvHead = hvChar and (hvChar:FindFirstChild("Head") or hvRoot)
            if hvRoot and hvHead then
                local shootPos = hvRoot.Position - hvRoot.CFrame.LookVector * 2.5 + Vector3.new(0, 1.5, 0)
                self._hvAttackCF = CFrame.new(shootPos, hvHead.Position)
            else
                self._hvAttackCF = nil
            end
        else
            self._hvAttackCF = nil
        end
        -- fall through → _Plan → _EvadePlan("HarionVoid") → stored CF
    end

    -- ── OrbitDesync ──────────────────────────────────────────────────────────
    if mode == "OrbitDesync" then
        local now  = os.clock()
        local cfg  = Data.Ragebot.OrbitDesync or {}
        local radius = type(cfg.Radius)      == "number" and math.clamp(cfg.Radius, 1.25, 5) or 3
        local height = type(cfg.Height)      == "number" and math.clamp(cfg.Height, -2,   6) or 1.5
        local speed  = type(cfg.StrafeSpeed) == "number" and cfg.StrafeSpeed                   or 2
        if not self._odAngle then self._odAngle = 0 end
        if not self._odLastT then self._odLastT = now end
        local delta = now - self._odLastT
        self._odLastT  = now
        self._odAngle  = (self._odAngle + delta * math.max(1, speed * 1.5)) % math.tau

        local odTgt = self._targetSelection:GetTarget()
        if odTgt then
            local odChar = odTgt.AliveState.Character
            local odRoot = odChar and odChar:FindFirstChild("HumanoidRootPart")
            local odHead = odChar and (odChar:FindFirstChild("Head") or odRoot)
            if odRoot and odHead then
                local ang     = self._odAngle
                local orbitP  = odHead.Position + Vector3.new(
                    math.cos(ang) * radius, height, math.sin(ang) * radius
                )
                local orbitCF = CFrame.new(orbitP, odHead.Position)
                self._odAttackCF  = orbitCF
                self._odCurrentCF = orbitCF
                if not self._odRenderBound then
                    self._odRenderBound = true
                    local rs     = game:GetService("RunService")
                    local rbRoot = state.RootPart
                    rs:BindToRenderStep("GravOrbit", Enum.RenderPriority.First.Value, function()
                        if Data.Ragebot.Evasion.Mode ~= "OrbitDesync" then
                            rs:UnbindFromRenderStep("GravOrbit")
                            self._odRenderBound = nil
                            return
                        end
                        local cf = self._odCurrentCF
                        if rbRoot and rbRoot.Parent and cf then
                            rbRoot.CFrame = cf
                        end
                    end)
                end
            else
                self._odAttackCF = nil
            end
        else
            if self._odRenderBound then
                game:GetService("RunService"):UnbindFromRenderStep("GravOrbit")
                self._odRenderBound = nil
            end
            self._odAttackCF  = nil
            self._odCurrentCF = nil
            cc:SetServerCFrame(CFrame.new(0, 1073741824, 0))
            return
        end
        -- fall through
    end

    -- ── 通用流程 ──────────────────────────────────────────────────────────────
    local target = self._targetSelection:GetTarget()
    self._lastTargetWorld = target and target.AliveState.RootPart.Position or nil

    local plan = self:_Plan(dt, action, target, state.RootPart, clientCF, mode)
    self:_ApplyPlan(plan, target, ctx)

    -- reload transport 更新
    local reloadGun = self._reloadGun
    if reloadGun ~= nil and self._reloadReadyAt == nil
        and self._pendingDepletionAmmo == nil
        and not reloadGun:IsReloading()
    then
        self._reloadReadyAt = os.clock() + self._net.getEstimatedReplicationDelay()
    end

    self:_ApplyForcedCrouch(plan.ShouldForceCrouch == true)

    local gun       = ctx.ItemBehaviors:EquippedItemAsGun()
    local ammo      = gun and gun:GetAmmo() or 0
    local shotsBefore = gun and gun.ShotRequestCount or 0
    local wa        = plan.WeaponAction

    if wa ~= nil then
        wa()
        local shotsFired = gun and (gun.ShotRequestCount - shotsBefore) or 0
        if gun ~= nil and shotsFired > 0 and gun:GetExpectedAmmoAfterPendingShots() <= 0 then
            ctx.CharacterController:SetServerCFrame(self._immuneCF())
            local now = os.clock()
            self._reloadGun                     = gun
            self._reloadReadyAt                 = now + self._net.getEstimatedReplicationDelay()
            self._pendingDepletionAmmo          = ammo
            self._reloadAcknowledgementDeadline = now
                + self._net.getEstimatedRemoteDelay()
                + self._net.getEstimatedReplicationDelay()
        end
    end
end

function Ragebot:_Plan(dt, action, target, ourRoot, clientCF, mode)
    local inOOB = target ~= nil and self._spatialLimitGate:Tick(target)
    local flag19 = not inOOB   -- true = 可射擊

    -- reload transport 優先
    local rtp = self:_PlanReloadTransport(action)
    if rtp ~= nil then return rtp end

    if action == nil then
        return self:_EvadePlan(ourRoot, mode)
    end

    if action.Type == "Swap" then
        local plan = self:_EvadePlan(ourRoot, mode)
        local item = action.Item
        plan.WeaponAction = function() item:Equip() end
        return plan
    end

    if action.Type == "Reload" then
        return { CFrame = self._immuneCF(), ShouldSkipDefense = true }
    end

    if target == nil then
        return self:_EvadePlan(ourRoot, mode)
    end

    local item = action.Item

    if item.__type == "Gun" then
        if item:IsReloading() then
            return { CFrame = self._immuneCF(), ShouldSkipDefense = true }
        end
        local aimCF, wa = self._hitscanStrategy:Plan(
            dt * self._Data.Ragebot.ShootFrames,
            target, item, ourRoot, flag19
        )
        return { CFrame = aimCF, WeaponAction = wa, ShouldForceCrouch = true, IsAimPose = wa ~= nil }
    end

    if item.__type == "Melee" then
        local aimCF, va, wa = self._meleeStrategy:Plan(
            dt * self._Data.Ragebot.ShootFrames,
            target, item, ourRoot, flag19
        )
        return {
            CFrame            = aimCF,
            ViewAngles        = va,
            WeaponAction      = wa,
            ShouldSkipDefense = true,
            ShouldForceCrouch = true,
        }
    end

    return {}
end

function Ragebot:_EvadePlan(ourRoot, mode)
    if mode == "Off"              then return {} end
    if mode == "ProjectileBreaker" then
        return { CFrame = self._projectileBreakerTeleport:Compute(ourRoot), ShouldSkipDefense = true }
    end
    if mode == "TeleportV2"       then return {} end
    if mode == "VoidSpam"         then return {} end
    if mode == "HarionVoid"       then
        return self._hvAttackCF
            and { CFrame = self._hvAttackCF, ShouldSkipDefense = true }
            or {}
    end
    if mode == "OrbitDesync"      then
        return self._odAttackCF
            and { CFrame = self._odAttackCF, ShouldSkipDefense = true }
            or {}
    end
    -- Random (預設)
    return { CFrame = RandomEvasionCF(ourRoot, self._Data) }
end

function Ragebot:_ApplyPlan(plan, target, ctx)
    local cc  = ctx.CharacterController
    local cf  = plan.CFrame

    if cf == nil or target == nil or plan.ShouldSkipDefense then
        cc:SetServerCFrame(cf)
        cc:SendViewAngles(20, plan.ViewAngles)
        return
    end

    local aliveState = target.AliveState
    local shield     = GetRiotShieldState(ctx.ItemBehaviors)
    local defCF      = DefenseCalc.getDefensiveCFrame(
        cf, shield, target.FighterState, aliveState.RootPart
    )
    cc:SetServerCFrame(defCF)

    if plan.IsAimPose or plan.ShouldDefendInPlace then
        self._lastDefensiveViewAngles = DefenseCalc.getDefensiveViewAngles(
            shield, target.FighterState
        )
    end

    cc:SendViewAngles(9, plan.ViewAngles or self._lastDefensiveViewAngles)
end

-- ── Reload Transport ────────────────────────────────────────────────────────
function Ragebot:_ClearReloadTransport()
    self._reloadGun                     = nil
    self._reloadReadyAt                 = nil
    self._reloadAcknowledgementDeadline = nil
    self._pendingDepletionAmmo          = nil
end

function Ragebot:_PlanReloadTransport(action)
    local gun = self._reloadGun
    if gun == nil then
        if action ~= nil and action.Type == "Reload" then
            self._reloadGun = action.Item
            return { CFrame = self._immuneCF(), ShouldSkipDefense = true }
        end
        return nil
    end

    local now    = os.clock()
    local equip  = self._innerContext and self._innerContext.ItemBehaviors:EquippedItemAsGun() or nil
    if equip ~= gun
        or (action ~= nil and (action.Type == "Swap" or action.Type == "Attack") and action.Item ~= gun)
    then
        self:_ClearReloadTransport()
        return nil
    end

    if gun:IsReloading() then
        self._reloadReadyAt             = nil
        self._pendingDepletionAmmo      = nil
        self._reloadAcknowledgementDeadline = nil
        return { CFrame = self._immuneCF(), ShouldSkipDefense = true }
    end

    local ammo = gun:GetAmmo()
    local base = { CFrame = self._immuneCF(), ShouldSkipDefense = true }

    if self._pendingDepletionAmmo ~= nil then
        if ammo <= 0 and gun:GetAmmoReserve() > 0 then
            self._pendingDepletionAmmo          = nil
            self._reloadAcknowledgementDeadline = nil
        else
            local deadline  = self._reloadAcknowledgementDeadline
            local timedOut  = deadline == nil or now >= deadline
            if not timedOut then
                timedOut = gun:GetExpectedAmmoAfterPendingShots() > 0
            end
            if timedOut then
                self:_ClearReloadTransport()
                return nil
            end
            return base
        end
    end

    if ammo > 0 or gun:GetAmmoReserve() <= 0 then
        self:_ClearReloadTransport()
        return nil
    end

    local readyAt = self._reloadReadyAt
    if readyAt == nil then
        readyAt             = now + self._net.getEstimatedReplicationDelay()
        self._reloadReadyAt = readyAt
    end

    local deadline = self._reloadAcknowledgementDeadline
    if now >= readyAt and (deadline == nil or now >= deadline) then
        base.WeaponAction = function()
            if gun:Reload() then
                self._reloadAcknowledgementDeadline = os.clock()
                    + self._net.getEstimatedRemoteDelay()
                    + self._net.getEstimatedReplicationDelay()
            end
        end
    end

    return base
end

-- ── Helpers ─────────────────────────────────────────────────────────────────
function Ragebot:_ApplyForcedCrouch(should)
    if should then
        self._stateHook:SetForced("IsCrouching", true)
    else
        self._stateHook:ClearForced("IsCrouching")
    end
end

function Ragebot:_Reset()
    self:_ClearReloadTransport()
    self._lastTargetWorld         = nil
    self._lastDefensiveViewAngles = nil
    self:_ApplyForcedCrouch(false)
    self._meleeStrategy:ResetState()
    self._projectileBreakerTeleport:ResetState()
    self._vsPhaseEnd = nil; self._vsHiding   = nil
    self._hvPhaseEnd = nil; self._hvHiding   = nil; self._hvAttackCF = nil
    self._odAngle    = nil; self._odLastT    = nil
    self._odAttackCF = nil; self._odCurrentCF = nil
    if self._odRenderBound then
        game:GetService("RunService"):UnbindFromRenderStep("GravOrbit")
        self._odRenderBound = nil
    end
    local ctx = self._innerContext
    if ctx == nil then return end
    ctx.CharacterController:SetServerCFrame(nil)
    ctx.CharacterController:SendViewAngles(20, nil)
end

function Ragebot:GetLastTargetWorld()
    return self._lastTargetWorld
end

function Ragebot:Destroy()
    self:_Reset()
    -- 外部 trove 負責 connection 清理
end

-- ════════════════════════════════════════════════════════════════════════════
-- 預設 Config 結構 (對應 Data.Ragebot)
-- ════════════════════════════════════════════════════════════════════════════
local DefaultRagebotConfig = {
    Enabled            = false,
    Keybind            = { State=false, Kind="Always", Bind=nil, ShowInList=true, Invisible=false },
    Stability          = 0.15,
    ShootFrames        = 1,
    PrioritizeHackers  = false,
    UtilizeHealthLead  = false,
    Weapons = {
        Priority  = {"Primary","Secondary","Melee"},
        Enabled   = { Primary=true, Secondary=true, Melee=false },
        OnEmpty   = "SwapOrReload",
    },
    Evasion = {
        Mode = "Random",
        Random = {
            AnchorFromCharacter  = false,
            BaseRadius           = 100,
            RadiusRandomFactor   = 0.5,
        },
        ProjectileBreaker = {
            DepthForward              = { Min=0, Max=4 },
            DepthForwardFrequency     = 5,
            DepthUp                   = { Min=0, Max=5.5 },
            DepthUpFrequency          = 5,
            RepositionInterval        = 0.3,
            FallbackAnchorFromCharacter = false,
            FallbackBaseRadius        = 100,
            FallbackRadiusRandomFactor = 0.5,
        },
        Translocate = { Offset = -5 },
        VoidSpam    = { HideTime = 0.25, AttackTime = 0.1 },
        HarionVoid  = { HideTime = 0.25, ShootTime  = 0.03 },
        OrbitDesync = { Radius = 3, Height = 1.5, StrafeSpeed = 2 },
    },
}

-- ════════════════════════════════════════════════════════════════════════════
-- Export
-- ════════════════════════════════════════════════════════════════════════════
return {
    -- 主控制器
    Ragebot               = Ragebot,
    -- 子模組 (供外部直接使用)
    TargetSelection       = TargetSelection,
    HitscanStrategy       = HitscanStrategy,
    MeleeStrategy         = MeleeStrategy,
    ShootLock             = ShootLock,
    ProjectileBreakerTeleport = ProjectileBreakerTeleport,
    SpatialLimitGate      = SpatialLimitGate,
    -- 工具函數
    GetShieldSide         = GetShieldSide,
    DefenseCalc           = DefenseCalc,
    OrientationUtils      = OrientationUtils,
    RandomEvasionCF       = RandomEvasionCF,
    RandomRingCF          = RandomRingCF,
    TranslocateCF         = TranslocateCF,
    GetWeaponAction       = GetWeaponAction,
    GetRiotShieldState    = GetRiotShieldState,
    -- 預設 config
    DefaultRagebotConfig  = DefaultRagebotConfig,
}
