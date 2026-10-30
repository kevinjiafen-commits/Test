--!nocheck
--!nolint

-- ============================================================
--  EXTRACTED: Counter · Priority (Targets) · Ragebot
--  Source: AntiBrain (Rivals)
--  All dependency modules included inline.
--  Requires: Desync service, Encoder service (anti-aim layer),
--            RenderStep binder, standard executor globals
--            (setthreadidentity, sethiddenproperty, getrawmetatable)
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- [1] Failure  (error capture / traceback helper)
-- ────────────────────────────────────────────────────────────
local Failure = (function()
    local F = {}

    F.traceback = function(problem)
        local ok, text = pcall(tostring, problem)
        return debug.traceback((ok and text or 'An unprintable error was raised'), 2)
    end
    F.capture = function(callback, ...)
        local ok, message = xpcall(callback, F.traceback, ...)
        return (ok and nil or message)
    end
    function F.summary(failure)
        return failure:match('^[^\n]*') or failure
    end

    return table.freeze(F)
end)()


-- ────────────────────────────────────────────────────────────
-- [2] Fighter  (alive / invincible / deflecting checks)
-- ────────────────────────────────────────────────────────────
local Fighter = (function()
    local F = {}

    F.alive = function(fighter, player)
        if type(fighter) ~= 'table' or type(fighter.Items) ~= 'table' or #fighter.Items == 0 then
            return false
        end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass('Humanoid') or nil
        return humanoid ~= nil and humanoid.Health > 0
    end
    F.invincible = function(fighter)
        local entity = fighter.Entity
        return type(entity) ~= 'table' or (entity._invincibility_visual and true or false)
    end
    F.deflecting = function(fighter)
        local item = fighter.EquippedItem
        return type(item) == 'table'
            and item._deflect_hash
            and type(item._attack_cooldown) == 'number'
            and tick() < item._attack_cooldown
    end

    return table.freeze(F)
end)()


-- ────────────────────────────────────────────────────────────
-- [3] Shot  (CFrame packing / scatter)
-- ────────────────────────────────────────────────────────────
local Shot = (function()
    local PACKED = table.freeze({ '\0', '\1', '\2', '\3', '\4', '\5' })
    local SCATTER = 0.1

    local pack = function(frame)
        local x, y, z = frame:ToOrientation()
        local position = frame.Position
        local values = { position.X, position.Y, position.Z, x, y, z }
        local packed = {}
        for index, key in PACKED do
            packed[key] = values[index]
        end
        return packed
    end

    local unpackFrame = function(packed)
        if type(packed) ~= 'table' then return nil end
        local values = table.create(6)
        for index, key in PACKED do
            local value = packed[key]
            if type(value) ~= 'number' then return nil end
            values[index] = value
        end
        return CFrame.new(values[1], values[2], values[3])
             * CFrame.fromOrientation(values[4], values[5], values[6])
    end

    local S = {}
    S.pack = pack

    function S.scatter()
        return CFrame.new(
            math.random() * SCATTER,
            math.random() * SCATTER,
            math.random() * SCATTER
        )
    end

    S.aim = function(cameraData, part, manipulation)
        if type(cameraData) ~= 'table' then return end
        local camera = unpackFrame(cameraData['\0'])
        local muzzle = unpackFrame(cameraData['\1'])
        if not camera or not muzzle then return end

        local offset = CFrame.new(Random.new():NextUnitVector() * SCATTER)
        if manipulation then
            camera = CFrame.new(manipulation.origin) * camera.Rotation
            muzzle = CFrame.new(manipulation.origin) * muzzle.Rotation
            if manipulation.hitOffset then
                offset = CFrame.new(manipulation.hitOffset)
            end
        else
            camera = CFrame.lookAt(camera.Position, part.Position)
            muzzle = CFrame.lookAt(muzzle.Position, part.Position)
        end
        cameraData['\0'] = pack(camera)
        cameraData['\1'] = pack(muzzle)
        cameraData['\3'] = pack(offset)
        cameraData['\2'] = part
    end

    return table.freeze(S)
end)()


-- ────────────────────────────────────────────────────────────
-- [4] Swing  (melee send / animation key)
-- ────────────────────────────────────────────────────────────
local Swing = (function()
    local SW = {}

    function SW.data(aim, part)
        return {
            ['\0'] = Shot.pack(aim),
            ['\1'] = Shot.pack(aim + Vector3.one * 0.01),
            ['\2'] = part,
            ['\3'] = Shot.pack(Shot.scatter()),
        }
    end
    function SW.animation(item, heavy)
        local kind = heavy and 'HeavyAttack' or 'Attack'
        local count = #item.ViewModel:GetAnimationKeys(kind)
        if count == 0 then return nil end
        if heavy then
            item._heavy_attack_num = (item._heavy_attack_num or 0) % count + 1
            return string.format('%s%s', kind, item._heavy_attack_num)
        end
        item._attack_num = (item._attack_num or 0) % count + 1
        return string.format('%s%s', kind, item._attack_num)
    end
    function SW.send(use, enums, item, aim, part, heavy)
        local animation = SW.animation(item, heavy)
        if not animation then return false end
        use(
            item:Get('ObjectID'),
            enums:ToEnum(heavy and 'StartAiming' or 'StartShooting'),
            { ['\1'] = SW.data(aim, part), ['\2'] = enums:ToEnum(animation) },
            nil
        )
        return true
    end

    return table.freeze(SW)
end)()


-- ────────────────────────────────────────────────────────────
-- [5] Origins  (gun shot-origin resolver)
-- ────────────────────────────────────────────────────────────
local Origins = (function()
    local O = {}
    local TRACK_REACH = 16

    function O.gun(target, preferred, eye, held, clear)
        if held
            and (held.Position - target).Magnitude <= TRACK_REACH
            and clear(held.Position + eye, target)
        then
            return held
        end
        if clear(preferred + eye, target) then
            return CFrame.new(preferred)
        end
        for _, offset in {
            Vector3.new( 3, 1,  0),
            Vector3.new(-3, 1,  0),
            Vector3.new( 0, 1,  3),
            Vector3.new( 0, 1, -3),
            Vector3.new( 3, 3,  3),
            Vector3.new(-3, 3, -3),
        } do
            local position = target + offset
            if clear(position + eye, target) then
                return CFrame.new(position)
            end
        end
        return nil
    end

    return table.freeze(O)
end)()


-- ────────────────────────────────────────────────────────────
-- [6] Ragers  (ragebot-detection heuristic)
-- ────────────────────────────────────────────────────────────
local Ragers = (function()
    local SPEED         = 400
    local JUMP_DISTANCE = 20
    local HOVER_HEIGHT  = 12
    local HOVER_DRIFT   = 0.2
    local HOVER_TIME    = 0.5
    local THRESHOLD     = 4
    local WINDOW        = 3
    local MEMORY        = 15

    local R = {}
    R.WINDOW = WINDOW
    R.MEMORY = MEMORY

    function R.new()
        return { seen = {}, signs = {}, flagged = {} }
    end

    local function sign(ragers, player, now, points)
        local signs = ragers.signs[player]
        if not signs then
            signs = {}
            ragers.signs[player] = signs
        end
        table.insert(signs, { at = now, points = points })
        while signs[1] and now - signs[1].at > WINDOW do
            table.remove(signs, 1)
        end
        local total = 0
        for _, entry in signs do total = total + entry.points end
        if total >= THRESHOLD then ragers.flagged[player] = now end
    end

    function R.observe(ragers, player, sample)
        local now  = sample.now
        local last = ragers.seen[player]
        local seen = { x = sample.x, y = sample.y, z = sample.z, at = now, still = nil }
        ragers.seen[player] = seen

        if sample.grace   then return end
        if sample.outside then sign(ragers, player, now, THRESHOLD) end
        if not last or now <= last.at then return end

        local dx, dy, dz = sample.x - last.x, sample.y - last.y, sample.z - last.z
        local distance = math.sqrt(dx*dx + dy*dy + dz*dz)

        if distance >= JUMP_DISTANCE and distance / (now - last.at) > SPEED then
            sign(ragers, player, now, sample.nearMe and 2 or 1)
            return
        end

        local height = sample.height
        if height and height >= HOVER_HEIGHT and math.abs(dy) <= HOVER_DRIFT then
            local since = last.still or last.at
            if now - since >= HOVER_TIME then
                sign(ragers, player, now, 1)
                seen.still = now
            else
                seen.still = since
            end
        end
    end
    function R.is(ragers, player, now)
        local at = ragers.flagged[player]
        return at ~= nil and now - at <= MEMORY
    end
    function R.respawned(ragers, player)
        ragers.seen[player] = nil
    end

    return table.freeze(R)
end)()


