-- ============================================================
--  SkinUI.lua  –  Rivals Skin Changer + Eclipse UI
--  Skins: Keyaug AR | DraconicWildcat AR | Reaver Vandal |
--         ArchKeyper Sniper | Keyrambit+Archrambit Knife |
--         Monster Can | Keychel Satchel
-- ============================================================

local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local HttpService    = game:GetService("HttpService")
local AssetService   = game:GetService("AssetService")
local RS             = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- ============================================================
--  SKIN LOADED FLAGS  (prevent double-loading)
-- ============================================================
local Loaded = {
    KeyaugAR       = false,
    DraconicAR     = false,
    ReaverVandal   = false,
    ArchKeyper     = false,
    KeyrambitKnife = false,
    MonsterCan     = false,
    KeychelSatchel = false,
}

-- ============================================================
--  HELPER: shared obj-to-mesh converter + CDN loader
--  (used by several skins)
-- ============================================================
local function MakeSharedLoader(cacheDir)
    if not isfolder("AWildcat") then pcall(makefolder, "AWildcat") end
    if not isfolder(cacheDir)   then pcall(makefolder, cacheDir)   end

    local cdnAssets, loading = {}, {}

    local function hashStr(s)
        local h = 5381
        for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
        return string.format("%08x", h)
    end

    local function dlRaw(url)
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and type(res) == "string" and #res > 0 then return res end
        local req = request or http_request or (syn and syn.request)
        if req then
            local ok2, r = pcall(req, { Url = url, Method = "GET" })
            if ok2 and r and r.StatusCode == 200 and type(r.Body) == "string" and #r.Body > 0 then
                return r.Body
            end
        end
        return nil
    end

    local function objToMesh(text)
        local v, vt, vn, out = {}, {}, {}, {}
        local tris, faces = 0, 0
        local function idx(s, n)
            if not s or s == "" then return nil end
            local i = tonumber(s); if not i then return nil end
            return i < 0 and n + i + 1 or i
        end
        local function corner(a, b, c)
            local p = v[idx(a,#v) or 0]; if not p then return nil end
            local nn = vn[idx(c,#vn) or 0] or {0,1,0}
            local t  = vt[idx(b,#vt) or 0] or {0,0}
            return string.format("[%.5f,%.5f,%.5f][%.4f,%.4f,%.4f][%.5f,%.5f,0]",
                p[1],p[2],p[3], nn[1],nn[2],nn[3], t[1],1-t[2])
        end
        for line in text:gmatch("[^\r\n]+") do
            local c = line:sub(1,2)
            if c == "v " then
                local x,y,z = line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)")
                v[#v+1] = {tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0}
            elseif c == "vt" then
                local u,w = line:match("^vt%s+(%S+)%s+(%S+)")
                vt[#vt+1] = {tonumber(u) or 0, tonumber(w) or 0}
            elseif c == "vn" then
                local x,y,z = line:match("^vn%s+(%S+)%s+(%S+)%s+(%S+)")
                vn[#vn+1] = {tonumber(x) or 0, tonumber(y) or 1, tonumber(z) or 0}
            elseif c == "f " then
                local corners = {}
                for tok in line:gmatch("%S+") do
                    if tok ~= "f" then
                        local a,b,cc = tok:match("^(%-?%d+)/?(%-?%d*)/?(%-?%d*)")
                        local s2 = a and corner(a,b,cc)
                        if s2 then corners[#corners+1] = s2 end
                    end
                end
                for i = 2, #corners-1 do
                    out[#out+1]=corners[1]; out[#out+1]=corners[i]; out[#out+1]=corners[i+1]
                    tris = tris+1
                end
                faces = faces+1
                if faces % 4000 == 0 then task.wait() end
            end
        end
        if tris == 0 then return nil, 0 end
        return "version 1.00\n"..tris.."\n"..table.concat(out), tris
    end

    local function loadAsset(path)
        for _ = 1, 5 do
            if isfile(path) then
                local ok, asset = pcall(getcustomasset, path)
                if ok and asset then return asset end
            end
            task.wait(0.3)
        end
        return nil
    end

    local loadCdnInner
    local function loadCdn(url)
        if cdnAssets[url] then return cdnAssets[url] end
        if loading[url] then while loading[url] do task.wait() end return cdnAssets[url] end
        loading[url] = true
        local ok, res = pcall(loadCdnInner, url)
        loading[url] = nil
        return ok and res or nil
    end

    loadCdnInner = function(url)
        local name = url:match("[^/]+$") or url
        local ext  = (url:match("%.(%w+)$") or "bin"):lower()
        local conv = ext == "obj"
        local path = cacheDir.."/"..hashStr(url)..".".. (conv and "mesh" or ext)
        if not isfile(path) then
            local data = dlRaw(url)
            if not data or (#data < 200 and data:find("404")) then return nil end
            if conv then
                local mesh, tris = objToMesh(data)
                if not mesh then return nil end
                data = mesh
            end
            if not pcall(writefile, path, data) then return nil end
        end
        local asset = loadAsset(path)
        cdnAssets[url] = asset
        return asset
    end

    return { loadCdn = loadCdn, loadAsset = loadAsset, hashStr = hashStr }
end

-- ============================================================
--  SKIN 1 – KEYAUG  (Assault Rifle)
-- ============================================================
local function LoadKeyaugAR(notify)
    if Loaded.KeyaugAR then notify("Keyaug AR 已经加载过了", "warning"); return end
    Loaded.KeyaugAR = true
    notify("正在加载 Keyaug AR...", "success")
    task.spawn(function()
        -- Part A: coslib unlocker
        pcall(function()
            local KEYWORD = "aug"
            local lp = Players.LocalPlayer
            local ctrl = lp.PlayerScripts:WaitForChild("Controllers", 10)
            local mods = RS:WaitForChild("Modules", 10)
            local enumLib = require(mods:WaitForChild("EnumLibrary", 10))
            if enumLib then pcall(function() enumLib:WaitForEnumBuilder() end) end
            local cosLib  = require(mods:WaitForChild("CosmeticLibrary", 10))
            local datCtrl = require(ctrl:WaitForChild("PlayerDataController", 10))
            local Cosmetics = cosLib.Cosmetics
            local arCache, augCache = {}, {}
            local function isAR(w)
                if type(w) == "table" then w = w.Name end
                if type(w) ~= "string" then return false end
                local r = arCache[w]; if r == nil then
                    r = (w:lower():gsub("%s+","")) == "assaultrifle"; arCache[w] = r end
                return r
            end
            local function isAugSkin(n)
                if type(n) ~= "string" then return false end
                local r = augCache[n]; if r == nil then
                    local c = Cosmetics[n]
                    r = (n:lower():find(KEYWORD,1,true) ~= nil) and c ~= nil and c.Type == "Skin"
                    augCache[n] = r end
                return r
            end
            local function mkSkin(name)
                local base = Cosmetics[name]; if not base then return nil end
                local d = {}; for k,v in pairs(base) do d[k]=v end
                d.Name=name; d.Type=d.Type or "Skin"; d.Seed=d.Seed or math.random(1,1000000)
                if enumLib then
                    local ok,id = pcall(enumLib.ToEnum, enumLib, name)
                    if ok and id then d.Enum=id; d.ObjectID=d.ObjectID or id end
                end
                return d
            end
            local matches = {}
            for name, c in pairs(Cosmetics) do
                if type(name)=="string" and c.Type=="Skin" and name:lower():find(KEYWORD,1,true) then
                    table.insert(matches, name) end
            end
            table.sort(matches)
            if #matches == 0 then return end
            local arSkin = mkSkin(matches[1])
            for _, key in ipairs({"OwnsCosmetic","OwnsCosmeticNormally","OwnsCosmeticUniversally","OwnsCosmeticForWeapon"}) do
                local orig = cosLib[key]
                if type(orig) == "function" then
                    cosLib[key] = function(self, inv, nm, wep, ...)
                        if isAR(wep) and isAugSkin(nm) then return true end
                        return orig(self, inv, nm, wep, ...)
                    end
                end
            end
            local origGet = datCtrl.Get
            local invSrc, invProxy
            datCtrl.Get = function(self, key, ...)
                local val = origGet(self, key, ...)
                if key == "CosmeticInventory" then
                    if invProxy and invSrc == val then return invProxy end
                    local prx = {}
                    if val then for k,v in pairs(val) do prx[k]=v end end
                    invSrc, invProxy = val, setmetatable(prx, {__index=function(_,k) if isAugSkin(k) then return true end end})
                    return invProxy
                end
                return val
            end
            local origGetWep = datCtrl.GetWeaponData
            local wepCache = {}
            datCtrl.GetWeaponData = function(self, wn, ...)
                local d = origGetWep(self, wn, ...)
                if not d then return nil end
                if arSkin and isAR(wn) then
                    local c = wepCache[wn]
                    if c and c.src==d and c.skin==arSkin then return c.out end
                    local m = {}; for k,v in pairs(d) do m[k]=v end
                    m.Name=wn; m.Skin=arSkin
                    wepCache[wn]={src=d,skin=arSkin,out=m}
                    return m
                end
                return d
            end
            task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end)
        end)

        -- Part B: visual replacer (Keyaug CDN meshes / sounds)
        pcall(function()
            local CDN_FOLDER = "AWildcat/keyaug"
            if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
            if not isfolder(CDN_FOLDER) then pcall(makefolder,CDN_FOLDER) end
            local loader = MakeSharedLoader(CDN_FOLDER)

            local CONFIG_JSON = [[{
"replacement_rules": [
{"name":"Body","replace_ids":[18687757654],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/refs/heads/main/KeyaugBody9.obj","scale":"aug","texture":"key"},
{"name":"Remove","replace_ids":[18687757291,18687757011,18687756555,18687757157],"mode":"id","enabled":true},
{"name":"shootingsound","replace_ids":[17662574783],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/kaug.mp3"},
{"name":"Removeshootsound","replace_ids":[18764343961],"mode":"id","enabled":true},
{"name":"Removebolt","replace_ids":[18687757424],"mode":"id","enabled":true},
{"name":"Removemag","replace_ids":[18687756845],"mode":"id","enabled":true},
{"name":"Mag","replace_ids":[18687756685],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/refs/heads/main/KeyaugMag1.obj","scale":"mag","texture":"key"},
{"name":"Reloadsound1","replace_ids":[13455395017],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/kaug%20reload%2017.mp3"},
{"name":"Reloadsound2","replace_ids":[13236549929],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/kaug%20reload%2029.mp3"},
{"name":"Reloadsound3","replace_ids":[13236549962],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/kaug%20reload%2062.mp3"},
{"name":"icoh","replace_ids":[18770201102,18770192853],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/iconkeyaug.png"}
]}]]

            local SCALES = {aug=1.2, mag=0.7}
            local KEY_BASE={255,196,40}; local KEY_DARK={150,100,10}; local KEY_EDGE={255,240,170}

            -- build PNG texture
            local crcTable = {}
            for i=0,255 do local c=i; for _=1,8 do if bit32.band(c,1)==1 then c=bit32.bxor(bit32.rshift(c,1),0xEDB88320) else c=bit32.rshift(c,1) end end crcTable[i]=c end
            local function crc32(s) local c=0xFFFFFFFF; for i=1,#s do c=bit32.bxor(crcTable[bit32.band(bit32.bxor(c,s:byte(i)),0xFF)],bit32.rshift(c,8)) end return bit32.bxor(c,0xFFFFFFFF) end
            local function adler32(s) local a,b=1,0; for i=1,#s do a=(a+s:byte(i))%65521; b=(b+a)%65521 end return b*65536+a end
            local function pngChunk(k,d) return string.pack(">I4",#d)..k..d..string.pack(">I4",crc32(k..d)) end
            local function makePng(w,h,pixel)
                local rows={}
                for y=0,h-1 do local row={"\0"}; for x=0,w-1 do local r,g,b=pixel(x,y); row[#row+1]=string.char(r,g,b) end rows[#rows+1]=table.concat(row) end
                local raw=table.concat(rows)
                local blocks={"\120\1"}; local pos=1
                while pos<=#raw do local piece=raw:sub(pos,pos+65534); pos=pos+#piece; local final=(pos>#raw) and 1 or 0
                    blocks[#blocks+1]=string.char(final)..string.pack("<I2",#piece)..string.pack("<I2",bit32.band(bit32.bnot(#piece),0xFFFF))..piece end
                blocks[#blocks+1]=string.pack(">I4",adler32(raw))
                return "\137PNG\r\n\26\n"..pngChunk("IHDR",string.pack(">I4I4",w,h).."\8\2\0\0\0")..pngChunk("IDAT",table.concat(blocks))..pngChunk("IEND","")
            end

            local function keyTex(x,y)
                local c=KEY_BASE
                if x<6 or y<6 or x>=250 or y>=250 then c=KEY_EDGE
                elseif ((x+y)//24)%2==0 then c=KEY_DARK end
                return c[1],c[2],c[3]
            end
            local texPath = CDN_FOLDER.."/tex_key_v2.png"
            if not isfile(texPath) then
                local ok,png=pcall(makePng,256,256,keyTex)
                if ok then pcall(writefile,texPath,png) end
            end
            local texAsset = loader.loadAsset(texPath)

            -- parse rules + replace
            local rules = HttpService:JSONDecode(CONFIG_JSON).replacement_rules
            local lookup, meshCache, scaleState = {}, {}, setmetatable({},{__mode="k"})
            local seen = setmetatable({},{__mode="k"})
            local forcedTexture = setmetatable({},{__mode="k"})

            local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end

            local pending=#rules
            local targets={}
            for i,rule in ipairs(rules) do
                task.spawn(function()
                    local t
                    if rule.mode=="cdn" then t=loader.loadCdn(rule.cdn_url)
                    elseif rule.with_id then t="rbxassetid://"..rule.with_id
                    else t="" end
                    targets[i]=t; pending=pending-1
                end)
            end
            while pending>0 do task.wait() end

            for i,rule in ipairs(rules) do
                local tgt=targets[i]; if tgt~=nil then
                    local entry={target=tgt}
                    if rule.scale then entry.scale=SCALES[rule.scale] end
                    if rule.texture and texAsset then entry.texture=texAsset end
                    for _,id in ipairs(rule.replace_ids) do
                        local n=parseId(id); if n then lookup[n]=entry end
                    end
                end
            end

            local PROPS={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}

            local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
            local function applyMesh(inst,asset)
                if not inst:IsA("MeshPart") then pcall(function() inst.MeshId=asset end); return end
                local ok,err=pcall(function()
                    local mp=meshCache[asset]
                    if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end
                    inst:ApplyMesh(mp)
                end)
                if not ok then pcall(function() inst.MeshId=asset end) end
            end
            local function applyScale(inst,factor)
                if not factor or factor==1 then return end
                local st=scaleState[inst]; if st~=nil then if st then task.defer(function() pcall(function() if inst:IsA("MeshPart") then inst.Size=st else inst.Scale=st end end) end) end; return end
                scaleState[inst]=false
                task.spawn(function()
                    task.wait(0.1)
                    local t; pcall(function() if inst:IsA("MeshPart") then t=inst.Size*factor elseif inst:IsA("SpecialMesh") then t=inst.Scale*factor end end)
                    if t then scaleState[inst]=t; pcall(function() if inst:IsA("MeshPart") then inst.Size=t else inst.Scale=t end end) end
                end)
            end
            local function setTexture(inst,asset)
                local prop=inst:IsA("SpecialMesh") and "TextureId" or "TextureID"
                forcedTexture[inst]=asset; pcall(function() inst[prop]=asset end)
            end
            local function handle(inst,p)
                local ok,cur=pcall(function() return inst[p] end); if not ok then return false end
                local forced=forcedTexture[inst]
                if forced and (p=="TextureID" or p=="TextureId") then if cur~=forced then pcall(function() inst[p]=forced end) end; return true end
                if cur=="" or cur==nil then return false end
                local id=parseId(cur); local entry=id and lookup[id]; if entry==nil then return false end
                local new=entry.target
                if p=="MeshId" then
                    if new=="" then hideMesh(inst) else applyMesh(inst,new); if entry.texture then setTexture(inst,entry.texture) end; applyScale(inst,entry.scale) end
                else pcall(function() inst[p]=new end) end
                return true
            end
            local function apply(inst)
                local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
                for _,p in ipairs(props) do
                    handle(inst,p)
                    pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end)
                end
            end
            game.DescendantAdded:Connect(apply)
            local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end
        end)
        notify("✅ Keyaug AR 已加载", "success")
    end)
end

-- ============================================================
--  SKIN 2 – DRACONIC WILDCAT  (Assault Rifle)
-- ============================================================
local function LoadDraconicAR(notify)
    if Loaded.DraconicAR then notify("Draconic AR 已经加载过了","warning"); return end
    Loaded.DraconicAR = true
    notify("正在加载 Draconic Wildcat AR...","success")
    task.spawn(function()
        pcall(function()
            local CDN = "AWildcat/draconic"
            if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
            if not isfolder(CDN) then pcall(makefolder,CDN) end
            local loader = MakeSharedLoader(CDN)

            local CONFIG_JSON = [[{
  "replacement_rules": [
    {"name":"ar15-body","replace_ids":[83884702080665],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/roar.mesh"},
    {"name":"Profile 6","replace_ids":[13158330555],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/draload.mp3"},
    {"name":"Reload 2?","replace_ids":[13236549962],"mode":"id","enabled":true},
    {"name":"Profile 9","replace_ids":[13158735106],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/m4a1%20dragon.mp3"},
    {"name":"remove","replace_ids":[75392286602848,131204076200915,85569047699564],"mode":"id","enabled":true},
    {"name":"Profile 10","replace_ids":[72815891526849,134260292117186,101461115963186],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/bow_dreag.mp3"},
    {"name":"Profile 12","replace_ids":[88813579505134],"mode":"id","enabled":true,"with_id":13010870236},
    {"name":"Profile 13","replace_ids":[88813579505134],"mode":"id","enabled":true,"with_id":13010885336},
    {"name":"Profile 14","replace_ids":[120946011201823],"mode":"id","enabled":true,"with_id":13010893629},
    {"name":"mag 2","replace_ids":[95562281570535],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/magazine_roar.mesh"},
    {"name":"low","replace_ids":[77401164737509],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/dragon_thumbnail.png"},
    {"name":"high","replace_ids":[124155708481848],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/dragon_gun_thumbnail_2.png"},
    {"name":"up mag remo","replace_ids":[83070615292783],"mode":"id","enabled":true}
  ]
}]]
            local SCALE = 2
            local SCALE_BY_ID = {[95562281570535]=1.3}
            local VOLUME = {[13158330555]=2.5,[13158735106]=0.4}
            -- texture by original mesh id
            local TEXTURE_URL_BY_ID = {
                [83884702080665]="https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/roar_texture_2048.png",
                [95562281570535]="https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/main/magazine_texture_2048.png",
            }

            local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end

            -- load per-mesh textures
            local TEXTURES = {}
            for id, url in pairs(TEXTURE_URL_BY_ID) do
                local t = loader.loadCdn(url)
                if t then TEXTURES[id] = t end
            end

            local rules = HttpService:JSONDecode(CONFIG_JSON).replacement_rules
            local lookup, meshCache = {}, {}
            local seen           = setmetatable({},{__mode="k"})
            local lastScaled     = setmetatable({},{__mode="k"})
            local volState       = setmetatable({},{__mode="k"})
            local texFor         = setmetatable({},{__mode="k"})
            local watched        = setmetatable({},{__mode="k"})

            -- resolve
            local pending = #rules; local targets = {}
            for i,rule in ipairs(rules) do
                task.spawn(function()
                    local t
                    if rule.mode=="cdn" then t=loader.loadCdn(rule.cdn_url)
                    elseif rule.with_id then t="rbxassetid://"..rule.with_id
                    else t="" end
                    targets[i]=t; pending=pending-1
                end)
            end
            while pending>0 do task.wait() end

            for i,rule in ipairs(rules) do
                local tgt=targets[i]; if tgt~=nil then
                    for _,id in ipairs(rule.replace_ids) do
                        local n=parseId(id); if n then lookup[n]=tgt end
                    end
                end
            end

            local function scaleMesh(inst,mult)
                local m=mult or SCALE; if m==1 then return end
                pcall(function()
                    if inst:IsA("MeshPart") then local last=lastScaled[inst]; if last and (inst.Size-last).Magnitude<0.001 then return end local t=inst.Size*m; inst.Size=t; lastScaled[inst]=t
                    elseif inst:IsA("SpecialMesh") then local last=lastScaled[inst]; if last and (inst.Scale-last).Magnitude<0.001 then return end local t=inst.Scale*m; inst.Scale=t; lastScaled[inst]=t end
                end)
            end
            local function applyVolume(inst,mult)
                if not mult then return end
                pcall(function()
                    local st=volState[inst]
                    if not st then
                        st={mult=mult,target=inst.Volume}; volState[inst]=st
                        inst:GetPropertyChangedSignal("Volume"):Connect(function()
                            if math.abs(inst.Volume-st.target)>0.001 then st.target=math.clamp(inst.Volume*st.mult,0,10); inst.Volume=st.target end
                        end)
                    end
                    if not st.done then st.target=math.clamp(inst.Volume*mult,0,10); inst.Volume=st.target; st.done=true end
                end)
            end
            local function setTexture(inst,tex)
                if not tex then return end; texFor[inst]=tex
                pcall(function() if inst:IsA("MeshPart") then inst.TextureID=tex else inst.TextureId=tex end end)
                for _,c in ipairs(inst:GetChildren()) do if c:IsA("SurfaceAppearance") then c:Destroy() end end
                if not watched[inst] then
                    watched[inst]=true
                    inst.ChildAdded:Connect(function(c) if c:IsA("SurfaceAppearance") then task.defer(function() pcall(function() c:Destroy() end) end) end end)
                    local prop=inst:IsA("MeshPart") and "TextureID" or "TextureId"
                    pcall(function() inst:GetPropertyChangedSignal(prop):Connect(function() local w=texFor[inst]; if w and inst[prop]~=w then pcall(function() inst[prop]=w end) end end) end)
                end
            end
            local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
            local function applyMesh(inst,asset)
                if inst:IsA("MeshPart") then
                    local ok,err=pcall(function() local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end; inst:ApplyMesh(mp) end)
                    if not ok then pcall(function() inst.MeshId=asset end) end
                else pcall(function() inst.MeshId=asset end) end
            end

            local PROPS={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}

            local function handle(inst,p)
                local ok,cur=pcall(function() return inst[p] end); if not ok then return end
                local id=parseId(cur); local new=id and lookup[id]; if new==nil then return end
                if p=="MeshId" then
                    if new=="" then hideMesh(inst) else
                        applyMesh(inst,new); scaleMesh(inst,SCALE_BY_ID[id]); setTexture(inst,TEXTURES[id])
                    end
                else pcall(function() inst[p]=new end); if p=="SoundId" then applyVolume(inst,VOLUME[id]) end end
            end
            local function apply(inst)
                local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
                for _,p in ipairs(props) do handle(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
            end
            game.DescendantAdded:Connect(apply)
            local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end
        end)
        notify("✅ Draconic Wildcat AR 已加载","success")
    end)
end

-- ============================================================
--  SKIN 3 – REAVER VANDAL
-- ============================================================
local function LoadReaverVandal(notify)
    if Loaded.ReaverVandal then notify("Reaver Vandal 已经加载过了","warning"); return end
    Loaded.ReaverVandal = true
    notify("正在加载 Reaver Vandal...","success")
    task.spawn(function()
        pcall(function()
            local CDN="AWildcat/reaver"
            if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
            if not isfolder(CDN) then pcall(makefolder,CDN) end
            local loader = MakeSharedLoader(CDN)

            local CONFIG_JSON=[[{
  "replacement_rules": [
    {"type":"group","name":"Model","children":[
      {"name":"Body Replace","replace_ids":[12613284036],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver_body.mesh"},
      {"name":"Upper Replace","replace_ids":[12613284249],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver_bits.mesh"},
      {"name":"Bolt Replace","replace_ids":[12613283355],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver_bolt.mesh"},
      {"name":"Mag Replace","replace_ids":[12613284529],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver_mag.mesh"},
      {"name":"Hide Extras","replace_ids":[12613283569,14652718299,12613284768],"mode":"id","enabled":true}
    ]},
    {"type":"group","name":"Sound","children":[
      {"name":"Shoot Replace","replace_ids":[13087362838],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver%20shoot.mp3"},
      {"name":"Reload Replace1","replace_ids":[13236549929,13236549962],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver%20load1.mp3"},
      {"name":"Reload Replace","replace_ids":[13455395017],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver%20load2.mp3"}
    ]},
    {"type":"group","name":"Icon","children":[
      {"name":"Icon Replace 1","replace_ids":[17160682738],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver%20vandel%20thumbnail.png"},
      {"name":"Icon Replace 2","replace_ids":[13197584241],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver%20vandel%20thumbnail%202.png"}
    ]}
  ]
}]]
            local SCALE=1.35

            local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
            local function flatten(list, out)
                for _,r in ipairs(list) do
                    if r.type=="group" then flatten(r.children or {},out)
                    elseif r.enabled then out[#out+1]=r end
                end; return out
            end

            local rules = HttpService:JSONDecode(CONFIG_JSON).replacement_rules
            local active = flatten(rules,{})
            local lookup, meshCache = {}, {}
            local seen        = setmetatable({},{__mode="k"})
            local lastScaled  = setmetatable({},{__mode="k"})
            local isMeshRule  = setmetatable({},{__mode="k"})

            local pending=#active; local targets={}
            for i,rule in ipairs(active) do
                task.spawn(function()
                    local t
                    if rule.mode=="cdn" then t=loader.loadCdn(rule.cdn_url)
                    elseif rule.with_id then t="rbxassetid://"..rule.with_id
                    else t="" end
                    targets[i]=t; pending=pending-1
                end)
            end
            while pending>0 do task.wait() end

            local meshTargets={}
            for i,rule in ipairs(active) do
                local tgt=targets[i]; if tgt~=nil then
                    local isMesh = rule.mode=="cdn" and tgt and tostring(rule.cdn_url):lower():find("%.mesh$")
                    if isMesh then meshTargets[tgt]=true end
                    for _,id in ipairs(rule.replace_ids) do
                        local n=parseId(id); if n then lookup[n]={target=tgt,baked=isMesh} end
                    end
                end
            end
            -- pre-warm mesh parts
            local warming=0
            for asset in pairs(meshTargets) do
                warming=warming+1
                task.spawn(function() pcall(function() meshCache[asset]=AssetService:CreateMeshPartAsync(asset) end); warming=warming-1 end)
            end
            local t0=os.clock(); while warming>0 and os.clock()-t0<15 do task.wait() end

            local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
            local function applyMesh(inst,asset)
                if inst:IsA("MeshPart") then
                    local ok,err=pcall(function() local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end; inst:ApplyMesh(mp) end)
                    if not ok then warn("[Reaver] ApplyMesh: "..tostring(err)); pcall(function() inst.MeshId=asset end) end
                else pcall(function() inst.MeshId=asset end) end
            end
            local origSz=setmetatable({},{__mode="k"})
            local function scaleMesh(inst,asset)
                if not inst:IsA("MeshPart") then return end
                if not origSz[inst] then origSz[inst]=inst.Size end
                task.spawn(function() task.wait(0.1); pcall(function()
                    local mp=meshCache[asset]; if not mp then return end
                    local nat=mp.Size; local ref=origSz[inst]
                    local f=math.max(ref.X,ref.Y,ref.Z)/math.max(nat.X,nat.Y,nat.Z)
                    inst.Size=nat*f*SCALE
                end) end)
            end
            local function applyClean(inst)
                pcall(function()
                    local prop=inst:IsA("MeshPart") and "TextureID" or "TextureId"
                    inst[prop]=""
                    if inst:IsA("MeshPart") then inst.Color=Color3.new(1,1,1) else inst.VertexColor=Vector3.new(1,1,1) end
                    for _,c in ipairs(inst:GetChildren()) do if c:IsA("SurfaceAppearance") then c:Destroy() end end
                    inst.ChildAdded:Connect(function(c) if c:IsA("SurfaceAppearance") then task.defer(function() pcall(function() c:Destroy() end) end) end end)
                end)
            end

            local PROPS={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
            local function handle(inst,p)
                local ok,cur=pcall(function() return inst[p] end); if not ok or cur=="" then return end
                local id=parseId(cur); local entry=id and lookup[id]; if not entry then return end
                local new=entry.target
                if p=="MeshId" then
                    if new=="" then hideMesh(inst) else applyMesh(inst,new); if entry.baked then applyClean(inst); scaleMesh(inst,new) end end
                else pcall(function() inst[p]=new end) end
            end
            local function apply(inst)
                local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
                for _,p in ipairs(props) do handle(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
            end
            game.DescendantAdded:Connect(apply)
            local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end
        end)
        notify("✅ Reaver Vandal 已加载","success")
    end)
end

-- ============================================================
--  SKIN 4 – ARCHKEYPER  (Sniper)
-- ============================================================
local function LoadArchKeyper(notify)
    if Loaded.ArchKeyper then notify("ArchKeyper 已经加载过了","warning"); return end
    Loaded.ArchKeyper = true
    notify("正在加载 ArchKeyper Sniper...","success")
    task.spawn(function()
        pcall(function()
            local CDN="AWildcat/archkeyper"
            if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
            if not isfolder(CDN) then pcall(makefolder,CDN) end
            local loader = MakeSharedLoader(CDN)

            local MESH_URL="https://raw.githubusercontent.com/mrbeanissohot/ArchKeyperr/main/arch_keyper_v4.mesh"
            local meshPath=CDN.."/arch_keyper_v4.mesh"
            local meshAsset

            -- download mesh
            if not isfile(meshPath) then
                local ok,body=pcall(function() return game:HttpGet(MESH_URL) end)
                if ok and body and #body>0 then pcall(writefile,meshPath,body) end
            end
            meshAsset = loader.loadAsset(meshPath)

            local CONFIG_JSON=[[{
  "replacement_rules": [
    {"name":"Profile 1","replace_ids":[13188892761],"mode":"local","enabled":true,"local_path":"arch_keyper_v4.mesh"},
    {"name":"Profile 2","replace_ids":[14778413014,13188893115,13188893017,14774727092,13188892855,13188893310,14002915797,13188892651,13188892532],"mode":"id","enabled":true},
    {"name":"Equip","replace_ids":[13269929260],"mode":"id","enabled":true,"with_id":13269929260},
    {"name":"Idle","replace_ids":[13269931582],"mode":"id","enabled":true,"with_id":13269931582},
    {"name":"Sprint","replace_ids":[13321899382],"mode":"id","enabled":true,"with_id":13321899382},
    {"name":"Inspect","replace_ids":[13269934368],"mode":"id","enabled":true,"with_id":13269934368},
    {"name":"Shoot","replace_ids":[13269963346],"mode":"id","enabled":true,"with_id":13269963346},
    {"name":"Reload","replace_ids":[13642104835],"mode":"id","enabled":true,"with_id":13642104835},
    {"name":"ReloadEmpty","replace_ids":[13269951125],"mode":"id","enabled":true,"with_id":13269951125}
  ]
}]]
            local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
            local rules=HttpService:JSONDecode(CONFIG_JSON).replacement_rules
            local lookup, meshCache = {}, {}
            local seen = setmetatable({},{__mode="k"})

            for _,rule in ipairs(rules) do
                if rule.enabled then
                    local tgt
                    if rule.mode=="local" and meshAsset then tgt=meshAsset
                    elseif rule.with_id then tgt="rbxassetid://"..rule.with_id
                    else tgt="" end
                    if tgt~=nil then
                        for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]=tgt end end
                    end
                end
            end

            local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
            local function applyMesh(inst,asset)
                if inst:IsA("MeshPart") then
                    local ok,err=pcall(function() local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end; inst:ApplyMesh(mp) end)
                    if not ok then pcall(function() inst.MeshId=asset end) end
                else pcall(function() inst.MeshId=asset end) end
            end
            local PROPS={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
            local function handle(inst,p)
                local ok,cur=pcall(function() return inst[p] end); if not ok then return end
                local id=parseId(cur); local new=id and lookup[id]; if new==nil then return end
                if p=="MeshId" then if new=="" then hideMesh(inst) else applyMesh(inst,new) end
                else pcall(function() inst[p]=new end) end
            end
            local function apply(inst)
                local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
                for _,p in ipairs(props) do handle(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
            end
            game.DescendantAdded:Connect(apply)
            local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end
        end)
        notify("✅ ArchKeyper Sniper 已加载","success")
    end)
end

-- ============================================================
--  SKIN 5 – KEYRAMBIT + ARCHRAMBIT  (Knife)
-- ============================================================
local function LoadKeyrambitKnife(notify)
    if Loaded.KeyrambitKnife then notify("Knife skin 已经加载过了","warning"); return end
    Loaded.KeyrambitKnife = true
    notify("正在加载 Keyrambit + Archrambit Knife...","success")
    task.spawn(function()
        -- Coslib unlocker (Keyrambit)
        pcall(function()
            local KEYWORD="keyrambit"
            local lp=Players.LocalPlayer
            local ctrl=lp.PlayerScripts:WaitForChild("Controllers",10)
            local mods=RS:WaitForChild("Modules",10)
            local enumLib=require(mods:WaitForChild("EnumLibrary",10))
            if enumLib then pcall(function() enumLib:WaitForEnumBuilder() end) end
            local cosLib=require(mods:WaitForChild("CosmeticLibrary",10))
            local datCtrl=require(ctrl:WaitForChild("PlayerDataController",10))
            local Cosmetics=cosLib.Cosmetics
            local function isKnife(w) if type(w)=="table" then w=w.Name end; if type(w)~="string" then return false end; return (w:lower():gsub("%s+",""))=="knife" end
            local function isKeyName(n) return type(n)=="string" and (n:lower():gsub("%s+","")):find(KEYWORD,1,true)~=nil end
            local function isKeySkin(n) local c=isKeyName(n) and Cosmetics[n]; return c and c.Type=="Skin" or false end
            local function mkSkin(name) local base=Cosmetics[name]; if not base then return nil end; local d={}; for k,v in pairs(base) do d[k]=v end; d.Name=name; d.Type=d.Type or "Skin"; d.Seed=d.Seed or math.random(1,1000000); if enumLib then local ok,id=pcall(enumLib.ToEnum,enumLib,name); if ok and id then d.Enum=id; d.ObjectID=d.ObjectID or id end end; return d end
            local matches={}; for name,c in pairs(Cosmetics) do if type(name)=="string" and c.Type=="Skin" and isKeyName(name) then table.insert(matches,name) end end; table.sort(matches)
            if #matches==0 then return end
            local knifeSkin=mkSkin(matches[1])
            for _,key in ipairs({"OwnsCosmetic","OwnsCosmeticNormally","OwnsCosmeticUniversally","OwnsCosmeticForWeapon"}) do local orig=cosLib[key]; if type(orig)=="function" then cosLib[key]=function(self,inv,nm,wep,...) if isKnife(wep) and isKeySkin(nm) then return true end; return orig(self,inv,nm,wep,...) end end end
            local origGet=datCtrl.Get; datCtrl.Get=function(self,key,...) local val=origGet(self,key,...); if key=="CosmeticInventory" then local prx={}; if val then for k,v in pairs(val) do prx[k]=v end end; return setmetatable(prx,{__index=function(_,k) if isKeySkin(k) then return true end end}) end; return val end
            local origGetWep=datCtrl.GetWeaponData; datCtrl.GetWeaponData=function(self,wn,...) local d=origGetWep(self,wn,...); if not d then return nil end; if isKnife(wn) and knifeSkin then local m={}; for k,v in pairs(d) do m[k]=v end; m.Name=wn; m.Skin=knifeSkin; return m end; return d end
            task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end)
        end)

        -- Green tint enforcer
        pcall(function()
            local GREEN=Color3.fromRGB(110,255,140)
            local ws=workspace; local lp=Players.LocalPlayer
            local tinted=setmetatable({},{__mode="k"})
            local function nameHit(inst) local p=inst; for _=1,10 do if not p or p==ws then break end; local n=p.Name:lower(); if n:find("knife",1,true) or n:find("rambit",1,true) then return true end; p=p.Parent end; return false end
            local function inMine(inst) local cam=ws.CurrentCamera; return (cam and inst:IsDescendantOf(cam)) or (lp.Character and inst:IsDescendantOf(lp.Character)) end
            local function tint(inst)
                if tinted[inst] or not (inst:IsA("MeshPart") or inst:IsA("SpecialMesh")) then return end
                if not (inMine(inst) and nameHit(inst)) then return end
                tinted[inst]=true
                local prop=inst:IsA("MeshPart") and "Color" or "VertexColor"
                local function set() pcall(function() if prop=="Color" then inst.Color=GREEN else inst.VertexColor=Vector3.new(GREEN.R,GREEN.G,GREEN.B) end end) end
                set(); pcall(function() inst:GetPropertyChangedSignal(prop):Connect(set) end)
            end
            ws.DescendantAdded:Connect(function(d) task.defer(tint,d) end)
            task.spawn(function() while true do local cam=ws.CurrentCamera; if cam then for _,d in ipairs(cam:GetDescendants()) do tint(d) end end; if lp.Character then for _,d in ipairs(lp.Character:GetDescendants()) do tint(d) end end; task.wait(0.5) end end)
        end)

        -- Archrambit visual replacer
        pcall(function()
            local CDN="AWildcat/archrambit"
            if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
            if not isfolder(CDN) then pcall(makefolder,CDN) end
            local loader=MakeSharedLoader(CDN)

            local MESH_URL   ="https://raw.githubusercontent.com/mrbeanissohot/Archrambit/main/archrambiyt.mesh"
            local TEX_URL    ="https://raw.githubusercontent.com/mrbeanissohot/Archrambit/main/arch_texture.png"
            local meshPath   =CDN.."/archrambiyt.mesh"
            local texPath    =CDN.."/arch_texture.png"

            if not isfile(meshPath) then local ok,b=pcall(function() return game:HttpGet(MESH_URL) end); if ok and b then pcall(writefile,meshPath,b) end end
            if not isfile(texPath)  then local ok,b=pcall(function() return game:HttpGet(TEX_URL)  end); if ok and b then pcall(writefile,texPath ,b) end end
            local meshAsset=loader.loadAsset(meshPath)
            local texAsset =loader.loadAsset(texPath)

            local CONFIG_JSON=[[{
  "replacement_rules": [
    {"name":"re","replace_ids":[12482022259,12482022363],"mode":"id","enabled":true},
    {"name":"xd","replace_ids":[105653154583773],"mode":"local","enabled":true},
    {"name":"an","replace_ids":[12613363718],"mode":"id","enabled":true,"with_id":18742841521},
    {"name":"in","replace_ids":[12613329711],"mode":"id","enabled":true,"with_id":18742879471},
    {"name":"hravy","replace_ids":[12613354440],"mode":"id","enabled":true,"with_id":18742868264},
    {"name":"idle","replace_ids":[12613190591],"mode":"id","enabled":true,"with_id":18742849437},
    {"name":"sprint","replace_ids":[12886796453],"mode":"id","enabled":true,"with_id":18742894186}
  ]
}]]
            local SCALE=1.45
            local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
            local rules=HttpService:JSONDecode(CONFIG_JSON).replacement_rules
            local lookup, meshCache = {}, {}
            local seen        = setmetatable({},{__mode="k"})
            local lastScaled  = setmetatable({},{__mode="k"})
            local watched     = setmetatable({},{__mode="k"})
            local GREEN=Color3.fromRGB(110,255,140)

            for _,rule in ipairs(rules) do if rule.enabled then
                local tgt
                if rule.mode=="local" and meshAsset then tgt=meshAsset
                elseif rule.with_id then tgt="rbxassetid://"..rule.with_id
                else tgt="" end
                if tgt~=nil then for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]=tgt end end end
            end end

            local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
            local function applyMesh(inst,asset)
                if inst:IsA("MeshPart") then local ok,err=pcall(function() local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end; inst:ApplyMesh(mp) end); if not ok then pcall(function() inst.MeshId=asset end) end
                else pcall(function() inst.MeshId=asset end) end
            end
            local fitted=setmetatable({},{__mode="k"})
            local function fitMesh(inst,asset,mult)
                if not inst:IsA("MeshPart") then return end
                if not fitted[inst] then fitted[inst]=inst.Size end
                local ref=fitted[inst]
                task.spawn(function() task.wait(0.1); pcall(function() local mp=meshCache[asset]; if not mp then return end; local nat=mp.Size; local f=math.max(ref.X,ref.Y,ref.Z)/math.max(nat.X,nat.Y,nat.Z); inst.Size=nat*f*(mult or SCALE) end) end)
            end
            local function forceGreen(inst) pcall(function() if inst:IsA("MeshPart") then inst.Color=GREEN elseif inst:IsA("SpecialMesh") then inst.VertexColor=Vector3.new(GREEN.R,GREEN.G,GREEN.B) end end) end
            local function applyTexture(inst)
                local prop=inst:IsA("MeshPart") and "TextureID" or "TextureId"
                if texAsset then pcall(function() inst[prop]=texAsset end) end
                forceGreen(inst)
                for _,c in ipairs(inst:GetChildren()) do if c:IsA("SurfaceAppearance") then c:Destroy() end end
                if not watched[inst] then
                    watched[inst]=true
                    inst.ChildAdded:Connect(function(c) if c:IsA("SurfaceAppearance") then task.defer(function() pcall(function() c:Destroy() end) end) end end)
                    pcall(function() inst:GetPropertyChangedSignal(prop):Connect(function() if texAsset and inst[prop]~=texAsset then pcall(function() inst[prop]=texAsset end) end end) end)
                    pcall(function() local cp=inst:IsA("MeshPart") and "Color" or "VertexColor"; inst:GetPropertyChangedSignal(cp):Connect(function() forceGreen(inst) end) end)
                end
            end
            local PROPS={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Animation={"AnimationId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
            local function handle(inst,p)
                local ok,cur=pcall(function() return inst[p] end); if not ok then return end
                local id=parseId(cur); local new=id and lookup[id]; if new==nil then return end
                if p=="MeshId" then if new=="" then hideMesh(inst) else applyMesh(inst,new); fitMesh(inst,new); applyTexture(inst) end
                else pcall(function() inst[p]=new end) end
            end
            local function apply(inst)
                local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
                for _,p in ipairs(props) do handle(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
            end
            game.DescendantAdded:Connect(apply)
            local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end
        end)
        notify("✅ Keyrambit + Archrambit Knife 已加载","success")
    end)
end

-- ============================================================
--  SKIN 6 – MONSTER CAN  (melee / throwable)
-- ============================================================
local function LoadMonsterCan(notify)
    if Loaded.MonsterCan then notify("Monster Can 已经加载过了","warning"); return end
    Loaded.MonsterCan = true
    notify("正在加载 Monster Can...","success")
    task.spawn(function()
        pcall(function()
            local CDN="AWildcat/monster_cache"
            if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
            if not isfolder(CDN) then pcall(makefolder,CDN) end
            local loader=MakeSharedLoader(CDN)

            local CONFIG_JSON=[[{
"replacement_rules": [
{"type":"group","name":"Body","children":[
  {"name":"Monster Body","replace_ids":[70494501482896],"mode":"cdn","enabled":true,"scale":"body","texture":"white","role":"body","cdn_url":"https://raw.githubusercontent.com/elcalzoskineitorfunk/Monster-Skin/refs/heads/main/MONSTER%20BODYY%20ver3.obj"},
  {"name":"Monster Logo","replace_ids":[70528849669897],"mode":"cdn","enabled":true,"scale":"logo","texture":"black","color":[0,0,0],"role":"logo","cdn_url":"https://raw.githubusercontent.com/elcalzoskineitorfunk/Monster-Skin/refs/heads/main/MONSTER%20LOGO%20ver10.obj"}
]},
{"type":"group","name":"Animation","children":[
  {"name":"Mns Animation [1]","replace_ids":[81951883744250],"mode":"id","enabled":true,"with_id":106136416209642},
  {"name":"Mns Animation [2]","replace_ids":[78544849697314],"mode":"id","enabled":true,"with_id":134840101984538},
  {"name":"Mns Animation [3]","replace_ids":[108185321380462],"mode":"id","enabled":true,"with_id":116339164768827},
  {"name":"Mns Animation [4]","replace_ids":[118241731290742],"mode":"id","enabled":true,"with_id":134433050302557},
  {"name":"Mns Use","replace_ids":[73325703605178,94406584083681],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/elcalzoskineitorfunk/Monster-Skin/refs/heads/main/monster-energy.mp3"}
]},
{"type":"group","name":"Icon","children":[
  {"name":"Monster Icon","replace_ids":[104600246515190],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/Bean-sValorant/main/white_monster_icon.png"}
]}
]}]]
            local SCALES={body=0.6,logo=0.45}

            local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
            local function flatten(list,out) for _,r in ipairs(list) do if r.type=="group" then flatten(r.children or {},out) elseif r.enabled then out[#out+1]=r end end; return out end

            local rules=HttpService:JSONDecode(CONFIG_JSON).replacement_rules
            local active=flatten(rules,{})
            local lookup, meshCache = {}, {}
            local seen        = setmetatable({},{__mode="k"})
            local scaleState  = setmetatable({},{__mode="k"})
            local forcedTexture=setmetatable({},{__mode="k"})
            local origSize    = setmetatable({},{__mode="k"})
            local fitState    = setmetatable({},{__mode="k"})
            local roleOf      = setmetatable({},{__mode="k"})

            local pending=#active; local targets={}
            for i,rule in ipairs(active) do
                task.spawn(function()
                    local t
                    if rule.mode=="cdn" then t=loader.loadCdn(rule.cdn_url)
                    elseif rule.with_id then t="rbxassetid://"..rule.with_id
                    else t="" end
                    targets[i]=t; pending=pending-1
                end)
            end
            while pending>0 do task.wait() end

            local meshAssets={}
            for i,rule in ipairs(active) do
                local tgt=targets[i]; if tgt~=nil then
                    local entry={target=tgt}
                    if rule.scale then entry.scale=SCALES[rule.scale] end
                    if rule.color then entry.color=Color3.fromRGB(rule.color[1],rule.color[2],rule.color[3]) end
                    if rule.role then entry.role=rule.role end
                    if tgt~="" and rule.scale then meshAssets[tgt]=true end
                    for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]=entry end end
                end
            end
            local warming=0; for asset in pairs(meshAssets) do warming=warming+1; task.spawn(function() pcall(function() meshCache[asset]=AssetService:CreateMeshPartAsync(asset) end); warming=warming-1 end) end
            local t0=os.clock(); while warming>0 and os.clock()-t0<15 do task.wait() end

            local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
            local function fitMesh(inst,asset)
                pcall(function()
                    local t=fitState[inst]; if not t then
                        local mp=meshCache[asset]; local o=origSize[inst]
                        if mp and o then local n=mp.Size; local nMax=math.max(n.X,n.Y,n.Z); if nMax>0 then t=n*(math.max(o.X,o.Y,o.Z)/nMax); fitState[inst]=t end end
                    end
                    if t then inst.Size=t end
                end)
            end
            local function applyMesh(inst,asset,entry)
                if not inst:IsA("MeshPart") then pcall(function() inst.MeshId=asset end); return end
                if not origSize[inst] then origSize[inst]=inst.Size end
                local ok,err=pcall(function() local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end; inst:ApplyMesh(mp) end)
                if not ok then pcall(function() inst.MeshId=asset end) end
                if not entry or entry.fit~=false then fitMesh(inst,asset) end
            end
            local function applyScale(inst,factor)
                if not factor or factor==1 then return end
                local st=scaleState[inst]; if st~=nil then if st then task.defer(function() pcall(function() if inst:IsA("MeshPart") then inst.Size=st else inst.Scale=st end end) end) end; return end
                scaleState[inst]=false
                task.spawn(function() task.wait(0.1); local t; pcall(function() if inst:IsA("MeshPart") then t=inst.Size*factor elseif inst:IsA("SpecialMesh") then t=inst.Scale*factor end end); if t then scaleState[inst]=t; pcall(function() if inst:IsA("MeshPart") then inst.Size=t else inst.Scale=t end end) end end)
            end
            local function setTexture(inst,asset)
                local prop=inst:IsA("SpecialMesh") and "TextureId" or "TextureID"
                forcedTexture[inst]=asset; pcall(function() inst[prop]=asset end)
            end

            local PROPS={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}
            local function handle(inst,p)
                local ok,cur=pcall(function() return inst[p] end); if not ok then return end
                local forced=forcedTexture[inst]
                if forced and (p=="TextureID" or p=="TextureId") then if cur~=forced then pcall(function() inst[p]=forced end) end; return end
                local id=parseId(cur); local entry=id and lookup[id]; if entry==nil then return end
                local new=entry.target
                if p=="MeshId" then
                    if new=="" then hideMesh(inst) else
                        applyMesh(inst,new,entry)
                        if entry.color then pcall(function() inst.Color=entry.color end) end
                        applyScale(inst,entry.scale)
                        if entry.role then roleOf[inst]=entry.role end
                    end
                else pcall(function() inst[p]=new end) end
            end
            local function apply(inst)
                local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
                for _,p in ipairs(props) do task.spawn(handle,inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
            end
            game.DescendantAdded:Connect(apply)
            local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end
        end)
        notify("✅ Monster Can 已加载","success")
    end)
end

-- ============================================================
--  SKIN 7 – KEYCHEL SATCHEL
-- ============================================================
local function LoadKeychelSatchel(notify)
    if Loaded.KeychelSatchel then notify("Keychel Satchel 已经加载过了","warning"); return end
    Loaded.KeychelSatchel = true
    notify("正在加载 Keychel Satchel...","success")
    task.spawn(function()
        pcall(function()
            local CDN="AWildcat/keychel"
            if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
            if not isfolder(CDN) then pcall(makefolder,CDN) end
            local loader=MakeSharedLoader(CDN)

            local CONFIG_JSON=[[{
  "replacement_rules": [
    {"name":"satchel","replace_ids":[111319295872696],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/Keychel/main/KEYCHELBODYNEW1.mesh"},
    {"name":"satchel detonator","replace_ids":[123563845986019],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/Keychel/main/KEYCHELBUTTONNEW2.mesh"},
    {"name":"ImageIconOfSatchel","replace_ids":[82237471151891],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/Keychel/main/Untitled49_20260527123520.png"},
    {"name":"ExplodingSound","replace_ids":[13455969017],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RPKEY/main/RPGKYNEW.mp3"},
    {"name":"ThrowStartPinpull","replace_ids":[14510062019],"mode":"id","enabled":true,"with_id":123368854506447},
    {"name":"ThrowIdle","replace_ids":[14510038568],"mode":"id","enabled":true,"with_id":95887720657783},
    {"name":"ThrowFinish","replace_ids":[14510046795],"mode":"id","enabled":true,"with_id":98498351754343},
    {"name":"Sprint","replace_ids":[14580328848],"mode":"id","enabled":true,"with_id":119518299690405},
    {"name":"Inspect","replace_ids":[14509964565],"mode":"id","enabled":true,"with_id":118832975932987},
    {"name":"LobFinish","replace_ids":[14580368724],"mode":"id","enabled":true,"with_id":116760723605331},
    {"name":"Equip","replace_ids":[14509948480],"mode":"id","enabled":true,"with_id":99784649946058},
    {"name":"Idle","replace_ids":[14509967864],"mode":"id","enabled":true,"with_id":138613177890181}
  ]
}]]
            local SCALE=1.0
            local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
            local rules=HttpService:JSONDecode(CONFIG_JSON).replacement_rules
            local lookup, meshCache = {}, {}
            local seen = setmetatable({},{__mode="k"})

            local pending=#rules; local targets={}
            for i,rule in ipairs(rules) do
                task.spawn(function()
                    local t
                    if rule.mode=="cdn" then t=loader.loadCdn(rule.cdn_url)
                    elseif rule.with_id then t="rbxassetid://"..rule.with_id
                    else t="" end
                    targets[i]=t; pending=pending-1
                end)
            end
            while pending>0 do task.wait() end

            local meshTargets={}
            for i,rule in ipairs(rules) do
                local tgt=targets[i]; if tgt~=nil then
                    if rule.mode=="cdn" and tgt and tostring(rule.cdn_url):lower():find("%.mesh$") then meshTargets[tgt]=true end
                    for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]={target=tgt} end end
                end
            end
            local warming=0; for asset in pairs(meshTargets) do warming=warming+1; task.spawn(function() pcall(function() meshCache[asset]=AssetService:CreateMeshPartAsync(asset) end); warming=warming-1 end) end
            local t0=os.clock(); while warming>0 and os.clock()-t0<15 do task.wait() end

            local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
            local function applyMesh(inst,asset)
                if inst:IsA("MeshPart") then local ok,err=pcall(function() local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end; inst:ApplyMesh(mp) end); if not ok then pcall(function() inst.MeshId=asset end) end
                else pcall(function() inst.MeshId=asset end) end
            end
            local PROPS={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
            local function handle(inst,p)
                local ok,cur=pcall(function() return inst[p] end); if not ok then return end
                local id=parseId(cur); local entry=id and lookup[id]; if entry==nil then return end
                local new=entry.target
                if p=="MeshId" then if new=="" then hideMesh(inst) else applyMesh(inst,new) end
                else pcall(function() inst[p]=new end) end
            end
            local function apply(inst)
                local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
                for _,p in ipairs(props) do handle(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
            end
            game.DescendantAdded:Connect(apply)
            local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end
        end)
        notify("✅ Keychel Satchel 已加载","success")
    end)
end

-- ============================================================
--  ECLIPSE UI  (unchanged core)
-- ============================================================
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

local Library = { Flags={}, Connections={}, Unloaded=false }

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i,v in pairs(props or {}) do inst[i]=v end
    for _,child in pairs(children or {}) do child.Parent=inst end
    return inst
end
local function Tween(obj, props, time, style, dir)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end
local function GetTextSize(text, size, font)
    return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000,10000))
end

local ScreenGui = Create("ScreenGui", { Name="EclipseUI", Parent=game:GetService("CoreGui"), ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false, IgnoreGuiInset=true })
local UIScale   = Create("UIScale", { Parent=ScreenGui })

local function UpdateScale()
    local vp = workspace.CurrentCamera.ViewportSize
    UIScale.Scale = math.max(math.min((vp.X-40)/CFG.BaseSize.X, (vp.Y-40)/CFG.BaseSize.Y, 1), 0.6)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
UpdateScale()

local NotifContainer = Create("Frame", { Parent=ScreenGui, Position=UDim2.new(1,-20,0,20), AnchorPoint=Vector2.new(1,0), Size=UDim2.new(0,300,1,0), BackgroundTransparency=1, ZIndex=100 })
Create("UIListLayout", { Parent=NotifContainer, Padding=UDim.new(0,5), HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Top })

function Library:Notify(msg, ntype)
    local color = (ntype=="success" and Color3.fromRGB(100,255,100)) or (ntype=="warning" and Color3.fromRGB(255,200,80)) or CFG.AccentColor
    local Frame = Create("Frame", { Parent=NotifContainer, Size=UDim2.new(0,0,0,30), BackgroundColor3=CFG.MainColor, BorderSizePixel=0, ClipsDescendants=true }, {
        Create("UIStroke",{Color=CFG.AccentColor,Thickness=1,Transparency=0.5}),
        Create("Frame",{Size=UDim2.new(0,2,1,0),BackgroundColor3=color}),
        Create("TextLabel",{Text=msg,TextColor3=CFG.TextColor,Font=CFG.Font,TextSize=12,Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left})
    })
    Tween(Frame,{Size=UDim2.new(0,280,0,35)},0.5,Enum.EasingStyle.Back)
    task.delay(3,function() Tween(Frame,{Size=UDim2.new(0,280,0,0),BackgroundTransparency=1},0.5); task.wait(0.5); Frame:Destroy() end)
end

local TooltipLabel = Create("TextLabel", { Parent=ScreenGui, Size=UDim2.new(0,0,0,20), BackgroundColor3=CFG.SecondaryColor, TextColor3=CFG.TextColor, TextSize=11, Font=CFG.Font, BorderSizePixel=0, Visible=false, ZIndex=200 }, {
    Create("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)}),
    Create("UIStroke",{Color=CFG.StrokeColor})
})
local function AddTooltip(obj,text)
    obj.MouseEnter:Connect(function() TooltipLabel.Text=text; TooltipLabel.Size=UDim2.fromOffset(GetTextSize(text,11,CFG.Font).X+12,20); TooltipLabel.Visible=true end)
    obj.MouseLeave:Connect(function() TooltipLabel.Visible=false end)
end
RunService.RenderStepped:Connect(function() if TooltipLabel.Visible then local m=UserInputService:GetMouseLocation(); TooltipLabel.Position=UDim2.fromOffset(m.X+15,m.Y+15) end end)

local MainFrame = Create("Frame", { Name="MainFrame", Parent=ScreenGui, Size=UDim2.fromOffset(CFG.BaseSize.X,CFG.BaseSize.Y), Position=UDim2.new(0.5,-300,0.5,-225), BackgroundColor3=CFG.MainColor, BorderSizePixel=0 }, {
    Create("UIStroke",{Color=CFG.StrokeColor}),
    Create("UICorner",{CornerRadius=UDim.new(0,3)})
})

-- drag
local Dragging,DragInput,DragStart,StartPos=false,nil,nil,nil
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        Dragging=true; DragStart=input.Position; StartPos=MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then Dragging=false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then DragInput=input end end)
UserInputService.InputChanged:Connect(function(input)
    if input==DragInput and Dragging then local delta=input.Position-DragStart; Tween(MainFrame,{Position=UDim2.new(StartPos.X.Scale,StartPos.X.Offset+delta.X,StartPos.Y.Scale,StartPos.Y.Offset+delta.Y)},0.05) end
end)

local TopBar = Create("Frame", { Parent=MainFrame, Size=UDim2.new(1,0,0,30), BackgroundColor3=CFG.MainColor, BorderSizePixel=0 }, {
    Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,0),BackgroundColor3=CFG.StrokeColor})
})
local TitleLabel = Create("TextLabel", { Parent=TopBar, Text="eclipse.wtf | skins", TextColor3=CFG.TextDark, TextSize=13, Font=CFG.Font, BackgroundTransparency=1, Size=UDim2.new(0,250,1,0), Position=UDim2.new(0,10,0,0), TextXAlignment=Enum.TextXAlignment.Left, RichText=true })

task.spawn(function()
    local list={"eclipse.wtf | skins","eclipse.wtf | <font color=\"#bdacff\">skins</font>","eclipse.wtf | skins"}
    local i=1; while not Library.Unloaded do TitleLabel.Text=list[i]; i=i%#list+1; task.wait(1.5) end
end)

local ContentContainer = Create("Frame", { Parent=MainFrame, Size=UDim2.new(1,0,1,-30), Position=UDim2.new(0,0,0,30), BackgroundTransparency=1 })

local Sidebar = Create("Frame", { Parent=ContentContainer, Size=UDim2.new(0,60,1,0), BackgroundColor3=Color3.fromRGB(17,17,17), BorderSizePixel=0 }, {
    Create("UIListLayout",{Padding=UDim.new(0,10),HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Top}),
    Create("UIPadding",{PaddingTop=UDim.new(0,15)})
})

local PagesContainer = Create("Frame", { Parent=ContentContainer, Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,60,0,0), BackgroundTransparency=1 })

local Tabs = {}

function Library:Tab(name, icon)
    local TabButton = Create("TextButton", { Parent=Sidebar, Size=UDim2.new(0,40,0,40), BackgroundColor3=CFG.MainColor, Text="", AutoButtonColor=false }, {
        Create("ImageLabel",{Name="Icon",Size=UDim2.new(0.6,0,0.6,0),Position=UDim2.new(0.2,0,0.2,0),BackgroundTransparency=1,Image="rbxassetid://"..icon,ImageColor3=CFG.TextDark}),
        Create("UICorner",{CornerRadius=UDim.new(0,6)})
    })

    local PageFrame = Create("ScrollingFrame", { Parent=PagesContainer, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, ScrollBarThickness=2, ScrollBarImageColor3=CFG.AccentColor, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y })
    local Padding   = Create("UIPadding",{Parent=PageFrame,PaddingTop=UDim.new(0,15),PaddingLeft=UDim.new(0,15),PaddingRight=UDim.new(0,15),PaddingBottom=UDim.new(0,15)})
    local LeftCol   = Create("Frame",{Parent=PageFrame,Size=UDim2.new(0.48,0,1,0),BackgroundTransparency=1},{Create("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})})
    local RightCol  = Create("Frame",{Parent=PageFrame,Size=UDim2.new(0.48,0,1,0),Position=UDim2.new(0.52,0,0,0),BackgroundTransparency=1},{Create("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})})

    TabButton.MouseButton1Click:Connect(function()
        for _,t in pairs(Tabs) do Tween(t.Btn,{TextColor3=CFG.TextDark,BackgroundColor3=CFG.MainColor},0.2); t.Page.Visible=false end
        Tween(TabButton,{TextColor3=CFG.AccentColor,BackgroundColor3=CFG.SecondaryColor},0.2); PageFrame.Visible=true
    end)
    table.insert(Tabs,{Btn=TabButton,Page=PageFrame})
    if #Tabs==1 then Tween(TabButton,{TextColor3=CFG.AccentColor,BackgroundColor3=CFG.SecondaryColor},0.2); PageFrame.Visible=true end

    local GroupFunctions={}
    local LeftSide=true

    function GroupFunctions:Group(title)
        local ParentCol = LeftSide and LeftCol or RightCol; LeftSide=not LeftSide
        local GroupFrame = Create("Frame",{Parent=ParentCol,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(17,17,17),BorderSizePixel=0},{Create("UIStroke",{Color=CFG.StrokeColor}),Create("UICorner",{CornerRadius=UDim.new(0,2)})})
        Create("Frame",{Parent=GroupFrame,Size=UDim2.new(1,0,0,25),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0},{
            Create("UICorner",{CornerRadius=UDim.new(0,2)}),
            Create("Frame",{Size=UDim2.new(1,0,0,5),Position=UDim2.new(0,0,1,-5),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0}),
            Create("TextLabel",{Text=title,Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=CFG.TextColor,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left}),
            Create("Frame",{Size=UDim2.new(0,4,0,4),Position=UDim2.new(1,-10,0.5,-2),BackgroundColor3=CFG.AccentColor,BorderSizePixel=0},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
        })
        local Content = Create("Frame",{Parent=GroupFrame,Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,25),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},{
            Create("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder}),
            Create("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})
        })

        local ItemFuncs={}

        function ItemFuncs:Toggle(cfg)
            local Enabled=false
            local Frame=Create("TextButton",{Parent=Content,Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=""})
            local Box=Create("Frame",{Parent=Frame,Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,0,0.5,-6),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0},{Create("UIStroke",{Color=CFG.StrokeColor})})
            local Check=Create("Frame",{Parent=Box,Size=UDim2.new(1,-4,1,-4),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=CFG.AccentColor,BackgroundTransparency=1})
            local Label=Create("TextLabel",{Parent=Frame,Text=cfg.Name,TextColor3=CFG.TextDark,TextSize=11,Font=CFG.Font,BackgroundTransparency=1,Position=UDim2.new(0,18,0,0),Size=UDim2.new(1,-18,1,0),TextXAlignment=Enum.TextXAlignment.Left})
            if cfg.Tooltip then AddTooltip(Frame,cfg.Tooltip) end
            local function Update()
                Enabled=not Enabled
                Tween(Check,{BackgroundTransparency=Enabled and 0 or 1},0.1)
                Tween(Label,{TextColor3=Enabled and CFG.TextColor or CFG.TextDark},0.1)
                if cfg.Callback then cfg.Callback(Enabled) end
            end
            Frame.MouseButton1Click:Connect(Update)
            return {Set=function(v) if v~=Enabled then Update() end end}
        end

        function ItemFuncs:Button(cfg)
            local Btn=Create("TextButton",{Parent=Content,Size=UDim2.new(1,0,0,22),BackgroundColor3=CFG.SecondaryColor,Text=cfg.Name,TextColor3=CFG.TextDark,Font=Enum.Font.GothamBold,TextSize=10},{Create("UIStroke",{Color=CFG.StrokeColor}),Create("UICorner",{CornerRadius=UDim.new(0,3)})})
            if cfg.Variant=="Primary" then Btn.BackgroundColor3=CFG.AccentColor; Btn.TextColor3=Color3.new(0,0,0) end
            Btn.MouseButton1Click:Connect(function() if cfg.Callback then cfg.Callback() end end)
            if cfg.Tooltip then AddTooltip(Btn,cfg.Tooltip) end
        end

        function ItemFuncs:Slider(cfg)
            local Value=cfg.Default or cfg.Min; local DraggingSlider=false
            local Frame=Create("Frame",{Parent=Content,Size=UDim2.new(1,0,0,32),BackgroundTransparency=1})
            Create("TextLabel",{Parent=Frame,Text=cfg.Name,TextColor3=CFG.TextDark,TextSize=11,Font=CFG.Font,BackgroundTransparency=1,Size=UDim2.new(1,0,0,15),TextXAlignment=Enum.TextXAlignment.Left})
            local ValLabel=Create("TextLabel",{Parent=Frame,Text=Value..(cfg.Unit or ""),TextColor3=CFG.TextDark,TextSize=11,Font=CFG.Font,BackgroundTransparency=1,Size=UDim2.new(1,0,0,15),TextXAlignment=Enum.TextXAlignment.Right})
            local SliderBG=Create("Frame",{Parent=Frame,Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,0,20),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0},{Create("UIStroke",{Color=CFG.StrokeColor}),Create("UICorner",{CornerRadius=UDim.new(1,0)})})
            local Fill=Create("Frame",{Parent=SliderBG,Size=UDim2.new(0,0,1,0),BackgroundColor3=CFG.AccentColor},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
            local function Update(input)
                local SX=SliderBG.AbsoluteSize.X; local PX=SliderBG.AbsolutePosition.X
                local Pct=math.clamp((input.Position.X-PX)/SX,0,1)
                Value=math.floor(cfg.Min+(cfg.Max-cfg.Min)*Pct)
                Fill.Size=UDim2.new(Pct,0,1,0); ValLabel.Text=Value..(cfg.Unit or "")
                if cfg.Callback then cfg.Callback(Value) end
            end
            Frame.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then DraggingSlider=true; Update(input) end end)
            UserInputService.InputChanged:Connect(function(input) if DraggingSlider and input.UserInputType==Enum.UserInputType.MouseMovement then Update(input) end end)
            UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then DraggingSlider=false end end)
            Fill.Size=UDim2.new((Value-cfg.Min)/(cfg.Max-cfg.Min),0,1,0)
            if cfg.Tooltip then AddTooltip(Frame,cfg.Tooltip) end
        end

        function ItemFuncs:Dropdown(cfg)
            local Expanded=false; local Current=cfg.Default or cfg.Options[1]
            local Frame=Create("Frame",{Parent=Content,Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,ZIndex=20})
            Create("TextLabel",{Parent=Frame,Text=cfg.Name,TextColor3=CFG.TextDark,TextSize=11,Font=CFG.Font,BackgroundTransparency=1,Size=UDim2.new(1,0,0,15),TextXAlignment=Enum.TextXAlignment.Left})
            local MainBox=Create("TextButton",{Parent=Frame,Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,16),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0,Text="",AutoButtonColor=false},{
                Create("UIStroke",{Color=CFG.StrokeColor}),Create("UICorner",{CornerRadius=UDim.new(0,3)}),
                Create("TextLabel",{Name="Val",Text=Current,Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,5,0,0),BackgroundTransparency=1,TextColor3=CFG.TextColor,TextSize=11,Font=CFG.Font,TextXAlignment=Enum.TextXAlignment.Left}),
                Create("TextLabel",{Text="▼",Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-20,0,0),BackgroundTransparency=1,TextColor3=CFG.TextDark,TextSize=10})
            })
            local ListFrame=Create("ScrollingFrame",{Parent=MainBox,Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,1,2),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0,Visible=false,ZIndex=50,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2},{Create("UIStroke",{Color=CFG.StrokeColor}),Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder}),Create("UICorner",{CornerRadius=UDim.new(0,3)})})
            for _,opt in pairs(cfg.Options) do
                local Btn=Create("TextButton",{Parent=ListFrame,Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=opt,TextColor3=(opt==Current) and CFG.AccentColor or CFG.TextDark,TextSize=11,Font=CFG.Font})
                Btn.MouseButton1Click:Connect(function() Current=opt; MainBox.Val.Text=opt; if cfg.Callback then cfg.Callback(opt) end; Expanded=false; Tween(ListFrame,{Size=UDim2.new(1,0,0,0)},0.1); task.wait(0.1); ListFrame.Visible=false end)
            end
            MainBox.MouseButton1Click:Connect(function()
                Expanded=not Expanded
                if Expanded then ListFrame.Visible=true; Tween(ListFrame,{Size=UDim2.new(1,0,0,math.min(#cfg.Options*20,100))},0.1)
                else Tween(ListFrame,{Size=UDim2.new(1,0,0,0)},0.1); task.wait(0.1); ListFrame.Visible=false end
            end)
            if cfg.Tooltip then AddTooltip(Frame,cfg.Tooltip) end
        end

        return ItemFuncs
    end
    return GroupFunctions
end

-- ============================================================
--  BUILD TABS
-- ============================================================

-- ── SKINS TAB ──────────────────────────────────────────────
local SkinsTab = Library:Tab("Skins", 98159911363596)

local ARGroup = SkinsTab:Group("突击步枪 (AR)")
ARGroup:Toggle({
    Name    = "Keyaug AR 皮肤",
    Tooltip = "加载 Keyaug 突击步枪皮肤 (视觉+解锁)",
    Callback = function(v)
        if v then LoadKeyaugAR(function(msg,t) Library:Notify(msg,t) end) end
    end
})
ARGroup:Toggle({
    Name    = "Draconic Wildcat AR 皮肤",
    Tooltip = "加载 Draconic Wildcat 龙皮突击步枪",
    Callback = function(v)
        if v then LoadDraconicAR(function(msg,t) Library:Notify(msg,t) end) end
    end
})

local VandalGroup = SkinsTab:Group("Vandal")
VandalGroup:Toggle({
    Name    = "Reaver Vandal 皮肤",
    Tooltip = "加载 Reaver 幽灵 Vandal 皮肤",
    Callback = function(v)
        if v then LoadReaverVandal(function(msg,t) Library:Notify(msg,t) end) end
    end
})

local SniperGroup = SkinsTab:Group("狙击枪 (Sniper)")
SniperGroup:Toggle({
    Name    = "ArchKeyper 狙击皮肤",
    Tooltip = "加载 ArchKeyper 狙击枪皮肤",
    Callback = function(v)
        if v then LoadArchKeyper(function(msg,t) Library:Notify(msg,t) end) end
    end
})

local KnifeGroup = SkinsTab:Group("刀具 (Knife)")
KnifeGroup:Toggle({
    Name    = "Keyrambit + Archrambit 刀皮",
    Tooltip = "加载 Keyrambit 解锁 + Archrambit 视觉替换 (绿色)",
    Callback = function(v)
        if v then LoadKeyrambitKnife(function(msg,t) Library:Notify(msg,t) end) end
    end
})

local MeleeGroup = SkinsTab:Group("近战 / 投掷物")
MeleeGroup:Toggle({
    Name    = "Monster Can 皮肤",
    Tooltip = "将近战物品替换为 Monster 能量饮料罐",
    Callback = function(v)
        if v then LoadMonsterCan(function(msg,t) Library:Notify(msg,t) end) end
    end
})
MeleeGroup:Toggle({
    Name    = "Keychel Satchel 皮肤",
    Tooltip = "加载 Keychel 炸弹包皮肤",
    Callback = function(v)
        if v then LoadKeychelSatchel(function(msg,t) Library:Notify(msg,t) end) end
    end
})

-- ── SETTINGS TAB ───────────────────────────────────────────
local SettingsTab = Library:Tab("Settings", 11888734334)

local MenuGroup = SettingsTab:Group("菜单设置")
MenuGroup:Toggle({
    Name    = "显示 / 隐藏菜单 (Insert)",
    Tooltip = "切换菜单可见性",
    Callback = function(v)
        MainFrame.Visible = v
    end
})
MenuGroup:Button({
    Name    = "关闭 UI",
    Variant = "Danger",
    Tooltip = "销毁整个 UI",
    Callback = function()
        Library.Unloaded = true
        ScreenGui:Destroy()
    end
})

-- ============================================================
--  MENU TOGGLE  (Insert key)
-- ============================================================
Library.MenuKey = Enum.KeyCode.Insert
local Visible = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Library.MenuKey then
        Visible = not Visible
        MainFrame.Visible = Visible
    end
end)

-- mobile button
local MobileToggle = Create("ImageButton", { Parent=ScreenGui, Size=UDim2.new(0,40,0,40), Position=UDim2.new(0.5,0,0,10), AnchorPoint=Vector2.new(0.5,0), BackgroundColor3=CFG.MainColor, Image="rbxassetid://3926305904", ImageColor3=CFG.AccentColor, AutoButtonColor=false }, {
    Create("UICorner",{CornerRadius=UDim.new(1,0)}),
    Create("UIStroke",{Color=CFG.AccentColor,Thickness=2})
})
MobileToggle.MouseButton1Click:Connect(function() Visible=not Visible; MainFrame.Visible=Visible end)

-- startup notify
Library:Notify("🎨 Skin UI 已加载！按 Insert 切换菜单", "success")
Library:Notify("⚠️ 皮肤加载后无法关闭，需重进游戏", "warning")
