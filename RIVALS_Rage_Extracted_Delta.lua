-- RIVALS Ragebot source extraction
-- Extracted from raw (2) (1).txt; kernel is source-derived and not rewritten.
-- The kernel requires the original RivalsRuntimeBridge/Options/Toggles/FighterDataCache context.

-- ORIGINAL RAGE UI BLOCK
            BuildRivalsRagebotUi = function(AutomationTab)
                local RagebotGroup = AutomationTab:AddLeftGroupbox('Ragebot')
                local ragebotToggle = RagebotGroup:AddToggle('P8S4T1', {
                    Text = 'Ragebot',
                    Default = false,
                    Tooltip = 'Fully automatic ragebot: aims and eliminates enemies on its own. Standalone - Aimbot and Triggerbot are not needed.',
                })
                ragebotToggle:AddKeyPicker('P8S4T1K', {
                    Default = 'Unknown',
                    Mode = 'Always',
                    Text = 'Ragebot',
                    NoUI = false,
                })
                -- Ragebot settings match Kicia's recovered page ("gV" builder, source ~258008):
                -- Stability 0..1.5 step .001, Shoot Frames 1..5, Prioritize Hackers, per-weapon
                -- toggles, On Empty, and the Random/Translocate evasion groups. Kicia exposes NO
                -- ProjectileBreaker sliders (hardcoded defaults) and its Weapon Priority reorder
                -- (OrderedList) has no Obsidian equivalent, so priority stays config order.
                RagebotGroup:AddToggle('P8S4T4', {
                    Text = 'Prioritize Hackers',
                    Default = false,
                    Tooltip = 'Target flagged cheaters first when present.',
                })
                RagebotGroup:AddSlider('P8S4S1', {
                    Text = 'Stability',
                    Default = 0.15, Min = 0, Max = 1.5, Rounding = 3, Compact = true,
                    Tooltip = 'How long a target may sit out of bounds before the bot stops firing at it.',
                })
                RagebotGroup:AddSlider('P8S4S2', {
                    Text = 'Shoot Frames',
                    Default = 1, Min = 1, Max = 5, Rounding = 0, Compact = true,
                    Tooltip = 'Fire once every N frames. 1 = every frame (fastest).',
                })
                RagebotGroup:AddToggle('P8S4T5', { Text = 'Use Primary', Default = true })
                RagebotGroup:AddToggle('P8S4T6', { Text = 'Use Secondary', Default = true })
                RagebotGroup:AddToggle('P8S4T7', { Text = 'Use Melee', Default = true })
                RagebotGroup:AddDropdown('P8S4D1', {
                    Values = { 'Swap', 'Reload', 'SwapOrReload' },
                    Default = 'SwapOrReload',
                    Multi = false,
                    Text = 'On Empty',
                    Tooltip = 'What to do when the chosen gun runs out of ammo.',
                })
                RagebotGroup:AddDropdown('P8S4D2', {
                    Values = { 'Random', 'Translocate', 'ProjectileBreaker' },
                    Default = 'Random',
                    Multi = false,
                    Text = 'Evasion Mode',
                    Tooltip = 'How to move when there is no target to shoot. Random scatters you far away, Translocate drops you onto an out-of-bounds part, Projectile Breaker hides behind cover.',
                })
                local RandomEvasionBox = RagebotGroup:AddDependencyBox()
                RandomEvasionBox:AddToggle('P8S4T8', {
                    Text = 'Character Origin',
                    Default = false,
                    Tooltip = 'Evasion (Random): scatter around your character instead of the map origin.',
                })
                RandomEvasionBox:AddSlider('P8S4S4', {
                    Text = 'Base Radius', Default = 100, Min = 5, Max = 100000000, Rounding = 0, Compact = true,
                    Tooltip = 'Evasion (Random): how far away to scatter.',
                })
                RandomEvasionBox:AddSlider('P8S4S5', {
                    Text = 'Random Range', Default = 0.5, Min = 0, Max = 1, Rounding = 1, Compact = true,
                    Tooltip = 'Evasion (Random): extra randomness on the scatter distance.',
                })
                RandomEvasionBox:SetupDependencies({ { Options.P8S4D2, 'Random' } })
                local TranslocateEvasionBox = RagebotGroup:AddDependencyBox()
                TranslocateEvasionBox:AddSlider('P8S4S3', {
                    Text = 'Offset', Default = -5, Min = -5, Max = 5, Rounding = 1, Compact = true,
                    Tooltip = 'Evasion (Translocate): vertical offset on the out-of-bounds part.',
                })
                TranslocateEvasionBox:SetupDependencies({ { Options.P8S4D2, 'Translocate' } })
            end