-- ────────────────────────────────────────────────────────────
-- [7] Watch  (per-frame opponent list + rager tracking)
-- ────────────────────────────────────────────────────────────
local Watch = (function()
    local OUTSIDE = 100
    local GROUND  = 200
    local VOID    = 1000000
    local RUNNING = 200
    local NEAR    = 8
    local GRACE   = 1.5

    local W = {}

    function W.new()
        local ground = RaycastParams.new()
        ground.FilterType = Enum.RaycastFilterType.Exclude
        return { ragers = Ragers.new(), ground = ground, box = nil, spawned = {}, last = {} }
    end

    local function barriers(watch, duel)
        local map    = type(duel.Map) == 'table' and duel.Map.Model or nil
        local folder = typeof(map) == 'Instance' and map:FindFirstChild('Barriers') or nil
        if not folder then return nil, nil end

        local held = watch.box
        if held and held.map == map then return held.low, held.high end

        local low  = Vector3.one * math.huge
        local high = -Vector3.one * math.huge
        for _, part in folder:GetChildren() do
            if part:IsA('BasePart') then
                local half = part.Size / 2
                low  = low:Min(part.Position - half)
                high = high:Max(part.Position + half)
            end
        end
        if low.X > high.X then return nil, nil end
        watch.box = { map = map, low = low, high = high }
        return low, high
    end

    function W.update(watch, me, duel, mine)
        local Workspace = game:GetService('Workspace')
        local Players   = game:GetService('Players')
        local RunService = game:GetService('RunService')

        local list    = {}
        local duelers = type(duel) == 'table' and duel._duelers_by_player or nil
        if type(duelers) ~= 'table' then return list end

        local now     = tick()
        local started = type(duel.Data) == 'table' and duel.Data.Status == 'RoundStarted'
        local low, high = barriers(watch, duel)
        local characters = {}
        for player in duelers do
            if player.Character then table.insert(characters, player.Character) end
        end
        watch.ground.FilterDescendantsInstances = characters

        for player, dueler in duelers do
            local character = player.Character
            local humanoid  = character and character:FindFirstChildOfClass('Humanoid') or nil
            local root      = character and character:FindFirstChild('HumanoidRootPart') or nil

            if player ~= me and character and type(dueler) == 'table'
                and humanoid and root and root:IsA('BasePart')
            then
                local ally     = dueler._is_ally == true
                local position = root.Position
                local health   = humanoid.Health
                local outside  = position.Magnitude >= VOID

                if low and high then
                    outside = outside or (position - position:Max(low):Min(high)).Magnitude > OUTSIDE
                end

                if not ally and health > 0 then
                    local held = watch.spawned[player]
                    local life = (held and held.character == character) and held or nil
                    if not life then
                        life = { character = character, at = now }
                        watch.spawned[player] = life
                        Ragers.respawned(watch.ragers, player)
                    end
                    local born = life.at
                    local hit  = Workspace:Raycast(position, Vector3.new(0, -GROUND, 0), watch.ground)

                    Ragers.observe(watch.ragers, player, {
                        x       = position.X,
                        y       = position.Y,
                        z       = position.Z,
                        now     = now,
                        outside = outside,
                        nearMe  = (position - mine).Magnitude <= NEAR,
                        height  = hit and (position.Y - hit.Position.Y) or GROUND,
                        grace   = not started or now - born < GRACE,
                    })
                end

                local seen     = watch.last[player]
                local velocity = root.AssemblyLinearVelocity
                if seen and now - seen.at > 0.005 then
                    local moved = (position - seen.position) / (now - seen.at)
                    if moved.Magnitude <= RUNNING and moved.Magnitude > velocity.Magnitude then
                        velocity = moved
                    end
                end
                if not seen or now - seen.at > 0.005 then
                    watch.last[player] = { position = position, at = now }
                end

                local head = character:FindFirstChild('HitboxHead')
                          or character:FindFirstChild('HitboxBody')

                table.insert(list, {
                    player   = player,
                    name     = player.Name,
                    character = character,
                    root     = root,
                    part     = (head and head:IsA('BasePart')) and head or root,
                    position = position,
                    velocity = velocity,
                    distance = (position - mine).Magnitude,
                    health   = health,
                    ally     = ally,
                    rager    = not ally and Ragers.is(watch.ragers, player, now),
                    inside   = not outside,
                })
            end
        end
        return list
    end

    return table.freeze(W)
end)()


