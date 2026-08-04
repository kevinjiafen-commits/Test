local __a1b2c3 = setmetatable({}, {
    __index = function(__d4e5f6, __g7h8i9)
        local __j0k1l2, __m3n4o5 = pcall(function()
            return game:GetService(__g7h8i9)
        end)
        if __m3n4o5 then
            return cloneref(__m3n4o5)
        end
        return nil
    end
})

local __p6q7r8 = getgenv()
if __p6q7r8.__s9t0u1 then
    __p6q7r8.__s9t0u1:Shutdown()
end

local __v2w3x4 = __a1b2c3.Players
local __y5z6a7 = __a1b2c3.RunService
local __b8c9d0 = __a1b2c3.ReplicatedStorage
local __e1f2g3 = __a1b2c3.Workspace
local __h4i5j6 = __a1b2c3.UserInputService
local __k7l8m9 = __v2w3x4.LocalPlayer
local __n0o1p2 = __e1f2g3.CurrentCamera
local __q3r4s5 = __k7l8m9.PlayerScripts
local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
local __w9x0y1 = require(__b8c9d0.Modules.Utility)

local __z2a3b4 = setmetatable({}, {
    __index = function(_, __c5d6e7)
        local __f8g9h0 = __k7l8m9.Character
        if not __f8g9h0 then return nil end
        if __c5d6e7 == "__root" then
            return __f8g9h0:FindFirstChild("HumanoidRootPart")
        elseif __c5d6e7 == "__head" then
            return __f8g9h0:FindFirstChild("Head")
        end
        return nil
    end
})

__p6q7r8.__s9t0u1 = {}

do
    local __i1j2k3 = __p6q7r8.__s9t0u1

    function __i1j2k3:__init()
        self.__active = true
        self.__target = nil
        self.__desync = false
        self.__conn1 = nil
        self.__conn2 = nil
        self.__task1 = nil
        self.__oldfunc = nil
        self:__setup()
    end

    function __i1j2k3:__setup()
        self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__active then return end
            self.__target = self:__find()
        end)

        local __l4m5n6 = __t6u7v8.StartShooting
        self.__oldfunc = __l4m5n6
        __t6u7v8.StartShooting = function(__o7p8q9, ...)
            local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
            if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                return unpack(__r0s1t2)
            end

            local __u3v4w5 = __r0s1t2[3]
            if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                return unpack(__r0s1t2)
            end

            __r0s1t2[4] = true
            local __x6y7z8 = self.__target

            if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                return unpack(__r0s1t2)
            end

            if not self.__desync or self.__curr ~= __x6y7z8 then
                self:__desync_start(__x6y7z8)
                task.wait(0.1)
            end

            if self.__task1 then
                task.cancel(self.__task1)
                self.__task1 = nil
            end

            local __a9b0c1 = __x6y7z8.Character:FindFirstChild("Head")
            if not __a9b0c1 then return unpack(__r0s1t2) end

            local __d2e3f4 = __a9b0c1.Position
            local __g5h6i7 = __a9b0c1.CFrame
            local __j8k9l0 = __d2e3f4 - Vector3.new(0, 5, 0)
            local __m1n2o3 = CFrame.lookAt(__j8k9l0, __d2e3f4)
            local __p4q5r6 = __g5h6i7:ToObjectSpace(CFrame.new(__d2e3f4 + Vector3.new(math.random(), math.random(), math.random())))

            __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(__j8k9l0, __d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
            __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(__d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
            __u3v4w5[utf8.char(2)] = __a9b0c1
            __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(__p4q5r6)

            self.__task1 = task.delay(0.15, function()
                self:__desync_stop()
            end)

            return unpack(__r0s1t2)
        end
    end

    function __i1j2k3:__find()
        local myChar = __k7l8m9.Character
        if not myChar then return nil end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
       
        local closest = nil
        local closestDist = math.huge
        local MAX_DISTANCE = 200

        for _, player in next, __v2w3x4:GetPlayers() do
            if player == __k7l8m9 then continue end
            if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
           
            local char = player.Character
            if not char then continue end

            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            
            if not (root and head and hum and hum.Health > 0) then continue end
           
            local dist = (myRoot.Position - root.Position).Magnitude
            
            if dist > MAX_DISTANCE then continue end
            
            if dist < closestDist then
                closestDist = dist
                closest = player
            end
        end
        
        return closest
    end

    function __i1j2k3:__desync_start(__c3d4e5)
        if self.__conn2 then self.__conn2:Disconnect() end
        self.__desync = true
        self.__curr = __c3d4e5

        self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__desync then return end
            local __f6g7h8 = __z2a3b4.__root
            if not __f6g7h8 then return end

            local __i9j0k1 = __c3d4e5.Character and __c3d4e5.Character:FindFirstChild("HumanoidRootPart")
            if not __i9j0k1 then
                self:__desync_stop()
                return
            end

            local __l2m3n4 = __f6g7h8.CFrame
            local __o5p6q7 = __f6g7h8.Velocity
            local __r8s9t0 = __f6g7h8.RotVelocity

            __f6g7h8.CFrame = __i9j0k1.CFrame * CFrame.new(0, -5, 0)

            __y5z6a7:BindToRenderStep("__restore", 101, function()
                __f6g7h8.CFrame = __l2m3n4
                __f6g7h8.Velocity = __o5p6q7
                __f6g7h8.RotVelocity = __r8s9t0
                __y5z6a7:UnbindFromRenderStep("__restore")
            end)
        end)
    end

    function __i1j2k3:__desync_stop()
        self.__desync = false
        self.__curr = nil
        if self.__conn2 then
            self.__conn2:Disconnect()
            self.__conn2 = nil
        end
    end

    function __i1j2k3:Shutdown()
        self.__active = false
        if self.__conn1 then self.__conn1:Disconnect() end
        if self.__conn2 then self.__conn2:Disconnect() end
        if self.__task1 then task.cancel(self.__task1) end
        if self.__oldfunc then
            __t6u7v8.StartShooting = self.__oldfunc
        end
    end

    __i1j2k3:__init()
end
