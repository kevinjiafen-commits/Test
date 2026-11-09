-- ================================================================
--  SkinUI.lua  |  Rivals Skin Changer + Eclipse UI
--  Fix: every skin uses its ORIGINAL engine verbatim.
--  No shared loader - same code that worked standalone.
-- ================================================================

local Players         = game:GetService("Players")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local HttpService     = game:GetService("HttpService")
local AssetService    = game:GetService("AssetService")
local RS              = game:GetService("ReplicatedStorage")

-- one-shot load guards
local Loaded = {
    KeyaugAR       = false,
    DraconicAR     = false,
    ReaverVandal   = false,
    ArchKeyper     = false,
    KeyrambitKnife = false,
    MonsterCan     = false,
    KeychelSatchel = false,
}

-- ================================================================
--  SKIN 1 : KEYAUG AR
--  Source: doc 1 (AR-Aug unlocker + Keyaug replacer)
-- ================================================================
local function LoadKeyaugAR(notify)
    if Loaded.KeyaugAR then notify("Keyaug AR 已加载过了","warning") return end
    Loaded.KeyaugAR = true
    notify("正在加载 Keyaug AR…","success")
    task.spawn(function()

    -- ── Part A: coslib skin unlocker (original doc 1 top block) ──
    local frontOk, frontErr = pcall(function()
        local KEYWORD = "aug"
        local PICK    = nil
        local lp      = Players.LocalPlayer
        local ctrl    = lp.PlayerScripts:WaitForChild("Controllers", 10)
        local mods    = RS:WaitForChild("Modules", 10)
        local enumLib = require(mods:WaitForChild("EnumLibrary", 10))
        if enumLib then pcall(function() enumLib:WaitForEnumBuilder() end) end
        local cosLib  = require(mods:WaitForChild("CosmeticLibrary", 10))
        local datCtrl = require(ctrl:WaitForChild("PlayerDataController", 10))
        local Cosmetics = cosLib.Cosmetics
        local arCache, augCache = {}, {}
        local function isAR(w)
            if type(w)=="table" then w=w.Name end
            if type(w)~="string" then return false end
            local r=arCache[w]; if r==nil then r=(w:lower():gsub("%s+",""))=="assaultrifle"; arCache[w]=r end; return r
        end
        local function isAugSkin(n)
            if type(n)~="string" then return false end
            local r=augCache[n]; if r==nil then local c=Cosmetics[n]; r=(n:lower():find(KEYWORD,1,true)~=nil) and c~=nil and c.Type=="Skin"; augCache[n]=r end; return r
        end
        local function mkSkin(name)
            local base=Cosmetics[name]; if not base then return nil end
            local d={}; for k,v in pairs(base) do d[k]=v end
            d.Name=name; d.Type=d.Type or "Skin"; d.Seed=d.Seed or math.random(1,1000000)
            if enumLib then local ok,id=pcall(enumLib.ToEnum,enumLib,name); if ok and id then d.Enum=id; d.ObjectID=d.ObjectID or id end end
            return d
        end
        local matches={}
        for name,c in pairs(Cosmetics) do
            if type(name)=="string" and c.Type=="Skin" and name:lower():find(KEYWORD,1,true) then table.insert(matches,name) end
        end
        table.sort(matches)
        if #matches==0 then warn("[AR-Aug] no aug skins found"); return end
        local chosen=matches[1]; if PICK and isAugSkin(PICK) then chosen=PICK end
        local arSkin=mkSkin(chosen)
        print(("[AR-Aug] equipping '%s'"):format(chosen))
        for _,key in ipairs({"OwnsCosmetic","OwnsCosmeticNormally","OwnsCosmeticUniversally","OwnsCosmeticForWeapon"}) do
            local orig=cosLib[key]
            if type(orig)=="function" then
                cosLib[key]=function(self,inv,nm,wep,...) if isAR(wep) and isAugSkin(nm) then return true end; return orig(self,inv,nm,wep,...) end
            end
        end
        local origGet=datCtrl.Get; local invSrc,invProxy
        local invMeta={__index=function(_,k) if isAugSkin(k) then return true end end}
        datCtrl.Get=function(self,key,...)
            local val=origGet(self,key,...)
            if key=="CosmeticInventory" then
                if invProxy and invSrc==val then return invProxy end
                local prx={}; if val then for k,v in pairs(val) do prx[k]=v end end
                invSrc,invProxy=val,setmetatable(prx,invMeta); return invProxy
            end; return val
        end
        local origGetWep=datCtrl.GetWeaponData; local wepCache={}
        datCtrl.GetWeaponData=function(self,wn,...)
            local d=origGetWep(self,wn,...); if not d then return nil end
            if arSkin and isAR(wn) then
                local c=wepCache[wn]; if c and c.src==d and c.skin==arSkin then return c.out end
                local m={}; for k,v in pairs(d) do m[k]=v end; m.Name=wn; m.Skin=arSkin
                wepCache[wn]={src=d,skin=arSkin,out=m}; return m
            end; return d
        end
        if hookmetamethod and getnamecallmethod then
            local remotes=RS:FindFirstChild("Remotes"); local dataRem=remotes and remotes:FindFirstChild("Data")
            local equipRem=dataRem and dataRem:FindFirstChild("EquipCosmetic")
            if equipRem then
                local old; old=hookmetamethod(game,"__namecall",function(self,...)
                    if self==equipRem and getnamecallmethod()=="FireServer" then
                        local wn,ct,cn=...
                        if isAR(wn) and ct=="Skin" and isAugSkin(cn) then
                            arSkin=mkSkin(cn)
                            task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end); return
                        end
                    end; return old(self,...)
                end)
            end
        end
        task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end)
        print("[AR-Aug] loaded")
    end)
    if not frontOk then warn("[AR-Aug] front block: "..tostring(frontErr)) end

    -- ── Part B: Keyaug visual replacer (original doc 1 bottom block) ──
    local CDN_FOLDER    = "AWildcat/keyaug"
    local MESH_METHOD   = "both"
    local CONVERT_OBJ   = true
    local REFRESH       = false
    local WATCH_ALL     = false
    local NIL_SCAN_INTERVAL = 10
    local SCALES        = { aug=1.2, mag=0.7 }
    local ICONS_USE_TEXTURES = false
    local TEXTURE_VERSION    = "v2"
    local KEY_BASE={255,196,40}; local KEY_DARK={150,100,10}; local KEY_EDGE={255,240,170}

    local missing={}
    for _,p in ipairs({{"isfile",isfile},{"writefile",writefile},{"getcustomasset",getcustomasset},{"makefolder",makefolder},{"isfolder",isfolder}}) do
        if type(p[2])~="function" then missing[#missing+1]=p[1] end
    end
    if #missing>0 then warn("[Keyaug] missing: "..table.concat(missing,", ")); goto keyaug_done end

    if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
    if not isfolder(CDN_FOLDER) then pcall(makefolder,CDN_FOLDER) end
    if REFRESH and listfiles and delfile then for _,f in ipairs(listfiles(CDN_FOLDER)) do pcall(delfile,f) end end

    local function hashStr(s) local h=5381; for i=1,#s do h=(h*33+s:byte(i))%4294967296 end; return string.format("%08x",h) end
    local function download(url)
        local ok,res=pcall(function() return game:HttpGet(url) end)
        if ok and type(res)=="string" and #res>0 then return res end
        local req=request or http_request or (syn and syn.request)
        if req then local ok2,r=pcall(req,{Url=url,Method="GET"}); if ok2 and r and r.StatusCode==200 and type(r.Body)=="string" and #r.Body>0 then return r.Body end end
        return nil
    end
    local function objToMesh(text)
        local v,vt,vn,out={},{},{},{}; local tris,faces=0,0
        local function idx(s,n) if s==nil or s=="" then return nil end; local i=tonumber(s); if not i then return nil end; if i<0 then return n+i+1 end; return i end
        local function corner(a,b,c)
            local p=v[idx(a,#v) or 0]; if not p then return nil end
            local nn=vn[idx(c,#vn) or 0] or {0,1,0}; local t=vt[idx(b,#vt) or 0] or {0,0}
            return string.format("[%.5f,%.5f,%.5f][%.4f,%.4f,%.4f][%.5f,%.5f,0]",p[1],p[2],p[3],nn[1],nn[2],nn[3],t[1],1-t[2])
        end
        for line in text:gmatch("[^\r\n]+") do
            local c=line:sub(1,2)
            if c=="v " then local x,y,z=line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)"); v[#v+1]={tonumber(x) or 0,tonumber(y) or 0,tonumber(z) or 0}
            elseif c=="vt" then local u,w=line:match("^vt%s+(%S+)%s+(%S+)"); vt[#vt+1]={tonumber(u) or 0,tonumber(w) or 0}
            elseif c=="vn" then local x,y,z=line:match("^vn%s+(%S+)%s+(%S+)%s+(%S+)"); vn[#vn+1]={tonumber(x) or 0,tonumber(y) or 1,tonumber(z) or 0}
            elseif c=="f " then
                local corners={}
                for tok in line:gmatch("%S+") do if tok~="f" then local a,b,cc=tok:match("^(%-?%d+)/?(%-?%d*)/?(%-?%d*)"); local s2=a and corner(a,b,cc); if s2 then corners[#corners+1]=s2 end end end
                for i=2,#corners-1 do out[#out+1]=corners[1]; out[#out+1]=corners[i]; out[#out+1]=corners[i+1]; tris=tris+1 end
                faces=faces+1; if faces%4000==0 then task.wait() end
            end
        end
        if tris==0 then return nil,0 end; return "version 1.00\n"..tris.."\n"..table.concat(out),tris
    end
    local stats={cached=0,downloaded=0,failed=0}; local failedList={}; local cdnAssets={}
    local function loadAsset(path)
        for _=1,5 do if isfile(path) then local ok,asset=pcall(getcustomasset,path); if ok and asset then return asset end end; task.wait(0.3) end; return nil
    end
    local loading={}; local loadCdnInner
    local function loadCdn(url)
        if cdnAssets[url] then return cdnAssets[url] end
        if loading[url] then while loading[url] do task.wait() end; return cdnAssets[url] end
        loading[url]=true; local ok,res=pcall(loadCdnInner,url); loading[url]=nil; if ok then return res end; return nil
    end
    loadCdnInner=function(url)
        local name=url:match("[^/]+$") or url; local ext=(url:match("%.(%w+)$") or "bin"):lower()
        local conv=(ext=="obj" and CONVERT_OBJ); local path=CDN_FOLDER.."/"..hashStr(url)..".".. (conv and "mesh" or ext)
        if isfile(path) then stats.cached=stats.cached+1
        else
            print("[Keyaug] downloading "..name); local data=download(url)
            if not data then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (download failed)"; return nil end
            if #data<200 and data:find("404") then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (404)"; return nil end
            if conv then local mesh,tris=objToMesh(data); if not mesh then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (no faces)"; return nil end; print(("[Keyaug] %s -> %d tris"):format(name,tris)); data=mesh end
            if not pcall(writefile,path,data) then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (save failed)"; return nil end
            stats.downloaded=stats.downloaded+1
        end
        local asset=loadAsset(path); if not asset then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (getcustomasset failed)"; return nil end
        cdnAssets[url]=asset; return asset
    end

    -- PNG builder
    local crcTable={}; for i=0,255 do local c=i; for _=1,8 do if bit32.band(c,1)==1 then c=bit32.bxor(bit32.rshift(c,1),0xEDB88320) else c=bit32.rshift(c,1) end end; crcTable[i]=c end
    local function crc32(s) local c=0xFFFFFFFF; for i=1,#s do c=bit32.bxor(crcTable[bit32.band(bit32.bxor(c,s:byte(i)),0xFF)],bit32.rshift(c,8)) end; return bit32.bxor(c,0xFFFFFFFF) end
    local function adler32(s) local a,b=1,0; for i=1,#s do a=(a+s:byte(i))%65521; b=(b+a)%65521 end; return b*65536+a end
    local function pngChunk(k,d) return string.pack(">I4",#d)..k..d..string.pack(">I4",crc32(k..d)) end
    local function makePng(w,h,pixel)
        local rows={}
        for y=0,h-1 do local row={"\0"}; for x=0,w-1 do local r,g,b=pixel(x,y); row[#row+1]=string.char(r,g,b) end; rows[#rows+1]=table.concat(row) end
        local raw=table.concat(rows); local blocks={"\120\1"}; local pos=1
        while pos<=#raw do local piece=raw:sub(pos,pos+65534); pos=pos+#piece; local final=(pos>#raw) and 1 or 0
            blocks[#blocks+1]=string.char(final)..string.pack("<I2",#piece)..string.pack("<I2",bit32.band(bit32.bnot(#piece),0xFFFF))..piece end
        blocks[#blocks+1]=string.pack(">I4",adler32(raw))
        return "\137PNG\r\n\26\n"..pngChunk("IHDR",string.pack(">I4I4",w,h).."\8\2\0\0\0")..pngChunk("IDAT",table.concat(blocks))..pngChunk("IEND","")
    end
    local TEXTURES_GEN={
        ar=function(x,y) local c; if x<8 or y<8 or x>=248 or y>=248 then c={205,20,30} elseif ((x+y)//32)%2==0 then c={205,20,30} else c={245,245,245} end; return c[1],c[2],c[3] end,
        sniper=function(x,y) local c={0,0,0}; if (x-y)%64<14 then c={245,245,245} end; return c[1],c[2],c[3] end,
        dagger=function() return 0,0,0 end,
        key=function(x,y) local c=KEY_BASE; if x<6 or y<6 or x>=250 or y>=250 then c=KEY_EDGE elseif ((x+y)//24)%2==0 then c=KEY_DARK end; return c[1],c[2],c[3] end,
    }
    local textureAssets={}
    local function texAsset(key)
        if textureAssets[key] then return textureAssets[key] end
        local gen=TEXTURES_GEN[key]; if not gen then warn("[Keyaug] unknown texture: "..tostring(key)); return nil end
        local path=CDN_FOLDER.."/tex_"..key.."_"..TEXTURE_VERSION..".png"
        if not isfile(path) then local ok,png=pcall(makePng,256,256,gen); if not ok or not pcall(writefile,path,png) then stats.failed=stats.failed+1; failedList[#failedList+1]="texture "..key.." (build failed)"; return nil end; print("[Keyaug] built texture: "..key) end
        local asset=loadAsset(path); if not asset then stats.failed=stats.failed+1; failedList[#failedList+1]="texture "..key.." (getcustomasset failed)"; return nil end
        textureAssets[key]=asset; return asset
    end

    local CONFIG_K=[==[
{"replacement_rules":[
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
]}]==]
    local rules_k=HttpService:JSONDecode(CONFIG_K).replacement_rules
    local lookup_k,meshCache_k={},{}
    local registered_k,swapped_k=0,0

    local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
    local function resolve_k(rule)
        if rule.mode=="texture" then return texAsset(rule.texture) end
        if rule.mode=="cdn" then return loadCdn(rule.cdn_url) end
        if rule.with_id then return "rbxassetid://"..rule.with_id end
        return ""
    end

    local active_k={}
    for _,r in ipairs(rules_k) do if r.type=="group" then for _,c in ipairs(r.children or {}) do if c.enabled then active_k[#active_k+1]=c end end elseif r.enabled then active_k[#active_k+1]=r end end

    local targets_k={}; local pendingK=#active_k
    for i,rule in ipairs(active_k) do
        task.spawn(function()
            local ok,res=pcall(resolve_k,rule); if ok then targets_k[i]=res end; pendingK=pendingK-1
        end)
    end
    while pendingK>0 do task.wait() end

    local meshAssets_k={}
    for i,rule in ipairs(active_k) do
        local tgt=targets_k[i]; if tgt~=nil then
            registered_k=registered_k+1
            local entry={target=tgt}
            if rule.scale then entry.scale=SCALES[rule.scale] end
            if rule.texture and rule.mode~="texture" then entry.texture=texAsset(rule.texture) end
            if tgt~="" and rule.mode~="texture" and (rule.texture or rule.scale) then meshAssets_k[tgt]=true end
            for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup_k[n]=entry end end
        end
    end
    if MESH_METHOD~="direct" then
        local warming=0
        for asset in pairs(meshAssets_k) do warming=warming+1; task.spawn(function() pcall(function() meshCache_k[asset]=AssetService:CreateMeshPartAsync(asset) end); warming=warming-1 end) end
        local t0=os.clock(); while warming>0 and os.clock()-t0<15 do task.wait() end
    end
    print(("[Keyaug] rules: %d | cached:%d dl:%d fail:%d"):format(registered_k,stats.cached,stats.downloaded,stats.failed))
    for _,f in ipairs(failedList) do warn("[Keyaug] FAILED: "..f) end

    local PROPS_K={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}
    local seen_k=setmetatable({},{__mode="k"}); local seenNil_k=setmetatable({},{__mode="k"})
    local forcedTexture_k=setmetatable({},{__mode="k"}); local scaleState_k=setmetatable({},{__mode="k"})
    local camera=workspace.CurrentCamera; local playerGui=Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local function shouldWatch(inst) if WATCH_ALL then return true end; if not inst:IsDescendantOf(game) then return true end; if camera and inst:IsDescendantOf(camera) then return true end; if playerGui and inst:IsDescendantOf(playerGui) then return true end; return false end
    local function hideMesh_k(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
    local function applyMesh_k(inst,asset)
        if not inst:IsA("MeshPart") then pcall(function() inst.MeshId=asset end); return end
        if MESH_METHOD~="apply" then pcall(function() inst.MeshId=asset end) end
        if MESH_METHOD~="direct" then
            local ok,err=pcall(function() local mp=meshCache_k[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache_k[asset]=mp end; inst:ApplyMesh(mp) end)
            if not ok then warn("[Keyaug] ApplyMesh: "..tostring(err)) end
        end
    end
    local function setTarget_k(inst,value) pcall(function() if inst:IsA("MeshPart") then inst.Size=value else inst.Scale=value end end) end
    local function applyScale_k(inst,factor)
        if not factor or factor==1 then return end
        local st=scaleState_k[inst]; if st~=nil then if st then task.defer(setTarget_k,inst,st) end; return end
        scaleState_k[inst]=false
        task.spawn(function()
            task.wait(0.1); local target; pcall(function() if inst:IsA("MeshPart") then target=inst.Size*factor elseif inst:IsA("SpecialMesh") then target=inst.Scale*factor end end)
            if target then scaleState_k[inst]=target; setTarget_k(inst,target) end
        end)
    end
    local function setTexture_k(inst,asset)
        local prop=inst:IsA("SpecialMesh") and "TextureId" or "TextureID"; forcedTexture_k[inst]=asset; pcall(function() inst[prop]=asset end)
    end
    local function handle_k(inst,p)
        local ok,cur=pcall(function() return inst[p] end); if not ok then return false end
        local forced=forcedTexture_k[inst]
        if forced and (p=="TextureID" or p=="TextureId") then if cur~=forced then pcall(function() inst[p]=forced end) end; return true end
        if cur=="" or cur==nil then return false end
        local id=parseId(cur); local entry=id and lookup_k[id]; if entry==nil then return false end
        local new=entry.target; swapped_k=swapped_k+1
        if swapped_k<=15 then print("[Keyaug] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
        if p=="MeshId" then if new=="" then hideMesh_k(inst) else applyMesh_k(inst,new); if entry.texture then setTexture_k(inst,entry.texture) end; applyScale_k(inst,entry.scale) end
        else pcall(function() inst[p]=new end) end
        return true
    end
    local function apply_k(inst)
        local props=PROPS_K[inst.ClassName]; if not props or seen_k[inst] then return end; seen_k[inst]=true
        local watching=shouldWatch(inst)
        for _,p in ipairs(props) do
            local matched=handle_k(inst,p)
            if matched or watching then pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle_k(inst,p) end) end) end
        end
    end
    local function scanNil_k()
        if type(getnilinstances)~="function" then return end
        pcall(function() for _,d in ipairs(getnilinstances()) do if not seenNil_k[d] then seenNil_k[d]=true; apply_k(d); for _,c in ipairs(d:GetDescendants()) do apply_k(c) end end end end)
    end
    game.DescendantAdded:Connect(apply_k)
    local n=0; for _,d in ipairs(game:GetDescendants()) do apply_k(d); n=n+1; if n%2000==0 then task.wait() end end
    scanNil_k()
    task.spawn(function() while true do task.wait(NIL_SCAN_INTERVAL); scanNil_k() end end)
    print("[Keyaug] loaded")
    ::keyaug_done::
    notify("✅ Keyaug AR 已加载","success")
    end) -- task.spawn
end

-- ================================================================
--  SKIN 2 : DRACONIC WILDCAT AR
--  Source: doc 6 verbatim
-- ================================================================
local function LoadDraconicAR(notify)
    if Loaded.DraconicAR then notify("Draconic AR 已加载过了","warning"); return end
    Loaded.DraconicAR = true
    notify("正在加载 Draconic Wildcat AR…","success")
    task.spawn(function()

    local CONFIG = [==[
{
  "replacement_rules": [
    { "name": "ar15-body", "replace_ids": [83884702080665], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/roar.mesh" },
    { "name": "Profile 6", "replace_ids": [13158330555], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/draload.mp3" },
    { "name": "Reload 2?", "replace_ids": [13236549962], "mode": "id", "enabled": true },
    { "name": "Profile 9", "replace_ids": [13158735106], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/m4a1%20dragon.mp3" },
    { "name": "remove", "replace_ids": [75392286602848, 131204076200915, 85569047699564], "mode": "id", "enabled": true },
    { "name": "Profile 10", "replace_ids": [72815891526849, 134260292117186, 101461115963186], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/bow_dreag.mp3" },
    { "name": "Profile 12", "replace_ids": [88813579505134], "mode": "id", "enabled": true, "with_id": 13010870236 },
    { "name": "Profile 13", "replace_ids": [88813579505134], "mode": "id", "enabled": true, "with_id": 13010885336 },
    { "name": "Profile 14", "replace_ids": [120946011201823], "mode": "id", "enabled": true, "with_id": 13010893629 },
    { "name": "Profile 17", "replace_ids": [92222928077393], "mode": "id", "enabled": true, "with_id": 13010870236 },
    { "name": "Profile 18", "replace_ids": [134773461791727], "mode": "id", "enabled": true, "with_id": 13010885336 },
    { "name": "Profile 19", "replace_ids": [135764895692827], "mode": "id", "enabled": true, "with_id": 13010904196 },
    { "name": "mag 2", "replace_ids": [95562281570535], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/magazine_roar.mesh" },
    { "name": "low", "replace_ids": [77401164737509], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/dragon_thumbnail.png" },
    { "name": "high", "replace_ids": [124155708481848], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/dragon_gun_thumbnail_2.png" },
    { "name": "up mag remo", "replace_ids": [83070615292783], "mode": "id", "enabled": true }
  ]
}
]==]

    local SCALE = 2
    local SCALE_BY_ID = { [95562281570535] = 1.3 }
    local VOLUME = { [13158330555] = 2.5, [13158735106] = 0.4 }
    local TEXTURE_URL_BY_ID = {
        [83884702080665] = "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/roar_texture_2048.png",
        [95562281570535] = "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/magazine_texture_2048.png",
    }
    local CACHE_DIR = "AWildcat"

    local function toRaw(url) return (url:gsub("github%.com/([^/]+)/([^/]+)/blob/","raw.githubusercontent.com/%1/%2/")) end
    local function cachePathFor(url) local name=(url:match("([^/]+)$")):gsub("%%20","_"); return CACHE_DIR.."/"..name end
    local function download_d(url, path)
        if isfile(path) then return true end
        local ok,body=pcall(function() return game:HttpGet(toRaw(url)) end)
        if not ok or type(body)~="string" or #body==0 then warn("[Draconic] download failed: "..url); return false end
        if makefolder and isfolder and not isfolder(CACHE_DIR) then pcall(makefolder,CACHE_DIR) end
        return (pcall(writefile,path,body))
    end

    local rules_d=HttpService:JSONDecode(CONFIG).replacement_rules
    local lookup_d,cache_d,meshCache_d={},{},{}
    local registered_d,skipped_d,swapped_d=0,0,0
    local seen_d=setmetatable({},{__mode="k"}); local lastScaled_d=setmetatable({},{__mode="k"})
    local volState_d=setmetatable({},{__mode="k"}); local texFor_d=setmetatable({},{__mode="k"})
    local watched_d=setmetatable({},{__mode="k"})

    local function parseId_d(v) return tonumber(tostring(v):match("(%d+)")) end
    local function loadAsset_d(path)
        if cache_d[path] then return cache_d[path] end
        for _=1,5 do if isfile(path) then local ok,asset=pcall(getcustomasset,path); if ok and asset then cache_d[path]=asset; return asset end end; task.wait(0.3) end; return nil
    end

    -- load per-mesh textures
    local TEXTURES_D={}
    for id,url in pairs(TEXTURE_URL_BY_ID) do
        local path=cachePathFor(url); download_d(url,path); local asset=loadAsset_d(path)
        if asset then TEXTURES_D[id]=asset else warn("[Draconic] texture not loaded: "..url) end
    end

    local function resolve_d(rule)
        if rule.mode=="local" then local path=cachePathFor(rule.url); download_d(rule.url,path); local asset=loadAsset_d(path); if not asset then warn("[Draconic] failed: "..rule.url) end; return asset end
        if rule.with_id then return "rbxassetid://"..rule.with_id end; return ""
    end
    local function register_d(rule)
        if rule.type=="group" then for _,c in ipairs(rule.children or {}) do register_d(c) end
        elseif rule.enabled then
            local target=resolve_d(rule); if target==nil then skipped_d=skipped_d+1; return end
            registered_d=registered_d+1
            for _,id in ipairs(rule.replace_ids) do local n=parseId_d(id); if n then lookup_d[n]=target end end
        end
    end
    for _,r in ipairs(rules_d) do register_d(r) end
    print(("[Draconic] registered: %d, skipped: %d"):format(registered_d,skipped_d))

    local PROPS_D={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}

    local function scaleMesh_d(inst,mult) local m=mult or SCALE; pcall(function() if inst:IsA("MeshPart") then local last=lastScaled_d[inst]; if last and (inst.Size-last).Magnitude<0.001 then return end; local t=inst.Size*m; inst.Size=t; lastScaled_d[inst]=t elseif inst:IsA("SpecialMesh") then local last=lastScaled_d[inst]; if last and (inst.Scale-last).Magnitude<0.001 then return end; local t=inst.Scale*m; inst.Scale=t; lastScaled_d[inst]=t end end) end
    local function applyVolume_d(inst,mult) if not mult then return end; pcall(function() local st=volState_d[inst]; if not st then st={mult=mult,target=inst.Volume}; volState_d[inst]=st; inst:GetPropertyChangedSignal("Volume"):Connect(function() if math.abs(inst.Volume-st.target)>0.001 then st.target=math.clamp(inst.Volume*st.mult,0,10); inst.Volume=st.target end end) end; if math.abs(inst.Volume-st.target)>0.001 or not st.done then st.target=math.clamp(inst.Volume*mult,0,10); inst.Volume=st.target; st.done=true end end) end
    local function setTexture_d(inst,tex) if not tex then return end; texFor_d[inst]=tex; pcall(function() if inst:IsA("MeshPart") then inst.TextureID=tex else inst.TextureId=tex end end)
        for _,c in ipairs(inst:GetChildren()) do if c:IsA("SurfaceAppearance") then c:Destroy() end end
        if not watched_d[inst] then watched_d[inst]=true; inst.ChildAdded:Connect(function(c) if c:IsA("SurfaceAppearance") then task.defer(function() pcall(function() c:Destroy() end) end) end end)
            local prop=inst:IsA("MeshPart") and "TextureID" or "TextureId"; pcall(function() inst:GetPropertyChangedSignal(prop):Connect(function() local w=texFor_d[inst]; if w and inst[prop]~=w then pcall(function() inst[prop]=w end) end end) end)
        end
    end
    local function hideMesh_d(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
    local function applyMesh_d(inst,asset)
        if inst:IsA("MeshPart") then
            local ok,err=pcall(function() local mp=meshCache_d[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache_d[asset]=mp end; inst:ApplyMesh(mp) end)
            if not ok then warn("[Draconic] ApplyMesh: "..tostring(err)); pcall(function() inst.MeshId=asset end) end
        else pcall(function() inst.MeshId=asset end) end
    end
    local function handle_d(inst,p)
        local ok,cur=pcall(function() return inst[p] end); if not ok then return end
        local id=parseId_d(cur); local new=id and lookup_d[id]; if new==nil then return end
        swapped_d=swapped_d+1; if swapped_d<=10 then print("[Draconic] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
        if p=="MeshId" then if new=="" then hideMesh_d(inst) else applyMesh_d(inst,new); scaleMesh_d(inst,SCALE_BY_ID[id]); setTexture_d(inst,TEXTURES_D[id]) end
        else pcall(function() inst[p]=new end); if p=="SoundId" then applyVolume_d(inst,VOLUME[id]) end end
    end
    local function apply_d(inst) local props=PROPS_D[inst.ClassName]; if not props or seen_d[inst] then return end; seen_d[inst]=true; for _,p in ipairs(props) do handle_d(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle_d(inst,p) end) end) end end
    game.DescendantAdded:Connect(apply_d)
    local n=0; for _,d in ipairs(game:GetDescendants()) do apply_d(d); n=n+1; if n%2000==0 then task.wait() end end
    task.spawn(function() while true do task.wait(5); local nn=0; for _,d in ipairs(game:GetDescendants()) do apply_d(d); nn=nn+1; if nn%2000==0 then task.wait() end end end end)
    print("[Draconic] loaded")
    notify("✅ Draconic Wildcat AR 已加载","success")
    end)
end

-- ================================================================
--  SKIN 3 : REAVER VANDAL
--  Source: doc 4 verbatim
-- ================================================================
local function LoadReaverVandal(notify)
    if Loaded.ReaverVandal then notify("Reaver Vandal 已加载过了","warning"); return end
    Loaded.ReaverVandal = true
    notify("正在加载 Reaver Vandal…","success")
    task.spawn(function()

    local v0=[==[
{
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
}
]==]
    local v1="Vandal"; local v2=1.35; local v3="native"; local v4=false; local v5=0; local v6=15; local v7_v=false
    local v8={}; for _,p in ipairs({{"isfile",isfile},{"writefile",writefile},{"getcustomasset",getcustomasset},{"makefolder",makefolder},{"isfolder",isfolder}}) do if type(p[2])~="function" then v8[#v8+1]=p[1] end end
    if #v8>0 then warn("[Vandal] missing: "..table.concat(v8,", ")); notify("❌ Reaver Vandal 加载失败","warning"); return end
    if not isfolder(v1) then pcall(makefolder,v1) end
    local v19=game:GetService("HttpService"); local v20=AssetService
    local v21=v19:JSONDecode(v0).replacement_rules
    local v22,v23,v24={},{},{}; local v25={}; local v26
    local v15_v,v16_v,v17_v=0,0,0; local v18={}
    local function v27(v50) return tonumber(tostring(v50):match("(%d+)")) end
    local function v28(v51) if v23[v51] then return v23[v51] end; for _=1,5 do if isfile(v51) then local ok,a=pcall(getcustomasset,v51); if ok and a then v23[v51]=a; return a end end; task.wait(0.3) end; return nil end
    local function v29(v52)
        if v52.mode=="local" then local path=v52.local_path; if not isfile(path) then return nil end; return v28(path)
        elseif v52.mode=="cdn" or v52.mode=="local" then
            local url=v52.cdn_url or v52.url; if not url then return nil end
            local name=(url:match("[^/]+$") or url):gsub("%%20","_"); local path=v1.."/"..name
            if not isfile(path) then local ok,b=pcall(function() return game:HttpGet(url) end); if not ok or not b then return nil end; pcall(writefile,path,b) end
            return v28(path)
        end
        if v52.with_id then return "rbxassetid://"..v52.with_id end; return nil
    end
    local function v30(v53) if not v53.enabled then return end; local tgt=v29(v53); if tgt==nil then return end; if v53.mode=="cdn" or v53.mode=="local" then v25[tgt]=true end; for _,id in ipairs(v53.replace_ids) do local n=v27(id); if n then v22[n]={target=tgt,baked=(v53.mode=="cdn" and tgt and tostring(v53.cdn_url or ""):lower():find("%.mesh$")~=nil)} end end end
    local function flatReg(list) for _,r in ipairs(list) do if r.type=="group" then flatReg(r.children or {}) else v30(r) end end end
    task.spawn(function()
        flatReg(v21)
        local warming=0
        for asset in pairs(v25) do warming=warming+1; task.spawn(function() pcall(function() v24[asset]=v20:CreateMeshPartAsync(asset) end); warming=warming-1 end) end
        local t0=os.clock(); while warming>0 and os.clock()-t0<30 do task.wait() end
        print("[Vandal] preload complete")
    end)
    local v33=setmetatable({},{__mode="k"}); local v34=setmetatable({},{__mode="k"})
    local function v35(v54) pcall(function() if v54:IsA("BasePart") then v54.Material=Enum.Material.Metal; v54.Reflectance=0.28; v54.Color=Color3.fromRGB(255,205,45) elseif v54:IsA("SpecialMesh") then local p=v54.Parent; if p and p:IsA("BasePart") then p.Material=Enum.Material.Metal; p.Reflectance=0.28; p.Color=Color3.fromRGB(255,205,45) end end end) end
    local function v36(v55,v56)
        if v55:IsA("MeshPart") then
            local mp=v24[v56]; if not mp then local ok=pcall(function() local m=v20:CreateMeshPartAsync(v56); v24[v56]=m; v55:ApplyMesh(m) end); if not ok then pcall(function() v55.MeshId=v56 end); return false end; return true end
            local ok=pcall(function() v55:ApplyMesh(mp) end); if not ok then pcall(function() v55.MeshId=v56 end); return false end; return true
        end; return (pcall(function() v55.MeshId=v56 end))
    end
    local function v37(v57) if not v26 then return end; pcall(function() if v57:IsA("MeshPart") then v57.TextureID=v26 elseif v57:IsA("SpecialMesh") then v57.TextureId=v26 end end) end
    local function v38(v58)
        if v34[v58] then return end; v34[v58]=true
        local props={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
        local pp=props[v58.ClassName]; if not pp then return end
        for _,p in ipairs(pp) do pcall(function() v58:GetPropertyChangedSignal(p):Connect(function()
            local ok,cur=pcall(function() return v58[p] end); if not ok then return end
            local n=v27(cur); if not n then return end
            if v22[n] then local e=v22[n]; if p=="MeshId" then v36(v58,e.target); if e.baked then v37(v58); v35(v58) end else pcall(function() v58[p]=e.target end) end end
        end) end) end
    end
    local function v39(v59,v60)
        local ok,cur=pcall(function() return v59[v60] end); if not ok then return end
        local n=v27(cur); if not n then return end
        local e=v22[n]; if not e then return end
        v17_v=v17_v+1; if v17_v<=15 then print("[Vandal] swapped "..v59.ClassName.."."..v60.." ("..tostring(n)..")") end
        if v60=="MeshId" then
            if e.target=="" then pcall(function() if v59:IsA("BasePart") then v59.Transparency=1; v59.LocalTransparencyModifier=1 elseif v59:IsA("SpecialMesh") then v59.Scale=Vector3.new(0,0,0) end end)
            else v36(v59,e.target); if v2~=1 then pcall(function() if v59:IsA("MeshPart") then v59.Size=v59.Size*v2 elseif v59:IsA("SpecialMesh") then v59.Scale=v59.Scale*v2 end end) end; v37(v59); v35(v59) end
        else pcall(function() v59[v60]=e.target end) end
    end
    local function v40(v61)
        if v33[v61] then return end
        local props={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
        local pp=props[v61.ClassName]; if not pp then return end; v33[v61]=true
        for _,p in ipairs(pp) do v39(v61,p) end; v38(v61)
    end
    local function v46() local n=0; for _,d in ipairs(game:GetDescendants()) do v40(d); n=n+1; if n%1000==0 then task.wait() end end end
    local function v47() if type(getnilinstances)~="function" then return end; pcall(function() for _,d in ipairs(getnilinstances()) do v40(d); for _,c in ipairs(d:GetDescendants()) do v40(c) end end end) end
    game.DescendantAdded:Connect(v40)
    task.spawn(function() v46(); v47(); print("[Vandal] initial scan done") end)
    if v5>0 then task.spawn(function() while true do task.wait(v5); v46() end end) end
    if v6>0 then task.spawn(function() while true do task.wait(v6); v47() end end) end
    print("[Vandal] loaded")
    notify("✅ Reaver Vandal 已加载","success")
    end)
end

-- ================================================================
--  SKIN 4 : KEYCHEL SATCHEL
--  Source: doc 3 verbatim (clean version)
-- ================================================================
local function LoadKeychelSatchel(notify)
    if Loaded.KeychelSatchel then notify("Keychel Satchel 已加载过了","warning"); return end
    Loaded.KeychelSatchel = true
    notify("正在加载 Keychel Satchel…","success")
    task.spawn(function()

    local v0=[==[
{
  "replacement_rules": [
    { "name": "satchel", "replace_ids": [111319295872696], "mode": "cdn", "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/mrbeanissohot/Keychel/main/KEYCHELBODYNEW1.mesh" },
    { "name": "satchel detonator", "replace_ids": [123563845986019], "mode": "cdn", "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/mrbeanissohot/Keychel/main/KEYCHELBUTTONNEW2.mesh" },
    { "name": "ImageIconOfSatchel", "replace_ids": [82237471151891], "mode": "cdn", "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/boxyghosly/Keychel/main/Untitled49_20260527123520.png" },
    { "name": "ExplodingSound", "replace_ids": [13455969017], "mode": "cdn", "enabled": true,
      "cdn_url": "https://raw.githubusercontent.com/boxyghosly/RPKEY/main/RPGKYNEW.mp3" },
    { "name": "ThrowStartPinpull", "replace_ids": [14510062019], "mode": "id", "enabled": true, "with_id": 123368854506447 },
    { "name": "ThrowIdle",         "replace_ids": [14510038568], "mode": "id", "enabled": true, "with_id": 95887720657783 },
    { "name": "ThrowFinish",       "replace_ids": [14510046795], "mode": "id", "enabled": true, "with_id": 98498351754343 },
    { "name": "Sprint",            "replace_ids": [14580328848], "mode": "id", "enabled": true, "with_id": 119518299690405 },
    { "name": "Inspect",           "replace_ids": [14509964565], "mode": "id", "enabled": true, "with_id": 118832975932987 },
    { "name": "LobFinish",         "replace_ids": [14580368724], "mode": "id", "enabled": true, "with_id": 116760723605331 },
    { "name": "Equip",             "replace_ids": [14509948480], "mode": "id", "enabled": true, "with_id": 99784649946058 },
    { "name": "Idle",              "replace_ids": [14509967864], "mode": "id", "enabled": true, "with_id": 138613177890181 }
  ]
}
]==]
    local v1_k=1; local v2_k=Color3.fromRGB(255,205,45); local v3_k=0.28; local v4_k=0.01
    local v5_k={[138805549853994]=true,[129504437671598]=true,[104440368867933]=true,[129357957202626]=true,[87546390135975]=true}
    local v6_k={MeshPart=true,SpecialMesh=true,Sound=true,Animation=true,Decal=true,Texture=true,ImageLabel=true,ImageButton=true,SurfaceAppearance=true}
    local v7_k={Terrain=true,Camera=true}
    local v8_k={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}
    local v9_k="Keychel"
    local function v10_k(url) return (url:gsub("github%.com/([^/]+)/([^/]+)/blob/","raw.githubusercontent.com/%1/%2/")) end
    local function v11_k(url) local name=(url:match("([^/]+)$")):gsub("%%20","_"); return v9_k.."/"..name end
    local function v12_k(url,path) if isfile(path) then return true end; local ok,b=pcall(function() return game:HttpGet(v10_k(url)) end); if not ok or type(b)~="string" or #b==0 then return false end; if makefolder and isfolder and not isfolder(v9_k) then pcall(makefolder,v9_k) end; return (pcall(writefile,path,b)) end
    local v19_k=HttpService; local v20_k=AssetService
    local v21_k=v19_k:JSONDecode(v0).replacement_rules
    local v22_k,v23_k,v24_k={},{},{}; local v25_k={}; local v26_k
    local v15_k,v16_k,v17_k=0,0,0; local v18_k={}
    local function v27_k(v50) return tonumber(tostring(v50):match("(%d+)")) end
    local function v28_k(v51) if v23_k[v51] then return v23_k[v51] end; for _=1,5 do if isfile(v51) then local ok,a=pcall(getcustomasset,v51); if ok and a then v23_k[v51]=a; return a end end; task.wait(0.2) end; return nil end
    local function v29_k(v52)
        if v52.mode=="cdn" or v52.mode=="local" then
            local url=v52.cdn_url or v52.url; if not url then return nil end
            local path=v11_k(url); v12_k(url,path); return v28_k(path)
        end
        if v52.with_id then return "rbxassetid://"..v52.with_id end; return nil
    end
    local function v30_k(v53) if not v53.enabled then return end; local tgt=v29_k(v53); if tgt==nil then return end
        if v53.mode=="cdn" or v53.mode=="local" then v25_k[tgt]=true end
        for _,id in ipairs(v53.replace_ids) do local n=v27_k(id); if n then v22_k[n]=tgt end end
    end
    local tasks_k={}
    for _,rule in ipairs(v21_k) do table.insert(tasks_k,task.spawn(function() pcall(v30_k,rule) end)) end
    for _,t in ipairs(tasks_k) do pcall(task.wait,0) end; pcall(task.wait,0)
    local t0=os.clock(); repeat task.wait(0.1) until os.clock()-t0>20
    local warming_k=0
    for asset in pairs(v25_k) do warming_k=warming_k+1; task.spawn(function() if not v24_k[asset] then pcall(function() v24_k[asset]=v20_k:CreateMeshPartAsync(asset) end) end; warming_k=warming_k-1 end) end
    local t1=os.clock(); while warming_k>0 and os.clock()-t1<30 do task.wait() end

    local v33_k=setmetatable({},{__mode="k"}); local v34_k=setmetatable({},{__mode="k"})
    local function v35_k(v54) pcall(function() if v54:IsA("BasePart") then v54.Material=Enum.Material.Metal; v54.Reflectance=v3_k; v54.Color=v2_k elseif v54:IsA("SpecialMesh") then local p=v54.Parent; if p and p:IsA("BasePart") then p.Material=Enum.Material.Metal; p.Reflectance=v3_k; p.Color=v2_k end end end) end
    local function v36_k(v55,v56)
        if v55:IsA("MeshPart") then local mp=v24_k[v56]; if not mp then pcall(function() local m=v20_k:CreateMeshPartAsync(v56); v24_k[v56]=m; v55:ApplyMesh(m) end); return false end
            local ok=pcall(function() v55:ApplyMesh(mp) end); if not ok then pcall(function() v55.MeshId=v56 end); return false end; return true
        end; return (pcall(function() v55.MeshId=v56 end))
    end
    local function v37_k(v57) if not v26_k then return end; pcall(function() if v57:IsA("MeshPart") then v57.TextureID=v26_k elseif v57:IsA("SpecialMesh") then v57.TextureId=v26_k end end) end
    local function v38_k(v58) if v34_k[v58] then return end; v34_k[v58]=true
        for _,p in ipairs(v8_k[v58.ClassName] or {}) do pcall(function() v58:GetPropertyChangedSignal(p):Connect(function()
            local ok,cur=pcall(function() return v58[p] end); if not ok then return end; local n=v27_k(cur); if not n then return end
            if v5_k[n] then pcall(function() if v58:IsA("BasePart") then v58.Transparency=1 elseif v58:IsA("SpecialMesh") then v58.Scale=Vector3.new(0,0,0) end end); return end
            local tgt=v22_k[n]; if tgt==nil then return end
            if p=="MeshId" then v36_k(v58,tgt); v37_k(v58); v35_k(v58) else pcall(function() v58[p]=tgt end) end
        end) end) end
    end
    local function v39_k(v59,v60)
        local ok,cur=pcall(function() return v59[v60] end); if not ok then return end
        local n=v27_k(cur); if not n then return end
        if v5_k[n] then pcall(function() if v59:IsA("BasePart") then v59.Transparency=1; v59.LocalTransparencyModifier=1 elseif v59:IsA("SpecialMesh") then v59.Scale=Vector3.new(0,0,0) end end); return end
        local tgt=v22_k[n]; if tgt==nil then return end
        v17_k=v17_k+1; if v17_k<=15 then print("[Keychel] swapped "..v59.ClassName.."."..v60.." ("..tostring(n)..")") end
        if v60=="MeshId" then if tgt=="" then pcall(function() if v59:IsA("BasePart") then v59.Transparency=1 elseif v59:IsA("SpecialMesh") then v59.Scale=Vector3.new(0,0,0) end end) else v36_k(v59,tgt); if v1_k~=1 then pcall(function() if v59:IsA("MeshPart") then v59.Size=v59.Size*v1_k elseif v59:IsA("SpecialMesh") then v59.Scale=v59.Scale*v1_k end end) end; v37_k(v59); v35_k(v59) end
        else pcall(function() v59[v60]=tgt end) end
    end
    local function v40_k(v61) if v33_k[v61] then return end; local pp=v8_k[v61.ClassName]; if not pp then return end; v33_k[v61]=true; for _,p in ipairs(pp) do v39_k(v61,p) end; v38_k(v61) end
    local function v41_k(v62) if not v62 then return end; local stack={v62}; local t=os.clock()+v4_k
        while #stack>0 do local inst=stack[#stack]; stack[#stack]=nil
            if not v7_k[inst.ClassName] then if v6_k[inst.ClassName] then pcall(v40_k,inst) end
                local ok,ch=pcall(function() return inst:GetChildren() end); if ok and ch then for _,c in ipairs(ch) do stack[#stack+1]=c end end end
            if os.clock()>t then task.wait(); t=os.clock()+v4_k end
        end
    end
    local function v42_k() local roots={workspace}; pcall(function() table.insert(roots,game:GetService("Players")) end); pcall(function() table.insert(roots,game:GetService("ReplicatedStorage")) end); return roots end
    local function v43_k() for _,r in ipairs(v42_k()) do pcall(function() r.DescendantAdded:Connect(function(d) if v6_k[d.ClassName] then pcall(v40_k,d) end end) end) end end
    task.spawn(function() for _,r in ipairs(v42_k()) do v41_k(r) end; v43_k(); print("[Keychel] scan complete") end)
    print("[Keychel] loaded")
    notify("✅ Keychel Satchel 已加载","success")
    end)
end

-- ================================================================
--  SKIN 5 : KEYRAMBIT + ARCHRAMBIT KNIFE
--  Source: doc 8 verbatim
-- ================================================================
local function LoadKeyrambitKnife(notify)
    if Loaded.KeyrambitKnife then notify("Knife skin 已加载过了","warning"); return end
    Loaded.KeyrambitKnife = true
    notify("正在加载 Keyrambit + Archrambit Knife…","success")
    task.spawn(function()

    -- coslib unlocker
    local frontOk2,frontErr2=pcall(function()
        local KEYWORD="keyrambit"; local PICK=nil
        local lp=Players.LocalPlayer; local ctrl=lp.PlayerScripts:WaitForChild("Controllers",10); local mods=RS:WaitForChild("Modules",10)
        local enumLib=require(mods:WaitForChild("EnumLibrary",10)); if enumLib then pcall(function() enumLib:WaitForEnumBuilder() end) end
        local cosLib=require(mods:WaitForChild("CosmeticLibrary",10)); local datCtrl=require(ctrl:WaitForChild("PlayerDataController",10))
        local Cosmetics=cosLib.Cosmetics
        local function wepName(w) if type(w)=="table" then w=w.Name end; return w end
        local function isKnife(w) w=wepName(w); if type(w)~="string" then return false end; return (w:lower():gsub("%s+",""))=="knife" end
        local function isKeyName(n) return type(n)=="string" and (n:lower():gsub("%s+","")):find(KEYWORD,1,true)~=nil end
        local function isKeySkin(n) local c=isKeyName(n) and Cosmetics[n]; return c and c.Type=="Skin" or false end
        local function mkSkin(name) local base=Cosmetics[name]; if not base then return nil end; local d={}; for k,v in pairs(base) do d[k]=v end; d.Name=name; d.Type=d.Type or "Skin"; d.Seed=d.Seed or math.random(1,1000000); if enumLib then local ok,id=pcall(enumLib.ToEnum,enumLib,name); if ok and id then d.Enum=id; d.ObjectID=d.ObjectID or id end end; return d end
        local matches={}; for name,c in pairs(Cosmetics) do if type(name)=="string" and c.Type=="Skin" and isKeyName(name) then table.insert(matches,name) end end; table.sort(matches)
        if #matches==0 then warn("[Knife-Key] no keyrambit skins"); return end
        local chosen=matches[1]; if PICK and isKeySkin(PICK) then chosen=PICK end
        local knifeSkin=mkSkin(chosen)
        print(("[Knife-Key] equipping '%s'"):format(chosen))
        for _,key in ipairs({"OwnsCosmetic","OwnsCosmeticNormally","OwnsCosmeticUniversally","OwnsCosmeticForWeapon"}) do local orig=cosLib[key]; if type(orig)=="function" then cosLib[key]=function(self,inv,nm,wep,...) if isKnife(wep) and isKeySkin(nm) then return true end; return orig(self,inv,nm,wep,...) end end end
        local origGet=datCtrl.Get; datCtrl.Get=function(self,key,...) local val=origGet(self,key,...); if key=="CosmeticInventory" then local prx={}; if val then for k,v in pairs(val) do prx[k]=v end end; return setmetatable(prx,{__index=function(_,k) if isKeySkin(k) then return true end end}) end; return val end
        local origGetWep=datCtrl.GetWeaponData; datCtrl.GetWeaponData=function(self,wn,...) local d=origGetWep(self,wn,...); if not d then return nil end; if isKnife(wn) and knifeSkin then local m={}; for k,v in pairs(d) do m[k]=v end; m.Name=wn; m.Skin=knifeSkin; return m end; return d end
        if hookmetamethod and getnamecallmethod then
            local remotes=RS:FindFirstChild("Remotes"); local dataRem=remotes and remotes:FindFirstChild("Data"); local equipRem=dataRem and dataRem:FindFirstChild("EquipCosmetic")
            if equipRem then local old; old=hookmetamethod(game,"__namecall",function(self,...) if self==equipRem and getnamecallmethod()=="FireServer" then local a={...}; local wn,ct,cn=a[1],a[2],a[3]; if isKnife(wn) and ct=="Skin" and isKeySkin(cn) then knifeSkin=mkSkin(cn); task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end); return end end; return old(self,...) end) end
        end
        task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end)
        print("[Knife-Key] loaded")
    end)
    if not frontOk2 then warn("[Knife-Key] "..tostring(frontErr2)) end

    -- green enforcer
    pcall(function()
        local GREEN=Color3.fromRGB(110,255,140); local ws=workspace; local lp=Players.LocalPlayer
        local tinted=setmetatable({},{__mode="k"})
        local function nameHit(inst) local p=inst; for _=1,10 do if not p or p==ws then break end; local n=p.Name:lower(); if n:find("knife",1,true) or n:find("rambit",1,true) then return true end; p=p.Parent end; return false end
        local function inMine(inst) local cam=ws.CurrentCamera; return (cam and inst:IsDescendantOf(cam)) or (lp.Character and inst:IsDescendantOf(lp.Character)) end
        local function tint(inst)
            if tinted[inst] or not (inst:IsA("MeshPart") or inst:IsA("SpecialMesh")) then return end
            if not (inMine(inst) and nameHit(inst)) then return end; tinted[inst]=true
            local prop=inst:IsA("MeshPart") and "Color" or "VertexColor"
            local function set() pcall(function() if prop=="Color" then inst.Color=GREEN else inst.VertexColor=Vector3.new(GREEN.R,GREEN.G,GREEN.B) end end) end
            set(); pcall(function() inst:GetPropertyChangedSignal(prop):Connect(set) end)
        end
        ws.DescendantAdded:Connect(function(d) task.defer(tint,d) end)
        task.spawn(function() while true do local cam=ws.CurrentCamera; if cam then for _,d in ipairs(cam:GetDescendants()) do tint(d) end end; if lp.Character then for _,d in ipairs(lp.Character:GetDescendants()) do tint(d) end end; task.wait(0.5) end end)
    end)

    -- Archrambit replacer
    local MESH_URL   ="https://raw.githubusercontent.com/mrbeanissohot/Archrambit/main/archrambiyt.mesh"
    local TEXTURE_URL_A="https://raw.githubusercontent.com/mrbeanissohot/Archrambit/main/arch_texture.png"
    local MESH_CACHE ="Archrambit/archrambiyt.mesh"
    local TEXTURE_CACHE="Archrambit/arch_texture.png"
    local CONFIG_A=[==[
{
  "replacement_rules": [
    {"name":"re","replace_ids":[12482022259,12482022363],"mode":"id","enabled":true},
    {"name":"xd","replace_ids":[105653154583773],"mode":"local","enabled":true,"local_path":"Archrambit/archrambiyt.mesh"},
    {"name":"an","replace_ids":[12613363718],"mode":"id","enabled":true,"with_id":18742841521},
    {"name":"in","replace_ids":[12613329711],"mode":"id","enabled":true,"with_id":18742879471},
    {"name":"hravy","replace_ids":[12613354440],"mode":"id","enabled":true,"with_id":18742868264},
    {"name":"idle","replace_ids":[12613190591],"mode":"id","enabled":true,"with_id":18742849437},
    {"name":"sprint","replace_ids":[12886796453],"mode":"id","enabled":true,"with_id":18742894186}
  ]
}
]==]
    local URL_FOR_PATH_A={[MESH_CACHE]=MESH_URL,[TEXTURE_CACHE]=TEXTURE_URL_A}
    local SCALE_A=1.45
    local rules_a=HttpService:JSONDecode(CONFIG_A).replacement_rules
    local lookup_a,cache_a,meshCache_a={},{},{}
    local registered_a,skipped_a,swapped_a=0,0,0
    local GREEN_A=Color3.fromRGB(110,255,140)

    local function parseId_a(v) return tonumber(tostring(v):match("(%d+)")) end
    local function download_a(url,path)
        local body; local req=request or http_request or (syn and syn.request) or (http and http.request)
        if req then local ok,res=pcall(req,{Url=url,Method="GET"}); if ok and res and res.Success~=false and (res.StatusCode==nil or res.StatusCode==200) then body=res.Body end end
        if not body then local ok,res=pcall(function() return game:HttpGet(url,true) end); if ok then body=res end end
        if not body or #body==0 then return false end
        pcall(function() local folder=path:match("^(.*)/[^/]+$"); if folder and makefolder and not isfolder(folder) then makefolder(folder) end end)
        return (pcall(writefile,path,body))
    end
    local function loadAsset_a(path)
        if cache_a[path] then return cache_a[path] end
        local url=URL_FOR_PATH_A[path]
        if url then if not download_a(url,path) then warn("[Archrambit] download failed: "..url..(isfile(path) and " (using cached)" or "")) end end
        for _=1,5 do if isfile(path) then local ok,asset=pcall(getcustomasset,path); if ok and asset then cache_a[path]=asset; return asset end end; task.wait(0.3) end; return nil
    end
    local function resolve_a(rule)
        if rule.mode=="local" then local asset=loadAsset_a(rule.local_path); if not asset then warn("[Archrambit] failed: "..rule.local_path) end; return asset end
        if rule.with_id then return "rbxassetid://"..rule.with_id end; return ""
    end
    local function register_a(rule)
        if rule.type=="group" then for _,c in ipairs(rule.children or {}) do register_a(c) end
        elseif rule.enabled then local target=resolve_a(rule); if target==nil then skipped_a=skipped_a+1; return end
            registered_a=registered_a+1; for _,id in ipairs(rule.replace_ids) do local n=parseId_a(id); if n then lookup_a[n]=target end end
        end
    end
    for _,r in ipairs(rules_a) do register_a(r) end
    local TEXTURE_A=loadAsset_a(TEXTURE_CACHE)
    if not TEXTURE_A then warn("[Archrambit] texture not loaded") end
    print(("[Archrambit] registered: %d, skipped: %d"):format(registered_a,skipped_a))

    local PROPS_A={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Animation={"AnimationId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
    local seen_a=setmetatable({},{__mode="k"}); local lastScaled_a=setmetatable({},{__mode="k"})
    local watched_a=setmetatable({},{__mode="k"}); local fitted_a=setmetatable({},{__mode="k"})

    local function hideMesh_a(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
    local function applyMesh_a(inst,asset)
        if inst:IsA("MeshPart") then local ok,err=pcall(function() local mp=meshCache_a[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache_a[asset]=mp end; inst:ApplyMesh(mp) end); if not ok then warn("[Archrambit] ApplyMesh: "..tostring(err)); pcall(function() inst.MeshId=asset end) end
        else pcall(function() inst.MeshId=asset end) end
    end
    local function fitMesh_a(inst,asset,mult) if not inst:IsA("MeshPart") then return end; if not fitted_a[inst] then fitted_a[inst]=inst.Size end; local ref=fitted_a[inst]
        task.spawn(function() task.wait(0.1); pcall(function() local mp=meshCache_a[asset]; if not mp then return end; local nat=mp.Size; local f=math.max(ref.X,ref.Y,ref.Z)/math.max(nat.X,nat.Y,nat.Z); inst.Size=nat*f*(mult or SCALE_A) end) end)
    end
    local function forceGreen_a(inst) pcall(function() if inst:IsA("MeshPart") then inst.Color=GREEN_A elseif inst:IsA("SpecialMesh") then inst.VertexColor=Vector3.new(GREEN_A.R,GREEN_A.G,GREEN_A.B) end end) end
    local function applyTexture_a(inst)
        local prop=inst:IsA("MeshPart") and "TextureID" or "TextureId"
        if TEXTURE_A then pcall(function() inst[prop]=TEXTURE_A end) end; forceGreen_a(inst)
        for _,c in ipairs(inst:GetChildren()) do if c:IsA("SurfaceAppearance") then c:Destroy() end end
        if not watched_a[inst] then watched_a[inst]=true
            inst.ChildAdded:Connect(function(c) if c:IsA("SurfaceAppearance") then task.defer(function() pcall(function() c:Destroy() end) end) end end)
            pcall(function() inst:GetPropertyChangedSignal(prop):Connect(function() if TEXTURE_A and inst[prop]~=TEXTURE_A then pcall(function() inst[prop]=TEXTURE_A end) end end) end)
            pcall(function() local cp=inst:IsA("MeshPart") and "Color" or "VertexColor"; inst:GetPropertyChangedSignal(cp):Connect(function() forceGreen_a(inst) end) end)
        end
    end
    local function handle_a(inst,p)
        local ok,cur=pcall(function() return inst[p] end); if not ok then return end
        local id=parseId_a(cur); local new=id and lookup_a[id]; if new==nil then return end
        swapped_a=swapped_a+1; if swapped_a<=10 then print("[Archrambit] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
        if p=="MeshId" then if new=="" then hideMesh_a(inst) else applyMesh_a(inst,new); fitMesh_a(inst,new); applyTexture_a(inst) end
        else pcall(function() inst[p]=new end) end
    end
    local function apply_a(inst) local props=PROPS_A[inst.ClassName]; if not props or seen_a[inst] then return end; seen_a[inst]=true; for _,p in ipairs(props) do handle_a(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle_a(inst,p) end) end) end end
    game.DescendantAdded:Connect(apply_a)
    local n=0; for _,d in ipairs(game:GetDescendants()) do apply_a(d); n=n+1; if n%2000==0 then task.wait() end end
    task.spawn(function() while true do task.wait(5); local nn=0; for _,d in ipairs(game:GetDescendants()) do apply_a(d); nn=nn+1; if nn%2000==0 then task.wait() end end end end)
    print("[Archrambit] loaded")
    notify("✅ Keyrambit + Archrambit Knife 已加载","success")
    end)
end

-- ================================================================
--  SKIN 6 : MONSTER CAN
--  Source: doc 7 verbatim (core engine, skip the logo-glue feature
--  which requires workspace ray-cast timing and is cosmetic only)
-- ================================================================
local function LoadMonsterCan(notify)
    if Loaded.MonsterCan then notify("Monster Can 已加载过了","warning"); return end
    Loaded.MonsterCan = true
    notify("正在加载 Monster Can…","success")
    task.spawn(function()

    local CDN_FOLDER ="AWildcat/monster_cache"
    local MESH_METHOD="both"
    local CONVERT_OBJ=true
    local REFRESH    =false
    local SCALES     ={body=0.6, logo=0.45}
    local ICONS_USE_TEXTURES=false
    local TEXTURE_VERSION="v2"

    local missing_m={}
    for _,p in ipairs({{"isfile",isfile},{"writefile",writefile},{"getcustomasset",getcustomasset},{"makefolder",makefolder},{"isfolder",isfolder}}) do if type(p[2])~="function" then missing_m[#missing_m+1]=p[1] end end
    if #missing_m>0 then warn("[Monster] missing: "..table.concat(missing_m,",")); notify("❌ Monster 加载失败","warning"); return end
    if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
    if not isfolder("AWildcat/monster") then pcall(makefolder,"AWildcat/monster") end
    if not isfolder(CDN_FOLDER) then pcall(makefolder,CDN_FOLDER) end
    if REFRESH and listfiles and delfile then for _,f in ipairs(listfiles(CDN_FOLDER)) do pcall(delfile,f) end end

    local function hashStr_m(s) local h=5381; for i=1,#s do h=(h*33+s:byte(i))%4294967296 end; return string.format("%08x",h) end
    local function download_m(url) local ok,res=pcall(function() return game:HttpGet(url) end); if ok and type(res)=="string" and #res>0 then return res end; local req=request or http_request or (syn and syn.request); if req then local ok2,r=pcall(req,{Url=url,Method="GET"}); if ok2 and r and r.StatusCode==200 and type(r.Body)=="string" and #r.Body>0 then return r.Body end end; return nil end
    local function objToMesh_m(text)
        local v,vt,vn,out={},{},{},{}; local tris,faces=0,0
        local function idx(s,n) if s==nil or s=="" then return nil end; local i=tonumber(s); if not i then return nil end; if i<0 then return n+i+1 end; return i end
        local function corner(a,b,c) local p=v[idx(a,#v) or 0]; if not p then return nil end; local nn=vn[idx(c,#vn) or 0] or {0,1,0}; local t=vt[idx(b,#vt) or 0] or {0,0}; return string.format("[%.5f,%.5f,%.5f][%.4f,%.4f,%.4f][%.5f,%.5f,0]",p[1],p[2],p[3],nn[1],nn[2],nn[3],t[1],1-t[2]) end
        for line in text:gmatch("[^\r\n]+") do
            local c=line:sub(1,2)
            if c=="v " then local x,y,z=line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)"); v[#v+1]={tonumber(x) or 0,tonumber(y) or 0,tonumber(z) or 0}
            elseif c=="vt" then local u,w=line:match("^vt%s+(%S+)%s+(%S+)"); vt[#vt+1]={tonumber(u) or 0,tonumber(w) or 0}
            elseif c=="vn" then local x,y,z=line:match("^vn%s+(%S+)%s+(%S+)%s+(%S+)"); vn[#vn+1]={tonumber(x) or 0,tonumber(y) or 1,tonumber(z) or 0}
            elseif c=="f " then local corners={}; for tok in line:gmatch("%S+") do if tok~="f" then local a,b,cc=tok:match("^(%-?%d+)/?(%-?%d*)/?(%-?%d*)"); local s2=a and corner(a,b,cc); if s2 then corners[#corners+1]=s2 end end end
                for i=2,#corners-1 do out[#out+1]=corners[1]; out[#out+1]=corners[i]; out[#out+1]=corners[i+1]; tris=tris+1 end
                faces=faces+1; if faces%4000==0 then task.wait() end end
        end
        if tris==0 then return nil,0 end; return "version 1.00\n"..tris.."\n"..table.concat(out),tris
    end
    local stats_m={cached=0,downloaded=0,failed=0}; local failedList_m={}; local cdnAssets_m={}
    local function loadAsset_m(path) for _=1,5 do if isfile(path) then local ok,asset=pcall(getcustomasset,path); if ok and asset then return asset end end; task.wait(0.3) end; return nil end
    local loading_m={}; local loadCdnInner_m
    local function loadCdn_m(url) if cdnAssets_m[url] then return cdnAssets_m[url] end; if loading_m[url] then while loading_m[url] do task.wait() end; return cdnAssets_m[url] end; loading_m[url]=true; local ok,res=pcall(loadCdnInner_m,url); loading_m[url]=nil; if ok then return res end; return nil end
    loadCdnInner_m=function(url)
        local name=url:match("[^/]+$") or url; local ext=(url:match("%.(%w+)$") or "bin"):lower(); local conv=(ext=="obj" and CONVERT_OBJ)
        local path=CDN_FOLDER.."/"..hashStr_m(url)..".".. (conv and "mesh" or ext)
        if isfile(path) then stats_m.cached=stats_m.cached+1
        else
            print("[Monster] downloading "..name); local data=download_m(url)
            if not data then stats_m.failed=stats_m.failed+1; failedList_m[#failedList_m+1]=name.." (download failed)"; return nil end
            if #data<200 and data:find("404") then stats_m.failed=stats_m.failed+1; failedList_m[#failedList_m+1]=name.." (404)"; return nil end
            if conv then local mesh,tris=objToMesh_m(data); if not mesh then stats_m.failed=stats_m.failed+1; failedList_m[#failedList_m+1]=name.." (no faces)"; return nil end; print(("[Monster] %s -> %d tris"):format(name,tris)); data=mesh end
            if not pcall(writefile,path,data) then stats_m.failed=stats_m.failed+1; failedList_m[#failedList_m+1]=name.." (save failed)"; return nil end
            stats_m.downloaded=stats_m.downloaded+1
        end
        local asset=loadAsset_m(path); if not asset then stats_m.failed=stats_m.failed+1; failedList_m[#failedList_m+1]=name.." (getcustomasset failed)"; return nil end
        cdnAssets_m[url]=asset; return asset
    end

    -- PNG builder (same as keyaug)
    local crcTable_m={}; for i=0,255 do local c=i; for _=1,8 do if bit32.band(c,1)==1 then c=bit32.bxor(bit32.rshift(c,1),0xEDB88320) else c=bit32.rshift(c,1) end end; crcTable_m[i]=c end
    local function crc32_m(s) local c=0xFFFFFFFF; for i=1,#s do c=bit32.bxor(crcTable_m[bit32.band(bit32.bxor(c,s:byte(i)),0xFF)],bit32.rshift(c,8)) end; return bit32.bxor(c,0xFFFFFFFF) end
    local function adler32_m(s) local a,b=1,0; for i=1,#s do a=(a+s:byte(i))%65521; b=(b+a)%65521 end; return b*65536+a end
    local function pngChunk_m(k,d) return string.pack(">I4",#d)..k..d..string.pack(">I4",crc32_m(k..d)) end
    local function makePng_m(w,h,pixel) local rows={}; for y=0,h-1 do local row={"\0"}; for x=0,w-1 do local r,g,b=pixel(x,y); row[#row+1]=string.char(r,g,b) end; rows[#rows+1]=table.concat(row) end
        local raw=table.concat(rows); local blocks={"\120\1"}; local pos=1
        while pos<=#raw do local piece=raw:sub(pos,pos+65534); pos=pos+#piece; local final=(pos>#raw) and 1 or 0; blocks[#blocks+1]=string.char(final)..string.pack("<I2",#piece)..string.pack("<I2",bit32.band(bit32.bnot(#piece),0xFFFF))..piece end
        blocks[#blocks+1]=string.pack(">I4",adler32_m(raw))
        return "\137PNG\r\n\26\n"..pngChunk_m("IHDR",string.pack(">I4I4",w,h).."\8\2\0\0\0")..pngChunk_m("IDAT",table.concat(blocks))..pngChunk_m("IEND","")
    end
    local TEXTURES_M={
        white=function(x,y) local vv=252; for k=-1,1 do local cx=128+k*40+(y-128)*0.35; if y>40 and y<216 and math.abs(x-cx)<6 then vv=210 end end; return vv,vv,vv end,
        black=function() return 0,0,0 end,
    }
    local textureAssets_m={}
    local function texAsset_m(key) if textureAssets_m[key] then return textureAssets_m[key] end; local gen=TEXTURES_M[key]; if not gen then warn("[Monster] unknown texture: "..tostring(key)); return nil end
        local path=CDN_FOLDER.."/tex_"..key.."_"..TEXTURE_VERSION..".png"
        if not isfile(path) then local ok,png=pcall(makePng_m,256,256,gen); if not ok or not pcall(writefile,path,png) then stats_m.failed=stats_m.failed+1; return nil end; print("[Monster] built texture: "..key) end
        local asset=loadAsset_m(path); if not asset then stats_m.failed=stats_m.failed+1; return nil end; textureAssets_m[key]=asset; return asset
    end

    local CONFIG_M=[==[
{"replacement_rules":[
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
]}]==]

    local rules_m=HttpService:JSONDecode(CONFIG_M).replacement_rules
    local lookup_m,meshCache_m={},{}; local registered_m,swapped_m=0,0
    local function parseId_m(v) return tonumber(tostring(v):match("(%d+)")) end
    local function resolve_m(rule)
        if rule.mode=="texture" then return texAsset_m(rule.texture) end
        if rule.mode=="cdn" then return loadCdn_m(rule.cdn_url) end
        if rule.with_id then return "rbxassetid://"..rule.with_id end; return ""
    end
    local function flatten_m(list,out) for _,r in ipairs(list) do if r.type=="group" then flatten_m(r.children or {},out) elseif r.enabled then local skip=(r.icon=="texture" and not ICONS_USE_TEXTURES) or (r.icon=="original" and ICONS_USE_TEXTURES); if not skip then out[#out+1]=r end end end; return out end
    local active_m=flatten_m(rules_m,{})
    local targets_m={}; local pendingM=#active_m
    for i,rule in ipairs(active_m) do task.spawn(function() local ok,res=pcall(resolve_m,rule); if ok then targets_m[i]=res end; pendingM=pendingM-1 end) end
    while pendingM>0 do task.wait() end
    local meshAssets_m={}
    for i,rule in ipairs(active_m) do
        local tgt=targets_m[i]; if tgt~=nil then
            registered_m=registered_m+1
            local entry={target=tgt}
            if rule.scale then entry.scale=SCALES[rule.scale] end
            if rule.color then entry.color=Color3.fromRGB(rule.color[1],rule.color[2],rule.color[3]) end
            if rule.texture and rule.mode~="texture" then entry.texture=texAsset_m(rule.texture) end
            if tgt~="" and rule.mode~="texture" and (rule.texture or rule.scale) then meshAssets_m[tgt]=true end
            for _,id in ipairs(rule.replace_ids) do local n=parseId_m(id); if n then lookup_m[n]=entry end end
        end
    end
    if MESH_METHOD~="direct" then
        local warming=0; for asset in pairs(meshAssets_m) do warming=warming+1; task.spawn(function() pcall(function() meshCache_m[asset]=AssetService:CreateMeshPartAsync(asset) end); warming=warming-1 end) end
        local t0=os.clock(); while warming>0 and os.clock()-t0<15 do task.wait() end
    end
    print(("[Monster] rules: %d | cached:%d dl:%d fail:%d"):format(registered_m,stats_m.cached,stats_m.downloaded,stats_m.failed))
    for _,f in ipairs(failedList_m) do warn("[Monster] FAILED: "..f) end

    local PROPS_M={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}
    local seen_m=setmetatable({},{__mode="k"}); local forcedTexture_m=setmetatable({},{__mode="k"})
    local scaleState_m=setmetatable({},{__mode="k"}); local origSize_m=setmetatable({},{__mode="k"}); local fitState_m=setmetatable({},{__mode="k"})

    local function hideMesh_m(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
    local function fitMesh_m(inst,asset) pcall(function() local t=fitState_m[inst]; if not t then local mp=meshCache_m[asset]; local o=origSize_m[inst]; if mp and o then local n=mp.Size; local nMax=math.max(n.X,n.Y,n.Z); if nMax>0 then t=n*(math.max(o.X,o.Y,o.Z)/nMax); fitState_m[inst]=t end end end; if t then inst.Size=t end end) end
    local function applyMesh_m(inst,asset,entry)
        if not inst:IsA("MeshPart") then pcall(function() inst.MeshId=asset end); return end
        if not origSize_m[inst] then origSize_m[inst]=inst.Size end
        if MESH_METHOD~="apply" then pcall(function() inst.MeshId=asset end) end
        if MESH_METHOD~="direct" then local ok,err=pcall(function() local mp=meshCache_m[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache_m[asset]=mp end; inst:ApplyMesh(mp) end); if not ok then warn("[Monster] ApplyMesh: "..tostring(err)) end end
        if not entry or entry.fit~=false then fitMesh_m(inst,asset) end
    end
    local function applyScale_m(inst,factor) if not factor or factor==1 then return end; local st=scaleState_m[inst]; if st~=nil then if st then task.defer(function() pcall(function() if inst:IsA("MeshPart") then inst.Size=st else inst.Scale=st end end) end) end; return end
        scaleState_m[inst]=false; task.spawn(function() task.wait(0.1); local t; pcall(function() if inst:IsA("MeshPart") then t=inst.Size*factor elseif inst:IsA("SpecialMesh") then t=inst.Scale*factor end end); if t then scaleState_m[inst]=t; pcall(function() if inst:IsA("MeshPart") then inst.Size=t else inst.Scale=t end end) end end)
    end
    local function setTexture_m(inst,asset) local prop=inst:IsA("SpecialMesh") and "TextureId" or "TextureID"; forcedTexture_m[inst]=asset; pcall(function() inst[prop]=asset end) end
    local function handle_m(inst,p)
        local ok,cur=pcall(function() return inst[p] end); if not ok then return end
        local forced=forcedTexture_m[inst]; if forced and (p=="TextureID" or p=="TextureId") then if cur~=forced then pcall(function() inst[p]=forced end) end; return end
        local id=parseId_m(cur); local entry=id and lookup_m[id]; if entry==nil then return end
        local new=entry.target; swapped_m=swapped_m+1; if swapped_m<=15 then print("[Monster] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
        if p=="MeshId" then if new=="" then hideMesh_m(inst) else applyMesh_m(inst,new,entry); if entry.texture then setTexture_m(inst,entry.texture) end; if entry.color then pcall(function() inst.Color=entry.color end) end; applyScale_m(inst,entry.scale) end
        else pcall(function() inst[p]=new end) end
    end
    local function apply_m(inst) local props=PROPS_M[inst.ClassName]; if not props or seen_m[inst] then return end; seen_m[inst]=true; for _,p in ipairs(props) do task.spawn(handle_m,inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle_m(inst,p) end) end) end end
    local function scanNil_m() if type(getnilinstances)~="function" then return end; pcall(function() for _,d in ipairs(getnilinstances()) do apply_m(d); for _,c in ipairs(d:GetDescendants()) do apply_m(c) end end end) end
    game.DescendantAdded:Connect(apply_m)
    local n=0; for _,d in ipairs(game:GetDescendants()) do apply_m(d); n=n+1; if n%2000==0 then task.wait() end end
    scanNil_m()
    task.spawn(function() while true do task.wait(2); local nn=0; for _,d in ipairs(game:GetDescendants()) do apply_m(d); nn=nn+1; if nn%2000==0 then task.wait() end end; scanNil_m() end end)
    print("[Monster] loaded")
    notify("✅ Monster Can 已加载","success")
    end)
end

-- ================================================================
--  SKIN 7 : ARCHKEYPER SNIPER
--  Source: doc 5 clean config section + standard replacer engine
-- ================================================================
local function LoadArchKeyper(notify)
    if Loaded.ArchKeyper then notify("ArchKeyper 已加载过了","warning"); return end
    Loaded.ArchKeyper = true
    notify("正在加载 ArchKeyper Sniper…","success")
    task.spawn(function()

    local CACHE_DIR="ArchKeyper"
    if not isfolder(CACHE_DIR) then pcall(makefolder,CACHE_DIR) end

    -- mesh comes from the "Profile 1" rule with mode=local/cdn
    local MESH_URL   ="https://raw.githubusercontent.com/mrbeanissohot/ArchKeyperr/main/arch_keyper_v4.mesh"
    local MESH_PATH  =CACHE_DIR.."/arch_keyper_v4.mesh"

    if not isfile(MESH_PATH) then
        local ok,body=pcall(function() return game:HttpGet(MESH_URL) end)
        if ok and body and #body>0 then pcall(writefile,MESH_PATH,body)
        else warn("[ArchKeyper] mesh download failed") end
    end
    local meshAsset_ak
    for _=1,5 do if isfile(MESH_PATH) then local ok,a=pcall(getcustomasset,MESH_PATH); if ok and a then meshAsset_ak=a; break end end; task.wait(0.3) end
    if not meshAsset_ak then warn("[ArchKeyper] could not load mesh"); notify("❌ ArchKeyper 加载失败","warning"); return end

    -- id-swap rules only (animations); mesh via local asset above
    local ID_RULES={
        [13188892761]=meshAsset_ak,  -- Profile 1 body
        -- Profile 2 ids (hide)
        [14778413014]="", [13188893115]="", [13188893017]="", [14774727092]="",
        [13188892855]="", [13188893310]="", [14002915797]="", [13188892651]="",
        [13188892532]="",
    }
    -- animation swaps (with_id)
    local ANIM_SWAPS={
        -- Equip, Idle, Sprint, Inspect, Shoot, Reload, ReloadEmpty kept as-is
        -- (the original had cdn_url pointing to rbxm files; use id swaps)
        [13269929260]=13269929260, [13269931582]=13269931582,
        [13321899382]=13321899382, [13269934368]=13269934368,
        [13269963346]=13269963346, [13642104835]=13642104835,
        [13269951125]=13269951125,
    }

    local lookup_ak={} -- id -> target
    for id,tgt in pairs(ID_RULES) do lookup_ak[id]=tgt end
    for id,wid in pairs(ANIM_SWAPS) do lookup_ak[id]="rbxassetid://"..wid end

    local meshCache_ak={}; local seen_ak=setmetatable({},{__mode="k"})
    local function parseId_ak(v) return tonumber(tostring(v):match("(%d+)")) end
    local function hideMesh_ak(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
    local function applyMesh_ak(inst,asset)
        if inst:IsA("MeshPart") then
            pcall(function() inst.MeshId=asset end) -- direct first
            local ok,err=pcall(function() local mp=meshCache_ak[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache_ak[asset]=mp end; inst:ApplyMesh(mp) end)
            if not ok then warn("[ArchKeyper] ApplyMesh: "..tostring(err)) end
        else pcall(function() inst.MeshId=asset end) end
    end
    local PROPS_AK={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
    local swapped_ak=0
    local function handle_ak(inst,p)
        local ok,cur=pcall(function() return inst[p] end); if not ok then return end
        local id=parseId_ak(cur); local new=id and lookup_ak[id]; if new==nil then return end
        swapped_ak=swapped_ak+1; if swapped_ak<=10 then print("[ArchKeyper] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
        if p=="MeshId" then if new=="" then hideMesh_ak(inst) else applyMesh_ak(inst,new) end
        else pcall(function() inst[p]=new end) end
    end
    local function apply_ak(inst) local props=PROPS_AK[inst.ClassName]; if not props or seen_ak[inst] then return end; seen_ak[inst]=true; for _,p in ipairs(props) do handle_ak(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle_ak(inst,p) end) end) end end
    game.DescendantAdded:Connect(apply_ak)
    local n=0; for _,d in ipairs(game:GetDescendants()) do apply_ak(d); n=n+1; if n%2000==0 then task.wait() end end
    task.spawn(function() while true do task.wait(5); local nn=0; for _,d in ipairs(game:GetDescendants()) do apply_ak(d); nn=nn+1; if nn%2000==0 then task.wait() end end end end)
    print("[ArchKeyper] loaded")
    notify("✅ ArchKeyper Sniper 已加载","success")
    end)
end

-- ================================================================
--  ECLIPSE UI
-- ================================================================
local CFG={
    MainColor      =Color3.fromRGB(14,14,14),
    SecondaryColor =Color3.fromRGB(26,26,26),
    AccentColor    =Color3.fromRGB(189,172,255),
    TextColor      =Color3.fromRGB(200,200,200),
    TextDark       =Color3.fromRGB(120,120,120),
    StrokeColor    =Color3.fromRGB(40,40,40),
    Font           =Enum.Font.Code,
    BaseSize       =Vector2.new(600,450),
}
local Library={Flags={},Connections={},Unloaded=false}

local function Create(class,props,children)
    local inst=Instance.new(class); for i,v in pairs(props or {}) do inst[i]=v end
    for _,child in pairs(children or {}) do child.Parent=inst end; return inst
end
local function Tween(obj,props,time,style,dir) TweenService:Create(obj,TweenInfo.new(time or 0.2,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props):Play() end
local function GetTextSize(text,size,font) return game:GetService("TextService"):GetTextSize(text,size,font,Vector2.new(10000,10000)) end

local ScreenGui=Create("ScreenGui",{Name="EclipseUI",Parent=game:GetService("CoreGui"),ZIndexBehavior=Enum.ZIndexBehavior.Sibling,ResetOnSpawn=false,IgnoreGuiInset=true})
local UIScale=Create("UIScale",{Parent=ScreenGui})
local function UpdateScale() local vp=workspace.CurrentCamera.ViewportSize; UIScale.Scale=math.max(math.min((vp.X-40)/CFG.BaseSize.X,(vp.Y-40)/CFG.BaseSize.Y,1),0.6) end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale); UpdateScale()

local NotifContainer=Create("Frame",{Parent=ScreenGui,Position=UDim2.new(1,-20,0,20),AnchorPoint=Vector2.new(1,0),Size=UDim2.new(0,300,1,0),BackgroundTransparency=1,ZIndex=100})
Create("UIListLayout",{Parent=NotifContainer,Padding=UDim.new(0,5),HorizontalAlignment=Enum.HorizontalAlignment.Right,VerticalAlignment=Enum.VerticalAlignment.Top})

function Library:Notify(msg,ntype)
    local color=(ntype=="success" and Color3.fromRGB(100,255,100)) or (ntype=="warning" and Color3.fromRGB(255,200,80)) or CFG.AccentColor
    local Frame=Create("Frame",{Parent=NotifContainer,Size=UDim2.new(0,0,0,30),BackgroundColor3=CFG.MainColor,BorderSizePixel=0,ClipsDescendants=true},{
        Create("UIStroke",{Color=CFG.AccentColor,Thickness=1,Transparency=0.5}),
        Create("Frame",{Size=UDim2.new(0,2,1,0),BackgroundColor3=color}),
        Create("TextLabel",{Text=msg,TextColor3=CFG.TextColor,Font=CFG.Font,TextSize=12,Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left})
    })
    Tween(Frame,{Size=UDim2.new(0,280,0,35)},0.5,Enum.EasingStyle.Back)
    task.delay(3,function() Tween(Frame,{Size=UDim2.new(0,280,0,0),BackgroundTransparency=1},0.5); task.wait(0.5); Frame:Destroy() end)
end

local TooltipLabel=Create("TextLabel",{Parent=ScreenGui,Size=UDim2.new(0,0,0,20),BackgroundColor3=CFG.SecondaryColor,TextColor3=CFG.TextColor,TextSize=11,Font=CFG.Font,BorderSizePixel=0,Visible=false,ZIndex=200},{Create("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)}),Create("UIStroke",{Color=CFG.StrokeColor})})
local function AddTooltip(obj,text) obj.MouseEnter:Connect(function() TooltipLabel.Text=text; TooltipLabel.Size=UDim2.fromOffset(GetTextSize(text,11,CFG.Font).X+12,20); TooltipLabel.Visible=true end); obj.MouseLeave:Connect(function() TooltipLabel.Visible=false end) end
RunService.RenderStepped:Connect(function() if TooltipLabel.Visible then local m=UserInputService:GetMouseLocation(); TooltipLabel.Position=UDim2.fromOffset(m.X+15,m.Y+15) end end)

local MainFrame=Create("Frame",{Name="MainFrame",Parent=ScreenGui,Size=UDim2.fromOffset(CFG.BaseSize.X,CFG.BaseSize.Y),Position=UDim2.new(0.5,-300,0.5,-225),BackgroundColor3=CFG.MainColor,BorderSizePixel=0},{Create("UIStroke",{Color=CFG.StrokeColor}),Create("UICorner",{CornerRadius=UDim.new(0,3)})})
local Dragging,DragInput,DragStart,StartPos=false,nil,nil,nil
MainFrame.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then Dragging=true; DragStart=input.Position; StartPos=MainFrame.Position; input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then Dragging=false end end) end end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then DragInput=input end end)
UserInputService.InputChanged:Connect(function(input) if input==DragInput and Dragging then local delta=input.Position-DragStart; Tween(MainFrame,{Position=UDim2.new(StartPos.X.Scale,StartPos.X.Offset+delta.X,StartPos.Y.Scale,StartPos.Y.Offset+delta.Y)},0.05) end end)

local TopBar=Create("Frame",{Parent=MainFrame,Size=UDim2.new(1,0,0,30),BackgroundColor3=CFG.MainColor,BorderSizePixel=0},{Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,0),BackgroundColor3=CFG.StrokeColor})})
local TitleLabel=Create("TextLabel",{Parent=TopBar,Text="eclipse.wtf | <font color=\"#bdacff\">skins</font>",TextColor3=CFG.TextDark,TextSize=13,Font=CFG.Font,BackgroundTransparency=1,Size=UDim2.new(0,250,1,0),Position=UDim2.new(0,10,0,0),TextXAlignment=Enum.TextXAlignment.Left,RichText=true})
local ContentContainer=Create("Frame",{Parent=MainFrame,Size=UDim2.new(1,0,1,-30),Position=UDim2.new(0,0,0,30),BackgroundTransparency=1})
local Sidebar=Create("Frame",{Parent=ContentContainer,Size=UDim2.new(0,60,1,0),BackgroundColor3=Color3.fromRGB(17,17,17),BorderSizePixel=0},{Create("UIListLayout",{Padding=UDim.new(0,10),HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Top}),Create("UIPadding",{PaddingTop=UDim.new(0,15)})})
local PagesContainer=Create("Frame",{Parent=ContentContainer,Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,60,0,0),BackgroundTransparency=1})

local Tabs={}
function Library:Tab(name,icon)
    local TabButton=Create("TextButton",{Parent=Sidebar,Size=UDim2.new(0,40,0,40),BackgroundColor3=CFG.MainColor,Text="",AutoButtonColor=false},{Create("ImageLabel",{Name="Icon",Size=UDim2.new(0.6,0,0.6,0),Position=UDim2.new(0.2,0,0.2,0),BackgroundTransparency=1,Image="rbxassetid://"..icon,ImageColor3=CFG.TextDark}),Create("UICorner",{CornerRadius=UDim.new(0,6)})})
    local PageFrame=Create("ScrollingFrame",{Parent=PagesContainer,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ScrollBarThickness=2,ScrollBarImageColor3=CFG.AccentColor,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y})
    Create("UIPadding",{Parent=PageFrame,PaddingTop=UDim.new(0,15),PaddingLeft=UDim.new(0,15),PaddingRight=UDim.new(0,15),PaddingBottom=UDim.new(0,15)})
    local LeftCol=Create("Frame",{Parent=PageFrame,Size=UDim2.new(0.48,0,1,0),BackgroundTransparency=1},{Create("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})})
    local RightCol=Create("Frame",{Parent=PageFrame,Size=UDim2.new(0.48,0,1,0),Position=UDim2.new(0.52,0,0,0),BackgroundTransparency=1},{Create("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})})
    TabButton.MouseButton1Click:Connect(function() for _,t in pairs(Tabs) do Tween(t.Btn,{BackgroundColor3=CFG.MainColor},0.2); t.Btn.Icon.ImageColor3=CFG.TextDark; t.Page.Visible=false end; Tween(TabButton,{BackgroundColor3=CFG.SecondaryColor},0.2); TabButton.Icon.ImageColor3=CFG.AccentColor; PageFrame.Visible=true end)
    table.insert(Tabs,{Btn=TabButton,Page=PageFrame})
    if #Tabs==1 then Tween(TabButton,{BackgroundColor3=CFG.SecondaryColor},0.2); TabButton.Icon.ImageColor3=CFG.AccentColor; PageFrame.Visible=true end
    local GroupFunctions={}; local LeftSide=true
    function GroupFunctions:Group(title)
        local ParentCol=LeftSide and LeftCol or RightCol; LeftSide=not LeftSide
        local GroupFrame=Create("Frame",{Parent=ParentCol,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(17,17,17),BorderSizePixel=0},{Create("UIStroke",{Color=CFG.StrokeColor}),Create("UICorner",{CornerRadius=UDim.new(0,2)})})
        Create("Frame",{Parent=GroupFrame,Size=UDim2.new(1,0,0,25),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0},{Create("UICorner",{CornerRadius=UDim.new(0,2)}),Create("Frame",{Size=UDim2.new(1,0,0,5),Position=UDim2.new(0,0,1,-5),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0}),Create("TextLabel",{Text=title,Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,TextColor3=CFG.TextColor,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left}),Create("Frame",{Size=UDim2.new(0,4,0,4),Position=UDim2.new(1,-10,0.5,-2),BackgroundColor3=CFG.AccentColor,BorderSizePixel=0},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})})
        local Content=Create("Frame",{Parent=GroupFrame,Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,25),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},{Create("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder}),Create("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})})
        local ItemFuncs={}
        function ItemFuncs:Toggle(cfg)
            local Enabled=false
            local Frame=Create("TextButton",{Parent=Content,Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=""})
            local Box=Create("Frame",{Parent=Frame,Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,0,0.5,-6),BackgroundColor3=CFG.SecondaryColor,BorderSizePixel=0},{Create("UIStroke",{Color=CFG.StrokeColor})})
            local Check=Create("Frame",{Parent=Box,Size=UDim2.new(1,-4,1,-4),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=CFG.AccentColor,BackgroundTransparency=1})
            local Label=Create("TextLabel",{Parent=Frame,Text=cfg.Name,TextColor3=CFG.TextDark,TextSize=11,Font=CFG.Font,BackgroundTransparency=1,Position=UDim2.new(0,18,0,0),Size=UDim2.new(1,-18,1,0),TextXAlignment=Enum.TextXAlignment.Left})
            if cfg.Tooltip then AddTooltip(Frame,cfg.Tooltip) end
            local function Update() Enabled=not Enabled; Tween(Check,{BackgroundTransparency=Enabled and 0 or 1},0.1); Tween(Label,{TextColor3=Enabled and CFG.TextColor or CFG.TextDark},0.1); if cfg.Callback then cfg.Callback(Enabled) end end
            Frame.MouseButton1Click:Connect(Update); return {Set=function(v) if v~=Enabled then Update() end end}
        end
        function ItemFuncs:Button(cfg)
            local Btn=Create("TextButton",{Parent=Content,Size=UDim2.new(1,0,0,22),BackgroundColor3=CFG.SecondaryColor,Text=cfg.Name,TextColor3=CFG.TextDark,Font=Enum.Font.GothamBold,TextSize=10},{Create("UIStroke",{Color=CFG.StrokeColor}),Create("UICorner",{CornerRadius=UDim.new(0,3)})})
            if cfg.Variant=="Primary" then Btn.BackgroundColor3=CFG.AccentColor; Btn.TextColor3=Color3.new(0,0,0) end
            if cfg.Variant=="Danger" then Btn.BackgroundColor3=Color3.fromRGB(200,60,60); Btn.TextColor3=Color3.new(1,1,1) end
            Btn.MouseButton1Click:Connect(function() if cfg.Callback then cfg.Callback() end end); if cfg.Tooltip then AddTooltip(Btn,cfg.Tooltip) end
        end
        return ItemFuncs
    end
    return GroupFunctions
end

-- ── BUILD TABS ──────────────────────────────────────────────
local SkinsTab=Library:Tab("Skins",98159911363596)

local ARGroup=SkinsTab:Group("突击步枪 (AR)")
ARGroup:Toggle({Name="Keyaug AR 皮肤",Tooltip="加载 Keyaug AUG 突击步枪皮肤",Callback=function(v) if v then LoadKeyaugAR(function(msg,t) Library:Notify(msg,t) end) end end})
ARGroup:Toggle({Name="Draconic Wildcat AR 皮肤",Tooltip="加载 Draconic 龙皮突击步枪",Callback=function(v) if v then LoadDraconicAR(function(msg,t) Library:Notify(msg,t) end) end end})

local VGroup=SkinsTab:Group("Vandal")
VGroup:Toggle({Name="Reaver Vandal 皮肤",Tooltip="加载 Reaver 幽灵 Vandal 皮肤",Callback=function(v) if v then LoadReaverVandal(function(msg,t) Library:Notify(msg,t) end) end end})

local SGroup=SkinsTab:Group("狙击枪 (Sniper)")
SGroup:Toggle({Name="ArchKeyper 狙击皮肤",Tooltip="加载 ArchKeyper 狙击枪皮肤",Callback=function(v) if v then LoadArchKeyper(function(msg,t) Library:Notify(msg,t) end) end end})

local KGroup=SkinsTab:Group("刀具 (Knife)")
KGroup:Toggle({Name="Keyrambit + Archrambit 刀皮",Tooltip="Keyrambit 解锁 + Archrambit 视觉替换 (绿色)",Callback=function(v) if v then LoadKeyrambitKnife(function(msg,t) Library:Notify(msg,t) end) end end})

local MGroup=SkinsTab:Group("近战 / 投掷物")
MGroup:Toggle({Name="Monster Can 皮肤",Tooltip="将近战物品替换为 Monster 能量饮料罐",Callback=function(v) if v then LoadMonsterCan(function(msg,t) Library:Notify(msg,t) end) end end})
MGroup:Toggle({Name="Keychel Satchel 皮肤",Tooltip="加载 Keychel 炸弹包皮肤",Callback=function(v) if v then LoadKeychelSatchel(function(msg,t) Library:Notify(msg,t) end) end end})

local SetTab=Library:Tab("Settings",11888734334)
local SetGroup=SetTab:Group("菜单设置")
SetGroup:Button({Name="关闭 UI",Variant="Danger",Tooltip="销毁整个 UI",Callback=function() Library.Unloaded=true; ScreenGui:Destroy() end})

-- ── MENU TOGGLE ─────────────────────────────────────────────
Library.MenuKey=Enum.KeyCode.Insert; local Visible=true
UserInputService.InputBegan:Connect(function(input,gpe) if not gpe and input.KeyCode==Library.MenuKey then Visible=not Visible; MainFrame.Visible=Visible end end)
local MobileToggle=Create("ImageButton",{Parent=ScreenGui,Size=UDim2.new(0,40,0,40),Position=UDim2.new(0.5,0,0,10),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=CFG.MainColor,Image="rbxassetid://3926305904",ImageColor3=CFG.AccentColor,AutoButtonColor=false},{Create("UICorner",{CornerRadius=UDim.new(1,0)}),Create("UIStroke",{Color=CFG.AccentColor,Thickness=2})})
MobileToggle.MouseButton1Click:Connect(function() Visible=not Visible; MainFrame.Visible=Visible end)

Library:Notify("🎨 Skin UI 已加载！按 Insert 切换菜单","success")
Library:Notify("⚠️  皮肤加载后需重进游戏才能还原","warning")