-- ────────────────────────────────────────────────────────────
-- [8] Blink  (solix / kicia movement engine for Counter)
-- ────────────────────────────────────────────────────────────
local Blink = (function()
    local DEFAULTS = table.freeze({
        flySpeed    = 15000,
        zigAmplitude = 400,
        zigFrequency = 8,
        cycle       = 0.05,
        flyTime     = 0.025,
        depth       = 6,
        boost       = 100000,
        boostEvery  = 0.6,
        spread      = 30,
    })
    local MOST_FLYING = 0.95
    local B = {}
    B.DEFAULTS = DEFAULTS

    function B.new()
        return {
            started = nil,
            fly     = { x = 0, y = 0, z = 0 },
            boostAt = 0,
            cycle   = nil,
            stop    = nil,
            spot    = nil,
            from    = nil,
        }
    end
    function B.reset(blink)
        blink.started, blink.cycle, blink.stop, blink.spot, blink.from = nil, nil, nil, nil, nil
    end

    local function pick(blink, spots, engine, random)
        local index = math.clamp(math.floor(random() * #spots) + 1, 1, #spots)
        if index == blink.spot and #spots > 1 then
            index = index % #spots + 1
        end
        blink.spot = index
        local spot   = spots[index]
        local angle  = random() * math.pi * 2
        local distance = math.sqrt(random()) * engine.spread
        return {
            x      = spot.x + math.cos(angle) * distance,
            y      = spot.floor - engine.depth,
            z      = spot.z + math.sin(angle) * distance,
            flying = false,
        }
    end

    function B.pose(blink, now, delta, from, spots, random, engine)
        if not blink.started then
            blink.started = now
            blink.from    = { x = from.x, y = from.y, z = from.z }
            blink.fly     = { x = from.x, y = from.y, z = from.z }
            blink.boostAt = now + engine.boostEvery
        end

        local home = blink.from or from
        local fly  = blink.fly

        fly.y = fly.y + engine.flySpeed * delta
        if now >= blink.boostAt then
            fly.y = fly.y + engine.boost
            blink.boostAt = now + engine.boostEvery
        end

        local length  = math.max(engine.cycle, 0.005)
        local elapsed = now - blink.started
        local cycle   = math.floor(elapsed / length)
        local phase   = elapsed / length - cycle
        local share   = math.min(engine.flyTime / length, MOST_FLYING)

        if phase < share or (spots and #spots == 0) then
            return {
                x      = fly.x + math.cos(now * engine.zigFrequency) * engine.zigAmplitude,
                y      = fly.y,
                z      = fly.z,
                flying = true,
            }
        end
        if not spots then
            return { x = home.x, y = home.y - engine.depth, z = home.z, flying = false }
        end

        local stop = blink.stop
        if not stop or blink.cycle ~= cycle then
            stop = pick(blink, spots, engine, random)
            blink.stop, blink.cycle = stop, cycle
        end
        return stop
    end

    return table.freeze(B)
end)()


-- ────────────────────────────────────────────────────────────
-- [9] Void resolver  (hides real position behind 2^20 Y)
-- ────────────────────────────────────────────────────────────
local function makeVoidResolver(_duel, _private, real)
    local HEIGHT = 2 ^ 20
    return function()
        local position = real()
        if position and position.Magnitude < HEIGHT then
            return CFrame.new(position.X, HEIGHT, position.Z)
        end
        return CFrame.new(0, HEIGHT, 0)
    end
end


-- ────────────────────────────────────────────────────────────
-- [10] CounterSystem  (core counter logic — module K)
-- ────────────────────────────────────────────────────────────
local CounterSystem = (function()
    local LIFT      = 6000
    local CEILING   = 40000
    local HOP_EVERY = 4
    local HOP_MIN, HOP_MAX = 1000, 2000
    local EYE    = 1.75
    local CAMERA = 1.8
    local ORDER  = 1.5
    local NAMES  = table.freeze({
        ue    = 'ue counter',
        solix = 'solix counter',
        kicia = 'kicia counter',
    })

    local function isMelee(item)
        return type(item) == 'table'
            and type(item.Info) == 'table'
            and item.Info.Type == 'Melee'
    end
    local function short(height)
        local size = math.abs(height)
        if size >= 1e6 then return string.format('%sM', math.floor(height / 1e5) / 10) end
        if size >= 1e4 then return string.format('%sK', math.floor(height / 1e2) / 10) end
        return tostring(math.floor(height))
    end

    -- Rescue: teleport player to spawn (static util, kept on module)
    local function toSpawn()
        local Modules   = require(game:GetService('ReplicatedStorage'):WaitForChild('Modules'))
        local character = Modules.player().Character
        local part      = character and character:FindFirstChild('HumanoidRootPart') or nil
        if not part or not part:IsA('BasePart') then return end

        local duel   = Modules.controller('SpectateController').CurrentDuelSubject
        local map    = type(duel) == 'table' and type(duel.Map) == 'table' and duel.Map.Model or nil
        local folder = typeof(map) == 'Instance' and map:FindFirstChild('Spawns') or nil
        if not folder then return end

        for _, spawn in folder:GetDescendants() do
            if spawn:IsA('BasePart') then
                part.AssemblyLinearVelocity = Vector3.zero
                part.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 3, 0))
                return
            end
        end
    end

    -- Build all runtime deps from live services
    local function resolve(run, services)
        -- NOTE: `run` is a Scope object, `services` is the service bus.
        -- Replace the Modules calls below with however the host script
        -- exposes them (e.g. game.ReplicatedStorage.Modules, etc.)
        local Modules  = require(game:GetService('ReplicatedStorage'):WaitForChild('Modules'))
        local me       = Modules.player()
        local fighters = Modules.controller('FighterController')
        local spectate = Modules.controller('SpectateController')
        local enums    = Modules.shared('EnumLibrary')
        local useItem  = Modules.remote({ 'Replication', 'Fighter', 'UseItem' })
        local random   = Random.new()
        local watch    = Watch.new()
        local taken    = nil

        local function send(...) useItem:FireServer(...) end
        local function root()
            local character = me.Character
            local part      = character and character:FindFirstChild('HumanoidRootPart') or nil
            return part and part:IsA('BasePart') and part or nil
        end

        return {
            now = tick,
            fighter = function()
                local f = fighters.LocalFighter
                return Fighter.alive(f, me) and f or nil
            end,
            root = root,
            opponents = function(part)
                return Watch.update(watch, me, spectate.CurrentDuelSubject, part.Position)
            end,
            height = function(part) return part.Position.Y end,
            equip = function(fighter, item)
                run:spawn(fighter.EquipItem, fighter, item.Data.ItemIndex)
            end,
            lift = function(part, anchor)
                part.CFrame = CFrame.new(anchor.x, anchor.y + LIFT, anchor.z) * part.CFrame.Rotation
            end,
            hop = function(part)
                local angle    = random:NextNumber(0, math.pi * 2)
                local distance = random:NextNumber(HOP_MIN, HOP_MAX)
                part.CFrame = part.CFrame + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
            end,
            rise = function(part, speed)
                part.AssemblyLinearVelocity = Vector3.new(0, speed, 0)
            end,
            drop = function(part, opponent, lead)
                local position = opponent.position
                local moving   = opponent.velocity * Vector3.new(1, 0, 1)
                local at = position + (moving.Magnitude > 1 and moving.Unit * lead or Vector3.zero)
                part.CFrame = CFrame.new(at) * part.CFrame.Rotation
                part.AssemblyLinearVelocity = Vector3.zero
            end,
            rescue = function(anchor)
                local part = root()
                if part and anchor then
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.CFrame = CFrame.new(anchor.x, anchor.y + 3, anchor.z)
                else
                    toSpawn()
                end
            end,
            prepare = function()
                taken = nil
                local fighter = fighters.LocalFighter
                if type(fighter) == 'table' then
                    local ok, data = pcall(fighter.GetCameraData, fighter)
                    taken = ok and type(data) == 'table' and table.clone(data) or nil
                end
            end,
            replicate = function(part)
                local setIdentity = setthreadidentity
                local setHidden   = sethiddenproperty
                if type(setIdentity) == 'function' then setIdentity(8) end
                if type(setHidden) == 'function' then
                    setHidden(part, 'PhysicsRepRootPart', game:GetService('Workspace').Terrain)
                end
            end,
            swing = function(item, part)
                local own = root()
                if not own then return end
                local data = taken
                if data then
                    local animation = Swing.animation(item, false)
                    if animation then
                        local sent = table.clone(data)
                        sent['\0'] = Shot.pack(CFrame.new(own.Position + Vector3.new(0, CAMERA, 0)))
                        send(item:Get('ObjectID'), enums:ToEnum('StartShooting'), {
                            ['\1'] = sent,
                            ['\2'] = enums:ToEnum(animation),
                        }, nil)
                    end
                    return
                end
                local eye   = own.Position + Vector3.new(0, EYE, 0)
                local level = Vector3.new(part.Position.X, eye.Y, part.Position.Z)
                local aim   = (level - eye).Magnitude > 0.01 and CFrame.lookAt(eye, level) or CFrame.new(eye)
                Swing.send(send, enums, item, aim, part, false)
            end,
            position = function(part)
                local p = part.Position
                return { x = p.X, y = p.Y, z = p.Z }
            end,
            spots = function()
                local duel   = spectate.CurrentDuelSubject
                local map    = type(duel) == 'table' and type(duel.Map) == 'table' and duel.Map.Model or nil
                local folder = typeof(map) == 'Instance' and map:FindFirstChild('Spawns') or nil
                local spots  = {}
                if folder then
                    for _, part in folder:GetDescendants() do
                        if part:IsA('BasePart') then
                            local pos = part.Position
                            table.insert(spots, {
                                x     = pos.X,
                                z     = pos.Z,
                                floor = pos.Y - part.Size.Y / 2,
                            })
                        end
                    end
                end
                return spots
            end,
            place = function(part, pose)
                local pitch = pose.flying and (-math.pi / 2) or (math.pi / 2)
                part.CFrame = CFrame.new(pose.x, pose.y, pose.z) * CFrame.Angles(pitch, 0, 0)
                part.AssemblyLinearVelocity = Vector3.zero
            end,
            random = function() return random:NextNumber() end,
            heartbeat = game:GetService('RunService').Heartbeat,
            join = services and function(frame)
                -- Desync.join(run, services, ORDER, function() frame() return nil end, frame)
                -- Wire this to your Desync implementation:
                local Desync = require(game:GetService('ReplicatedStorage'):WaitForChild('Desync'))
                Desync.join(run, services, ORDER, function() frame() return nil end, frame)
            end or nil,
        }
    end

    -- ── Counter state ────────────────────────────────────────

    local Counter = {}
    Counter.HOP_EVERY = HOP_EVERY
    Counter.CEILING   = CEILING
    Counter.resolve   = resolve
    Counter.rescue    = toSpawn

    function Counter.new()
        return {
            life     = false,
            born     = 0,
            hopAt    = 0,
            equipAt  = 0,
            mode     = nil,
            last     = nil,
            blink    = Blink.new(),
            drop     = nil,
            nextDrop = 0,
            anchor   = nil,
        }
    end

    local function over(counter, forget)
        if forget then counter.anchor = nil end
        counter.life     = false
        counter.last     = nil
        counter.drop     = nil
        counter.nextDrop = 0
        Blink.reset(counter.blink)
    end

    local function allowed(opponent, settings)
        return (not settings.enemiesOnly or not opponent.ally)
            and (not settings.aliveOnly  or opponent.health > 0)
    end

    local function first(list, priority, random)
        if #list == 0 then return nil end
        if priority == 'random' then
            return list[math.clamp(math.floor(random() * #list) + 1, 1, #list)]
        end
        local best = list[1]
        for i = 2, #list do
            local other = list[i]
            local better
            if priority == 'a to z' then
                better = other.name < best.name
            elseif priority == 'z to a' then
                better = other.name > best.name
            else  -- 'lowest health'
                better = other.health < best.health
            end
            if better then best = other end
        end
        return best
    end

    local function choose(counter, opponents, settings, now, random)
        local bots, legits = {}, {}
        for _, opponent in opponents do
            if opponent.health > 0 and opponent.inside and allowed(opponent, settings) then
                table.insert(opponent.rager and bots or legits, opponent)
            end
        end

        local priority = settings.legits.priority
        if settings.bots.on and #bots > 0 then
            return first(bots, priority, random), settings.bots
        end

        local legit = settings.legits
        if legit.on and #legits > 0 and #legits <= legit.max
            and now - counter.born >= legit.delay
        then
            return first(legits, priority, random), legit
        end

        return nil, nil
    end

    -- ── Counter.step  (call every heartbeat / desync frame) ─
    --
    --  deps     = resolve(run, services)
    --  settings = function() → settings table (see CounterControls.build)
    --
    function Counter.step(counter, deps, settings)
        if not settings.active then
            if counter.life then deps.rescue(counter.anchor) end
            over(counter, true)
            return nil
        end

        local fighter = deps.fighter()
        local root    = fighter and deps.root() or nil

        if not fighter or not root then
            over(counter, true)
            return 'counter: no character...'
        end

        if counter.mode ~= settings.mode then
            if counter.life then deps.rescue(counter.anchor) end
            over(counter, false)
            counter.mode = settings.mode
        end

        local anchor = counter.anchor
        if not anchor then
            anchor = deps.position(root)
            counter.anchor = anchor
        end

        local from      = anchor
        local opponents = deps.opponents(root)
        local now       = deps.now()
        local item      = fighter.EquippedItem
        local holding   = isMelee(item)

        if settings.swapToMelee and not holding and now >= counter.equipAt then
            for _, carried in fighter.Items do
                if isMelee(carried) then
                    deps.equip(fighter, carried)
                    counter.equipAt = now + settings.swapEvery
                    break
                end
            end
        end

        local delta = counter.last and (now - counter.last) or 0
        counter.last = now

        if not counter.life then
            counter.born = now
            deps.prepare(root)
        end

        local name   = NAMES[settings.mode] or settings.mode
        local status
        local target = nil
        local fresh  = false

        if settings.mode == 'solix' or settings.mode == 'kicia' then
            -- ── Blink engines ─────────────────────────────────
            counter.life = true
            local spots = settings.mode == 'solix' and deps.spots() or nil
            local pose  = Blink.pose(counter.blink, now, delta, from, spots, deps.random, settings.engine)
            deps.place(root, pose)
            status = string.format('%s: at %s...', name, short(pose.y))
        else
            -- ── UE engine (lift → drop loop) ───────────────────
            local drop = counter.drop

            if drop and now >= drop.ends then
                counter.drop, counter.nextDrop = nil, drop.ends + drop.gap
                drop = nil
                deps.lift(root, from)
            end

            if drop then
                for _, opponent in opponents do
                    if opponent.name == drop.name
                        and opponent.health > 0
                        and opponent.inside
                        and allowed(opponent, settings)
                    then
                        target = opponent
                    end
                end
                if not target then
                    counter.drop, counter.nextDrop = nil, now
                    deps.lift(root, from)
                end
            elseif counter.life and now >= counter.nextDrop then
                local chosen, group = choose(counter, opponents, settings, now, deps.random)
                if chosen and group then
                    target = chosen
                    fresh  = true
                    counter.drop = {
                        name = chosen.name,
                        ends = now + group.stay,
                        gap  = group.gap,
                        lead = group.lead,
                    }
                end
            end

            local dropping = counter.drop
            if target and dropping then
                deps.drop(root, target, dropping.lead)
                if fresh then deps.replicate(root) end
                status = string.format('%s: dropping on %s...', name, target.name)
            else
                if not counter.life then
                    counter.life  = true
                    counter.hopAt = now + HOP_EVERY
                    deps.lift(root, from)
                elseif deps.height(root) > CEILING then
                    deps.lift(root, from)
                elseif now >= counter.hopAt then
                    counter.hopAt = now + HOP_EVERY
                    deps.hop(root)
                end
                deps.rise(root, settings.voidSpeed)
                status = string.format('%s: climbing...', name)
            end
        end

        -- swing at any visible target while holding melee
        if holding and now >= (item._equip_cooldown or 0) then
            local aim = target
            if not aim then
                for _, opponent in opponents do
                    if allowed(opponent, settings) and (not aim or opponent.distance < aim.distance) then
                        aim = opponent
                    end
                end
            end
            if aim then deps.swing(item, aim.part) end
        end

        return status
    end

    -- ── Counter.loop  (attach to heartbeat / desync) ────────
    function Counter.loop(run, settings, deps, report)
        local counter = Counter.new()
        local frame   = function()
            local status = Counter.step(counter, deps, settings())
            if report then report(status) end
        end
        local join = deps.join
        if join then
            join(frame)
        else
            run:connect(
                assert(deps.heartbeat, 'the counter needs a frame signal'),
                frame
            )
        end
    end

    return table.freeze(Counter)
end)()


-- ────────────────────────────────────────────────────────────
-- [11] Counter  (module L — thin wrapper that wires report)
-- ────────────────────────────────────────────────────────────
local Counter = (function()
    -- RageReport is an in-process service bus value;
    -- replace the set call with however your script exposes it.
    local function setReport(services, report)
        -- Service.set(services, REPORT_KEY, report)
        -- e.g. services.RageReport = report
        if services then services.RageReport = report end
    end

    local C = {}
    C.ENGINE = Blink.DEFAULTS
    C.rescue = CounterSystem.rescue

    function C.start(run, settings, services, dependencies)
        local shown = false

        run:add(function()
            if shown then setReport(services, nil) end
        end)

        CounterSystem.loop(
            run,
            settings,
            dependencies or CounterSystem.resolve(run, services),
            function(status)
                if status ~= nil then
                    shown = true
                    setReport(services, { status = status, target = nil })
                elseif shown then
                    shown = false
                    setReport(services, nil)
                end
            end
        )
    end

    return table.freeze(C)
end)()


-- ────────────────────────────────────────────────────────────
-- [12] Targets  (priority list + pick — module V)
-- ────────────────────────────────────────────────────────────
local Targets = (function()
    local VOID = 1000000
    local T    = {}

    -- Create a new priority object
    function T.priority(settings, notify, scope)
        return {
            players  = {},
            notify   = notify,
            settings = settings,
            scope    = scope,
            current  = nil,
        }
    end

    -- Add a player to the priority list
    function T.prioritize(priority, player, me)
        if player == me or table.find(priority.players, player) then return end
        table.insert(priority.players, player)

        local leaving = player.AncestryChanged:Once(function()
            local at = table.find(priority.players, player)
            if at then table.remove(priority.players, at) end
        end)
        local owner = priority.scope
        if owner and leaving then
            owner:add(function() leaving:Disconnect() end)
        end
        if priority.settings().notify then
            priority.notify(string.format('Added %s to ragebot priority', player.Name))
        end
    end

    -- Internal: validate one player as a shootable candidate
    local function candidate(player, dueler, me)
        if player == me or type(dueler) ~= 'table' or dueler._is_ally then return nil end

        local character = player.Character
        local humanoid  = character and character:FindFirstChildOfClass('Humanoid') or nil
        if not character or not humanoid or not (humanoid.Health > 0) then return nil end

        local root = character:FindFirstChild('HumanoidRootPart')
        local distance = root and root:IsA('BasePart') and root.Position.Magnitude or math.huge
        if not (distance < VOID) then return nil end

        local head    = character:FindFirstChild('HitboxHead')
        local fighter = dueler.ClientFighter
        if not head or not head:IsA('BasePart') or not fighter
            or Fighter.invincible(fighter) or Fighter.deflecting(fighter)
        then return nil end
        if not (head.Position.Magnitude < VOID) then return nil end

        return {
            part      = head,
            character = character,
            fighter   = fighter,
            name      = player.Name,
            health    = humanoid.Health,
        }
    end

    T.candidate = candidate

    -- Pick the best target from duelers, respecting priority list
    function T.pick(priority, duelers, me, reachable)
        local options  = priority.settings()
        local checked  = {}
        local rejected = {}

        local function available(player, dueler)
            if rejected[player] then return nil end
            local target = checked[player] or candidate(player, dueler, me)
            if target and (not reachable or checked[player] or reachable(target)) then
                checked[player] = target
                return target
            end
            rejected[player] = true
            return nil
        end

        -- Auto-prioritize voided players
        if options.autoPrioritize then
            if options.join['voided players'] then
                for player, dueler in duelers do
                    local character = player.Character
                    local root      = character and character:FindFirstChild('HumanoidRootPart') or nil
                    if player ~= me and not dueler._is_ally
                        and root and root:IsA('BasePart')
                        and root.Position.Magnitude > VOID
                    then
                        T.prioritize(priority, player, me)
                    end
                end
            end

            for _, player in priority.players do
                local dueler = duelers[player]
                local target = dueler and available(player, dueler) or nil
                if target then
                    priority.current = player
                    return target
                end
            end
        end

        -- Sticky-target: keep current if still valid
        local current       = priority.current
        local currentDueler = current and duelers[current] or nil
        local held          = current and currentDueler and available(current, currentDueler) or nil
        if held then return held end

        -- Fallback: lowest health then alphabetical
        local best, selected = nil, nil
        for player, dueler in duelers do
            local target = available(player, dueler)
            if target and (
                not best
                or target.health < best.health
                or (target.health == best.health and target.name < best.name)
            ) then
                best, selected = target, player
            end
        end

        priority.current = selected
        return best
    end

    return table.freeze(T)
end)()


-- ────────────────────────────────────────────────────────────
-- [13] Attacks  (ragebot attack cycle — gun / knife / melee)
-- ────────────────────────────────────────────────────────────
local Attacks = (function()
    local SETTLE       = 0.05
    local EYE          = 1.75
    local CROUCHED_EYE = 0.25

    local function shield(fighter)
        local item = fighter.EquippedItem
        if type(item) == 'table' and item.Name == 'Riot Shield' then return true, true end
        for _, carried in fighter.Items do
            if carried.Name == 'Riot Shield' then return true, false end
        end
        return false, false
    end
    local function beyondShield(target, reach)
        local has, held = shield(target.fighter)
        if not has then return nil end
        local facing = CFrame.new(target.part.Position) * target.fighter:GetRotationCFrame()
        return (facing * CFrame.new(0, 0, held and reach or -reach)).Position
    end
    local function around(target, reach)
        local position = target.part.Position
        local from     = beyondShield(target, reach) or position + Random.new():NextUnitVector() * reach
        return CFrame.new(from, position)
    end

    local A = {}

    function A.new(deps)
        return {
            deps           = deps,
            server         = nil,
            meleeAt        = tick(),
            swingAt        = tick(),
            physicsAt      = tick(),
            shotAt         = tick(),
            spamAt         = tick(),
            hiding         = false,
            burstAt        = nil,
            burstAmmo      = nil,
            attackPose     = nil,
            attackTarget   = nil,
            attackItem     = nil,
            attackMode     = nil,
            attackPosition = nil,
            poseFired      = false,
            equipItem      = nil,
            equipAt        = 0,
            reloadItem     = nil,
            reloadAt       = 0,
        }
    end

    local function detach(attacks)
        attacks.attackPose, attacks.attackTarget, attacks.attackItem = nil, nil, nil
        attacks.attackMode, attacks.attackPosition, attacks.burstAt  = nil, nil, nil
        attacks.burstAmmo  = nil
        attacks.poseFired  = false
    end

    function A.reset(attacks)
        detach(attacks)
        attacks.hiding, attacks.spamAt = false, tick()
        attacks.equipItem, attacks.reloadItem = nil, nil
        attacks.equipAt,  attacks.reloadAt   = 0, 0
    end

    local function spamming(attacks)
        local options = attacks.deps.settings()
        if not options.voidSpam then
            attacks.hiding, attacks.spamAt, attacks.burstAt = false, tick(), nil
            return false
        end
        local now = tick()
        local item, ammo, started = attacks.attackItem, attacks.burstAmmo, attacks.burstAt
        local confirmed = item and ammo and started
            and (item.Data.Ammo or ammo) < ammo
            and (item.Info.ShootCooldown or 0) > options.voidAttack
            and now >= started + SETTLE

        if attacks.hiding then
            if now >= attacks.spamAt then attacks.hiding = false end
        elseif confirmed
            or (attacks.burstAt and now >= attacks.burstAt + math.max(options.voidAttack, SETTLE))
            or (not attacks.attackPose and now >= attacks.spamAt)
        then
            attacks.hiding = true
            attacks.spamAt = now + options.voidHide
        end
        return attacks.hiding
    end

    local function place(attacks, root, at)
        attacks.server = at
        if at then root.CFrame = at end
        attacks.deps.replicate(root)
    end
    local function settle(attacks, root)
        detach(attacks)
        attacks.physicsAt = tick() + SETTLE
        place(attacks, root, attacks.deps.hide())
    end
    local function attach(attacks, root, item, target, mode, pose)
        local held, position = attacks.attackPose, attacks.attackPosition
        local reuse   = mode == 'gun' and attacks.attackMode == mode and attacks.attackItem == item and held == pose
        local changed = not held
            or (attacks.attackTarget ~= target.part and not reuse)
            or attacks.attackItem ~= item
            or attacks.attackMode ~= mode
            or not position
            or (mode == 'gun' and held ~= pose)
        local moved = mode ~= 'gun' and position and (target.part.Position - position).Magnitude > 2

        if changed or (moved and attacks.poseFired) then
            held = pose
            attacks.attackPose, attacks.attackTarget, attacks.attackItem = held, target.part, item
            attacks.attackMode, attacks.attackPosition = mode, target.part.Position
            attacks.poseFired = false
            if changed then attacks.burstAt, attacks.burstAmmo = nil, nil end
            local delay = attacks.deps.replicationDelay
            attacks.physicsAt = tick() + math.max(SETTLE, delay and delay() or SETTLE)
        end
        attacks.attackTarget = target.part
        local published = assert(held)
        place(attacks, root, published)
        return published, tick() >= attacks.physicsAt
    end

    local function beginBurst(attacks, now)
        attacks.poseFired = true
        if not attacks.burstAt then
            attacks.burstAt   = now
            attacks.burstAmmo = attacks.attackItem.Data.Ammo
        end
    end

    local function equipItem(attacks, fighter, item)
        local now = tick()
        if attacks.equipItem == item and now < attacks.equipAt then return end
        attacks.equipItem, attacks.equipAt = item, now + 0.25
        local schedule = attacks.deps.equip
        if schedule then schedule(fighter, item)
        else task.spawn(fighter.EquipItem, fighter, item.Data.ItemIndex) end
    end

    -- ── attack modes ─────────────────────────────────────────

    local function knife(attacks, fighter, root, item, target)
        local deps = attacks.deps
        if fighter.EquippedItem ~= item then
            equipItem(attacks, fighter, item); settle(attacks, root)
            return 'void...'
        end
        if not target or tick() < (item._equip_cooldown or 0) then
            settle(attacks, root); return 'void...'
        end
        if spamming(attacks) then settle(attacks, root); return 'void spamming...' end

        local now     = tick()
        local facing  = type(target.fighter.GetRotationCFrame) == 'function'
            and (CFrame.new(target.part.Position) * target.fighter:GetRotationCFrame())
            or target.part.CFrame
        local behind  = facing * CFrame.new(0, 0, 3)
        local previous = attacks.attackPose
        local pose, ready = attach(attacks, root, item, target, 'knife', behind)
        local aim = CFrame.lookAt(pose.Position, target.part.Position)

        if previous ~= pose or (ready and now >= attacks.swingAt) then
            local pitch, yaw = aim:ToOrientation()
            -- CameraHold.send omitted — wire if you have that service
        end
        if ready and now >= attacks.swingAt then
            if not Swing.send(deps.use, deps.enums, item, aim, target.part, true) then
                settle(attacks, root); return 'invalid knife animation... (void)'
            end
            attacks.swingAt = now + 1/60
            beginBurst(attacks, now)
        end
        return ready and string.format('backstabbing %s...', target.name)
                      or string.format('attaching %s...', target.name)
    end

    local function melee(attacks, fighter, root, item, target)
        local deps = attacks.deps
        local function wait()
            settle(attacks, root); attacks.meleeAt = tick() + SETTLE
        end
        if fighter.EquippedItem ~= item then equipItem(attacks, fighter, item); wait(); return 'void...' end
        if not target                   then wait(); return 'void...' end
        if tick() < (item._equip_cooldown or 0) then wait(); return 'void...' end
        if spamming(attacks)            then wait(); return 'void spamming...' end

        local now      = tick()
        local pose, ready = attach(attacks, root, item, target, 'melee', around(target, 3))
        local aim = CFrame.lookAt(pose.Position, target.part.Position)

        if ready and now >= attacks.meleeAt and now >= attacks.swingAt then
            if not Swing.send(deps.use, deps.enums, item, aim, target.part, false) then
                wait(); return 'invalid melee animation... (void)'
            end
            attacks.swingAt = now + 1/60
            beginBurst(attacks, now)
        end
        return ready and string.format('attacking %s...', target.name)
                      or string.format('attaching %s...', target.name)
    end

    local function ammunition(item)
        if (item.Data.Ammo or 0) > 0 then return true, false end
        return false, (item.Data.AmmoReserve or 0) == 0
    end

    local function reloadItem(attacks, item)
        local deps = attacks.deps
        local now  = tick()
        if attacks.reloadItem == item and now < attacks.reloadAt then return end
        attacks.reloadItem, attacks.reloadAt = item, now + 0.25

        local results = { item:StartReloading() }
        if table.remove(results, 1) ~= true then return end
        local action = table.remove(results, 1)
        if type(action) ~= 'string' then return end
        local arguments = {}
        for index, value in results do arguments[utf8.char(index)] = value end
        deps.use(item:Get('ObjectID'), deps.enums:ToEnum(action), arguments, nil)
    end

    local function chooseGun(guns, options)
        local first, last, step = 1, #guns, 1
        if not options.primary then first, last, step = #guns, 1, -1 end
        local chosen = nil
        for index = first, last, step do
            local item  = guns[index]
            local loaded, empty = ammunition(item)
            local candidate = { item = item, loaded = loaded, empty = empty }
            if loaded or not empty then
                local reloading = tick() < (item._reload_cooldown or 0)
                local threads   = item._reload_threads
                if item.Info.ReloadType == 'Segmented' and type(threads) == 'table' then
                    local active = threads[#threads]
                    reloading = reloading or (active ~= nil and coroutine.status(active) ~= 'dead')
                end
                if not options.swapWhenEmpty or (loaded and not reloading) then
                    return candidate
                end
                chosen = chosen or candidate
            end
        end
        return chosen
    end

    local function shoot(deps, item, target, aim, attempts)
        for _ = 1, attempts do
            local arguments = {
                ['\1'] = {
                    ['\0'] = Shot.pack(aim),
                    ['\1'] = Shot.pack(aim),
                    ['\2'] = target.part,
                    ['\3'] = Shot.pack(Shot.scatter()),
                },
                ['\2'] = true,
            }
            if item.Name == 'Revolver' then arguments['\3'] = true end
            deps.use(item:Get('ObjectID'), deps.enums:ToEnum('StartShooting'), arguments, nil)
        end
    end

    local function gun(attacks, fighter, root, guns, target, status)
        local options = attacks.deps.settings()
        local chosen  = chooseGun(guns, options)
        if not chosen then settle(attacks, root); return 'no usable item(s)... (void)' end

        local item = chosen.item
        if fighter.EquippedItem ~= item then
            equipItem(attacks, fighter, item); settle(attacks, root); return 'void...'
        end
        if item.Info.ReloadType == 'Segmented' then
            local threads = item._reload_threads
            local thread  = threads[#threads]
            if thread and coroutine.status(thread) ~= 'dead' then
                settle(attacks, root); return 'reloading...'
            end
        end

        local now = tick()
        if now < (item._equip_cooldown or 0) then settle(attacks, root); return 'void...' end
        if now < (item._reload_cooldown or 0) then settle(attacks, root); return 'reloading...' end
        if status ~= 'RoundStarted'           then settle(attacks, root); return 'void...' end
        if not chosen.loaded and not chosen.empty then
            reloadItem(attacks, item); settle(attacks, root); return 'reloading...'
        end
        if not target     then settle(attacks, root); return 'void...' end
        if spamming(attacks) then settle(attacks, root); return 'void spamming...' end

        local position = target.part.Position
        local above    = beyondShield(target, 2) or position + Vector3.new(0, 3, 0)
        local eye      = Vector3.new(0, fighter:IsCrouching() and CROUCHED_EYE or EYE, 0)
        local clear    = attacks.deps.clear or function() return true end
        local hasShield = shield(target.fighter)
        local held     = (attacks.attackMode == 'gun'
                       and attacks.attackItem == item
                       and not hasShield
                       and attacks.attackPose) or nil
        local route = (held
                    and not attacks.poseFired
                    and attacks.attackTarget == target.part
                    and clear(held.Position + eye, position)
                    and held)
                   or Origins.gun(position, above, eye, held, clear)

        if not route then
            settle(attacks, root)
            return string.format('blocked %s... (void)', target.name)
        end

        local pose, ready = attach(attacks, root, item, target, 'gun', route)
        local aim = CFrame.lookAt(pose.Position + eye, position)

        if ready and now >= attacks.shotAt then
            attacks.shotAt = now + 1/120
            beginBurst(attacks, now)
            shoot(attacks.deps, item, target, aim, options.shootAttempts)
        end
        return ready and string.format('killing %s...', target.name)
                      or string.format('attaching %s...', target.name)
    end

    -- ── Attacks.cycle  (main per-frame ragebot pump) ────────
    function A.cycle(attacks, fighter, root, target, status, _deltaTime)
        attacks.server = nil
        local mode = attacks.deps.settings().mode
        local guns, chosen = {}, nil

        for _, item in fighter.Items do
            if item.Info.Type == 'Gun' then
                table.insert(guns, item)
            elseif mode == 'knife' and item.Name == 'Knife' then
                chosen = item; break
            elseif mode == 'melee' and item.Info.Type == 'Melee' then
                chosen = item; break
            end
        end

        local doing
        if chosen and mode == 'knife' then
            doing = knife(attacks, fighter, root, chosen, target)
        elseif chosen then
            doing = melee(attacks, fighter, root, chosen, target)
        elseif #guns > 0 then
            doing = gun(attacks, fighter, root, guns, target, status)
        else
            doing = 'invalid weapons for ragebot'
        end

        return attacks.server, doing
    end

    return table.freeze(A)
end)()


-- ────────────────────────────────────────────────────────────
-- [14] Ragebot  (module ab — top-level start function)
-- ────────────────────────────────────────────────────────────
--
-- Usage:
--   Ragebot.start(run, settingsFn, services, notifyFn, counterOnFn)
--
--   run         = Scope object (has :add, :spawn, :connect, closed flag)
--   settingsFn  = function() → settings table (see UI section below)
--   services    = service bus (for Desync, RageReport, etc.)
--   notifyFn    = function(message: string)
--   counterOnFn = function() → bool  (true when counter is active)
--
local Ragebot = (function()
    local ORDER = 1

    local R = {}

    function R.start(run, settings, services, notify, counterOn)
        local Modules   = require(game:GetService('ReplicatedStorage'):WaitForChild('Modules'))
        local me        = Modules.player()
        local fighters  = Modules.controller('FighterController')
        local spectate  = Modules.controller('SpectateController')
        local enums     = Modules.shared('EnumLibrary')
        local constants = Modules.shared('CONSTANTS')
        local useItem   = Modules.remote({ 'Replication', 'Fighter', 'UseItem' })
        local Workspace = game:GetService('Workspace')

        local setIdentity = setthreadidentity
        local setHidden   = sethiddenproperty
        local terrain     = Workspace.Terrain
        local real        = nil
        local params      = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude

        local function duel()
            local current = spectate.CurrentDuelSubject
            return type(current) == 'table' and current or nil
        end

        -- Priority list
        local priority = Targets.priority(settings, function(message)
            -- restore thread identity before UI call
            if type(setthreadidentity) == 'function' then setthreadidentity(8) end
            notify(message)
        end, run)

        -- Attack engine (deps injected)
        local attacks = Attacks.new({
            settings = settings,
            enums    = enums,
            use      = function(...) useItem:FireServer(...) end,
            hide     = makeVoidResolver(duel, constants.IS_PRIVATE_SERVER == true, function()
                return real
            end),
            -- CameraHold.use omitted — wire if needed
            hold  = nil,
            clear = function(from, to)
                return Workspace:Raycast(from, to - from, params) == nil
            end,
            equip = function(fighter, item)
                run:spawn(fighter.EquipItem, fighter, item.Data.ItemIndex)
            end,
            replicationDelay = function()
                return math.max(0.05, me:GetNetworkPing() * 2 + 1/30)
            end,
            replicate = function(root)
                if type(setIdentity) == 'function' then setIdentity(8) end
                if type(setHidden) == 'function' then
                    setHidden(root, 'PhysicsRepRootPart', terrain)
                end
            end,
        })

        -- Listen for attackers → auto-prioritize
        local hurt = enums:ToEnum('HurtEffect')
        -- FighterEvents.listen omitted — wire your own equivalent if needed:
        -- run:connect(someSignal, function(kind, effect, detail) ... end)

        local function stop()
            Attacks.reset(attacks)
            priority.current = nil
            if services then services.RageReport = nil end
        end

        -- Desync main loop
        -- Replace with your Desync.join implementation:
        local Desync = require(game:GetService('ReplicatedStorage'):WaitForChild('Desync'))
        Desync.join(run, services, ORDER, function(cframe, root, deltaTime)
            local fighter = fighters.LocalFighter

            if not settings().active or counterOn() or type(fighter) ~= 'table' then
                stop()
                return nil
            end

            real = cframe.Position

            local current = duel()
            local status  = current and type(current.Data) == 'table' and current.Data.Status or nil
            local duelers = current and current._duelers_by_player or nil
            local excluded = {}

            if me.Character then table.insert(excluded, me.Character) end
            if type(duelers) == 'table' then
                for player in duelers do
                    if player.Character then table.insert(excluded, player.Character) end
                end
            end
            local camera = Workspace.CurrentCamera
            if camera then table.insert(excluded, camera) end
            params.FilterDescendantsInstances = excluded

            local function reachable(checked)
                if settings().mode ~= 'gun' then return true end
                local position = checked.part.Position
                local eye      = Vector3.new(0, fighter:IsCrouching() and 0.25 or 1.75, 0)
                return Origins.gun(
                    position,
                    position + Vector3.new(0, 3, 0),
                    eye,
                    attacks.attackPose,
                    function(from, to)
                        return Workspace:Raycast(from, to - from, params) == nil
                    end
                ) ~= nil
            end

            local target = (status == 'RoundStarted' and type(duelers) == 'table')
                and Targets.pick(priority, duelers, me, reachable)
                or nil

            local server, doing = Attacks.cycle(attacks, fighter, root, target, status, deltaTime)

            if services then
                services.RageReport = {
                    status = doing,
                    target = target and target.part or nil,
                }
            end

            return server
        end, stop)

        run:add(stop)
    end

    return table.freeze(R)
end)()


-- ============================================================
--  ECLIPSE UI LIBRARY  (eclipse.wtf)
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local Player    = Players.LocalPlayer
local Mouse     = Player:GetMouse()

local CFG = {
    MainColor      = Color3.fromRGB(14, 14, 14),
    SecondaryColor = Color3.fromRGB(26, 26, 26),
    AccentColor    = Color3.fromRGB(189, 172, 255),
    TextColor      = Color3.fromRGB(200, 200, 200),
    TextDark       = Color3.fromRGB(120, 120, 120),
    StrokeColor    = Color3.fromRGB(40, 40, 40),
    Font           = Enum.Font.Code,
    BaseSize       = Vector2.new(600, 450),
}

local Library = {
    Flags       = {},
    Connections = {},
    Unloaded    = false,
}

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props or {}) do inst[i] = v end
    for _, child in pairs(children or {}) do child.Parent = inst end
    return inst
end

local function Tween(obj, props, time, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function GetTextSize(text, size, font)
    return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
end

-- ── ScreenGui ────────────────────────────────────────────────
local ScreenGui = Create("ScreenGui", {
    Name            = "EclipseUI",
    Parent          = game:GetService("CoreGui"),
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn    = false,
    IgnoreGuiInset  = true,
})

local UIScale = Create("UIScale", { Parent = ScreenGui })

local function UpdateScale()
    local vp = workspace.CurrentCamera.ViewportSize
    UIScale.Scale = math.max(math.min((vp.X - 40) / CFG.BaseSize.X, (vp.Y - 40) / CFG.BaseSize.Y, 1), 0.6)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
UpdateScale()

-- ── Notifications ────────────────────────────────────────────
local NotificationContainer = Create("Frame", {
    Parent              = ScreenGui,
    Position            = UDim2.new(1, -20, 0, 20),
    AnchorPoint         = Vector2.new(1, 0),
    Size                = UDim2.new(0, 300, 1, 0),
    BackgroundTransparency = 1,
    ZIndex              = 100,
})
Create("UIListLayout", {
    Parent              = NotificationContainer,
    Padding             = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment   = Enum.VerticalAlignment.Top,
})

function Library:Notify(msg, ntype)
    local color = (ntype == "success" and Color3.fromRGB(100, 255, 100))
               or (ntype == "warning" and Color3.fromRGB(255, 100, 100))
               or CFG.AccentColor

    local Frame = Create("Frame", {
        Parent           = NotificationContainer,
        Size             = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, {
        Create("UIStroke", { Color = CFG.AccentColor, Thickness = 1, Transparency = 0.5 }),
        Create("Frame",    { Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = color }),
        Create("TextLabel", {
            Text               = msg,
            TextColor3         = CFG.TextColor,
            Font               = CFG.Font,
            TextSize           = 12,
            Size               = UDim2.new(1, -10, 1, 0),
            Position           = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment     = Enum.TextXAlignment.Left,
        }),
    })

    Tween(Frame, { Size = UDim2.new(0, 250, 0, 35) }, 0.5, Enum.EasingStyle.Back)
    task.delay(3, function()
        Tween(Frame, { Size = UDim2.new(0, 250, 0, 0), BackgroundTransparency = 1 }, 0.5)
        task.wait(0.5)
        Frame:Destroy()
    end)
end

-- ── Tooltip ──────────────────────────────────────────────────
local TooltipLabel = Create("TextLabel", {
    Parent          = ScreenGui,
    Size            = UDim2.new(0, 0, 0, 20),
    BackgroundColor3 = CFG.SecondaryColor,
    TextColor3      = CFG.TextColor,
    TextSize        = 11,
    Font            = CFG.Font,
    BorderSizePixel = 0,
    Visible         = false,
    ZIndex          = 200,
}, {
    Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
    Create("UIStroke",  { Color = CFG.StrokeColor }),
})

local function AddTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        TooltipLabel.Text    = text
        TooltipLabel.Size    = UDim2.fromOffset(GetTextSize(text, 11, CFG.Font).X + 12, 20)
        TooltipLabel.Visible = true
    end)
    obj.MouseLeave:Connect(function() TooltipLabel.Visible = false end)
end

RunService.RenderStepped:Connect(function()
    if TooltipLabel.Visible then
        local m = UserInputService:GetMouseLocation()
        TooltipLabel.Position = UDim2.fromOffset(m.X + 15, m.Y + 15)
    end
end)

-- ── MainFrame ────────────────────────────────────────────────
local MainFrame = Create("Frame", {
    Name             = "MainFrame",
    Parent           = ScreenGui,
    Size             = UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
    Position         = UDim2.new(0.5, -300, 0.5, -225),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel  = 0,
}, {
    Create("UIStroke", { Color = CFG.StrokeColor }),
    Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
})

-- drag
local Dragging, DragInput, DragStart, StartPos = false, nil, nil, nil
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true; DragStart = input.Position; StartPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local delta = input.Position - DragStart
        Tween(MainFrame, {
            Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + delta.Y
            )
        }, 0.05)
    end
end)

-- ── TopBar ───────────────────────────────────────────────────
local TopBar = Create("Frame", {
    Parent           = MainFrame,
    Size             = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel  = 0,
}, {
    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CFG.StrokeColor,
    }),
})

local TitleLabel = Create("TextLabel", {
    Parent             = TopBar,
    Text               = "eclipse.wtf | ragebot",
    TextColor3         = CFG.TextDark,
    TextSize           = 13,
    Font               = CFG.Font,
    BackgroundTransparency = 1,
    Size               = UDim2.new(0, 200, 1, 0),
    Position           = UDim2.new(0, 10, 0, 0),
    TextXAlignment     = Enum.TextXAlignment.Left,
    RichText           = true,
})

-- animated title
task.spawn(function()
    local base = "eclipse.wtf | ragebot"
    while not Library.Unloaded do
        for i = 0, #base do
            if Library.Unloaded then break end
            local sub = base:sub(1, i)
            local display = sub:gsub("wtf", '<font color="#bdacff">wtf</font>')
                               :gsub("ragebot", '<font color="#bdacff">ragebot</font>')
            TitleLabel.Text = display
            task.wait(0.07)
        end
        task.wait(1.5)
        for i = #base, 0, -1 do
            if Library.Unloaded then break end
            local sub = base:sub(1, i)
            local display = sub:gsub("wtf", '<font color="#bdacff">wtf</font>')
                               :gsub("ragebot", '<font color="#bdacff">ragebot</font>')
            TitleLabel.Text = display
            task.wait(0.04)
        end
        task.wait(0.5)
    end
end)

-- ── Layout ───────────────────────────────────────────────────
local ContentContainer = Create("Frame", {
    Parent             = MainFrame,
    Size               = UDim2.new(1, 0, 1, -30),
    Position           = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1,
})

local Sidebar = Create("Frame", {
    Parent           = ContentContainer,
    Size             = UDim2.new(0, 60, 1, 0),
    BackgroundColor3 = Color3.fromRGB(17, 17, 17),
    BorderSizePixel  = 0,
}, {
    Create("UIListLayout", {
        Padding             = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment   = Enum.VerticalAlignment.Top,
    }),
    Create("UIPadding", { PaddingTop = UDim.new(0, 15) }),
})

local PagesContainer = Create("Frame", {
    Parent             = ContentContainer,
    Size               = UDim2.new(1, -60, 1, 0),
    Position           = UDim2.new(0, 60, 0, 0),
    BackgroundTransparency = 1,
})

local Tabs      = {}
local CurrentTab = nil

-- ── Tab builder ──────────────────────────────────────────────
function Library:Tab(name, icon)
    local TabButton = Create("TextButton", {
        Parent           = Sidebar,
        Size             = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = CFG.MainColor,
        Text             = "",
        AutoButtonColor  = false,
    }, {
        Create("ImageLabel", {
            Name               = "Icon",
            Size               = UDim2.new(0.6, 0, 0.6, 0),
            Position           = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Image              = "rbxassetid://" .. tostring(icon),
            ImageColor3        = CFG.TextDark,
        }),
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    })

    local PageFrame = Create("ScrollingFrame", {
        Parent              = PagesContainer,
        Size                = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible             = false,
        ScrollBarThickness  = 2,
        ScrollBarImageColor3 = CFG.AccentColor,
        CanvasSize          = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })

    local Padding = Create("UIPadding", {
        Parent        = PageFrame,
        PaddingTop    = UDim.new(0, 15),
        PaddingLeft   = UDim.new(0, 15),
        PaddingRight  = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 15),
    })

    local LeftCol = Create("Frame", {
        Parent             = PageFrame,
        Size               = UDim2.new(0.48, 0, 1, 0),
        BackgroundTransparency = 1,
    }, { Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

    local RightCol = Create("Frame", {
        Parent             = PageFrame,
        Size               = UDim2.new(0.48, 0, 1, 0),
        Position           = UDim2.new(0.52, 0, 0, 0),
        BackgroundTransparency = 1,
    }, { Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            Tween(t.Btn, { TextColor3 = CFG.TextDark, BackgroundColor3 = CFG.MainColor }, 0.2)
            t.Btn:FindFirstChild("Icon").ImageColor3 = CFG.TextDark
            t.Page.Visible = false
        end
        Tween(TabButton, { BackgroundColor3 = CFG.SecondaryColor }, 0.2)
        TabButton:FindFirstChild("Icon").ImageColor3 = CFG.AccentColor
        PageFrame.Visible = true
        CurrentTab = PageFrame
    end)

    table.insert(Tabs, { Btn = TabButton, Page = PageFrame })

    if #Tabs == 1 then
        Tween(TabButton, { BackgroundColor3 = CFG.SecondaryColor }, 0.2)
        TabButton:FindFirstChild("Icon").ImageColor3 = CFG.AccentColor
        PageFrame.Visible = true
    end

    local LeftSide      = true
    local GroupFunctions = {}

    function GroupFunctions:Group(title)
        local ParentCol = LeftSide and LeftCol or RightCol
        LeftSide = not LeftSide

        local GroupFrame = Create("Frame", {
            Parent           = ParentCol,
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(17, 17, 17),
            BorderSizePixel  = 0,
        }, {
            Create("UIStroke", { Color = CFG.StrokeColor }),
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
        })

        -- header
        Create("Frame", {
            Parent           = GroupFrame,
            Size             = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel  = 0,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 5),
                Position         = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
            }),
            Create("TextLabel", {
                Text           = title,
                Size           = UDim2.new(1, -20, 1, 0),
                Position       = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3     = CFG.TextColor,
                Font           = Enum.Font.GothamBold,
                TextSize       = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            Create("Frame", {
                Size             = UDim2.new(0, 4, 0, 4),
                Position         = UDim2.new(1, -10, 0.5, -2),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel  = 0,
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
        })

        local Content = Create("Frame", {
            Parent            = GroupFrame,
            Size              = UDim2.new(1, 0, 0, 0),
            Position          = UDim2.new(0, 0, 0, 25),
            AutomaticSize     = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }),
            Create("UIPadding", {
                PaddingTop    = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft   = UDim.new(0, 8),
                PaddingRight  = UDim.new(0, 8),
            }),
        })

        local ItemFuncs = {}

        -- Toggle
        function ItemFuncs:Toggle(cfg)
            local Enabled = cfg.Default or false
            local Frame   = Create("TextButton", {
                Parent             = Content,
                Size               = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text               = "",
            })
            local Box = Create("Frame", {
                Parent           = Frame,
                Size             = UDim2.new(0, 12, 0, 12),
                Position         = UDim2.new(0, 0, 0.5, -6),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
            }, { Create("UIStroke", { Color = CFG.StrokeColor }) })
            local Check = Create("Frame", {
                Parent             = Box,
                Size               = UDim2.new(1, -4, 1, -4),
                Position           = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint        = Vector2.new(0.5, 0.5),
                BackgroundColor3   = CFG.AccentColor,
                BackgroundTransparency = Enabled and 0 or 1,
            })
            local Label = Create("TextLabel", {
                Parent             = Frame,
                Text               = cfg.Name,
                TextColor3         = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark),
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Position           = UDim2.new(0, 18, 0, 0),
                Size               = UDim2.new(1, -18, 1, 0),
                TextXAlignment     = Enum.TextXAlignment.Left,
            })
            if cfg.Risky then Label.TextColor3 = Color3.fromRGB(200, 80, 80) end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end

            local function Update()
                Enabled = not Enabled
                Tween(Check, { BackgroundTransparency = Enabled and 0 or 1 }, 0.1)
                Tween(Label, {
                    TextColor3 = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)
                }, 0.1)
                if cfg.Callback then cfg.Callback(Enabled) end
            end

            Frame.MouseButton1Click:Connect(Update)
            return {
                Set = function(v) if v ~= Enabled then Update() end end,
                Get = function()  return Enabled end,
            }
        end

        -- Slider
        function ItemFuncs:Slider(cfg)
            local Value         = cfg.Default or cfg.Min
            local DraggingSlider = false

            local Frame = Create("Frame", {
                Parent             = Content,
                Size               = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
            })
            local Label = Create("TextLabel", {
                Parent             = Frame,
                Text               = cfg.Name,
                TextColor3         = CFG.TextDark,
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, 0, 0, 15),
                TextXAlignment     = Enum.TextXAlignment.Left,
            })
            local ValueLabel = Create("TextLabel", {
                Parent             = Frame,
                Text               = tostring(Value) .. (cfg.Unit or ""),
                TextColor3         = CFG.TextDark,
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, 0, 0, 15),
                TextXAlignment     = Enum.TextXAlignment.Right,
            })
            local SliderBG = Create("Frame", {
                Parent           = Frame,
                Size             = UDim2.new(1, 0, 0, 6),
                Position         = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            })
            local Fill = Create("Frame", {
                Parent           = SliderBG,
                Size             = UDim2.new((Value - cfg.Min) / (cfg.Max - cfg.Min), 0, 1, 0),
                BackgroundColor3 = CFG.AccentColor,
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            local function UpdateSlider(input)
                local pct   = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
                local raw   = cfg.Min + (cfg.Max - cfg.Min) * pct
                local step  = cfg.Step or 1
                Value       = math.floor(raw / step + 0.5) * step
                Fill.Size   = UDim2.new(pct, 0, 1, 0)
                ValueLabel.Text = string.format(cfg.Format or "%g", Value) .. (cfg.Unit or "")
                if cfg.Callback then cfg.Callback(Value) end
            end

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = true
                    UpdateSlider(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if DraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = false
                end
            end)

            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
            return { Get = function() return Value end }
        end

        -- Dropdown
        function ItemFuncs:Dropdown(cfg)
            local Expanded = false
            local Current  = cfg.Default or cfg.Options[1]

            local Frame = Create("Frame", {
                Parent             = Content,
                Size               = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                ZIndex             = 20,
            })
            Create("TextLabel", {
                Parent             = Frame,
                Text               = cfg.Name,
                TextColor3         = CFG.TextDark,
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, 0, 0, 15),
                TextXAlignment     = Enum.TextXAlignment.Left,
            })
            local MainBox = Create("TextButton", {
                Parent           = Frame,
                Size             = UDim2.new(1, 0, 0, 20),
                Position         = UDim2.new(0, 0, 0, 16),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
                Text             = "",
                AutoButtonColor  = false,
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                Create("TextLabel", {
                    Name               = "Val",
                    Text               = Current,
                    Size               = UDim2.new(1, -20, 1, 0),
                    Position           = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3         = CFG.TextColor,
                    TextSize           = 11,
                    Font               = CFG.Font,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                }),
                Create("TextLabel", {
                    Text               = "▼",
                    Size               = UDim2.new(0, 20, 1, 0),
                    Position           = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3         = CFG.TextDark,
                    TextSize           = 10,
                }),
            })
            local ListFrame = Create("ScrollingFrame", {
                Parent              = MainBox,
                Size                = UDim2.new(1, 0, 0, 0),
                Position            = UDim2.new(0, 0, 1, 2),
                BackgroundColor3    = CFG.SecondaryColor,
                BorderSizePixel     = 0,
                Visible             = false,
                ZIndex              = 50,
                CanvasSize          = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness  = 2,
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })

            for _, opt in ipairs(cfg.Options) do
                local Btn = Create("TextButton", {
                    Parent             = ListFrame,
                    Size               = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text               = opt,
                    TextColor3         = (opt == Current) and CFG.AccentColor or CFG.TextDark,
                    TextSize           = 11,
                    Font               = CFG.Font,
                })
                Btn.MouseButton1Click:Connect(function()
                    Current              = opt
                    MainBox:FindFirstChild("Val").Text = opt
                    Expanded             = false
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible    = false
                    if cfg.Callback then cfg.Callback(opt) end
                end)
            end

            MainBox.MouseButton1Click:Connect(function()
                Expanded = not Expanded
                if Expanded then
                    ListFrame.Visible = true
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, math.min(#cfg.Options * 20, 100)) }, 0.1)
                else
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end
            end)

            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
            return { Get = function() return Current end }
        end

        -- Keybind
        function ItemFuncs:Keybind(cfg)
            local Key     = cfg.Default or Enum.KeyCode.RightShift
            local Waiting = false
            local Held    = false

            local Frame = Create("Frame", {
                Parent             = Content,
                Size               = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
            })
            Create("TextLabel", {
                Parent             = Frame,
                Text               = cfg.Name,
                TextColor3         = CFG.TextDark,
                TextSize           = 11,
                Font               = CFG.Font,
                BackgroundTransparency = 1,
                Size               = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment     = Enum.TextXAlignment.Left,
            })
            local Btn = Create("TextButton", {
                Parent           = Frame,
                Size             = UDim2.new(0, 70, 1, 0),
                AnchorPoint      = Vector2.new(1, 0),
                Position         = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = CFG.SecondaryColor,
                Text             = "[" .. Key.Name .. "]",
                TextColor3       = CFG.TextDark,
                TextSize         = 10,
                Font             = CFG.Font,
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })

            Btn.MouseButton1Click:Connect(function()
                Waiting   = true
                Btn.Text  = "[...]"
                Btn.TextColor3 = CFG.AccentColor
            end)
            UserInputService.InputBegan:Connect(function(inp)
                if inp.KeyCode == Key then Held = true end
                if Waiting and inp.UserInputType == Enum.UserInputType.Keyboard then
                    Waiting        = false
                    Key            = inp.KeyCode
                    Btn.Text       = "[" .. Key.Name .. "]"
                    Btn.TextColor3 = CFG.TextDark
                    if cfg.Callback then cfg.Callback(Key) end
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.KeyCode == Key then Held = false end
            end)

            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
            return {
                Active = function() return Held end,
                GetKey = function() return Key end,
            }
        end

        -- Button
        function ItemFuncs:Button(cfg)
            local Btn = Create("TextButton", {
                Parent           = Content,
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = CFG.SecondaryColor,
                Text             = cfg.Name,
                TextColor3       = CFG.TextDark,
                Font             = Enum.Font.GothamBold,
                TextSize         = 10,
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })
            if cfg.Variant == "Primary" then
                Btn.BackgroundColor3 = CFG.AccentColor
                Btn.TextColor3       = Color3.new(0, 0, 0)
            elseif cfg.Variant == "Danger" then
                Btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                Btn.TextColor3       = Color3.new(0, 0, 0)
            end
            Btn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
            end)
            if cfg.Tooltip then AddTooltip(Btn, cfg.Tooltip) end
        end

        return ItemFuncs
    end

    return GroupFunctions
end

-- ── Menu toggle ──────────────────────────────────────────────
Library.MenuKey = Enum.KeyCode.Insert
local Visible   = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Library.MenuKey then
        Visible         = not Visible
        MainFrame.Visible = Visible
    end
end)