-- ORIGINAL RAGE KERNEL
        -- __KICIA_RAGEBOT_BEGIN__
            local KiciaRagebot = {}
            RivalsRuntimeBridge.KiciaRagebot = KiciaRagebot

            local RunService = game:GetService('RunService')
            local HttpServiceRB = cloneref(game:GetService('HttpService'))
            local CollectionServiceRB = cloneref(game:GetService('CollectionService'))
            local PlayersRB = cloneref(game:GetService('Players'))
            local ReplicatedStorageRB = cloneref(game:GetService('ReplicatedStorage'))
            local WorkspaceRB = workspace
            local LPRB = PlayersRB.LocalPlayer
            local rbRandom = Random.new()

            -- Executor capability shims (all feature-detected live on build 17625359962).
            local rbSetHidden = sethiddenproperty
            local rbSetFFlag = (type(setfflag) == 'function') and setfflag or sfflag
            local rbSetThreadIdentity = setthreadidentity
            local rbGetThreadIdentity = getthreadidentity

            -- Clean FireServer stolen off a throwaway RemoteEvent (matches the script's No Spread
            -- calling convention: positional call, never :FireServer()).
            local rbCleanFireEvent = Instance.new('RemoteEvent')
            local rbFireServerNative = clonefunction(rbCleanFireEvent.FireServer)

            local function rbRawWrite(obj, key, value)
                if typeof(obj) == 'Instance' then
                    if not pcall(rbSetHidden, obj, key, value) then
                        pcall(function() obj[key] = value end)
                    end
                else
                    pcall(rawset, obj, key, value)
                end
            end

            -- ---- settings (read live from the Obsidian controls; Kicia defaults as fallback) ----
            local function optValue(id, default)
                local o = Options and Options[id]
                if o and o.Value ~= nil then
                    return o.Value
                end
                return default
            end
            local function togValue(id, default)
                local t = Toggles and Toggles[id]
                if t and t.Value ~= nil then
                    return t.Value == true
                end
                return default
            end
            local Setting = {
                Stability = function() return optValue('P8S4S1', 0.15) end,
                ShootFrames = function() return optValue('P8S4S2', 1) end,
                PrioritizeHackers = function() return togValue('P8S4T4', false) end,
                WeaponPrimary = function() return togValue('P8S4T5', true) end,
                WeaponSecondary = function() return togValue('P8S4T6', true) end,
                WeaponMelee = function() return togValue('P8S4T7', true) end,
                OnEmpty = function() return optValue('P8S4D1', 'SwapOrReload') end,
                EvasionMode = function() return optValue('P8S4D2', 'Random') end,
                TranslocateOffset = function() return optValue('P8S4S3', -5) end,
                RandomBaseRadius = function() return optValue('P8S4S4', 100) end,
                RandomRadiusFactor = function() return optValue('P8S4S5', 0.5) end,
                RandomAnchorFromCharacter = function() return togValue('P8S4T8', false) end,
                -- ProjectileBreaker has no Kicia UI; RepositionInterval keeps Kicia's default.
                RepositionInterval = function() return 0.3 end,
            }
            -- Kicia's ProjectileBreaker depth constants (config present in Kicia; no UI slider).
            local PB_DEPTH_FORWARD = { Min = 0, Max = 4 }
            local PB_DEPTH_FORWARD_FREQ = 5
            local PB_DEPTH_UP = { Min = 0, Max = 5.5 }
            local PB_DEPTH_UP_FREQ = 5
            local PB_FALLBACK_BASE_RADIUS = 100
            local PB_FALLBACK_RADIUS_FACTOR = 0.5
            local PB_FALLBACK_ANCHOR_FROM_CHARACTER = false

            -- ---- self-contained game-handle resolution -----------------------------------
            local function findChild(root, ...)
                local node = root
                for _, name in ipairs({ ... }) do
                    if not node then
                        return nil
                    end
                    node = node:FindFirstChild(name)
                end
                return node
            end

            local cachedEnumLibrary = nil
            local function resolveEnumLibrary()
                if cachedEnumLibrary then
                    return cachedEnumLibrary
                end
                local mod = findChild(ReplicatedStorageRB, 'Modules', 'EnumLibrary')
                if not mod then
                    return nil
                end
                local ok, lib = pcall(require, mod)
                if ok and type(lib) == 'table' then
                    cachedEnumLibrary = lib
                    return lib
                end
                return nil
            end
            local function enc(name)
                local lib = resolveEnumLibrary()
                if not lib then
                    return nil
                end
                local ok, token = pcall(lib.ToEnum, lib, name)
                if ok then
                    return token
                end
                return nil
            end

            local cachedUseItemRemote = nil
            local function resolveUseItemRemote()
                if cachedUseItemRemote and cachedUseItemRemote.Parent then
                    return cachedUseItemRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UseItem')
                if remote and remote:IsA('RemoteEvent') then
                    cachedUseItemRemote = cloneref(remote)
                    return cachedUseItemRemote
                end
                return nil
            end
            local cachedUpdateStateRemote = nil
            local function resolveUpdateStateRemote()
                if cachedUpdateStateRemote and cachedUpdateStateRemote.Parent then
                    return cachedUpdateStateRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UpdateState')
                if remote and remote:IsA('RemoteEvent') then
                    cachedUpdateStateRemote = cloneref(remote)
                    return cachedUpdateStateRemote
                end
                return nil
            end
            local cachedCameraRotationRemote = nil
            local function resolveCameraRotationRemote()
                if cachedCameraRotationRemote and cachedCameraRotationRemote.Parent then
                    return cachedCameraRotationRemote
                end
                local remote = findChild(ReplicatedStorageRB, 'Remotes', 'Replication', 'Fighter', 'UpdateCameraRotation')
                if remote and remote:IsA('RemoteEvent') then
                    cachedCameraRotationRemote = cloneref(remote)
                    return cachedCameraRotationRemote
                end
                return nil
            end
            local function requireModuleRB(name)
                local mod = findChild(ReplicatedStorageRB, 'Modules', name)
                if not mod then
                    return nil
                end
                local ok, result = pcall(require, mod)
                if ok then
                    return result
                end
                return nil
            end

            -- FighterController singleton (carries LocalFighter + Objects) + its prototype
            -- (carries _CameraReplicationLoop).  Cached with cheap revalidation.
            local cachedFighterController = nil
            local function resolveFighterController()
                local cc = cachedFighterController
                if type(cc) == 'table' and rawget(cc, 'LocalFighter') ~= nil then
                    return cc
                end
                for _, m in ipairs(getgc(true)) do
                    if type(m) == 'table' and rawget(m, 'LocalFighter') ~= nil and rawget(m, 'Objects') ~= nil then
                        cachedFighterController = m
                        return m
                    end
                end
                return nil
            end
            local function resolveLocalFighter()
                local controller = resolveFighterController()
                return controller and rawget(controller, 'LocalFighter') or nil
            end
            local cachedFCPrototype = nil
            local function resolveFighterControllerPrototype()
                if type(cachedFCPrototype) == 'table' and rawget(cachedFCPrototype, '_CameraReplicationLoop') ~= nil then
                    return cachedFCPrototype
                end
                local controller = resolveFighterController()
                if controller then
                    local mt = getmetatable(controller)
                    local proto = mt and rawget(mt, '__index') or nil
                    if type(proto) == 'table' and rawget(proto, '_CameraReplicationLoop') ~= nil then
                        cachedFCPrototype = proto
                        return proto
                    end
                end
                for _, m in ipairs(getgc(true)) do
                    if type(m) == 'table' then
                        local idx = rawget(m, '__index')
                        if type(idx) == 'table' and rawget(idx, '_CameraReplicationLoop') ~= nil then
                            cachedFCPrototype = idx
                            return idx
                        end
                    end
                end
                return nil
            end

            -- ---- firing transport (Kicia t157/t16, lines 73511 / 88523 / 88535) ----------
            local function fireGun(objectId, isRaycast, aim1, aim2, hitboxHead, extra)
                local remote = resolveUseItemRemote()
                local token = enc('StartShooting')
                if not remote or not token or not objectId then
                    return
                end
                local inner = { ['\0'] = aim1, ['\1'] = aim2, ['\2'] = hitboxHead, ['\3'] = extra }
                local payload
                if isRaycast then
                    payload = { ['\1'] = inner, ['\2'] = true }
                else
                    payload = { ['\1'] = inner }
                end
                rbFireServerNative(remote, objectId, token, payload, nil)
            end
            local function fireMeleeAttack(objectId, a, b, c, d)
                local remote = resolveUseItemRemote()
                local token = enc('StartShooting')
                local anim = enc('AttackAnimation1')
                if not remote or not token or not anim or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, token, { ['\1'] = { ['\0'] = a, ['\1'] = b, ['\2'] = c, ['\3'] = d }, ['\2'] = anim }, nil)
            end
            local function fireMeleeHeavy(objectId, a, b, c, d)
                local remote = resolveUseItemRemote()
                local token = enc('StartAiming') -- Kicia HeavyAttackEncoded uses StartAiming
                local anim = enc('HeavyAttackAnimation1')
                if not remote or not token or not anim or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, token, { ['\1'] = { ['\0'] = a, ['\1'] = b, ['\2'] = c, ['\3'] = d }, ['\2'] = anim }, nil)
            end
            local function fireReload(objectId)
                local remote = resolveUseItemRemote()
                local start = enc('StartReloading')
                local reload = enc('Reload')
                if not remote or not start or not reload or not objectId then
                    return
                end
                rbFireServerNative(remote, objectId, start, { ['\1'] = reload, ['\2'] = reload }, nil)
            end

            -- ---- raw ClientItem helpers --------------------------------------------------
            local function itemObjectId(item)
                local data = rawget(item, 'Data')
                return data and rawget(data, 'ObjectID') or nil
            end
            local function itemInfo(item)
                return rawget(item, 'Info')
            end
            local function itemType(item)
                local info = itemInfo(item)
                return info and rawget(info, 'Type') or nil
            end
            local function itemIsRaycast(item)
                local info = itemInfo(item)
                return info and rawget(info, 'IsRaycast') == true
            end
            local function itemName(item)
                return rawget(item, 'Name') or rawget(item, 'ItemName')
            end
            local function itemAmmo(item)
                local data = rawget(item, 'Data')
                local ammo = data and rawget(data, 'Ammo')
                return type(ammo) == 'number' and ammo or 0
            end
            local function itemAmmoReserve(item)
                local data = rawget(item, 'Data')
                local reserve = data and rawget(data, 'AmmoReserve')
                if type(reserve) ~= 'number' then
                    return math.huge
                end
                return reserve
            end
            -- Kicia t157:IsReloading (lines 73560-73573): _reload_cooldown OR _shoot_cooldown_no_ammo.
            local function itemIsReloading(item)
                local now = tick()
                local cooldown = rawget(item, '_reload_cooldown')
                if type(cooldown) == 'number' and now < cooldown then
                    return true
                end
                local noAmmoCooldown = rawget(item, '_shoot_cooldown_no_ammo')
                return type(noAmmoCooldown) == 'number' and now < noAmmoCooldown
            end
            -- Kicia t157:IsMagFull (line 73575): Info.MaxAmmo <= current ammo.
            local function itemIsMagFull(item)
                local info = itemInfo(item)
                local maxAmmo = info and rawget(info, 'MaxAmmo')
                return type(maxAmmo) == 'number' and maxAmmo <= itemAmmo(item)
            end
            -- Kicia t157:IsEquipped (line 73501): the item's own IsEquipped field - the same
            -- read the game's Items modules (Minigun, Riot Shield) use. The fighter-side
            -- Data.EquippedItemID compare it replaced never matched Kicia and is gone.
            local function itemIsEquipped(item)
                return rawget(item, 'IsEquipped')
            end
            -- Kicia t157:Equip (lines 73493-73499): no-op when equipped, then
            -- item.ClientFighter:EquipItem(index). ClientFighter lives on the ITEM (the
            -- LocalFighter IS a ClientFighter and has no such field; live-verified),
            -- and index is the fighter's Items-table key - the exact value the game's
            -- QuickAttackSystem passes (EquipItem(table.find(ClientFighter.Items, item))).
            local function equipItem(item, index)
                if itemIsEquipped(item) then
                    return
                end
                local clientFighter = rawget(item, 'ClientFighter')
                if clientFighter and index and type(clientFighter.EquipItem) == 'function' then
                    pcall(function() clientFighter:EquipItem(index) end)
                end
            end
            -- Kicia t157:Reload guard (lines 73539-73546).
            local function reloadItem(item)
                if itemIsReloading(item) or itemAmmoReserve(item) <= 0 or itemIsMagFull(item) then
                    return
                end
                fireReload(itemObjectId(item))
            end

            -- ---- spoofed aim payload tables (hitscan strategy, lines 40519-40551) ---------
            local NEG_HUGE = -9e37
            local function buildAim(base, pitch, oy, oz)
                return {
                    ['\0'] = base['\0'], ['\1'] = base['\1'], ['\2'] = base['\2'],
                    ['\3'] = pitch, ['\4'] = oy, ['\5'] = oz,
                }
            end
            local AIM_ABOVE_ORIGIN = { ['\0'] = NEG_HUGE, ['\1'] = 0, ['\2'] = 0 }         -- t91
            local AIM_ABOVE_END = { ['\0'] = 0, ['\1'] = -90000000, ['\2'] = 0 }           -- t92
            local AIM_BELOW_ORIGIN = { ['\0'] = NEG_HUGE, ['\1'] = 0, ['\2'] = 0 }         -- t93
            local AIM_BELOW_END = { ['\0'] = 0, ['\1'] = 90000000, ['\2'] = 0 }            -- t94
            local AIM_EXTRA = { ['\0'] = 0, ['\1'] = 1, ['\2'] = 0, ['\3'] = 0, ['\4'] = 0, ['\5'] = 0 } -- t95
            local OFFSET_ABOVE = Vector3.new(0, -0.7, 0.05)                                -- v230/v138
            local OFFSET_BELOW = Vector3.new(0, -3.85, 0.05)                               -- v231/v139
            local PITCH_ABOVE = -math.pi / 2                                               -- v140
            local PITCH_BELOW = math.pi / 2                                                -- v141

            -- Riot-Shield-aware above/below classifier (Kicia ia(), lines 151550-151570).
            -- "None" for shield-less targets (common case) folds to Above.  Enemy
            -- itemObserver/camera are best-effort on this build; shield-less path is exact.
            local function classifyAboveBelow(target)
                local obs = target and target.itemObserver
                if obs then
                    local ok, result = pcall(function()
                        local equipped = obs:GetEquippedItem()
                        if equipped ~= nil and equipped.name == 'Riot Shield' then
                            local pitch = math.deg(target:GetCameraRotation().X)
                            if 22 < pitch and pitch < 91 then
                                return 'Below'
                            end
                            return 'Above'
                        end
                        for _, it in obs:GetItems() do
                            if it.name == 'Riot Shield' then
                                local pitch = math.deg(target:GetCameraRotation().X)
                                if 315 < pitch and pitch < 360 or 0 < pitch and pitch < 91 then
                                    return 'Above'
                                end
                                return 'Below'
                            end
                        end
                        return 'None'
                    end)
                    if ok and result then
                        return result
                    end
                end
                return 'None'
            end
            local function isAbove(target)
                return classifyAboveBelow(target) ~= 'Below'
            end

            -- ---- root virtualization (Kicia t201, lines 145034-145080) -------------------
            local RootDesync = {}
            RootDesync.__index = RootDesync
            function RootDesync.new(rootPart)
                local self = setmetatable({
                    _rootPart = rootPart,
                    _boundId = HttpServiceRB:GenerateGUID(false),
                    _oldCFrame = rootPart.CFrame,
                    _cframe = nil,
                }, RootDesync)
                RunService:BindToRenderStep(self._boundId, Enum.RenderPriority.First.Value, function()
                    self:_RenderStepUpdate()
                end)
                return self
            end
            function RootDesync:_RenderStepUpdate()
                local old = self._oldCFrame
                if old ~= nil then
                    self._rootPart.CFrame = old
                    self._oldCFrame = nil
                end
            end
            function RootDesync:SetServerCFrame(cf)
                self._cframe = cf
            end
            function RootDesync:GetServerCFrame()
                return self._cframe or self._rootPart.CFrame
            end
            function RootDesync:GetClientCFrame()
                return self._oldCFrame or self._rootPart.CFrame
            end
            function RootDesync:HeartbeatUpdate()
                local cf = self._cframe
                if cf ~= nil then
                    self._oldCFrame = self._rootPart.CFrame
                    self._rootPart.CFrame = cf
                end
            end
            function RootDesync:Destroy()
                pcall(function() RunService:UnbindFromRenderStep(self._boundId) end)
            end

            -- ---- view-angle driver (Kicia t1141, lines 196889-197137) --------------------
            -- Hooks ClientFighterCharacterJoints.Update + FighterController._CameraReplicationLoop
            -- to inject a spoofed CameraRotationRaw so the replicated camera does not stare at the
            -- void.  Two deobfuscator artifacts are reconstructed to their unambiguous intent
            -- (recorded as anomalies A/B/C while recovering this function):
            --   * encodeCameraRotation (Vector2->2 bytes) and encodeSingle (scalar->1 byte) were
            --     collapsed onto one key in the dump; both restored from their recovered bodies.
            --   * _Resolve's priority loop was erased (junk filler); reconstructed as "winner =
            --     the highest numeric-priority live slot" (the ragebot uses one slot, priority 20).
            local function encodeSingle(n)
                if n == n then
                    return utf8.char(math.clamp(math.floor(n % (2 * math.pi) / math.pi / 2 * 256 + 0.5), 0, 255))
                end
                return utf8.char(0)
            end
            local function encodeCameraRotation(v)
                if v == v then
                    return utf8.char(math.clamp(math.floor(v.X % (2 * math.pi) / math.pi / 2 * 256 + 0.5), 0, 255))
                        .. utf8.char(math.clamp(math.floor(v.Y % (2 * math.pi) / math.pi / 2 * 256 + 0.5), 0, 255))
                end
                return utf8.char(0) .. utf8.char(0)
            end
            local function decodeSingle(s)
                return utf8.codepoint(s) * math.pi * 2 / 256
            end
            local function anglesToRaw(a)
                if a.kind == 'Unnormalized' then
                    return Vector2.new(a.pitch, 0) * math.pi * 2 / 256
                end
                return Vector2.new(decodeSingle(encodeSingle(math.rad(a.pitch))), decodeSingle(encodeSingle(math.rad(a.yaw))))
            end
            local function anglesToEncoded(a)
                if a.kind == 'Unnormalized' then
                    return utf8.char(math.clamp(a.pitch, 0, 255)) .. utf8.char(math.clamp(a.yaw, 0, 255))
                end
                return encodeSingle(math.rad(a.pitch)) .. encodeSingle(math.rad(a.yaw))
            end

            local ViewAngleDriver = {}
            ViewAngleDriver.__index = ViewAngleDriver
            function ViewAngleDriver.new()
                return setmetatable({
                    _slots = {},
                    _winning = nil,
                    _fullySuppressed = false,
                    _dirty = false,
                }, ViewAngleDriver)
            end
            function ViewAngleDriver:_Resolve()
                local best, winner = nil, nil
                for priority, value in pairs(self._slots) do
                    if value ~= nil and (best == nil or priority > best) then
                        best = priority
                        winner = value
                    end
                end
                self._winning = winner
            end
            function ViewAngleDriver:_LoadJointsHook()
                if self._jointsRestore ~= nil then
                    return true
                end
                local joints = requireModuleRB('ClientFighterCharacterJoints')
                local original = joints and rawget(joints, 'Update') or nil
                if not joints or original == nil then
                    return false
                end
                local driver = self
                local function hooked(jointsSelf, a, b)
                    local cfc = rawget(jointsSelf, 'ClientFighterCharacter')
                    local cf = cfc and rawget(cfc, 'ClientFighter') or nil
                    if cf == nil then
                        return original(jointsSelf, a, b)
                    end
                    if rawget(cf, 'IsLocalPlayer') == true then
                        local winning = driver._winning
                        if winning ~= nil then
                            rbRawWrite(b, 'CameraRotationRaw', anglesToRaw(winning))
                        end
                    end
                    return original(jointsSelf, a, b)
                end
                rawset(joints, 'Update', hooked)
                self._jointsRestore = { joints = joints, original = original }
                return true
            end
            function ViewAngleDriver:_LoadReplicationHook()
                if self._replicationRestore ~= nil then
                    return true
                end
                local proto = resolveFighterControllerPrototype()
                local instance = resolveFighterController()
                local loop = proto and rawget(proto, '_CameraReplicationLoop') or nil
                if not proto or not instance or loop == nil then
                    return false
                end
                local utilIndex, util
                local ok, upvalues = pcall(debug.getupvalues, loop)
                if ok and type(upvalues) == 'table' then
                    for index, value in pairs(upvalues) do
                        if type(value) == 'table' then
                            local vmt = getmetatable(value)
                            local vidx = vmt and rawget(vmt, '__index') or nil
                            if vidx ~= nil and rawget(vidx, 'EncodeCameraRotation') ~= nil then
                                util = value
                                utilIndex = index
                                break
                            end
                        end
                    end
                end
                if utilIndex == nil or util == nil then
                    return false
                end
                local driver = self
                local replacement = {}
                function replacement.EncodeCameraRotation(_, raw)
                    if next(driver._slots) == nil and not driver._fullySuppressed then
                        return encodeCameraRotation(raw)
                    end
                    rbRawWrite(instance, '_replication_stopped', false)
                    local last = rawget(instance, '_last_encoded_camera_rotation')
                    if not last then
                        last = encodeCameraRotation(raw)
                    end
                    return last
                end
                if not pcall(debug.setupvalue, loop, utilIndex, replacement) then
                    return false
                end
                self._replicationRestore = { loop = loop, utilityIndex = utilIndex, utility = util }
                return true
            end
            function ViewAngleDriver:SendViewAngles(priority, value)
                if self._slots[priority] == value then
                    return
                end
                self._slots[priority] = value
                self._dirty = true
                self:_Resolve()
                if self._winning == nil then
                    return
                end
                if self:_LoadJointsHook() then
                    self:_LoadReplicationHook()
                end
            end
            function ViewAngleDriver:Flush()
                if not self._dirty or self._fullySuppressed then
                    return
                end
                local winning = self._winning
                if winning == nil then
                    self._dirty = false
                    return
                end
                self._dirty = false
                local remote = resolveCameraRotationRemote()
                if remote then
                    rbFireServerNative(remote, anglesToEncoded(winning), nil)
                end
            end
            function ViewAngleDriver:ClearAll()
                table.clear(self._slots)
                self._winning = nil
                self._dirty = false
            end
            function ViewAngleDriver:Destroy()
                local jointsRestore = self._jointsRestore
                if jointsRestore ~= nil then
                    self._jointsRestore = nil
                    pcall(rawset, jointsRestore.joints, 'Update', jointsRestore.original)
                end
                local replicationRestore = self._replicationRestore
                if replicationRestore ~= nil then
                    self._replicationRestore = nil
                    pcall(debug.setupvalue, replicationRestore.loop, replicationRestore.utilityIndex, replicationRestore.utility)
                end
            end

            -- ---- character controller wrapper (Kicia t4, lines 25419-25541) --------------
            local CharacterController = {}
            CharacterController.__index = CharacterController
            function CharacterController.new(rootPart)
                return setmetatable({
                    _rootDesync = RootDesync.new(rootPart),
                    _viewAngleDriver = ViewAngleDriver.new(),
                }, CharacterController)
            end
            function CharacterController:SetServerCFrame(cf)
                if self._rootDesync then
                    self._rootDesync:SetServerCFrame(cf)
                end
            end
            function CharacterController:GetClientCFrame()
                return self._rootDesync and self._rootDesync:GetClientCFrame() or nil
            end
            function CharacterController:SendViewAngles(priority, value)
                self._viewAngleDriver:SendViewAngles(priority, value)
            end
            function CharacterController:HeartbeatUpdate()
                if self._rootDesync then
                    self._rootDesync:HeartbeatUpdate()
                end
                self._viewAngleDriver:Flush()
            end
            function CharacterController:Destroy()
                self._viewAngleDriver:ClearAll()
                self._viewAngleDriver:Destroy()
                if self._rootDesync then
                    self._rootDesync:Destroy()
                    self._rootDesync = nil
                end
            end

            -- ---- forced-crouch state hook (Kicia t192, lines 12022-12081, simplified) -----
            -- Kicia additionally installs a dummy _UpdateServerState to suppress the game's
            -- own conflicting sends; the essential forcing is firing UpdateState directly.
            local StateHook = {}
            StateHook.__index = StateHook
            function StateHook.new()
                return setmetatable({ _forced = {} }, StateHook)
            end
            function StateHook:SetForced(name, value)
                local token = enc(name)
                if token == nil or self._forced[token] == value then
                    return
                end
                local remote = resolveUpdateStateRemote()
                if not remote then
                    return
                end
                self._forced[token] = value
                rbFireServerNative(remote, token, value, nil)
            end
            function StateHook:ClearForced(name, offValue)
                local token = enc(name)
                if token == nil or self._forced[token] == nil then
                    return
                end
                self._forced[token] = nil
                local remote = resolveUpdateStateRemote()
                if remote then
                    rbFireServerNative(remote, token, offValue, nil)
                end
            end

            -- ---- part glue (Kicia t116, lines 150715-150820) -----------------------------
            local VOID_CFRAME = CFrame.new(
                math.random(-100000, -10000),
                100000,
                math.random(-100000, 10000)
            )
            local PartGlue = {}
            PartGlue.__index = PartGlue
            function PartGlue.new()
                return setmetatable({ _gluedParts = {}, _bindings = {} }, PartGlue)
            end
            function PartGlue:_SetupGlue(part)
                local entry = self._gluedParts[part]
                if entry ~= nil then
                    entry.refCount = entry.refCount + 1
                    return
                end
                local weld = part:FindFirstChildOfClass('WeldConstraint')
                local originalPart1 = nil
                if weld ~= nil then
                    originalPart1 = weld.Part1
                    if originalPart1 ~= nil then
                        weld.Part1 = nil
                    end
                    part.Anchored = true
                end
                self._gluedParts[part] = { refCount = 1, weld = weld, originalPart1 = originalPart1 }
            end
            function PartGlue:_ReleaseGlue(part)
                local entry = self._gluedParts[part]
                if entry == nil then
                    return
                end
                entry.refCount = entry.refCount - 1
                if 0 < entry.refCount then
                    return
                end
                local weld = entry.weld
                if weld ~= nil and entry.originalPart1 ~= nil then
                    weld.Part1 = entry.originalPart1
                    entry.originalPart1.Anchored = false
                end
                self._gluedParts[part] = nil
            end
            function PartGlue:Acquire(ourPart, hitboxPart, useRotation)
                local prev = rbGetThreadIdentity()
                rbSetThreadIdentity(8)
                pcall(rbSetHidden, ourPart, 'PhysicsRepRootPart', hitboxPart)
                rbSetThreadIdentity(prev)
                local bound = self._bindings[ourPart]
                if bound ~= hitboxPart then
                    if bound ~= nil then
                        self:_ReleaseGlue(bound)
                    end
                    self:_SetupGlue(hitboxPart)
                    self._bindings[ourPart] = hitboxPart
                end
                local cf = CFrame.new(VOID_CFRAME.Position)
                if useRotation then
                    cf = cf * hitboxPart.CFrame.Rotation
                end
                hitboxPart.CFrame = cf
                return VOID_CFRAME
            end
            function PartGlue:Free(ourPart)
                local bound = self._bindings[ourPart]
                if bound == nil then
                    return
                end
                self._bindings[ourPart] = nil
                self:_ReleaseGlue(bound)
                local prev = rbGetThreadIdentity()
                rbSetThreadIdentity(8)
                pcall(rbSetHidden, ourPart, 'PhysicsRepRootPart', nil)
                rbSetThreadIdentity(prev)
            end
            function PartGlue:Destroy()
                for _, entry in pairs(self._gluedParts) do
                    local weld = entry.weld
                    if weld ~= nil and entry.originalPart1 ~= nil then
                        pcall(function()
                            weld.Part1 = entry.originalPart1
                            entry.originalPart1.Anchored = false
                        end)
                    end
                end
                table.clear(self._gluedParts)
                table.clear(self._bindings)
            end

            -- ---- enemy target list + validity (Kicia t190, lines 92617-92664) ------------
            local function isEnemyPlayer(player)
                if player == nil or player == LPRB then
                    return false
                end
                local localTeamId = LPRB:GetAttribute('TeamID')
                local theirTeamId = player:GetAttribute('TeamID')
                if localTeamId ~= nil and theirTeamId ~= nil then
                    return localTeamId ~= theirTeamId
                end
                if LPRB.Team ~= nil and player.Team ~= nil then
                    return LPRB.Team ~= player.Team
                end
                return true
            end
            local function isTargetInvincible(entity)
                local data = entity and rawget(entity, 'Data')
                return data ~= nil and rawget(data, 'IsInvincible') == true
            end
            local function collectEnemies()
                local out = {}
                local controller = resolveFighterController()
                local objects = controller and rawget(controller, 'Objects') or nil
                if type(objects) ~= 'table' then
                    return out
                end
                for _, fighter in ipairs(objects) do
                    local ok, entry = pcall(function()
                        local player = rawget(fighter, 'Player')
                        local entity = rawget(fighter, 'Entity')
                        local model = entity and rawget(entity, 'Model') or nil
                        if not model then
                            return nil
                        end
                        if player ~= nil and not isEnemyPlayer(player) then
                            return nil
                        end
                        local hitboxHead = model:FindFirstChild('HitboxHead')
                        local hitboxBody = model:FindFirstChild('HitboxBody')
                        local rootPart = model:FindFirstChild('HumanoidRootPart') or hitboxBody
                        if not (hitboxHead and rootPart) then
                            return nil
                        end
                        local humanoid = model:FindFirstChildOfClass('Humanoid')
                        return {
                            fighter = fighter,
                            player = player,
                            entity = entity,
                            model = model,
                            hitboxHead = hitboxHead,
                            hitboxBody = hitboxBody,
                            rootPart = rootPart,
                            itemObserver = rawget(fighter, 'itemObserver') or rawget(fighter, 'ItemObserver'),
                            alive = humanoid == nil or humanoid.Health > 0,
                            invincible = isTargetInvincible(entity),
                            hacker = false,
                            equippedGunProjectile = false,
                        }
                    end)
                    if ok and entry then
                        out[#out + 1] = entry
                    end
                end
                return out
            end
            local function isValidTarget(entry)
                return entry ~= nil and entry.alive and not entry.invincible and not entry.deflecting
            end
            local function selectTarget()
                local enemies = collectEnemies()
                local prioritizeHackers = Setting.PrioritizeHackers()
                if prioritizeHackers then
                    for _, entry in ipairs(enemies) do
                        if entry.hacker and isValidTarget(entry) then
                            return entry
                        end
                    end
                end
                for _, entry in ipairs(enemies) do
                    if not (prioritizeHackers and entry.hacker) and isValidTarget(entry) then
                        return entry
                    end
                end
                return nil
            end
            local function hasTargets()
                for _, entry in ipairs(collectEnemies()) do
                    if isValidTarget(entry) then
                        return true
                    end
                end
                return false
            end

            -- ---- weapon selection (Kicia t34.getAction, lines 122419-122490) -------------
            local function itemCategory(slotIndex)
                if slotIndex == 1 then
                    return 'Primary'
                elseif slotIndex == 2 then
                    return 'Secondary'
                elseif slotIndex == 3 then
                    return 'Melee'
                end
                return nil
            end
            local function isCategoryEnabled(category)
                if category == 'Primary' then
                    return Setting.WeaponPrimary()
                elseif category == 'Secondary' then
                    return Setting.WeaponSecondary()
                elseif category == 'Melee' then
                    return Setting.WeaponMelee()
                end
                return false
            end
            local function getAction(fighter)
                if not fighter then
                    return nil
                end
                local items = rawget(fighter, 'Items')
                if type(items) ~= 'table' then
                    return nil
                end
                local onEmpty = Setting.OnEmpty()
                local priorityList = {} -- Kicia default Priority = {} (all equal; first-found wins)
                -- The slot is the Items-table key (1=Primary, 2=Secondary, 3=Melee - the game's
                -- own EquipPrimary input is EquipItem(1)). Kicia's registry passes the same key
                -- into its wrapper as .index; ClientItems carry no index field of their own.
                local bestAttack, bestAttackPri, bestAttackIndex = nil, math.huge, nil
                local bestSwap, bestSwapPri, bestSwapIndex = nil, math.huge, nil
                local anyEnabled = false
                for slotKey, item in next, items do
                    if type(item) == 'table' then
                        local category = itemCategory(slotKey)
                        if category ~= nil and isCategoryEnabled(category) then
                            anyEnabled = true
                            local priority = table.find(priorityList, category) or math.huge
                            if itemType(item) == 'Gun' and itemAmmo(item) == 0 then
                                if itemAmmoReserve(item) > 0 and priority < bestSwapPri then
                                    if onEmpty == 'Reload' then
                                        bestAttackPri = priority
                                        bestAttack = item
                                        bestAttackIndex = slotKey
                                    else
                                        bestSwap = item
                                        bestSwapPri = priority
                                        bestSwapIndex = slotKey
                                    end
                                end
                            elseif bestAttack == nil or priority < bestAttackPri then
                                bestAttackPri = priority
                                bestAttack = item
                                bestAttackIndex = slotKey
                            end
                        end
                    end
                end
                if not anyEnabled then
                    return nil
                end
                if bestAttack == nil then
                    if onEmpty == 'Swap' or bestSwap == nil then
                        return nil
                    end
                    if itemIsEquipped(bestSwap) then
                        return { type = 'Reload', item = bestSwap, itemType = itemType(bestSwap), index = bestSwapIndex }
                    end
                    return { type = 'Swap', item = bestSwap, itemType = itemType(bestSwap), index = bestSwapIndex }
                end
                local emptyGun = itemType(bestAttack) == 'Gun' and itemAmmo(bestAttack) == 0
                if not itemIsEquipped(bestAttack) then
                    return { type = 'Swap', item = bestAttack, itemType = itemType(bestAttack), index = bestAttackIndex }
                end
                if emptyGun then
                    return { type = 'Reload', item = bestAttack, itemType = itemType(bestAttack), index = bestAttackIndex }
                end
                return { type = 'Attack', item = bestAttack, itemType = itemType(bestAttack), index = bestAttackIndex }
            end

            -- ---- shoot lock (Kicia t93, lines 65724-65750) -------------------------------
            local ShootLock = {}
            ShootLock.__index = ShootLock
            function ShootLock.new()
                return setmetatable({ _lockedUntil = nil }, ShootLock)
            end
            function ShootLock:ShouldFire(canFire, lockDuration)
                local now = os.clock()
                local locked = self._lockedUntil ~= nil and now < self._lockedUntil
                if canFire then
                    self._lockedUntil = now + lockDuration
                end
                if not locked then
                    locked = canFire
                end
                return locked
            end
            function ShootLock:Reset()
                self._lockedUntil = nil
            end

            -- ---- spatial limit gate (Kicia t98, lines 142617-142668) ---------------------
            local SPATIAL_BOUND = 4194304
            local function outOfSpatialBound(pos)
                return SPATIAL_BOUND <= math.abs(pos.X) or SPATIAL_BOUND <= math.abs(pos.Y) or SPATIAL_BOUND <= math.abs(pos.Z)
            end
            local SpatialLimitGate = {}
            SpatialLimitGate.__index = SpatialLimitGate
            function SpatialLimitGate.new()
                return setmetatable({ _measurements = {} }, SpatialLimitGate)
            end
            function SpatialLimitGate:Tick(target)
                local key = target.fighter or target
                local m = self._measurements[key]
                if m == nil then
                    m = { expectedDuration = 1 }
                    self._measurements[key] = m
                end
                local now = os.clock()
                local entry = m.limitEntryTime
                local hasAmmo = target.equippedAmmoState ~= false
                if not outOfSpatialBound(target.rootPart.Position) then
                    if entry ~= nil then
                        if hasAmmo then
                            m.expectedDuration = now - entry
                        end
                        m.limitEntryTime = nil
                    end
                    return false
                end
                if entry == nil then
                    m.limitEntryTime = now
                    entry = now
                end
                if hasAmmo and (m.expectedDuration - Setting.Stability()) <= (now - entry) then
                    return false
                end
                return true
            end

            -- ---- defensive module (Kicia t156, lines 151628-151664) ----------------------
            local function localShieldStance(fighter)
                local items = fighter and rawget(fighter, 'Items') or nil
                if type(items) ~= 'table' then
                    return 'None'
                end
                for _, item in next, items do
                    if type(item) == 'table' and itemName(item) == 'Riot Shield' then
                        if itemIsEquipped(item) then
                            return 'Equipped'
                        end
                        return 'Unequipped'
                    end
                end
                return 'None'
            end
            local function getDefensiveCFrame(cframe, stance, targetRootPart)
                if stance == 'Equipped' then
                    return CFrame.new(cframe.Position, targetRootPart.Position)
                end
                if stance == 'Unequipped' then
                    return CFrame.new(cframe.Position, cframe.Position + (cframe.Position - targetRootPart.Position))
                end
                return cframe
            end
            local function getDefensiveViewAngles(stance)
                if stance == 'None' then
                    return nil
                end
                local pitch = (stance == 'Equipped') and 90 or -90
                return { kind = 'Normalized', pitch = pitch, yaw = rbRandom:NextNumber(0, 360) }
            end

            -- ---- evasion (Kicia f573 / f4230 / t167 / t103) ------------------------------
            local FAR_AXIS = 1073741824
            local function ringPoint(anchor, minR, maxR)
                local angle = rbRandom:NextNumber(0, 2 * math.pi)
                local radius = rbRandom:NextNumber(minR, maxR)
                return CFrame.new(anchor + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
                    * CFrame.fromOrientation(
                        rbRandom:NextNumber(0, 2 * math.pi),
                        rbRandom:NextNumber(0, 2 * math.pi),
                        rbRandom:NextNumber(0, 2 * math.pi)
                    )
            end
            local function scatterFar(pos, anchorFromCharacter, baseRadius, radiusFactor)
                local extra = baseRadius * radiusFactor
                local anchor = anchorFromCharacter and pos or Vector3.new(0, pos.Y, 0)
                local ring = ringPoint(anchor, baseRadius, baseRadius + extra)
                local ringPos = ring.Position
                local x, y, z = ringPos.X, ringPos.Y, ringPos.Z
                local pick = rbRandom:NextInteger(1, 3)
                if pick == 1 then
                    x = FAR_AXIS
                elseif pick == 2 then
                    y = FAR_AXIS
                else
                    z = FAR_AXIS
                end
                return ring - ringPos + Vector3.new(x, y, z)
            end
            local function randomEvade(clientCF)
                return scatterFar(clientCF.Position, Setting.RandomAnchorFromCharacter(), Setting.RandomBaseRadius(), Setting.RandomRadiusFactor())
            end
            local function translocateEvade(clientCF, hasTargetsNow)
                -- Kicia fallback (t103.compute): a far ring-scatter (v107(pos, 10000, 1e9)).
                if not hasTargetsNow then
                    return ringPoint(clientCF.Position, 10000, 1000000000)
                end
                local chosen = nil
                for _, part in ipairs(CollectionServiceRB:GetTagged('OutOfBoundsPart')) do
                    if part:GetAttribute('KillDelay') == 0 then
                        chosen = part
                        break
                    end
                end
                if chosen == nil then
                    return ringPoint(clientCF.Position, 10000, 1000000000)
                end
                return chosen.CFrame * CFrame.new(0, -chosen.Size.Y / 2 + Setting.TranslocateOffset(), 0)
            end
            local function depthOsc(range, freq)
                return range.Min + (range.Max - range.Min) * ((math.sin(os.clock() * (2 * math.pi * freq)) + 1) * 0.5)
            end
            local function surfaceCFrame(surface, up, forward)
                return CFrame.fromMatrix(
                    surface.surfacePosition - surface.up * 0.01 - surface.up * up + surface.forward * forward,
                    surface.right,
                    surface.up,
                    -surface.forward
                )
            end
            local PB_OVERLAP = OverlapParams.new()
            PB_OVERLAP.FilterType = Enum.RaycastFilterType.Exclude
            PB_OVERLAP.FilterDescendantsInstances = {}
            PB_OVERLAP.BruteForceAllSlow = true
            local PB_PROBE_SIZE = Vector3.new(5, 5, 5)
            local function isBoundaryPart(part)
                return part.Name == 'Barriers' or part:HasTag('OutOfBoundsPart') or part:HasTag('KillBrick')
            end
            local function hasBoundaryNear(pos)
                for _, part in ipairs(WorkspaceRB:GetPartBoundsInBox(CFrame.new(pos), PB_PROBE_SIZE, PB_OVERLAP)) do
                    if isBoundaryPart(part) then
                        return true
                    end
                end
                return false
            end
            -- Kicia's f6204 (surface descriptor from a part face) is erased; reconstructed as the
            -- part's top-face frame - the only shape consistent with surfaceCFrame's fields.
            local function describeSurface(part)
                local cf = part.CFrame
                return {
                    surfacePosition = (cf * CFrame.new(0, part.Size.Y / 2, 0)).Position,
                    up = cf.UpVector,
                    right = cf.RightVector,
                    forward = cf.LookVector,
                }
            end
            local ProjectileBreaker = {}
            ProjectileBreaker.__index = ProjectileBreaker
            function ProjectileBreaker.new()
                return setmetatable({
                    _nextPositionCooldown = -1,
                    _poolEnvironmentID = nil,
                    _pool = {},
                    _processedParts = {},
                    _lastBreakSurface = nil,
                }, ProjectileBreaker)
            end
            function ProjectileBreaker:BindEnvironment(envId)
                self._poolEnvironmentID = envId
                self._pool = {}
                self._processedParts = {}
            end
            function ProjectileBreaker:_HasProjectileThreat()
                for _, entry in ipairs(collectEnemies()) do
                    if entry.equippedGunProjectile then
                        return true
                    end
                end
                return false
            end
            function ProjectileBreaker:_ScanBatch(envId)
                local depthForwardMax = PB_DEPTH_FORWARD.Min + PB_DEPTH_FORWARD.Max
                local upMid = (PB_DEPTH_UP.Min + PB_DEPTH_UP.Max) * 0.5
                local forwardMid = depthForwardMax * 0.5
                local scanned = 0
                local function consider(part)
                    if not (part:IsA('BasePart') and not self._processedParts[part]) then
                        return
                    end
                    self._processedParts[part] = true
                    scanned = scanned + 1
                    local surface = describeSurface(part)
                    if hasBoundaryNear(surfaceCFrame(surface, upMid, forwardMid).Position) then
                        return
                    end
                    self._pool[#self._pool + 1] = surface
                end
                for _, tagged in ipairs(CollectionServiceRB:GetTagged('RaycastWhitelist' .. tostring(envId))) do
                    if not isBoundaryPart(tagged) then
                        consider(tagged)
                        if 64 <= scanned or 30 <= #self._pool then
                            return
                        end
                        for _, descendant in ipairs(tagged:GetDescendants()) do
                            if not isBoundaryPart(descendant) then
                                consider(descendant)
                                if 64 <= scanned or 30 <= #self._pool then
                                    return
                                end
                            end
                        end
                    end
                end
            end
            function ProjectileBreaker:_BreakLine()
                local envId = self._poolEnvironmentID
                if envId == nil then
                    return nil
                end
                if #self._pool < 30 then
                    self:_ScanBatch(envId)
                end
                if #self._pool < 30 then
                    return nil
                end
                self._nextPositionCooldown = os.clock() + Setting.RepositionInterval()
                return self._pool[rbRandom:NextInteger(1, #self._pool)]
            end
            function ProjectileBreaker:Compute(clientCF)
                if os.clock() < self._nextPositionCooldown then
                    local last = self._lastBreakSurface
                    if last ~= nil then
                        return surfaceCFrame(last, depthOsc(PB_DEPTH_UP, PB_DEPTH_UP_FREQ), depthOsc(PB_DEPTH_FORWARD, PB_DEPTH_FORWARD_FREQ))
                    end
                end
                if not self:_HasProjectileThreat() then
                    self._lastBreakSurface = nil
                    return scatterFar(clientCF.Position, PB_FALLBACK_ANCHOR_FROM_CHARACTER, PB_FALLBACK_BASE_RADIUS, PB_FALLBACK_RADIUS_FACTOR)
                end
                local breakLine = self:_BreakLine()
                if breakLine == nil then
                    return scatterFar(clientCF.Position, PB_FALLBACK_ANCHOR_FROM_CHARACTER, PB_FALLBACK_BASE_RADIUS, PB_FALLBACK_RADIUS_FACTOR)
                end
                self._lastBreakSurface = breakLine
                return surfaceCFrame(breakLine, depthOsc(PB_DEPTH_UP, PB_DEPTH_UP_FREQ), depthOsc(PB_DEPTH_FORWARD, PB_DEPTH_FORWARD_FREQ))
            end
            function ProjectileBreaker:ResetState()
                self._nextPositionCooldown = -1
                self._lastBreakSurface = nil
            end

            -- ---- firing strategies (Kicia t96 hitscan / t98 melee) -----------------------
            local function farMiss()
                return CFrame.new(
                    math.random(-1000000, 1000000),
                    math.random(5000, 10000),
                    math.random(-1000000, 1000000)
                )
            end
            local HitscanStrategy = {}
            HitscanStrategy.__index = HitscanStrategy
            function HitscanStrategy.new(partGlue)
                return setmetatable({ _partGlue = partGlue, _shootLock = ShootLock.new() }, HitscanStrategy)
            end
            function HitscanStrategy:Plan(dt, target, item, ourRootPart, canFire)
                local hitboxHead = target.hitboxHead
                local above = isAbove(target)
                local offset = above and OFFSET_ABOVE or OFFSET_BELOW
                local void = self._partGlue:Acquire(ourRootPart, hitboxHead)
                self._gluedOurPart = ourRootPart
                local cframe
                if above then
                    cframe = void + offset
                else
                    cframe = CFrame.new(void.Position + offset, hitboxHead.Position)
                end
                if not self._shootLock:ShouldFire(canFire, dt * Setting.ShootFrames()) then
                    return farMiss(), nil
                end
                local _, oy, oz = target.rootPart.CFrame:ToOrientation()
                local pitch = above and PITCH_ABOVE or PITCH_BELOW
                local aim1 = buildAim(above and AIM_ABOVE_ORIGIN or AIM_BELOW_ORIGIN, pitch, oy, oz)
                local aim2 = buildAim(above and AIM_ABOVE_END or AIM_BELOW_END, pitch, oy, oz)
                local objectId = itemObjectId(item)
                local isRaycast = itemIsRaycast(item)
                local function weaponAction()
                    fireGun(objectId, isRaycast, aim1, aim2, hitboxHead, AIM_EXTRA)
                end
                return cframe, weaponAction
            end
            function HitscanStrategy:ResetState()
                self._shootLock:Reset()
                local glued = self._gluedOurPart
                if glued ~= nil then
                    self._partGlue:Free(glued)
                    self._gluedOurPart = nil
                end
            end

            local BACKSTAB_WINDOW = 0.625
            local BACKSTAB_COOLDOWN = 1.25
            local MeleeStrategy = {}
            MeleeStrategy.__index = MeleeStrategy
            function MeleeStrategy.new(partGlue)
                return setmetatable({
                    _partGlue = partGlue,
                    _shootLock = ShootLock.new(),
                    _hitboxWindowUntil = -1,
                    _attackCooldown = -1,
                }, MeleeStrategy)
            end
            local function meleeViewAngles(px, oy)
                return { kind = 'Normalized', pitch = math.deg(px), yaw = math.deg(oy) }
            end
            function MeleeStrategy:_RecordBackstab()
                local now = os.clock()
                self._hitboxWindowUntil = now + BACKSTAB_WINDOW
                self._attackCooldown = now + BACKSTAB_COOLDOWN
            end
            function MeleeStrategy:Plan(dt, target, item, ourRootPart, canFire)
                local hitboxHead = target.hitboxHead
                local above = isAbove(target)
                local offset = above and OFFSET_ABOVE or OFFSET_BELOW
                local void = self._partGlue:Acquire(ourRootPart, hitboxHead)
                self._gluedOurPart = ourRootPart
                local cframe
                if above then
                    cframe = void + offset
                else
                    cframe = CFrame.new(void.Position + offset, hitboxHead.Position)
                end
                local px, oy, oz = target.rootPart.CFrame:ToOrientation()
                local pitch = above and PITCH_ABOVE or PITCH_BELOW
                local aim1 = buildAim(above and AIM_ABOVE_ORIGIN or AIM_BELOW_ORIGIN, pitch, oy, oz)
                local aim2 = buildAim(above and AIM_ABOVE_END or AIM_BELOW_END, pitch, oy, oz)
                local objectId = itemObjectId(item)
                local now = os.clock()
                if now < self._hitboxWindowUntil then
                    return cframe, meleeViewAngles(px, oy), function()
                        fireMeleeHeavy(objectId, aim1, aim2, hitboxHead, AIM_EXTRA)
                    end
                end
                if not self._shootLock:ShouldFire(canFire, dt * Setting.ShootFrames()) then
                    return farMiss(), nil, nil
                end
                if now < self._attackCooldown then
                    return farMiss(), nil, nil
                end
                if itemName(item) ~= 'Knife' then
                    return cframe, nil, function()
                        fireMeleeAttack(objectId, aim1, aim2, hitboxHead, AIM_EXTRA)
                    end
                end
                self:_RecordBackstab()
                return cframe, meleeViewAngles(px, oy), function()
                    fireMeleeHeavy(objectId, aim1, aim2, hitboxHead, AIM_EXTRA)
                end
            end
            function MeleeStrategy:ResetState()
                self._hitboxWindowUntil = -1
                self._attackCooldown = -1
                self._shootLock:Reset()
                local glued = self._gluedOurPart
                if glued ~= nil then
                    self._partGlue:Free(glued)
                    self._gluedOurPart = nil
                end
            end

            -- ---- FFlag environment toggles (Kicia SetEnabled, lines 63538-63571) ----------
            local ORIGINAL_FALLEN_PARTS_HEIGHT = nil
            local function applyEnabledFFlags(enabled)
                if enabled and ORIGINAL_FALLEN_PARTS_HEIGHT == nil then
                    ORIGINAL_FALLEN_PARTS_HEIGHT = WorkspaceRB.FallenPartsDestroyHeight
                end
                pcall(function()
                    WorkspaceRB.FallenPartsDestroyHeight = enabled and (0 / 0) or (ORIGINAL_FALLEN_PARTS_HEIGHT or -500)
                end)
                if rbSetFFlag then
                    pcall(rbSetFFlag, 'DFIntS2PhysicsSenderRate', enabled and '120' or '15')
                    pcall(rbSetFFlag, 'DFIntAssemblyHistoryBufferSize', enabled and '2147483648' or '15')
                    pcall(rbSetFFlag, 'DFIntAssemblyHistorySkipSize', enabled and '0' or '8')
                end
            end

            -- ---- controller (Kicia t1, lines 63573-63758) --------------------------------
            local Controller = {}
            Controller.__index = Controller
            function Controller.new()
                local partGlue = PartGlue.new()
                return setmetatable({
                    _enabled = false,
                    _partGlue = partGlue,
                    _hitscanStrategy = HitscanStrategy.new(partGlue),
                    _meleeStrategy = MeleeStrategy.new(partGlue),
                    _projectileBreaker = ProjectileBreaker.new(),
                    _spatialLimitGate = SpatialLimitGate.new(),
                    _stateHook = StateHook.new(),
                    _characterController = nil,
                    _boundRootPart = nil,
                    _lastTargetWorld = nil,
                    _lastDefensiveViewAngles = nil,
                }, Controller)
            end
            function Controller:SetEnabled(enabled)
                if self._enabled == enabled then
                    return
                end
                self._enabled = enabled
                applyEnabledFFlags(enabled)
                self:_Reset()
            end
            function Controller:_ApplyForcedCrouch(on)
                if on then
                    self._stateHook:SetForced('IsCrouching', true)
                else
                    self._stateHook:ClearForced('IsCrouching', false)
                end
            end
            function Controller:_EnsureCharacterController()
                local Char, HumanoidRootPart = GetChar(), GetRoot()
                if not HumanoidRootPart or HumanoidRootPart.Parent ~= Char then
                    if self._characterController then
                        self._characterController:Destroy()
                        self._characterController = nil
                        self._boundRootPart = nil
                    end
                    return nil
                end
                if self._characterController == nil or self._boundRootPart ~= HumanoidRootPart then
                    if self._characterController then
                        self._characterController:Destroy()
                    end
                    self._characterController = CharacterController.new(HumanoidRootPart)
                    self._boundRootPart = HumanoidRootPart
                end
                return self._characterController
            end
            function Controller:_EvadePlan(clientCF, mode)
                if mode == 'Off' then
                    return {}
                end
                if mode ~= 'ProjectileBreaker' then
                    return { cframe = randomEvade(clientCF) }
                end
                return { cframe = self._projectileBreaker:Compute(clientCF), shouldSkipDefense = true }
            end
            function Controller:_Plan(dt, action, target, ourRootPart, clientCF, mode)
                local canFire = true
                if target ~= nil then
                    canFire = not self._spatialLimitGate:Tick(target)
                end
                if action == nil then
                    return self:_EvadePlan(clientCF, mode)
                end
                if action.type == 'Swap' then
                    local plan = self:_EvadePlan(clientCF, mode)
                    local item = action.item
                    local index = action.index
                    plan.weaponAction = function() equipItem(item, index) end
                    return plan
                end
                if action.type == 'Reload' then
                    local plan = self:_EvadePlan(clientCF, mode)
                    local item = action.item
                    plan.weaponAction = function() reloadItem(item) end
                    return plan
                end
                if target == nil then
                    return self:_EvadePlan(clientCF, mode)
                end
                if action.itemType == 'Melee' then
                    local cframe, viewAngles, weaponAction = self._meleeStrategy:Plan(dt, target, action.item, ourRootPart, canFire)
                    return { cframe = cframe, viewAngles = viewAngles, weaponAction = weaponAction, shouldSkipDefense = true, shouldForceCrouch = true }
                end
                if action.itemType ~= 'Gun' then
                    return {}
                end
                if itemIsReloading(action.item) then
                    return self:_EvadePlan(clientCF, mode)
                end
                local cframe, weaponAction = self._hitscanStrategy:Plan(dt, target, action.item, ourRootPart, canFire)
                return { cframe = cframe, weaponAction = weaponAction, shouldForceCrouch = true, isAimPose = weaponAction ~= nil }
            end
            function Controller:_ApplyPlan(plan, target, characterController, fighter)
                local cframe = plan.cframe
                if cframe == nil or target == nil or plan.shouldSkipDefense then
                    characterController:SetServerCFrame(cframe)
                    characterController:SendViewAngles(20, plan.viewAngles)
                    return
                end
                local stance = localShieldStance(fighter)
                characterController:SetServerCFrame(getDefensiveCFrame(cframe, stance, target.rootPart))
                if plan.isAimPose or plan.shouldDefendInPlace then
                    self._lastDefensiveViewAngles = getDefensiveViewAngles(stance)
                end
                characterController:SendViewAngles(20, plan.viewAngles or self._lastDefensiveViewAngles)
            end
            function Controller:Update(dt)
                local fighter = resolveLocalFighter()
                local characterController = self:_EnsureCharacterController()
                if fighter == nil or characterController == nil or not self._enabled then
                    self:_Reset()
                    return
                end
                if RivalsRuntimeBridge.IsReadyToFight and not RivalsRuntimeBridge.IsReadyToFight() then
                    self:_Reset()
                    return
                end
                local ourRootPart = self._boundRootPart
                local clientCF = characterController:GetClientCFrame()
                local mode = Setting.EvasionMode()
                if mode == 'Translocate' then
                    self:_ApplyForcedCrouch(false)
                    characterController:SetServerCFrame(translocateEvade(clientCF, hasTargets()))
                    characterController:HeartbeatUpdate()
                    return
                end
                local target = selectTarget()
                local action = getAction(fighter)
                self._lastTargetWorld = target ~= nil and target.rootPart.Position or nil
                local plan = self:_Plan(dt, action, target, ourRootPart, clientCF, mode)
                self:_ApplyPlan(plan, target, characterController, fighter)
                self:_ApplyForcedCrouch(plan.shouldForceCrouch == true)
                if plan.weaponAction ~= nil then
                    plan.weaponAction()
                end
                characterController:HeartbeatUpdate()
            end
            function Controller:GetLastTargetWorld()
                return self._lastTargetWorld
            end
            function Controller:_Reset()
                self._lastTargetWorld = nil
                self._lastDefensiveViewAngles = nil
                self:_ApplyForcedCrouch(false)
                self._meleeStrategy:ResetState()
                self._hitscanStrategy:ResetState()
                self._projectileBreaker:ResetState()
                if self._characterController then
                    self._characterController:SetServerCFrame(nil)
                    self._characterController:SendViewAngles(20, nil)
                    self._characterController:HeartbeatUpdate()
                end
            end
            function Controller:Destroy()
                self:SetEnabled(false)
                self:_Reset()
                if self._characterController then
                    self._characterController:Destroy()
                    self._characterController = nil
                    self._boundRootPart = nil
                end
                self._partGlue:Destroy()
                applyEnabledFFlags(false)
            end

            -- ---- lifecycle / bridge ------------------------------------------------------
            local controllerInstance = nil
            local function ensureController()
                if controllerInstance == nil then
                    controllerInstance = Controller.new()
                end
                return controllerInstance
            end
            function KiciaRagebot.IsEnabled()
                if not togValue('P8S4T1', false) then
                    return false
                end
                -- Executor support: FighterController discovery walks the GC and the
                -- void redirect writes the hidden PhysicsRepRootPart property. Without
                -- either the bot cannot function, so decline (one-time notice via the
                -- gate) instead of running the loop's side effects for nothing.
                -- Checked after the toggle so the notice fires at enable, not at load;
                -- cached because this runs per-frame.
                if KiciaRagebot.CapsOk == nil then
                    KiciaRagebot.CapsOk = __kicia_hook_genv.KiciaHookCaps.gate('Ragebot', 'getgc', 'sethiddenproperty')
                end
                if not KiciaRagebot.CapsOk then
                    return false
                end
                -- Practice / shooting range: the ragebot must never act here (target dummies, no real
                -- match). Live-verified: the local fighter carries IsInShootingRange=true in
                -- the practice range and IsInDuel=true in real 1v1s. Returning false makes the controller
                -- settle to disabled (release part-glue, restore FFlags) via the normal Update path. The
                -- Seeded guard means we only gate once the duel state has actually been read.
                local localDuel = FighterDataCache and FighterDataCache.LocalDuel
                if localDuel and localDuel.Seeded and localDuel.IsInShootingRange == true then
                    return false
                end
                -- Enabled AND keybind-active (Kicia ObserveEnabledKeybind); Mode 'Always' -> always true.
                local keypicker = Options and Options.P8S4T1K
                if keypicker and type(keypicker.GetState) == 'function' then
                    return keypicker:GetState() == true
                end
                return true
            end
            function KiciaRagebot.Update(dt)
                local controller = ensureController()
                local enabled = KiciaRagebot.IsEnabled()
                if controller._enabled ~= enabled then
                    controller:SetEnabled(enabled)
                end
                controller:Update(dt or 0)
            end
            function KiciaRagebot.Reset()
                if controllerInstance then
                    controllerInstance:_Reset()
                end
            end
            function KiciaRagebot.Destroy()
                if controllerInstance then
                    controllerInstance:Destroy()
                    controllerInstance = nil
                end
            end
            RivalsRuntimeBridge.UpdateKiciaRagebot = KiciaRagebot.Update
            RivalsRuntimeBridge.ResetKiciaRagebot = KiciaRagebot.Reset
            RivalsRuntimeBridge.DestroyKiciaRagebot = KiciaRagebot.Destroy
        -- __KICIA_RAGEBOT_END__
