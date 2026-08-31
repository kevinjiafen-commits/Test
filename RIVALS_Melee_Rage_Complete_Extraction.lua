-- Exact source extraction from raw (2) (1).txt
-- Melee Rage dependency tree: constants -> helpers -> firing -> locks/glue -> MeleeStrategy -> Controller wiring

-- ==================== CONSTANTS ====================
            local OFFSET_ABOVE = Vector3.new(0, -0.7, 0.05)                                -- v230/v138
            local OFFSET_BELOW = Vector3.new(0, -3.85, 0.05)                               -- v231/v139
            local PITCH_ABOVE = -math.pi / 2                                               -- v140
            local PITCH_BELOW = math.pi / 2                                                -- v141
            local AIM_ABOVE_ORIGIN = { ['\0'] = NEG_HUGE, ['\1'] = 0, ['\2'] = 0 }         -- t91
            local AIM_ABOVE_END = { ['\0'] = 0, ['\1'] = -90000000, ['\2'] = 0 }           -- t92
            local AIM_BELOW_ORIGIN = { ['\0'] = NEG_HUGE, ['\1'] = 0, ['\2'] = 0 }         -- t93
            local AIM_BELOW_END = { ['\0'] = 0, ['\1'] = 90000000, ['\2'] = 0 }            -- t94
            local AIM_EXTRA = { ['\0'] = 0, ['\1'] = 1, ['\2'] = 0, ['\3'] = 0, ['\4'] = 0, ['\5'] = 0 } -- t95

-- ==================== HELPERS ====================
            local function itemName(item)
                return rawget(item, 'Name') or rawget(item, 'ItemName')
            end
            local function itemObjectId(item)
                local data = rawget(item, 'Data')
                return data and rawget(data, 'ObjectID') or nil
            end
            local function meleeViewAngles(px, oy)
                return { kind = 'Normalized', pitch = math.deg(px), yaw = math.deg(oy) }
            end
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
            local function isAbove(target)
                return classifyAboveBelow(target) ~= 'Below'
            end

            -- ---- root virtualization (Kicia t201, lines 145034-145080) -------------------
            local RootDesync = {}
            RootDesync.__index = RootDesync
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
            local function farMiss()
                return CFrame.new(
                    math.random(-1000000, 1000000),
                    math.random(5000, 10000),
                    math.random(-1000000, 1000000)
                )
            end
            local HitscanStrategy = {}
            HitscanStrategy.__index = HitscanStrategy

-- ==================== FIRING HELPERS ====================
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

-- ==================== SHOOT LOCK ====================
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

-- ==================== PART GLUE ====================
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

-- ==================== SPATIAL LIMIT GATE ====================
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

-- ==================== MELEE STRATEGY ====================
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

-- ==================== CONTROLLER WIRING ====================
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