local MobileToggle = Create("ImageButton", {
    Parent           = ScreenGui,
    Size             = UDim2.new(0, 40, 0, 40),
    Position         = UDim2.new(0.5, 0, 0, 10),
    AnchorPoint      = Vector2.new(0.5, 0),
    BackgroundColor3 = CFG.MainColor,
    Image            = "rbxassetid://3926305904",
    ImageColor3      = CFG.AccentColor,
    AutoButtonColor  = false,
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
    Create("UIStroke", { Color = CFG.AccentColor, Thickness = 2 }),
})
MobileToggle.MouseButton1Click:Connect(function()
    Visible           = not Visible
    MainFrame.Visible = Visible
end)


-- ============================================================
--  RAGEBOT / COUNTER / PRIORITY — UI WIRED TO ECLIPSE LIB
-- ============================================================

-- ── Tabs ─────────────────────────────────────────────────────
local RageTab  = Library:Tab("Rage",     10455604811)
local CountTab = Library:Tab("Counter",  11888734334)

-- ════════════════════════════════════════════════════════════
--  RAGEBOT TAB
-- ════════════════════════════════════════════════════════════

local RageGroup     = RageTab:Group("Ragebot")
local PriorityGroup = RageTab:Group("Priority")

-- ── state ────────────────────────────────────────────────────
local rbSettings = {
    active         = false,
    voidSpam       = true,
    voidHide       = 0.25,
    voidAttack     = 0.10,
    shootAttempts  = 1,
    mode           = 'gun',
    primary        = true,
    swapWhenEmpty  = false,
    autoPrioritize = false,
    notify         = true,
    join           = { attackers = true, ["voided players"] = true },
}

-- ── ragebot group controls ───────────────────────────────────
local rbEnabledToggle = RageGroup:Toggle({
    Name    = "Enabled",
    Tooltip = "Toggle ragebot on / off",
    Callback = function(v) rbSettings.active = v end,
})

local rbKey = RageGroup:Keybind({
    Name    = "Ragebot Key",
    Default = Enum.KeyCode.RightShift,
    Tooltip = "Hold this key to activate ragebot",
})

local rbVoidSpamToggle = RageGroup:Toggle({
    Name    = "Void Spam",
    Default = true,
    Tooltip = "Rapidly hides in void between attack windows",
    Callback = function(v) rbSettings.voidSpam = v end,
})

local rbHideSlider = RageGroup:Slider({
    Name    = "Hide Duration",
    Min     = 1,
    Max     = 100,
    Default = 25,
    Unit    = "cs",
    Step    = 1,
    Format  = "%g",
    Tooltip = "Centiseconds spent hidden in void (0.01s steps)",
    Callback = function(v) rbSettings.voidHide = v / 100 end,
})

local rbAttackSlider = RageGroup:Slider({
    Name    = "Attack Window",
    Min     = 1,
    Max     = 100,
    Default = 10,
    Unit    = "cs",
    Step    = 1,
    Format  = "%g",
    Tooltip = "Centiseconds spent attacking before hiding again",
    Callback = function(v) rbSettings.voidAttack = v / 100 end,
})

local rbAttemptsSlider = RageGroup:Slider({
    Name    = "Shoot Attempts",
    Min     = 1,
    Max     = 2,
    Default = 1,
    Unit    = "x",
    Step    = 1,
    Format  = "%g",
    Tooltip = "How many times to fire per cycle",
    Callback = function(v) rbSettings.shootAttempts = v end,
})

local rbModeDropdown = RageGroup:Dropdown({
    Name    = "Attack Mode",
    Options = { "gun", "knife", "melee" },
    Default = "gun",
    Tooltip = "Ragebot fight mode; falls back to gun if unavailable",
    Callback = function(v) rbSettings.mode = v or 'gun' end,
})

local rbWeaponDropdown = RageGroup:Dropdown({
    Name    = "Preferred Weapon",
    Options = { "primary", "secondary" },
    Default = "primary",
    Tooltip = "Which gun slot to use first",
    Callback = function(v) rbSettings.primary = (v ~= "secondary") end,
})

local rbSwapToggle = RageGroup:Toggle({
    Name    = "Swap When Empty",
    Default = false,
    Tooltip = "Switch to the other gun slot when ammo runs out",
    Callback = function(v) rbSettings.swapWhenEmpty = v end,
})

-- ── priority group controls ──────────────────────────────────
local prioAutoToggle = PriorityGroup:Toggle({
    Name    = "Auto Prioritize",
    Default = false,
    Tooltip = "Automatically target players who attack you or void",
    Callback = function(v) rbSettings.autoPrioritize = v end,
})

local prioNotifyToggle = PriorityGroup:Toggle({
    Name    = "Priority Notification",
    Default = true,
    Tooltip = "Show a notification when a player is added to priority",
    Callback = function(v) rbSettings.notify = v end,
})

local prioAttackersToggle = PriorityGroup:Toggle({
    Name    = "Target Attackers",
    Default = true,
    Tooltip = "Prioritize players who hit you",
    Callback = function(v) rbSettings.join["attackers"] = v end,
})

local prioVoidedToggle = PriorityGroup:Toggle({
    Name    = "Target Voided Players",
    Default = true,
    Tooltip = "Prioritize players who are outside the map",
    Callback = function(v) rbSettings.join["voided players"] = v end,
})

-- ── ragebot settings reader ──────────────────────────────────
local function readRagebotSettings()
    rbSettings.active = rbKey.Active()
    return rbSettings
end

-- ── ragebot enabled toggle ref (for Feature.bind equivalent) ─
local rbToggleRef = rbEnabledToggle


-- ════════════════════════════════════════════════════════════
--  COUNTER TAB
-- ════════════════════════════════════════════════════════════

local CounterGroup = CountTab:Group("Counter")
local CounterOptGroup = CountTab:Group("Options")

local COUNTER_ENGINES = {
    ["UE Counter"]    = "ue",
    ["Kicia Counter"] = "kicia",
    ["Solix Counter"] = "solix",
}

local ctrSettings = {
    active      = false,
    mode        = "ue",
    enemiesOnly = true,
    aliveOnly   = true,
    swapToMelee = true,
    swapEvery   = 0.3,
    voidSpeed   = 3000,
    engine      = Blink.DEFAULTS,
    bots = {
        on   = true,
        stay = 0.35,
        gap  = 0.50,
        lead = 6,
    },
    legits = {
        on       = true,
        stay     = 0.35,
        gap      = 0.50,
        lead     = 6,
        delay    = 3,
        max      = 1,
        priority = "lowest health",
    },
}

local ctrEnabledToggle = CounterGroup:Toggle({
    Name    = "Enabled",
    Tooltip = "Teleports your character out of the map and drops onto enemies; disables ragebot while active",
    Callback = function(v) ctrSettings.active = v end,
})

local ctrKey = CounterGroup:Keybind({
    Name    = "Counter Key",
    Default = Enum.KeyCode.RightControl,
    Tooltip = "Hold to activate counter",
})

local ctrEngineDropdown = CounterGroup:Dropdown({
    Name    = "Engine",
    Options = { "UE Counter", "Kicia Counter", "Solix Counter" },
    Default = "UE Counter",
    Tooltip = "UE: flies out of map and drops. Kicia/Solix: blink between sky and spawn",
    Callback = function(v)
        ctrSettings.mode = COUNTER_ENGINES[v] or "ue"
    end,
})

local ctrBotsToggle = CounterOptGroup:Toggle({
    Name    = "Attack Ragebots",
    Default = true,
    Tooltip = "Drop onto players detected as using a ragebot",
    Callback = function(v) ctrSettings.bots.on = v end,
})

local ctrLegitsToggle = CounterOptGroup:Toggle({
    Name    = "Attack Legits",
    Default = true,
    Tooltip = "Also drop onto normal players after 3 seconds, while only one is alive",
    Callback = function(v) ctrSettings.legits.on = v end,
})

CounterOptGroup:Button({
    Name     = "Get Me Out of Void",
    Variant  = "Danger",
    Tooltip  = "Teleports you back above spawn if stuck in the void",
    Callback = function()
        CounterSystem.rescue()
    end,
})

-- ── counter settings reader ──────────────────────────────────
local function readCounterSettings()
    ctrSettings.active = ctrKey.Active()
    return ctrSettings
end

-- ── counter on? (used by Ragebot.start to pause while counter runs) ─
local function counterIsOn()
    return ctrKey.Active()
end


-- ============================================================
--  BOOT NOTIFICATION
-- ============================================================
Library:Notify("eclipse ragebot loaded", "success")
