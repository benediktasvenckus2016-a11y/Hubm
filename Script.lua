-- DEOBFUSCATION BY SLAXER\n\nrepeat task.wait() until game:IsLoaded()

repeat task.wait() until game:IsLoaded()

_G.SLAXER_UILocked = false


-- ===================== SLAXER PRIME V2 =====================
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local LP              = Players.LocalPlayer


-- ===================== CHARACTER LIFECYCLE COORDINATOR =====================
-- This coordinator does not reset the Humanoid or create a second reset loop.
-- It only invalidates stale callbacks when Roblox replaces the Character.
_G.SLAXERCharacterLifecycle = {}
do
	local activeCharacter = nil
	local generation = 0
	local humanoidDiedConnection = nil

	function _G.SLAXERCharacterLifecycle.Begin(character)
		generation = generation + 1
		activeCharacter = character
		if humanoidDiedConnection then
			humanoidDiedConnection:Disconnect()
			humanoidDiedConnection = nil
		end
		return generation
	end

	function _G.SLAXERCharacterLifecycle.IsCurrent(character, token)
		return activeCharacter == character and generation == token and LP.Character == character and character.Parent ~= nil
	end

	function _G.SLAXERCharacterLifecycle.BindHumanoid(character, humanoid, token)
		if not _G.SLAXERCharacterLifecycle.IsCurrent(character, token) or not humanoid then return end
		humanoidDiedConnection = humanoid.Died:Connect(function()
			if activeCharacter == character and generation == token then
				activeCharacter = nil
			end
		end)
	end

	function _G.SLAXERCharacterLifecycle.Invalidate(character)
		if activeCharacter ~= character then return end
		generation = generation + 1
		activeCharacter = nil
		if humanoidDiedConnection then
			humanoidDiedConnection:Disconnect()
			humanoidDiedConnection = nil
		end
	end
end


-- Aimbot panel source (loaded only when button pressed)
_G.SLAXER_AIMBOT_PANEL_SRC = [====[
-- old AIMBOT
_G.SLAXER_AIMBOT_PANEL = function()
task.spawn(function() pcall(function()
if _G.SLAXER_UILocked == nil then _G.SLAXER_UILocked = false end
repeat task.wait() until game:IsLoaded()

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TS         = game:GetService("TweenService")
local HS         = game:GetService("HttpService")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer

local CFG = {
    SPEED                 = 56.5,
    VERT_SPEED            = 56.5,
    HEIGHT                = 1,
    V_OFF                 = 0,
    TURN_SPEED            = 40,
    MAX_TORQUE            = 500000,
    JUMP_PREDICT          = 0.35,
    TP_DOWN_PREDICT       = 0.5,
    JUMP_DETECT_THRESHOLD = 0,
    MAX_JUMP_HISTORY      = 12,
    JUMP_COUNT_TRIGGER    = 0,
    TP_DOWN_VEL_THRESHOLD = -80,
    TP_DOWN_RESPONSE_DIST = 8,
    VEL_SAMPLES           = 6,
    POS_SAMPLES           = 4,
    PREDICT_PCT           = 120,
    SWING_COOLDOWN        = 0.08,
    autoSwing             = true,
    BatSpam               = false,
    SpamDelay             = 50,
    keybind               = "V",
}

local PRO_CFG = {
    SPEED                 = 56.5,
    VERT_SPEED            = 56.5,
    LOOK_OFFSET           = 4,
    TURN_SPEED            = 50,
    MAX_TURN              = 35,
    PREDICT_PCT           = 50,
    VEL_SAMPLES           = 8,
    POS_SAMPLES           = 6,
    MAX_JUMP_HISTORY      = 15,
    JUMP_DETECT_THRESHOLD = 0,
    JUMP_COUNT_TRIGGER    = 1,
    TP_DOWN_VEL_THRESHOLD = -80,
    JUMP_PREDICT          = 0.4,
    TP_DOWN_PREDICT       = 0.5,
    autoSwing             = true,
    SWING_COOLDOWN        = 0.06,
    BatSpam               = true,
    SpamDelay             = 40,
    keybind               = "N",
}

local GOOD_CFG = {
    SPEED         = 56.5,
    VERT_SPEED    = 56.5,
    LOOK_OFFSET   = 5,
    keybind       = "B",
}

local GOOD_TURN_SPEED = 40
local GOOD_MAX_TURN   = 28

local UA_PATH   = "UltimateAimBot9_config.json"
local PRO_PATH  = "ProAimBot_config.json"
local GOOD_PATH = "GoodAimBot_config.json"

function saveUA()
    if not writefile then return end
    pcall(writefile, UA_PATH, HS:JSONEncode(CFG))
end
function loadUA()
    if not readfile or not isfile or not isfile(UA_PATH) then return end
    local ok, d = pcall(function() return HS:JSONDecode(readfile(UA_PATH)) end)
    if ok and type(d) == "table" then for k, v in pairs(d) do if CFG[k] ~= nil then CFG[k] = v end end end
end
function savePro()
    if not writefile then return end
    pcall(writefile, PRO_PATH, HS:JSONEncode(PRO_CFG))
end
function loadPro()
    if not readfile or not isfile or not isfile(PRO_PATH) then return end
    local ok, d = pcall(function() return HS:JSONDecode(readfile(PRO_PATH)) end)
    if ok and type(d) == "table" then for k, v in pairs(d) do if PRO_CFG[k] ~= nil then PRO_CFG[k] = v end end end
end
function saveGood()
    if not writefile then return end
    pcall(writefile, GOOD_PATH, HS:JSONEncode(GOOD_CFG))
end
function loadGood()
    if not readfile or not isfile or not isfile(GOOD_PATH) then return end
    local ok, d = pcall(function() return HS:JSONDecode(readfile(GOOD_PATH)) end)
    if ok and type(d) == "table" then for k, v in pairs(d) do if GOOD_CFG[k] ~= nil then GOOD_CFG[k] = v end end end
end
loadUA()
loadPro()
loadGood()

local aimEnabled           = false
local batEquippedThisRun   = false
local angVelc              = nil
local angVelcAtt           = nil
local swingCD              = false
local _intendedVel         = Vector3.zero
local SpamThread           = nil

local _velHistory          = {}
local _posHistory          = {}
local _jumpHistory         = {}
local _infiniteJumpDetected= false
local _tpDownDetected      = false
local _jumpCount           = 0
local _peakY               = 0
local _normalModeTimer     = 0
local _lastTargetY         = 0

local proEnabled           = false
local proEquippedThisRun   = false
local proSwingCD           = false
local _proIntendedVel      = Vector3.zero
local ProSpamThread        = nil
local proAngVelc           = nil
local proAngVelcAtt        = nil

local _proVelHistory       = {}
local _proPosHistory       = {}
local _proJumpHistory      = {}
local _proInfJumpDet       = false
local _proTpDownDet        = false
local _proPeakY            = 0
local _proNormalTimer      = 0
local _proLastY            = 0

local goodEnabled          = false
local goodEquippedThisRun  = false
local _goodIntendedVel     = Vector3.zero
local goodAngVelc          = nil
local goodAngVelcAtt       = nil

local DETECT_NAMES = {"LockBAV","LockAngVel","LockBodyAtt","BatLock","LockBAVAtt","AutoBatAtt","AutoBatAV","AntiBatDet","AntiAim","VelocityLock"}

function purgeHRP(hrp)
    if not hrp then return end
    pcall(function()
        for _, n in ipairs(DETECT_NAMES) do
            local o = hrp:FindFirstChild(n)
            if o then o:Destroy() end
        end
        for _, c in ipairs(hrp:GetChildren()) do
            local low = c.Name:lower()
            if c.Name ~= "_UA_AngV" and c.Name ~= "_UA_Att"
            and c.Name ~= "_PR_AngV" and c.Name ~= "_PR_Att"
            and c.Name ~= "_GB_AngV" and c.Name ~= "_GB_Att"
            and (low:find("lockb") or low:find("lockangv") or low:find("batlock") or low:find("antiaim") or low:find("velocitylock")) then
                pcall(function() c:Destroy() end)
            end
        end
    end)
end

function setupAngVelc(hrp)
    pcall(function()
        local o1 = hrp:FindFirstChild("_UA_AngV")
        local o2 = hrp:FindFirstChild("_UA_Att")
        if o1 then o1:Destroy() end
        if o2 then o2:Destroy() end
    end)
    local att = Instance.new("Attachment"); att.Name = "_UA_Att"; att.Parent = hrp
    local av = Instance.new("AngularVelocity")
    av.Name = "_UA_AngV"; av.Attachment0 = att
    av.RelativeTo = Enum.ActuatorRelativeTo.World
    av.MaxTorque = CFG.MAX_TORQUE; av.AngularVelocity = Vector3.zero; av.Parent = hrp
    angVelcAtt = att; angVelc = av
end
function cleanAngVelc()
    pcall(function() if angVelc    and angVelc.Parent    then angVelc:Destroy()    end end)
    pcall(function() if angVelcAtt and angVelcAtt.Parent then angVelcAtt:Destroy() end end)
    angVelc = nil; angVelcAtt = nil
end

function setupProAngVelc(hrp)
    pcall(function()
        local o1 = hrp:FindFirstChild("_PR_AngV")
        local o2 = hrp:FindFirstChild("_PR_Att")
        if o1 then o1:Destroy() end
        if o2 then o2:Destroy() end
    end)
    local att = Instance.new("Attachment"); att.Name = "_PR_Att"; att.Parent = hrp
    local av = Instance.new("AngularVelocity")
    av.Name = "_PR_AngV"; av.Attachment0 = att
    av.RelativeTo = Enum.ActuatorRelativeTo.World
    av.MaxTorque = math.huge; av.AngularVelocity = Vector3.zero; av.Parent = hrp
    proAngVelcAtt = att; proAngVelc = av
end
function cleanProAngVelc()
    pcall(function() if proAngVelc    and proAngVelc.Parent    then proAngVelc:Destroy()    end end)
    pcall(function() if proAngVelcAtt and proAngVelcAtt.Parent then proAngVelcAtt:Destroy() end end)
    proAngVelc = nil; proAngVelcAtt = nil
end

function setupGoodAngVelc(hrp)
    pcall(function()
        local o1 = hrp:FindFirstChild("_GB_AngV")
        local o2 = hrp:FindFirstChild("_GB_Att")
        if o1 then o1:Destroy() end
        if o2 then o2:Destroy() end
    end)
    local att = Instance.new("Attachment"); att.Name = "_GB_Att"; att.Parent = hrp
    local av = Instance.new("AngularVelocity")
    av.Name = "_GB_AngV"; av.Attachment0 = att
    av.RelativeTo = Enum.ActuatorRelativeTo.World
    av.MaxTorque = math.huge; av.AngularVelocity = Vector3.zero; av.Parent = hrp
    goodAngVelcAtt = att; goodAngVelc = av
end
function cleanGoodAngVelc()
    pcall(function() if goodAngVelc    and goodAngVelc.Parent    then goodAngVelc:Destroy()    end end)
    pcall(function() if goodAngVelcAtt and goodAngVelcAtt.Parent then goodAngVelcAtt:Destroy() end end)
    goodAngVelc = nil; goodAngVelcAtt = nil
end

local TARGET_PARTS = {"HumanoidRootPart", "Torso", "UpperTorso", "Head", "LowerTorso"}

function findBestPart(myHRP)
    local nearestHRP  = nil
    local nearestDist = math.huge
    local bestPart    = nil
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            local eh  = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearestHRP  = eh
                    local closestPart = eh
                    local closestD    = d
                    for _, pName in ipairs(TARGET_PARTS) do
                        local part = p.Character:FindFirstChild(pName)
                        if part and part:IsA("BasePart") then
                            local pd = (part.Position - myHRP.Position).Magnitude
                            if pd < closestD then
                                closestD    = pd
                                closestPart = part
                            end
                        end
                    end
                    bestPart = closestPart
                end
            end
        end
    end
    return nearestHRP, nearestDist, bestPart
end

function detectInfiniteJump(targetHRP)
    if not targetHRP then
        _infiniteJumpDetected = false; _tpDownDetected = false; _jumpCount = 0
        return "normal"
    end
    local velY = targetHRP.Velocity.Y
    local posY = targetHRP.Position.Y
    if posY > _peakY then _peakY = posY end
    local upwardSpikes = 0
    for i = 2, #_jumpHistory do
        if _jumpHistory[i] > CFG.JUMP_DETECT_THRESHOLD
        and _jumpHistory[i-1] < CFG.JUMP_DETECT_THRESHOLD * 0.3 then
            upwardSpikes = upwardSpikes + 1
        end
    end
    if upwardSpikes >= CFG.JUMP_COUNT_TRIGGER and not _infiniteJumpDetected then
        _infiniteJumpDetected = true; _jumpCount = upwardSpikes; _peakY = posY; _tpDownDetected = false
    end
    if _infiniteJumpDetected and velY < CFG.TP_DOWN_VEL_THRESHOLD then
        _tpDownDetected = true; return "tp_down"
    end
    if _infiniteJumpDetected and velY < -20 and (posY < _peakY - 5) then return "falling" end
    if _infiniteJumpDetected and math.abs(velY) < 5 and posY < _lastTargetY + 2 then
        _normalModeTimer = _normalModeTimer + 1
        if _normalModeTimer > 8 then
            _infiniteJumpDetected = false; _tpDownDetected = false; _jumpCount = 0
            _peakY = 0; _normalModeTimer = 0; _jumpHistory = {}
            return "normal"
        end
    else
        _normalModeTimer = 0
    end
    _lastTargetY = posY
    if _infiniteJumpDetected then return _tpDownDetected and "tp_down" or "infinite_jump" end
    return "normal"
end

function detectProInfiniteJump(targetHRP)
    if not targetHRP then
        _proInfJumpDet = false; _proTpDownDet = false
        return "normal"
    end
    local velY = targetHRP.Velocity.Y
    local posY = targetHRP.Position.Y
    if posY > _proPeakY then _proPeakY = posY end
    local upwardSpikes = 0
    for i = 2, #_proJumpHistory do
        if _proJumpHistory[i] > PRO_CFG.JUMP_DETECT_THRESHOLD and _proJumpHistory[i-1] < PRO_CFG.JUMP_DETECT_THRESHOLD * 0.3 then
            upwardSpikes = upwardSpikes + 1
        end
    end
    if upwardSpikes >= PRO_CFG.JUMP_COUNT_TRIGGER and not _proInfJumpDet then
        _proInfJumpDet = true; _proPeakY = posY; _proTpDownDet = false
    end
    if _proInfJumpDet and velY < PRO_CFG.TP_DOWN_VEL_THRESHOLD then
        _proTpDownDet = true; return "tp_down"
    end
    if _proInfJumpDet and velY < -20 and (posY < _proPeakY - 5) then return "falling" end
    if _proInfJumpDet and math.abs(velY) < 5 and posY < _proLastY + 2 then
        _proNormalTimer = _proNormalTimer + 1
        if _proNormalTimer > 8 then
            _proInfJumpDet = false; _proTpDownDet = false
            _proPeakY = 0; _proNormalTimer = 0; _proJumpHistory = {}
            return "normal"
        end
    else
        _proNormalTimer = 0
    end
    _proLastY = posY
    if _proInfJumpDet then return _proTpDownDet and "tp_down" or "infinite_jump" end
    return "normal"
end

local GRAVITY = -196.2

function computePredictedPos(myHRP, targetHRP, bestPart, mode)
    local aimPart   = bestPart or targetHRP
    local curPos    = aimPart.Position
    local rawCurVel = aimPart.Velocity
    local xzSpikeMag = math.abs(rawCurVel.X) + math.abs(rawCurVel.Z)
    local curVel
    if xzSpikeMag > 400 then
        if #_velHistory > 0 then
            local safe = _velHistory[#_velHistory]
            curVel = Vector3.new(safe.X, rawCurVel.Y, safe.Z)
        else
            curVel = Vector3.new(0, rawCurVel.Y, 0)
        end
    else
        curVel = rawCurVel
    end
    table.insert(_velHistory, curVel)
    if #_velHistory > CFG.VEL_SAMPLES then table.remove(_velHistory, 1) end
    table.insert(_posHistory, curPos)
    if #_posHistory > CFG.POS_SAMPLES then table.remove(_posHistory, 1) end
    table.insert(_jumpHistory, rawCurVel.Y)
    if #_jumpHistory > CFG.MAX_JUMP_HISTORY then table.remove(_jumpHistory, 1) end
    local accel = Vector3.zero
    if #_velHistory >= 3 then
        local newest = _velHistory[#_velHistory]
        local oldest = _velHistory[1]
        accel = (newest - oldest) / math.max(#_velHistory * 0.016, 0.016)
    end
    local wasTeleported = false
    if #_posHistory >= 2 then
        local delta = _posHistory[#_posHistory] - _posHistory[#_posHistory - 1]
        if delta.Magnitude > 12 then
            wasTeleported = true
            _velHistory = {}
            _posHistory = { curPos }
        end
    end
    local targetVelXZ = Vector3.new(curVel.X, 0, curVel.Z)
    local targetSpeed  = targetVelXZ.Magnitude
    local mySpeed      = math.max(CFG.SPEED, 1)
    local dXZ          = Vector3.new(curPos.X - myHRP.Position.X, 0, curPos.Z - myHRP.Position.Z)
    local vv  = targetVelXZ:Dot(targetVelXZ)
    local dv  = dXZ:Dot(targetVelXZ)
    local dd  = dXZ:Dot(dXZ)
    local ia  = vv - mySpeed * mySpeed
    local ib  = 2 * dv
    local interceptT
    if math.abs(ia) < 0.01 then
        interceptT = dXZ.Magnitude / math.max(mySpeed - targetSpeed * 0.5, 1)
    else
        local disc = ib * ib - 4 * ia * dd
        if disc < 0 then
            interceptT = dXZ.Magnitude / mySpeed
        else
            local sq = math.sqrt(disc)
            local t1 = (-ib - sq) / (2 * ia)
            local t2 = (-ib + sq) / (2 * ia)
            if     t1 > 0.001 and t2 > 0.001 then interceptT = math.min(t1, t2)
            elseif t1 > 0.001                  then interceptT = t1
            elseif t2 > 0.001                  then interceptT = t2
            else                                    interceptT = dXZ.Magnitude / mySpeed
            end
        end
    end
    interceptT = math.clamp(interceptT, 0.02, 1.5)
    local pctMult  = math.max(CFG.PREDICT_PCT / 100, 0.05)
    local leadTime = math.clamp(interceptT * pctMult, 0.02, 1.5)
    local predictedPos
    local isEmergency = false
    if wasTeleported then
        predictedPos = curPos + curVel * math.min(leadTime, 0.08)
    elseif mode == "tp_down" then
        local landX = curPos.X + curVel.X * CFG.TP_DOWN_PREDICT
        local landZ = curPos.Z + curVel.Z * CFG.TP_DOWN_PREDICT
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {LP.Character}; rp.FilterType = Enum.RaycastFilterType.Exclude
        local rr = workspace:Raycast(Vector3.new(landX, curPos.Y, landZ), Vector3.new(0, -200, 0), rp)
        local gy = rr and rr.Position.Y or curPos.Y
        predictedPos = Vector3.new(landX, gy + CFG.HEIGHT + 3, landZ)
        isEmergency = true
    elseif mode == "infinite_jump" then
        local jt = CFG.JUMP_PREDICT
        predictedPos = curPos + Vector3.new(curVel.X * jt * 0.5, -2, curVel.Z * jt * 0.5)
    elseif curVel.Y < -28 then
        local deltaY = curVel.Y * 0.22
        local disc   = curVel.Y * curVel.Y - 2 * GRAVITY * math.abs(deltaY)
        local ballT  = disc > 0 and ((-curVel.Y - math.sqrt(disc)) / (-GRAVITY)) or 0.18
        ballT = math.clamp(ballT, 0.04, 0.55)
        local blendT = math.max(leadTime, ballT)
        predictedPos = Vector3.new(
            curPos.X + curVel.X * blendT,
            curPos.Y + curVel.Y * ballT + 0.5 * GRAVITY * ballT * ballT + 2.8,
            curPos.Z + curVel.Z * blendT
        )
    elseif curVel.Y > 28 then
        local tPeak  = curVel.Y / math.abs(GRAVITY)
        local blendT = math.min(leadTime, tPeak * 1.2)
        predictedPos = Vector3.new(
            curPos.X + curVel.X * blendT + accel.X * blendT * blendT * 0.5,
            curPos.Y + curVel.Y * blendT + 0.5 * GRAVITY * blendT * blendT,
            curPos.Z + curVel.Z * blendT + accel.Z * blendT * blendT * 0.5
        )
    else
        predictedPos = curPos + curVel * leadTime + accel * (leadTime * leadTime * 0.5)
    end
    if targetVelXZ.Magnitude > 1 and not wasTeleported then
        local fwdDir     = targetVelXZ.Unit
        local relToTgt   = myHRP.Position - curPos
        local relXZ      = Vector3.new(relToTgt.X, 0, relToTgt.Z)
        local relDot     = relXZ:Dot(fwdDir)
        local minAhead   = 4
        local catchUp    = math.max(minAhead - relDot, 0)
        local speedBonus = math.clamp(targetSpeed * 0.09, 1, 5)
        local totalBias  = math.clamp(catchUp + speedBonus, 2, 14)
        predictedPos = predictedPos + Vector3.new(fwdDir.X * totalBias, 0, fwdDir.Z * totalBias)
    end
    predictedPos = predictedPos + Vector3.new(0, CFG.V_OFF, 0)
    return predictedPos, isEmergency
end

function computeProPredictedPos(myHRP, targetHRP, mode)
    local curPos    = targetHRP.Position
    local rawCurVel = targetHRP.Velocity
    local xzSpikeMag = math.abs(rawCurVel.X) + math.abs(rawCurVel.Z)
    local curVel
    if xzSpikeMag > 400 then
        if #_proVelHistory > 0 then
            local safe = _proVelHistory[#_proVelHistory]
            curVel = Vector3.new(safe.X, rawCurVel.Y, safe.Z)
        else
            curVel = Vector3.new(0, rawCurVel.Y, 0)
        end
    else
        curVel = rawCurVel
    end
    table.insert(_proVelHistory, curVel)
    if #_proVelHistory > PRO_CFG.VEL_SAMPLES then table.remove(_proVelHistory, 1) end
    table.insert(_proPosHistory, curPos)
    if #_proPosHistory > PRO_CFG.POS_SAMPLES then table.remove(_proPosHistory, 1) end
    table.insert(_proJumpHistory, rawCurVel.Y)
    if #_proJumpHistory > PRO_CFG.MAX_JUMP_HISTORY then table.remove(_proJumpHistory, 1) end
    local accel = Vector3.zero
    if #_proVelHistory >= 3 then
        local newest = _proVelHistory[#_proVelHistory]
        local oldest = _proVelHistory[1]
        accel = (newest - oldest) / math.max(#_proVelHistory * 0.016, 0.016)
    end
    local wasTeleported = false
    if #_proPosHistory >= 2 then
        local delta = _proPosHistory[#_proPosHistory] - _proPosHistory[#_proPosHistory - 1]
        if delta.Magnitude > 12 then
            wasTeleported = true
            _proVelHistory = {}
            _proPosHistory = { curPos }
        end
    end
    local targetVelXZ = Vector3.new(curVel.X, 0, curVel.Z)
    local targetSpeed  = targetVelXZ.Magnitude
    local mySpeed      = math.max(PRO_CFG.SPEED, 1)
    local dXZ          = Vector3.new(curPos.X - myHRP.Position.X, 0, curPos.Z - myHRP.Position.Z)
    local vv  = targetVelXZ:Dot(targetVelXZ)
    local dv  = dXZ:Dot(targetVelXZ)
    local dd  = dXZ:Dot(dXZ)
    local ia  = vv - mySpeed * mySpeed
    local ib  = 2 * dv
    local interceptT
    if math.abs(ia) < 0.01 then
        interceptT = dXZ.Magnitude / math.max(mySpeed - targetSpeed * 0.5, 1)
    else
        local disc = ib * ib - 4 * ia * dd
        if disc < 0 then
            interceptT = dXZ.Magnitude / mySpeed
        else
            local sq = math.sqrt(disc)
            local t1 = (-ib - sq) / (2 * ia)
            local t2 = (-ib + sq) / (2 * ia)
            if     t1 > 0.001 and t2 > 0.001 then interceptT = math.min(t1, t2)
            elseif t1 > 0.001                  then interceptT = t1
            elseif t2 > 0.001                  then interceptT = t2
            else                                    interceptT = dXZ.Magnitude / mySpeed
            end
        end
    end
    interceptT = math.clamp(interceptT, 0.02, 1.5)
    local pctMult  = math.max(PRO_CFG.PREDICT_PCT / 100, 0.05)
    local leadTime = math.clamp(interceptT * pctMult, 0.02, 1.5)
    local predictedPos
    local isEmergency = false
    if wasTeleported then
        predictedPos = curPos + curVel * math.min(leadTime, 0.08)
    elseif mode == "tp_down" then
        local landX = curPos.X + curVel.X * PRO_CFG.TP_DOWN_PREDICT
        local landZ = curPos.Z + curVel.Z * PRO_CFG.TP_DOWN_PREDICT
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {LP.Character}; rp.FilterType = Enum.RaycastFilterType.Exclude
        local rr = workspace:Raycast(Vector3.new(landX, curPos.Y, landZ), Vector3.new(0, -200, 0), rp)
        local gy = rr and rr.Position.Y or curPos.Y
        predictedPos = Vector3.new(landX, gy + 3, landZ)
        isEmergency = true
    elseif mode == "infinite_jump" then
        local jt = PRO_CFG.JUMP_PREDICT
        predictedPos = curPos + Vector3.new(curVel.X * jt * 0.5, -2, curVel.Z * jt * 0.5)
    elseif curVel.Y < -28 then
        local deltaY = curVel.Y * 0.22
        local disc   = curVel.Y * curVel.Y - 2 * GRAVITY * math.abs(deltaY)
        local ballT  = disc > 0 and ((-curVel.Y - math.sqrt(disc)) / (-GRAVITY)) or 0.18
        ballT = math.clamp(ballT, 0.04, 0.55)
        local blendT = math.max(leadTime, ballT)
        predictedPos = Vector3.new(
            curPos.X + curVel.X * blendT,
            curPos.Y + curVel.Y * ballT + 0.5 * GRAVITY * ballT * ballT + 2.8,
            curPos.Z + curVel.Z * blendT
        )
    elseif curVel.Y > 28 then
        local tPeak  = curVel.Y / math.abs(GRAVITY)
        local blendT = math.min(leadTime, tPeak * 1.2)
        predictedPos = Vector3.new(
            curPos.X + curVel.X * blendT + accel.X * blendT * blendT * 0.5,
            curPos.Y + curVel.Y * blendT + 0.5 * GRAVITY * blendT * blendT,
            curPos.Z + curVel.Z * blendT + accel.Z * blendT * blendT * 0.5
        )
    else
        predictedPos = curPos + curVel * leadTime + accel * (leadTime * leadTime * 0.5)
    end
    if targetVelXZ.Magnitude > 1 and not wasTeleported then
        local fwdDir     = targetVelXZ.Unit
        local relToTgt   = myHRP.Position - curPos
        local relXZ      = Vector3.new(relToTgt.X, 0, relToTgt.Z)
        local relDot     = relXZ:Dot(fwdDir)
        local minAhead   = 4
        local catchUp    = math.max(minAhead - relDot, 0)
        local speedBonus = math.clamp(targetSpeed * 0.09, 1, 5)
        local totalBias  = math.clamp(catchUp + speedBonus, 2, 14)
        predictedPos = predictedPos + Vector3.new(fwdDir.X * totalBias, 0, fwdDir.Z * totalBias)
    end
    return predictedPos, isEmergency
end

function startBatSpam()
    if SpamThread then return end
    SpamThread = task.spawn(function()
        while CFG.BatSpam do
            pcall(function()
                local char = LP.Character
                if char then
                    local bat = char:FindFirstChild("bat") or char:FindFirstChild("Bat")
                    if not bat then
                        for _, tool in pairs(LP.Backpack:GetChildren()) do
                            if tool.Name:lower() == "bat" then bat = tool break end
                        end
                    end
                    if bat and bat:IsA("Tool") then
                        bat:Activate()
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local _, nearDist, _ = findBestPart(hrp)
                            if nearDist and nearDist < 6 then
                                task.wait(0.02)
                                bat:Activate()
                            end
                        end
                    end
                end
            end)
            task.wait(CFG.SpamDelay / 1000)
        end
        SpamThread = nil
    end)
end
function stopBatSpam()
    CFG.BatSpam = false
    SpamThread  = nil
end

function startProBatSpam()
    if ProSpamThread then return end
    ProSpamThread = task.spawn(function()
        while PRO_CFG.BatSpam do
            pcall(function()
                local char = LP.Character
                if char then
                    local bat = char:FindFirstChild("bat") or char:FindFirstChild("Bat")
                    if not bat then
                        for _, tool in pairs(LP.Backpack:GetChildren()) do
                            if tool.Name:lower() == "bat" then bat = tool break end
                        end
                    end
                    if bat and bat:IsA("Tool") then
                        bat:Activate()
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local closestDist = math.huge
                            for _, plr in Players:GetPlayers() do
                                if plr ~= LP and plr.Character then
                                    local tr = plr.Character:FindFirstChild("HumanoidRootPart")
                                    if tr then
                                        local d = (tr.Position - hrp.Position).Magnitude
                                        if d < closestDist then closestDist = d end
                                    end
                                end
                            end
                            if closestDist < 6 then
                                task.wait(0.02)
                                bat:Activate()
                            end
                        end
                    end
                end
            end)
            task.wait(PRO_CFG.SpamDelay / 1000)
        end
        ProSpamThread = nil
    end)
end
function stopProBatSpam()
    PRO_CFG.BatSpam = false
    ProSpamThread   = nil
end

function enableAim()
    if proEnabled then
        proEnabled = false
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Velocity = hrp.Velocity * 0.3; purgeHRP(hrp) end
        if hum then hum.AutoRotate = true end
        if proAngVelc then pcall(function() proAngVelc.AngularVelocity = Vector3.zero end) end
        cleanProAngVelc(); stopProBatSpam()
    end
    if goodEnabled then
        goodEnabled = false; goodEquippedThisRun = false
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Velocity = hrp.Velocity * 0.3 end
        if hum then hum.AutoRotate = true end
        if goodAngVelc then pcall(function() goodAngVelc.AngularVelocity = Vector3.zero end) end
        cleanGoodAngVelc()
    end
    aimEnabled = true; batEquippedThisRun = false
    _velHistory = {}; _posHistory = {}; _intendedVel = Vector3.zero
    _jumpHistory = {}; _infiniteJumpDetected = false; _tpDownDetected = false
    local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then purgeHRP(hrp); setupAngVelc(hrp) end
    if CFG.BatSpam then startBatSpam() end
end
function disableAim()
    aimEnabled = false; batEquippedThisRun = false
    stopBatSpam()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hrp then hrp.Velocity = hrp.Velocity * 0.3; purgeHRP(hrp) end
    if hum then hum.AutoRotate = true end
    if angVelc then pcall(function() angVelc.AngularVelocity = Vector3.zero end) end
    cleanAngVelc()
end

function enablePro()
    if aimEnabled then
        aimEnabled = false; batEquippedThisRun = false
        stopBatSpam()
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Velocity = hrp.Velocity * 0.3; purgeHRP(hrp) end
        if hum then hum.AutoRotate = true end
        if angVelc then pcall(function() angVelc.AngularVelocity = Vector3.zero end) end
        cleanAngVelc()
    end
    if goodEnabled then
        goodEnabled = false; goodEquippedThisRun = false
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Velocity = hrp.Velocity * 0.3 end
        if hum then hum.AutoRotate = true end
        if goodAngVelc then pcall(function() goodAngVelc.AngularVelocity = Vector3.zero end) end
        cleanGoodAngVelc()
    end
    proEnabled = true; proEquippedThisRun = false; proSwingCD = false; _proIntendedVel = Vector3.zero
    _proVelHistory = {}; _proPosHistory = {}; _proJumpHistory = {}
    _proInfJumpDet = false; _proTpDownDet = false; _proPeakY = 0; _proNormalTimer = 0
    local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then purgeHRP(hrp); setupProAngVelc(hrp) end
    if PRO_CFG.BatSpam then startProBatSpam() end
end
function disablePro()
    proEnabled = false; proEquippedThisRun = false
    stopProBatSpam()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hrp then hrp.Velocity = hrp.Velocity * 0.3; purgeHRP(hrp) end
    if hum then hum.AutoRotate = true end
    if proAngVelc then pcall(function() proAngVelc.AngularVelocity = Vector3.zero end) end
    cleanProAngVelc()
end

function enableGood()
    if aimEnabled then
        aimEnabled = false; batEquippedThisRun = false
        stopBatSpam()
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Velocity = hrp.Velocity * 0.3; purgeHRP(hrp) end
        if hum then hum.AutoRotate = true end
        if angVelc then pcall(function() angVelc.AngularVelocity = Vector3.zero end) end
        cleanAngVelc()
    end
    if proEnabled then
        proEnabled = false; proEquippedThisRun = false
        stopProBatSpam()
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Velocity = hrp.Velocity * 0.3; purgeHRP(hrp) end
        if hum then hum.AutoRotate = true end
        if proAngVelc then pcall(function() proAngVelc.AngularVelocity = Vector3.zero end) end
        cleanProAngVelc()
    end
    goodEquippedThisRun = false; goodEnabled = true; _goodIntendedVel = Vector3.zero
    local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then purgeHRP(hrp); setupGoodAngVelc(hrp) end
end
function disableGood()
    goodEnabled = false; goodEquippedThisRun = false
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hrp then hrp.Velocity = hrp.Velocity * 0.3 end
    if hum then hum.AutoRotate = true end
    if goodAngVelc then pcall(function() goodAngVelc.AngularVelocity = Vector3.zero end) end
    cleanGoodAngVelc()
end

RunService.Heartbeat:Connect(function()
    if not aimEnabled then return end
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    purgeHRP(root)
    if not angVelc or not angVelc.Parent then setupAngVelc(root) end
    if not batEquippedThisRun then
        batEquippedThisRun = true
        if not char:FindFirstChildOfClass("Tool") then
            local bp  = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
            local bat = bp and bp:FindFirstChild("Bat")
            if bat then pcall(function() hum:EquipTool(bat) end) end
        end
    end
    local target, dist, bestPart = findBestPart(root)
    if not target then
        hum.AutoRotate = true
        if angVelc then pcall(function() angVelc.AngularVelocity = Vector3.zero end) end
        return
    end
    local mode = detectInfiniteJump(target)
    local predictedPos, isEmergency = computePredictedPos(root, target, bestPart, mode)
    hum.AutoRotate = false
    pcall(function()
        if not angVelc or not angVelc.Parent then return end
        local dCF = CFrame.lookAt(root.Position, predictedPos)
        local rCF = root.CFrame:ToObjectSpace(dCF)
        local ax, an = rCF:ToAxisAngle()
        if an > 0.01 then
            angVelc.AngularVelocity = root.CFrame:VectorToWorldSpace(ax) * (an * CFG.TURN_SPEED)
        else
            angVelc.AngularVelocity = Vector3.zero
        end
    end)
    local moveDir = predictedPos - root.Position
    local distToTarget = moveDir.Magnitude
    -- منع الطيران والانجذاب من بعيد
    if distToTarget > 38 then
        if angVelc then pcall(function() angVelc.AngularVelocity = Vector3.zero end) end
        hum.AutoRotate = true
        return
    end
    local hDir    = Vector3.new(moveDir.X, 0, moveDir.Z)
    local speedMult = 1
    if distToTarget > 22 then speedMult = 0.42
    elseif distToTarget > 14 then speedMult = 0.68
    elseif distToTarget > 8 then speedMult = 0.85 end
    local hVel    = hDir.Magnitude > 0.1 and hDir.Unit * (CFG.SPEED * speedMult) or Vector3.zero
    local vVel
    if isEmergency then
        vVel = Vector3.new(0, math.clamp(math.sign(moveDir.Y) * CFG.VERT_SPEED * 0.7, -35, 45), 0)
    elseif math.abs(moveDir.Y) > 0.15 then
        vVel = Vector3.new(0, math.clamp(math.sign(moveDir.Y) * CFG.VERT_SPEED * 0.55, -30, 40), 0)
    else
        vVel = Vector3.new(0, -1.5, 0)
    end
    _intendedVel = hVel + vVel
    root.Velocity = _intendedVel
    if hDir.Magnitude > 0.5 and distToTarget < 25 then hum:Move(hDir.Unit, false) end
    if CFG.autoSwing and not swingCD then
        local bat = char:FindFirstChild("Bat")
        if bat and bat:IsA("Tool") then
            swingCD = true
            pcall(function()
                bat:Activate()
                local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
                if ev then ev:FireServer() end
            end)
            task.delay(CFG.SWING_COOLDOWN, function() swingCD = false end)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not proEnabled then return end
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    purgeHRP(root)
    pcall(function()
        if _G and _G.FR_State then
            _G.FR_State.antiBatEnabled = false; _G.FR_State.bypassAntiBatEnabled = false
        end
    end)
    if not proAngVelc or not proAngVelc.Parent then setupProAngVelc(root) end
    if not proEquippedThisRun then
        proEquippedThisRun = true
        if not char:FindFirstChildOfClass("Tool") then
            local bp  = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
            local bat = bp and (bp:FindFirstChild("Bat") or bp:FindFirstChild("bat"))
            if bat then pcall(function() hum:EquipTool(bat) end) end
        end
    end
    local closestTR, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tr = plr.Character:FindFirstChild("HumanoidRootPart")
            local h2 = plr.Character:FindFirstChildOfClass("Humanoid")
            if tr and h2 and h2.Health > 0 then
                local d = (tr.Position - root.Position).Magnitude
                if d < closestDist then closestDist = d; closestTR = tr end
            end
        end
    end
    if closestTR then
        local mode = detectProInfiniteJump(closestTR)
        local predictedPos, isEmergency = computeProPredictedPos(root, closestTR, mode)
        local fp = predictedPos + closestTR.CFrame.LookVector * PRO_CFG.LOOK_OFFSET
        local look     = fp - root.Position
        local flatLook = Vector3.new(look.X, 0, look.Z)
        hum.AutoRotate = false
        if look.Magnitude > 0.01 and flatLook.Magnitude > 0.01 then
            local tYaw  = math.deg(math.atan2(-flatLook.X, -flatLook.Z))
            local yawD  = (tYaw - root.Orientation.Y + 180) % 360 - 180
            local tPit  = math.deg(math.atan2(look.Y, flatLook.Magnitude))
            local pitD  = (tPit - root.Orientation.X + 180) % 360 - 180
            local yawR  = math.clamp(math.rad(yawD) * PRO_CFG.TURN_SPEED, -PRO_CFG.MAX_TURN, PRO_CFG.MAX_TURN)
            local pitR  = math.clamp(math.rad(pitD) * PRO_CFG.TURN_SPEED, -PRO_CFG.MAX_TURN, PRO_CFG.MAX_TURN)
            local yRad  = math.rad(root.Orientation.Y)
            local rAxis = Vector3.new(math.cos(yRad), 0, -math.sin(yRad))
            proAngVelc.AngularVelocity = Vector3.new(0, yawR, 0) + (rAxis * pitR)
        else
            proAngVelc.AngularVelocity = Vector3.zero
        end
        local mDir = fp - root.Position
        local hDir = Vector3.new(mDir.X, 0, mDir.Z)
        local hVel = hDir.Magnitude > 0.1 and hDir.Unit * PRO_CFG.SPEED or Vector3.zero
        local vVel
        if isEmergency then
            vVel = Vector3.new(0, math.sign(mDir.Y) * PRO_CFG.VERT_SPEED * 1.4, 0)
        elseif math.abs(mDir.Y) > 0.8 then
            vVel = Vector3.new(0, math.sign(mDir.Y) * PRO_CFG.VERT_SPEED, 0)
        else
            vVel = Vector3.new(0, -2, 0)
        end
        _proIntendedVel = hVel + vVel
        root.Velocity = _proIntendedVel
        if hDir.Magnitude > 0.5 then hum:Move(hDir.Unit, false) end
        if PRO_CFG.autoSwing and not proSwingCD and closestDist <= 8 then
            local bat = char:FindFirstChild("Bat") or char:FindFirstChild("bat")
            if bat and bat:IsA("Tool") then
                proSwingCD = true
                pcall(function()
                    bat:Activate()
                    local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
                    if ev then ev:FireServer() end
                end)
                task.delay(PRO_CFG.SWING_COOLDOWN, function() proSwingCD = false end)
            end
        end
    else
        hum.AutoRotate = true
        if proAngVelc then pcall(function() proAngVelc.AngularVelocity = Vector3.zero end) end
    end
end)

RunService.Heartbeat:Connect(function()
    if not goodEnabled then return end
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    purgeHRP(root)
    pcall(function()
        if _G and _G.FR_State then
            _G.FR_State.antiBatEnabled = false; _G.FR_State.bypassAntiBatEnabled = false
        end
    end)
    if not goodAngVelc or not goodAngVelc.Parent then setupGoodAngVelc(root) end
    if not goodEquippedThisRun then
        goodEquippedThisRun = true
        if not char:FindFirstChildOfClass("Tool") then
            local bp  = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
            local bat = bp and bp:FindFirstChild("Bat")
            if bat then pcall(function() hum:EquipTool(bat) end) end
        end
    end
    local closestTR, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tr = plr.Character:FindFirstChild("HumanoidRootPart")
            local h2 = plr.Character:FindFirstChildOfClass("Humanoid")
            if tr and h2 and h2.Health > 0 then
                local d = (tr.Position - root.Position).Magnitude
                if d < closestDist then closestDist = d; closestTR = tr end
            end
        end
    end
    if closestTR then
        local _vs     = closestTR.Velocity.Magnitude
        local _dynOff = _vs < 0.1 and 1.5 or GOOD_CFG.LOOK_OFFSET
        local fp       = closestTR.Position + closestTR.CFrame.LookVector * _dynOff
        local look     = fp - root.Position
        local flatLook = Vector3.new(look.X, 0, look.Z)
        hum.AutoRotate = false
        if look.Magnitude > 0.01 and flatLook.Magnitude > 0.01 then
            local tYaw  = math.deg(math.atan2(-flatLook.X, -flatLook.Z))
            local yawD  = (tYaw - root.Orientation.Y + 180) % 360 - 180
            local tPit  = math.deg(math.atan2(look.Y, flatLook.Magnitude))
            local pitD  = (tPit - root.Orientation.X + 180) % 360 - 180
            local yawR  = math.clamp(math.rad(yawD) * GOOD_TURN_SPEED, -GOOD_MAX_TURN, GOOD_MAX_TURN)
            local pitR  = math.clamp(math.rad(pitD) * GOOD_TURN_SPEED, -GOOD_MAX_TURN, GOOD_MAX_TURN)
            local yRad  = math.rad(root.Orientation.Y)
            local rAxis = Vector3.new(math.cos(yRad), 0, -math.sin(yRad))
            goodAngVelc.AngularVelocity = Vector3.new(0, yawR, 0) + (rAxis * pitR)
        else
            goodAngVelc.AngularVelocity = Vector3.zero
        end
        local mDir = fp - root.Position
        local hDir = Vector3.new(mDir.X, 0, mDir.Z)
        local hVel = hDir.Magnitude > 0.1 and hDir.Unit * GOOD_CFG.SPEED or Vector3.zero
        local vVel = math.abs(mDir.Y) > 0.8
            and Vector3.new(0, math.sign(mDir.Y) * GOOD_CFG.VERT_SPEED, 0)
            or  Vector3.new(0, -2, 0)
        _goodIntendedVel = hVel + vVel; root.Velocity = _goodIntendedVel
        if hDir.Magnitude > 0.5 then hum:Move(hDir.Unit, false) end
        if closestDist <= 5 then
            local bat = char:FindFirstChild("Bat")
            if bat and bat:IsA("Tool") then
                pcall(function()
                    bat:Activate()
                    local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
                    if ev then ev:FireServer() end
                end)
            end
        end
    else
        hum.AutoRotate = true
        if goodAngVelc then pcall(function() goodAngVelc.AngularVelocity = Vector3.zero end) end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if aimEnabled then
        local v = root.Velocity
        if math.abs(v.X) > 350 or math.abs(v.Z) > 350 then root.Velocity = _intendedVel end
        purgeHRP(root)
    elseif proEnabled then
        local v = root.Velocity
        if math.abs(v.X) > 350 or math.abs(v.Z) > 350 then root.Velocity = _proIntendedVel end
        purgeHRP(root)
    elseif goodEnabled then
        local v = root.Velocity
        if math.abs(v.X) > 350 or math.abs(v.Z) > 350 then root.Velocity = _goodIntendedVel end
        purgeHRP(root)
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    batEquippedThisRun = false; proEquippedThisRun = false; goodEquippedThisRun = false
    _velHistory = {}; _posHistory = {}; _intendedVel = Vector3.zero; _goodIntendedVel = Vector3.zero
    _jumpHistory = {}; _infiniteJumpDetected = false; _tpDownDetected = false
    _proVelHistory = {}; _proPosHistory = {}; _proJumpHistory = {}; _proIntendedVel = Vector3.zero
    _proInfJumpDet = false; _proTpDownDet = false; _proPeakY = 0; _proNormalTimer = 0
    if aimEnabled then
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then purgeHRP(hrp); setupAngVelc(hrp) end
        if CFG.BatSpam then startBatSpam() end
    elseif proEnabled then
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then purgeHRP(hrp); setupProAngVelc(hrp) end
        if PRO_CFG.BatSpam then startProBatSpam() end
    elseif goodEnabled then
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then purgeHRP(hrp); setupGoodAngVelc(hrp) end
    end
end)

pcall(function()
    local old = CoreGui:FindFirstChild("SLAXER_AIMBOT_PANEL")
    if old then old:Destroy() end
end)
if _G.SLAXER_AimbotPanel_Running then _G.SLAXER_AimbotPanel_Running = false; task.wait(0.1) end
_G.SLAXER_AimbotPanel_Running = true

local PURPLE_OFF  = Color3.fromRGB(35, 8, 8)
local PURPLE_ON   = Color3.fromRGB(220, 20, 20)
local PURPLE_STR  = Color3.fromRGB(220, 20, 20)
local PURPLE_DARK = Color3.fromRGB(15, 3, 3)
local CARD_COL    = Color3.fromRGB(30, 6, 6)
local INP_COL     = Color3.fromRGB(25, 5, 5)
local W_COL       = Color3.fromRGB(255, 255, 255)
local DIM_COL     = Color3.fromRGB(150, 15, 15)
local BG_IMG      = "rbxassetid://121407572722967"

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SLAXER_AIMBOT_PANEL"; screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 50; screenGui.IgnoreGuiInset = true
pcall(function() if syn and syn.protect_gui then syn.protect_gui(screenGui) end end)
if not pcall(function() screenGui.Parent = CoreGui end) then
    screenGui.Parent = LP:WaitForChild("PlayerGui")
end

function makeDraggable(frame, handle)
    local dn, ds, sp, di = false, nil, nil, nil
    local draggingActive = false
    handle.InputBegan:Connect(function(i)
        if _G.SLAXER_UILocked then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dn = true; ds = i.Position; sp = frame.Position; draggingActive = false
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dn = false; draggingActive = false end end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then di = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if _G.SLAXER_UILocked then return end
        if i == di and dn and ds then
            local delta = i.Position - ds
            -- only start drag after moving 14px so a simple tap still counts as click
            if not draggingActive then
                if delta.Magnitude < 14 then return end
                draggingActive = true
            end
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
        end
    end)
end

local floatFrame = Instance.new("Frame")
floatFrame.Name = "FloatFrame"; floatFrame.Size = UDim2.new(0, 176, 0, 164)
floatFrame.Position = UDim2.new(0, 10, 0.5, -65)
floatFrame.BackgroundTransparency = 0.3; floatFrame.BackgroundColor3 = PURPLE_DARK
floatFrame.BorderSizePixel = 0; floatFrame.Active = true; floatFrame.Parent = screenGui
Instance.new("UICorner", floatFrame).CornerRadius = UDim.new(0, 10)
local floatStroke = Instance.new("UIStroke", floatFrame)
floatStroke.Color = PURPLE_STR; floatStroke.Thickness = 2

local floatBg = Instance.new("ImageLabel", floatFrame)
floatBg.Size = UDim2.new(1, 0, 1, 0); floatBg.Image = BG_IMG
floatBg.BackgroundTransparency = 1; floatBg.ImageTransparency = 0.25
floatBg.ScaleType = Enum.ScaleType.Crop; floatBg.ZIndex = 0
Instance.new("UICorner", floatBg).CornerRadius = UDim.new(0, 10)
makeDraggable(floatFrame, floatFrame)

local strongBtn = Instance.new("TextButton")
strongBtn.Name = "StrongBtn"; strongBtn.Size = UDim2.new(0, 160, 0, 32)
strongBtn.Position = UDim2.new(0, 8, 0, 8)
strongBtn.BackgroundColor3 = PURPLE_OFF; strongBtn.BorderSizePixel = 0
strongBtn.Text = "BETTER AIMBOT"; strongBtn.TextColor3 = W_COL
strongBtn.Font = Enum.Font.GothamBlack; strongBtn.TextSize = 11; strongBtn.ZIndex = 2
strongBtn.Parent = floatFrame
Instance.new("UICorner", strongBtn).CornerRadius = UDim.new(0, 6)
local strongStroke = Instance.new("UIStroke", strongBtn)
strongStroke.Color = PURPLE_STR; strongStroke.Thickness = 1.2


local proBtn = Instance.new("TextButton")
proBtn.Name = "ProBtn"; proBtn.Size = UDim2.new(0, 160, 0, 32)
proBtn.Position = UDim2.new(0, 8, 0, 48)
proBtn.BackgroundColor3 = PURPLE_OFF; proBtn.BorderSizePixel = 0
proBtn.Text = "PRO AIMBOT"; proBtn.TextColor3 = W_COL
proBtn.Font = Enum.Font.GothamBlack; proBtn.TextSize = 11; proBtn.ZIndex = 2
proBtn.Parent = floatFrame
Instance.new("UICorner", proBtn).CornerRadius = UDim.new(0, 6)
local proStroke = Instance.new("UIStroke", proBtn)
proStroke.Color = PURPLE_STR; proStroke.Thickness = 1.2


local goodBtn = Instance.new("TextButton")
goodBtn.Name = "GoodBtn"; goodBtn.Size = UDim2.new(0, 160, 0, 32)
goodBtn.Position = UDim2.new(0, 8, 0, 88)
goodBtn.BackgroundColor3 = PURPLE_OFF; goodBtn.BorderSizePixel = 0
goodBtn.Text = "GOOD AIMBOT(BYPASSES ALL ANTIBAT)"; goodBtn.TextColor3 = W_COL
goodBtn.Font = Enum.Font.GothamBlack; goodBtn.TextSize = 6; goodBtn.ZIndex = 2
goodBtn.Parent = floatFrame
Instance.new("UICorner", goodBtn).CornerRadius = UDim.new(0, 6)
local goodStroke = Instance.new("UIStroke", goodBtn)
goodStroke.Color = PURPLE_STR; goodStroke.Thickness = 1.2

-- SPEED CONFIG
local speedBox = Instance.new("TextBox", floatFrame)
speedBox.Name = "SpeedBox"
speedBox.Size = UDim2.new(0, 160, 0, 24)
speedBox.Position = UDim2.new(0, 8, 0, 124)
speedBox.BackgroundColor3 = INP_COL
speedBox.BorderSizePixel = 0
speedBox.Text = tostring(CFG.SPEED)
speedBox.TextColor3 = W_COL
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 11
speedBox.ZIndex = 2
speedBox.PlaceholderText = "SPEED"
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)
local speedStroke = Instance.new("UIStroke", speedBox)
speedStroke.Color = PURPLE_STR
speedStroke.Thickness = 1

speedBox.FocusLost:Connect(function()
    local n = tonumber(speedBox.Text)
    if n and n > 0 and n <= 500 then
        CFG.SPEED = n
        PRO_CFG.SPEED = n
        GOOD_CFG.SPEED = n
        saveUA(); savePro(); saveGood()
    else
        speedBox.Text = tostring(CFG.SPEED)
    end
end)


function updateStrongVisual()
    TS:Create(strongBtn,   TweenInfo.new(0.15), {BackgroundColor3 = aimEnabled and PURPLE_ON or PURPLE_OFF}):Play()
    TS:Create(strongStroke,TweenInfo.new(0.15), {Color = aimEnabled and Color3.fromRGB(255, 60, 60) or PURPLE_STR}):Play()
end
function updateProVisual()
    TS:Create(proBtn,   TweenInfo.new(0.15), {BackgroundColor3 = proEnabled and PURPLE_ON or PURPLE_OFF}):Play()
    TS:Create(proStroke,TweenInfo.new(0.15), {Color = proEnabled and Color3.fromRGB(255, 60, 60) or PURPLE_STR}):Play()
end
function updateGoodVisual()
    TS:Create(goodBtn,   TweenInfo.new(0.15), {BackgroundColor3 = goodEnabled and PURPLE_ON or PURPLE_OFF}):Play()
    TS:Create(goodStroke,TweenInfo.new(0.15), {Color = goodEnabled and Color3.fromRGB(255, 60, 60) or PURPLE_STR}):Play()
end







strongBtn.MouseButton1Click:Connect(function()
    if aimEnabled then
        disableAim(); aimEnabled = false; updateStrongVisual(); saveUA()
    else
        enableAim(); updateStrongVisual(); updateProVisual(); updateGoodVisual(); saveUA()
    end
end)

proBtn.MouseButton1Click:Connect(function()
    if proEnabled then
        disablePro(); proEnabled = false; updateProVisual(); savePro()
    else
        enablePro(); updateStrongVisual(); updateProVisual(); updateGoodVisual(); savePro()
    end
end)

goodBtn.MouseButton1Click:Connect(function()
    if goodEnabled then
        disableGood(); goodEnabled = false; updateGoodVisual(); saveGood()
    else
        enableGood(); updateStrongVisual(); updateProVisual(); updateGoodVisual(); saveGood()
    end
end)



function keyToEnum(n)
    if not n then return nil end
    local ok, kc = pcall(function() return Enum.KeyCode[n] end)
    return ok and kc or nil
end

UIS.InputBegan:Connect(function(inp, _gpe)
    local isKb = inp.UserInputType == Enum.UserInputType.Keyboard
    local isGP = inp.UserInputType == Enum.UserInputType.Gamepad1
    if not isKb and not isGP then return end
    local kc = keyToEnum(CFG.keybind)
    if kc and inp.KeyCode == kc then
        if aimEnabled then disableAim(); aimEnabled = false else enableAim() end
        updateStrongVisual(); updateProVisual(); updateGoodVisual(); saveUA()
    end
    local pkc = keyToEnum(PRO_CFG.keybind)
    if pkc and inp.KeyCode == pkc then
        if proEnabled then disablePro(); proEnabled = false else enablePro() end
        updateStrongVisual(); updateProVisual(); updateGoodVisual(); savePro()
    end
    local gkc = keyToEnum(GOOD_CFG.keybind)
    if gkc and inp.KeyCode == gkc then
        if goodEnabled then disableGood(); goodEnabled = false else enableGood() end
        updateStrongVisual(); updateProVisual(); updateGoodVisual(); saveGood()
    end
end)

game:BindToClose(function()
    _G.SLAXER_AimbotPanel_Running = false
    disableAim(); disablePro(); disableGood()
end)

end) end)
end

]====]

function _G.SLAXER_OpenAimbotPanel()
	local src = _G.SLAXER_AIMBOT_PANEL_SRC
	if not src then warn('[SLAXER] Aimbot source missing') return end
	local ok, err = pcall(function()
		local fn = (loadstring or load)(src)
		if not fn then error('compile failed') end
		fn()
		if type(_G.SLAXER_AIMBOT_PANEL) == 'function' then
			_G.SLAXER_AIMBOT_PANEL()
		end
	end)
	if not ok then warn('[SLAXER] Aimbot Panel error:', err) end
end

local LANG = "en"
local TRANSLATIONS = {
	fr = {
		speed="Vitesse", carry_speed="Vitesse Carry", lagger_normal="Lagger Normal", lagger_carry="Lagger Carry",
		mode="Mode", normal="Normal", carry="Carry", lagger_normal_lbl="Lagger Normal", lagger_carry_lbl="Lagger Carry",
		speed_toggle="Toggle Vitesse", lagger_mode="Mode Lagger",
		auto_bat="Auto Bat", auto_swing="Auto Swing", bat_speed="Vitesse Bat", face_offset="Offset Face", keybind="Touche",
		auto_grab="Auto Grab", duration="Durée", radius="Rayon",
		inf_jump="Saut Infini", anti_rag="Anti Ragdoll", fps_boost="FPS Boost", medusa="Méduse",
		anim_toggle="Anim T-Hard", unwalk="Unwalk", hitbox_esp="Hitbox ESP",
		auto_play="Auto Play", side="Côté", right="Droite", left="Gauche",
		tp_down="TP Bas", drop_brainrot="Drop Brainrot", auto_tp_down="Auto TP Bas",
		jump_threshold="Sauts avant TP", hitbox_dist="Hitbox + Distance",
		dark_mode="Mode Sombre", rm_acc="Suppr. Accessoires",
		now_playing="En cours", stop_music="STOP MUSIQUE",
		edit_binds="Modifier Touches", hide_gui="Masquer UI",
		interface="Interface", buttons="Boutons", menu_size="Taille Menu",
		separate_btns="Boutons Séparés", btn_size="Taille Boutons",
		scale="Échelle", my_scripts="Mes Scripts", add_script="Ajouter Script",
		script_name="Nom", script_code="CODE DU SCRIPT", run="LANCER", del="SUP",
		speed_config="Config Vitesse", face_tracking="Suivi de Face",
		auto_steal="Auto Vol", toggles="Toggles", visual="Visuel",
		songs="Musiques", settings="Paramètres",
		executor="Executor", movement="Mouvement", mechanics="Mécaniques",
		aimbot="Aimbot", language="Langue",
		auto_bat_btn="AUTO\nBAT", auto_play_btn="AUTO\nJEU", drop_br_btn="DROP\nBR",
		tp_down_btn="TP\nBAS", carry_spd_btn="CARRY\nVIT", lagger_btn="LAGGER",
		hard_hit="Hard Hit", bat_radius="Rayon Bat",
		anti_lag="Anti Lag", ultra_mode="Ultra Mode",
		esp="ESP (N&B)", tracer="Tracer Lines", no_cam="No Cam Collision",
		engage_range="Engage Range", gamepad="Manette",
		aim_bypass="Aimbot V2",
		aim_bypass_btn="AIM\nV2",
		inf_jump_mode="Mode Saut Infini", inf_jump_manual="Manuel", 		btn_scale="Taille Boutons", btn_scale_up="Agrandir", btn_scale_down="Réduire",
		inf_jump_hold="Hold",
	},
	en = {
		speed="Speed", carry_speed="Carry Speed", lagger_normal="Lagger Normal", lagger_carry="Lagger Carry",
		mode="Mode", normal="Normal", carry="Carry", lagger_normal_lbl="Lagger Normal", lagger_carry_lbl="Lagger Carry",
		speed_toggle="Speed Toggle", lagger_mode="Lagger Mode",
		auto_bat="Auto Bat", auto_swing="Auto Swing", bat_speed="Bat Speed", face_offset="Face Offset", keybind="Keybind",
		auto_grab="Auto Grab", duration="Duration", radius="Radius",
		inf_jump="Inf Jump", anti_rag="Anti Ragdoll", fps_boost="FPS Boost", medusa="Medusa",
		anim_toggle="T-Hard Anim", unwalk="Unwalk", hitbox_esp="Hitbox ESP",
		auto_play="Auto Play", side="Side", right="Right", left="Left",
		tp_down="TP Down", drop_brainrot="Drop Brainrot", auto_tp_down="Auto TP Down",
		jump_threshold="Jumps before TP", hitbox_dist="Hitbox + Distance",
		dark_mode="Dark Mode", rm_acc="Rm. Accessories",
		now_playing="Now Playing", stop_music="STOP MUSIC",
		edit_binds="Edit Binds", hide_gui="Hide GUI",
		interface="Interface", buttons="Buttons", menu_size="Menu Size",
		separate_btns="Detach Btns", btn_size="Button Size",
		scale="Scale", my_scripts="My Scripts", add_script="Add Script",
		script_name="Name", script_code="SCRIPT CODE", run="RUN", del="DEL",
		speed_config="Speed Config", face_tracking="Face Tracking",
		auto_steal="Auto Steal", toggles="Toggles", visual="Visual",
		extra="Extra",
		songs="Songs", settings="Settings",
		executor="Executor", movement="Movement", mechanics="Mechanics",
		main="Main",
		aimbot="Aimbot", language="Language",
		auto_bat_btn="AUTO\nBAT", auto_play_btn="AUTO\nPLAY", drop_br_btn="DROP\nBR",
		tp_down_btn="TP\nDOWN", carry_spd_btn="CARRY\nSPD", lagger_btn="LAGGER",
		hard_hit="Hard Hit", bat_radius="Bat Radius",
		anti_lag="Anti Lag", ultra_mode="Ultra Mode",
		esp="ESP (B&W)", tracer="Tracer Lines", no_cam="No Cam Collision",
		engage_range="Engage Range", gamepad="Gamepad",
		aim_bypass="Aimbot V2",
		aim_bypass_btn="AIM\nV2",
		inf_jump_mode="Inf Jump Mode", inf_jump_manual="Manual", 		btn_scale="Button Scale", btn_scale_up="Bigger", btn_scale_down="Smaller",
		inf_jump_hold="Hold",
	},
	es = {
		speed="Velocidad", carry_speed="Velocidad Carry", lagger_normal="Lagger Normal", lagger_carry="Lagger Carry",
		mode="Modo", normal="Normal", carry="Carry", lagger_normal_lbl="Lagger Normal", lagger_carry_lbl="Lagger Carry",
		speed_toggle="Toggle Velocidad", lagger_mode="Modo Lagger",
		auto_bat="Auto Bat", auto_swing="Auto Swing", bat_speed="Velocidad Bat", face_offset="Offset Cara", keybind="Tecla",
		auto_grab="Auto Robar", duration="Duración", radius="Radio",
		inf_jump="Salto Infinito", anti_rag="Anti Ragdoll", fps_boost="FPS Boost", medusa="Medusa",
		anim_toggle="Anim T-Hard", unwalk="Unwalk", hitbox_esp="Hitbox ESP",
		auto_play="Auto Jugar", side="Lado", right="Derecha", left="Izquierda",
		tp_down="TP Abajo", drop_brainrot="Drop Brainrot", auto_tp_down="Auto TP Abajo",
		jump_threshold="Saltos antes TP", hitbox_dist="Hitbox + Distancia",
		dark_mode="Modo Oscuro", rm_acc="Quitar Accesorios",
		now_playing="Reproduciendo", stop_music="DETENER MÚSICA",
		edit_binds="Editar Teclas", hide_gui="Ocultar UI",
		interface="Interfaz", buttons="Botones", menu_size="Tamaño Menú",
		separate_btns="Botones Separados", btn_size="Tamaño Botones",
		scale="Escala", my_scripts="Mis Scripts", add_script="Añadir Script",
		script_name="Nombre", script_code="CÓDIGO DEL SCRIPT", run="EJECUTAR", del="BORRAR",
		speed_config="Config Velocidad", face_tracking="Seguimiento Cara",
		auto_steal="Auto Robar", toggles="Toggles", visual="Visual",
		extra="Extra",
		songs="Canciones", settings="Ajustes",
		executor="Executor", movement="Movimiento", mechanics="Mecánicas",
		aimbot="Aimbot", language="Idioma",
		auto_bat_btn="AUTO\nBAT", auto_play_btn="AUTO\nJUEGO", drop_br_btn="DROP\nBR",
		tp_down_btn="TP\nABAJO", carry_spd_btn="CARRY\nVEL", lagger_btn="LAGGER",
		hard_hit="Hard Hit", bat_radius="Radio Bat",
		anti_lag="Anti Lag", ultra_mode="Ultra Mode",
		esp="ESP (B&N)", tracer="Tracer Lines", no_cam="Sin Colisión Cam",
		engage_range="Rango", gamepad="Mando",
		aim_bypass="Aimbot V2",
		aim_bypass_btn="AIM\nV2",
		inf_jump_mode="Modo Salto", inf_jump_manual="Manual", 		btn_scale="Escala Botón", btn_scale_up="Aumentar", btn_scale_down="Reducir",
		inf_jump_hold="Hold",
	},
	de = {
		speed="Geschwindigkeit", carry_speed="Carry Geschw.", lagger_normal="Lagger Normal", lagger_carry="Lagger Carry",
		mode="Modus", normal="Normal", carry="Carry", lagger_normal_lbl="Lagger Normal", lagger_carry_lbl="Lagger Carry",
		speed_toggle="Geschw. Toggle", lagger_mode="Lagger Modus",
		auto_bat="Auto Bat", auto_swing="Auto Schlag", bat_speed="Bat Geschw.", face_offset="Gesicht Offset", keybind="Taste",
		auto_grab="Auto Stehlen", duration="Dauer", radius="Radius",
		inf_jump="Unendl. Sprung", anti_rag="Anti Ragdoll", fps_boost="FPS Boost", medusa="Medusa",
		anim_toggle="T-Hard Anim", unwalk="Unwalk", hitbox_esp="Hitbox ESP",
		auto_play="Auto Spielen", side="Seite", right="Rechts", left="Links",
		tp_down="TP Runter", drop_brainrot="Drop Brainrot", auto_tp_down="Auto TP Runter",
		jump_threshold="Sprünge vor TP", hitbox_dist="Hitbox + Abstand",
		dark_mode="Dunkelmodus", rm_acc="Zubehör entfernen",
		now_playing="Läuft gerade", stop_music="MUSIK STOPP",
		edit_binds="Tasten bearbeiten", hide_gui="UI verstecken",
		interface="Oberfläche", buttons="Buttons", menu_size="Menügröße",
		separate_btns="Getrennte Btns", btn_size="Button Größe",
		scale="Skalierung", my_scripts="Meine Skripte", add_script="Skript hinzufügen",
		script_name="Name", script_code="SKRIPT CODE", run="STARTEN", del="LÖSCHEN",
		speed_config="Geschw. Konfig", face_tracking="Gesichtsverfolgung",
		auto_steal="Auto Stehlen", toggles="Toggles", visual="Visuell",
		songs="Lieder", settings="Einstellungen",
		executor="Executor", movement="Bewegung", mechanics="Mechaniken",
		aimbot="Aimbot", language="Sprache",
		auto_bat_btn="AUTO\nBAT", auto_play_btn="AUTO\nSPIEL", drop_br_btn="DROP\nBR",
		tp_down_btn="TP\nRUNTER", carry_spd_btn="CARRY\nGESCH", lagger_btn="LAGGER",
		hard_hit="Hard Hit", bat_radius="Bat Radius",
		anti_lag="Anti Lag", ultra_mode="Ultra Modus",
		esp="ESP (S&W)", tracer="Tracer Lines", no_cam="Kein Cam Collision",
		engage_range="Reichweite", gamepad="Gamepad",
		aim_bypass="Aimbot V2",
		aim_bypass_btn="AIM\nV2",
		inf_jump_mode="Sprung Modus", inf_jump_manual="Manuell", 		btn_scale="Button Skalierung", btn_scale_up="Größer", btn_scale_down="Kleiner",
		inf_jump_hold="Hold",
	},
	pt = {
		speed="Velocidade", carry_speed="Velocidade Carry", lagger_normal="Lagger Normal", lagger_carry="Lagger Carry",
		mode="Modo", normal="Normal", carry="Carry", lagger_normal_lbl="Lagger Normal", lagger_carry_lbl="Lagger Carry",
		speed_toggle="Toggle Velocidade", lagger_mode="Modo Lagger",
		auto_bat="Auto Bat", auto_swing="Auto Swing", bat_speed="Velocidade Bat", face_offset="Offset Rosto", keybind="Tecla",
		auto_grab="Auto Roubar", duration="Duração", radius="Raio",
		inf_jump="Pulo Infinito", anti_rag="Anti Ragdoll", fps_boost="FPS Boost", medusa="Medusa",
		anim_toggle="Anim T-Hard", unwalk="Unwalk", hitbox_esp="Hitbox ESP",
		auto_play="Auto Jogar", side="Lado", right="Direita", left="Esquerda",
		tp_down="TP Baixo", drop_brainrot="Drop Brainrot", auto_tp_down="Auto TP Baixo",
		jump_threshold="Saltos antes TP", hitbox_dist="Hitbox + Distância",
		dark_mode="Modo Escuro", rm_acc="Remover Acessórios",
		now_playing="Tocando agora", stop_music="PARAR MÚSICA",
		edit_binds="Editar Teclas", hide_gui="Ocultar UI",
		interface="Interface", buttons="Botões", menu_size="Tamanho Menu",
		separate_btns="Botões Separados", btn_size="Tamanho Botões",
		scale="Escala", my_scripts="Meus Scripts", add_script="Adicionar Script",
		script_name="Nome", script_code="CÓDIGO DO SCRIPT", run="EXECUTAR", del="EXCLUIR",
		speed_config="Config Velocidade", face_tracking="Rastreamento Rosto",
		auto_steal="Auto Roubar", toggles="Toggles", visual="Visual",
		extra="Extra",
		songs="Músicas", settings="Configurações",
		executor="Executor", movement="Movimento", mechanics="Mecânicas",
		aimbot="Aimbot", language="Idioma",
		auto_bat_btn="AUTO\nBAT", auto_play_btn="AUTO\nJOGO", drop_br_btn="DROP\nBR",
		tp_down_btn="TP\nBAIXO", carry_spd_btn="CARRY\nVEL", lagger_btn="LAGGER",
		hard_hit="Hard Hit", bat_radius="Raio Bat",
		anti_lag="Anti Lag", ultra_mode="Ultra Mode",
		esp="ESP (P&B)", tracer="Tracer Lines", no_cam="Sem Colisão Cam",
		engage_range="Alcance", gamepad="Gamepad",
		aim_bypass="Aimbot V2",
		aim_bypass_btn="AIM\nV2",
		inf_jump_mode="Modo Pulo", inf_jump_manual="Manual", 		btn_scale="Escala Botão", btn_scale_up="Aumentar", btn_scale_down="Diminuir",
		inf_jump_hold="Hold",
	},
	ja = {
		speed="速度", carry_speed="キャリー速度", lagger_normal="ラガー通常", lagger_carry="ラガーキャリー",
		mode="モード", normal="通常", carry="キャリー", lagger_normal_lbl="ラガー通常", lagger_carry_lbl="ラガーキャリー",
		speed_toggle="速度トグル", lagger_mode="ラガーモード",
		auto_bat="オートバット", auto_swing="オートスイング", bat_speed="バット速度", face_offset="顔オフセット", keybind="キー",
		auto_grab="オートグラブ", duration="時間", radius="半径",
		inf_jump="無限ジャンプ", anti_rag="アンチラグドール", fps_boost="FPS強化", medusa="メデューサ",
		anim_toggle="TハードアニメT", unwalk="アンウォーク", hitbox_esp="ヒットボックスESP",
		auto_play="オートプレイ", side="サイド", right="右", left="左",
		tp_down="TP下", drop_brainrot="ドロップ", auto_tp_down="オートTP下",
		jump_threshold="TPまでのジャンプ", hitbox_dist="ヒットボックス+距離",
		dark_mode="ダークモード", rm_acc="アクセサリー削除",
		now_playing="再生中", stop_music="音楽停止",
		edit_binds="キー編集", hide_gui="UI非表示",
		interface="インターフェース", buttons="ボタン", menu_size="メニューサイズ",
		separate_btns="ボタン分離", btn_size="ボタンサイズ",
		scale="スケール", my_scripts="マイスクリプト", add_script="スクリプト追加",
		script_name="名前", script_code="スクリプトコード", run="実行", del="削除",
		speed_config="速度設定", face_tracking="顔追跡",
		auto_steal="オートスティール", toggles="トグル", visual="ビジュアル",
		songs="曲", settings="設定",
		executor="Executor", movement="移動", mechanics="メカニクス",
		aimbot="エイムボット", language="言語",
		auto_bat_btn="AUTO\nBAT", auto_play_btn="AUTO\nプレイ", drop_br_btn="DROP\nBR",
		tp_down_btn="TP\n下", carry_spd_btn="CARRY\n速", lagger_btn="LAGGER",
		hard_hit="ハードヒット", bat_radius="バット半径",
		anti_lag="アンチラグ", ultra_mode="ウルトラモード",
		esp="ESP (白黒)", tracer="トレーサー", no_cam="カム無衝突",
		engage_range="射程", gamepad="ゲームパッド",
		aim_bypass="Aimbot V2",
		aim_bypass_btn="AIM\nV2",
		inf_jump_mode="ジャンプモード", inf_jump_manual="手動", 		btn_scale="ボタンサイズ", btn_scale_up="拡大", btn_scale_down="縮小",
		inf_jump_hold="ホールド",
	},
	ar = {
		speed="السرعة", carry_speed="سرعة الحمل", lagger_normal="لاغر عادي", lagger_carry="لاغر حمل",
		mode="الوضع", normal="عادي", carry="حمل", lagger_normal_lbl="لاغر عادي", lagger_carry_lbl="لاغر حمل",
		speed_toggle="تبديل السرعة", lagger_mode="وضع اللاغر",
		auto_bat="باط تلقائي", auto_swing="ضربة تلقائية", bat_speed="سرعة الباط", face_offset="إزاحة الوجه", keybind="المفتاح",
		auto_grab="سرقة تلقائية", duration="المدة", radius="النطاق",
		inf_jump="قفز لانهائي", anti_rag="ضد الرجدول", fps_boost="تعزيز FPS", medusa="ميدوسا",
		anim_toggle="أنيم T-Hard", unwalk="بدون مشي", hitbox_esp="Hitbox ESP",
		auto_play="تشغيل تلقائي", side="الجانب", right="يمين", left="يسار",
		tp_down="TP للأسفل", drop_brainrot="سقوط", auto_tp_down="TP تلقائي للأسفل",
		jump_threshold="قفزات قبل TP", hitbox_dist="Hitbox + مسافة",
		dark_mode="الوضع الداكن", rm_acc="إزالة الإكسسوارات",
		now_playing="يعزف الآن", stop_music="إيقاف الموسيقى",
		edit_binds="تعديل المفاتيح", hide_gui="إخفاء الواجهة",
		interface="الواجهة", buttons="الأزرار", menu_size="حجم القائمة",
		separate_btns="أزرار منفصلة", btn_size="حجم الأزرار",
		scale="المقياس", my_scripts="سكريبتاتي", add_script="إضافة سكريبت",
		script_name="الاسم", script_code="كود السكريبت", run="تشغيل", del="حذف",
		speed_config="إعداد السرعة", face_tracking="تتبع الوجه",
		auto_steal="سرقة تلقائية", toggles="التبديلات", visual="المرئيات",
		songs="الأغاني", settings="الإعدادات",
		executor="Executor", movement="الحركة", mechanics="الميكانيكا",
		aimbot="أيمبوت", language="اللغة",
		auto_bat_btn="AUTO\nBAT", auto_play_btn="AUTO\nPLAY", drop_br_btn="DROP\nBR",
		tp_down_btn="TP\nأسفل", carry_spd_btn="CARRY\nسرعة", lagger_btn="LAGGER",
		hard_hit="ضربة قوية", bat_radius="نطاق الباط",
		anti_lag="ضد التأخر", ultra_mode="وضع أولترا",
		esp="ESP (أسود أبيض)", tracer="خطوط تتبع", no_cam="لا تصادم كاميرا",
		engage_range="المدى", gamepad="غيم باد",
		aim_bypass="Aimbot V2",
		aim_bypass_btn="AIM\nV2",
		inf_jump_mode="وضع القفز", inf_jump_manual="يدوي", 		btn_scale="حجم الأزرار", btn_scale_up="تكبير", btn_scale_down="تصغير",
		inf_jump_hold="ضغط",
	},
}
local LANG_LIST = {
	{code="fr", flag="🇫🇷", name="Fra"},{code="en", flag="🇬🇧", name="Eng"},
	{code="es", flag="🇪🇸", name="Esp"},{code="de", flag="🇩🇪", name="Deu"},
	{code="pt", flag="🇵🇹", name="Por"},{code="ja", flag="🇯🇵", name="日本"},
	{code="ar", flag="🇸🇦", name="عرب"},
}
local langCallbacks = {}
function T(key) return (TRANSLATIONS[LANG] or TRANSLATIONS["en"])[key] or key end
function onLangChange(cb) table.insert(langCallbacks,cb) end
function setLang(code) LANG=code; for _,cb in ipairs(langCallbacks) do pcall(cb) end end

local OWNER_NAME = "SLAXER PRIME"
function addOwnerTag(char)
	if not char then return end; local head=char:WaitForChild("Head",5); if not head then return end
	local old=head:FindFirstChild("SLAXERTag"); if old then old:Destroy() end
	local bb=Instance.new("BillboardGui",head); bb.Name="SLAXERTag"; bb.Size=UDim2.new(0,210,0,32); bb.StudsOffset=Vector3.new(0,2.8,0); bb.AlwaysOnTop=true
	local lbl=Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.Text="SLAXER PRIME V2 👑"; lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=14; lbl.TextColor3=Color3.fromRGB(220,20,20); lbl.TextStrokeTransparency=0; lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
end
if LP.Name~=OWNER_NAME then
	local function tryTagOwner(p) if p.Name~=OWNER_NAME then return end; if p.Character then task.spawn(function() task.wait(0.5); addOwnerTag(p.Character) end) end; p.CharacterAdded:Connect(function(char) task.wait(0.5); addOwnerTag(char) end) end
	for _,p in ipairs(Players:GetPlayers()) do tryTagOwner(p) end; Players.PlayerAdded:Connect(tryTagOwner)
end


local State = {
	normalSpeed=60, carrySpeed=30, laggerSpeed=13, laggerCarrySpeed=25,
	speedType="normal", laggerActive=false, -- LAGGER FORCED OFF
	autoBatToggled=false, hittingCooldown=false, aimbotSpeed=56.5, autoSwingEnabled=true,
	infJumpEnabled=false, infJumpMode="manual", antiRagdollEnabled=true, fpsBoostEnabled=true, antiCrasherEnabled=true,
	guiVisible=true, isStealing=false, stealStartTime=nil, lastStealTick=0,
	medusaLastUsed=0, medusaDebounce=false, medusaCounterEnabled=false,
	dropBrainrotActive=false, autoPlayEnabled=false, autoPlaySide="right",
	_tpInProgress=false, lastMoveDir=Vector3.new(0,0,0),
	animEnabled=false, unwalkEnabled=false, hitboxEnabled=false,
	darkModeEnabled=false, removeAccEnabled=false, menuScale=0.75,
	autoTPDownEnabled=false, jumpThreshold=2, jumpCounter=0,
	hardHitEnabled=false, hardHitRadius=10, batRadius=20,
	antiLagEnabled=true, ultraModeEnabled=false,
	espEnabled=false, tracerEnabled=false,
	noCamCollisionEnabled=false,
	
	aimBypassToggled=false,
	antiTpDownToggled=false,
	antiTpDownSpeed=55,
	
	-- NEW: Mobile Button Scale
	mobileBtnScale=1.0,
	mobileBtnSquare=false,
	mobileBtnBox=false,
	autoSwitchSpeed=false,
	ragdollTracking={},
}
local Keys = {
	autoBat=Enum.KeyCode.E, speed=Enum.KeyCode.Q, lagger=Enum.KeyCode.C,
	guiHide=Enum.KeyCode.LeftControl, autoPlay=Enum.KeyCode.L,
	dropBrainrot=Enum.KeyCode.H, tpDown=Enum.KeyCode.T,
}
local GPKeys = {
	autoBat=Enum.KeyCode.ButtonR2, speed=Enum.KeyCode.ButtonL2, lagger=Enum.KeyCode.ButtonL1,
	autoPlay=Enum.KeyCode.ButtonR1, tpDown=Enum.KeyCode.ButtonB,
	dropBrainrot=Enum.KeyCode.ButtonX, guiHide=Enum.KeyCode.ButtonSelect,
}
-- ============================================================
-- VARIABLES PRINCIPALES
-- ============================================================
local AutoSteal = {
    Enabled = false,
    EnabledV2 = false,
    IsStealing = false,
    Radius = 61,
    Duration = 1.3,
    HalfHoldMin = 1.3,
    HalfFireRange = 9,
    HalfHoldMax = 2.99,
    HalfEntryDelay = 0.25,
    V2HoldPercent = 0.75,
    V2WaitTimeout = 2.0,
    V2FireRange = 10,
    
    Data = {},
    ProgressFill = nil,
    PctLabel = nil,
    Waiting = false,
    StatusLabel = nil
}

-- AUTO SAVE / LOAD CONFIG
local SAVE_FILE = "SLAXERPrimeV2_Config.json"
local UserPanels = {}
function loadAllConfig()
    local ok, result = pcall(function()
        if not (isfile and isfile(SAVE_FILE) and readfile) then return nil end
        return HttpService:JSONDecode(readfile(SAVE_FILE))
    end)
    if ok and type(result) == "table" then return result end
    return nil
end
local _loadedConfig = loadAllConfig()

local isStealing = false
local autoGrabSetDelayRadius = 9
local autoGrabStopTime = 0.96
local autoGrabStopEnabled = true

local autoStealConnection = nil

local progressRadLbl = nil

-- ============================================================
-- VARIABLES DE ESCALA
-- ============================================================
local currentScale = 1.0
local mainFrame = nil
local mainFrameObjects = {}

-- ============================================================
-- FUNCIONES UTILITY
-- ============================================================
function isMyPlotByName(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

function findNearestPrompt()
    local char = LP.Character
    if not char then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil, nil end

    local nearestPrompt, nearestDist, nearestName = nil, math.huge, nil

    for _, plot in ipairs(plots:GetChildren()) do
        if not isMyPlotByName(plot.Name) then
        local pods = plot:FindFirstChild("AnimalPodiums")
        if pods then
        for _, pod in ipairs(pods:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - root.Position).Magnitude
                    if dist < nearestDist and dist <= AutoSteal.Radius then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, child in ipairs(att:GetChildren()) do
                                if child:IsA("ProximityPrompt") and child.ActionText and child.ActionText:lower():find("steal") then
                                    nearestPrompt = child
                                    nearestDist = dist
                                    nearestName = pod.Name
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
        end
        end
    end

    return nearestPrompt, nearestName
end

-- ============================================================
-- EXECUTE STEAL
-- ============================================================
function executeSteal(prompt, podName)
    if isStealing then return end

    if not AutoSteal.Data[prompt] then
        AutoSteal.Data[prompt] = { hold = {}, trigger = {}, ready = true }
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(AutoSteal.Data[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(AutoSteal.Data[prompt].trigger, c.Function) end
                end
            end
        end)
    end

    local data = AutoSteal.Data[prompt]
    if not data.ready then return end
    data.ready = false
    isStealing = true
    AutoSteal.IsStealing = true
    AutoSteal.Waiting = false
    stealStartTime = tick()
    if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "STEALING" end

    if AutoSteal.ProgressFill then
        AutoSteal.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    end
    if AutoSteal.PctLabel then
        AutoSteal.PctLabel.Text = "0%"
    end

    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end

        local startTime = tick()
        local duration = AutoSteal.Duration
        local promptFired = false

        if autoGrabStopEnabled then
            while isStealing and AutoSteal.Enabled do
                local elapsed = tick() - startTime
                if elapsed >= autoGrabStopTime then break end
                if AutoSteal.ProgressFill then
                    AutoSteal.ProgressFill.Size = UDim2.new(math.clamp(elapsed / duration, 0, 1), 0, 1, 0)
                end
                if AutoSteal.PctLabel then
                    AutoSteal.PctLabel.Text = math.floor(math.clamp(elapsed / duration, 0, 1) * 100) .. "%"
                end
                if not prompt.Parent or not prompt.Parent.Parent then break end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - prompt.Parent.Parent.Position).Magnitude > AutoSteal.Radius then
                    break
                end
                task.wait()
            end

            local stopProgress = math.clamp(autoGrabStopTime / duration, 0, 1)
            if AutoSteal.ProgressFill then
                AutoSteal.ProgressFill.Size = UDim2.new(stopProgress, 0, 1, 0)
            end
            if AutoSteal.PctLabel then
                AutoSteal.PctLabel.Text = math.floor(stopProgress * 100) .. "%"
            end

            local phase2Timeout = math.max(2.99 - autoGrabStopTime - math.max(duration - autoGrabStopTime, 0), 0.05)
            local phase2Start = tick()
            AutoSteal.Waiting = true
            if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "WAITING" end
            if AutoSteal.PctLabel then
                AutoSteal.PctLabel.Text = math.floor(stopProgress * 100) .. "% WAIT"
            end

            while isStealing and AutoSteal.Enabled do
                if tick() - phase2Start >= phase2Timeout then
                    if AutoSteal.ProgressFill then AutoSteal.ProgressFill.Size = UDim2.new(0, 0, 1, 0) end
                    if AutoSteal.PctLabel then AutoSteal.PctLabel.Text = "0%" end
                    data.ready = true
                    isStealing = false
        AutoSteal.IsStealing = false
                    task.wait()
                    local newPrompt, newName = findNearestPrompt()
                    if newPrompt then executeSteal(newPrompt, newName) end
                    return
                end
                if not prompt.Parent or not prompt.Parent.Parent then
                    isStealing = false
        AutoSteal.IsStealing = false
                    if AutoSteal.ProgressFill then AutoSteal.ProgressFill.Size = UDim2.new(0, 0, 1, 0) end
                    if AutoSteal.PctLabel then AutoSteal.PctLabel.Text = "0%" end
                    data.ready = true
                    return
                end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - prompt.Parent.Parent.Position).Magnitude
                    if dist <= autoGrabSetDelayRadius then
                        break
                    elseif dist > AutoSteal.Radius then
                        isStealing = false
        AutoSteal.IsStealing = false
                        if AutoSteal.ProgressFill then AutoSteal.ProgressFill.Size = UDim2.new(0, 0, 1, 0) end
                        if AutoSteal.PctLabel then AutoSteal.PctLabel.Text = "0%" end
                        data.ready = true
                        return
                    end
                end
                task.wait()
            end

            if isStealing and AutoSteal.Enabled then
                local fillStart = tick()
                local fillDuration = math.max(duration - autoGrabStopTime, 0.05)
                while true do
                    local fp = math.clamp((tick() - fillStart) / fillDuration, 0, 1)
                    if AutoSteal.ProgressFill then
                        AutoSteal.ProgressFill.Size = UDim2.new(stopProgress + fp * (1 - stopProgress), 0, 1, 0)
                    end
                    if AutoSteal.PctLabel then
                        AutoSteal.PctLabel.Text = math.floor((stopProgress + fp * (1 - stopProgress)) * 100) .. "%"
                    end
                    if fp >= 1 and not promptFired then
                        promptFired = true
                        pcall(function()
                            for _, f in ipairs(data.trigger) do task.spawn(f) end
                            local remote = ReplicatedStorage:FindFirstChild("StealAnimal")
                            if remote and podName then
                                remote:FireServer(podName)
                            end
                            if prompt then
                                prompt:Fire()
                            end
                        end)
                        break
                    end
                    task.wait()
                end
            end
        else
            while isStealing and AutoSteal.Enabled do
                local elapsed = tick() - startTime
                local progress = math.clamp(elapsed / duration, 0, 1)
                if AutoSteal.ProgressFill then AutoSteal.ProgressFill.Size = UDim2.new(progress, 0, 1, 0) end
                if AutoSteal.PctLabel then AutoSteal.PctLabel.Text = math.floor(progress * 100) .. "%" end
                if not prompt.Parent or not prompt.Parent.Parent then break end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - prompt.Parent.Parent.Position).Magnitude > AutoSteal.Radius then
                    break
                end
                if elapsed >= duration and not promptFired then
                    promptFired = true
                    pcall(function()
                        for _, f in ipairs(data.trigger) do task.spawn(f) end
                        local remote = ReplicatedStorage:FindFirstChild("StealAnimal")
                        if remote and podName then remote:FireServer(podName) end
                        if prompt then prompt:Fire() end
                    end)
                    break
                end
                task.wait()
            end
        end

        if AutoSteal.ProgressFill then AutoSteal.ProgressFill.Size = UDim2.new(0, 0, 1, 0) end
        if AutoSteal.PctLabel then AutoSteal.PctLabel.Text = "0%" end
        data.ready = true
        isStealing = false
        AutoSteal.IsStealing = false
        AutoSteal.Waiting = false
        stealStartTime = nil
        if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "READY" end
    end)
end

-- ============================================================
-- START / STOP AUTO STEAL
-- ============================================================
function startAutoSteal()
    if autoStealConnection then return end
    autoStealConnection = RunService.Heartbeat:Connect(function()
        if not AutoSteal.Enabled or isStealing then return end
        local p, n = findNearestPrompt()
        if p then executeSteal(p, n) end
    end)
end

function stopAutoSteal()
    if autoStealConnection then
        autoStealConnection:Disconnect()
        autoStealConnection = nil
    end
    isStealing = false
    AutoSteal.IsStealing = false
    AutoSteal.Waiting = false
    stealStartTime = nil
    if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "READY" end
    if AutoSteal.ProgressFill then
        TS:Create(AutoSteal.ProgressFill, TweenInfo.new(0.2), { Size = UDim2.new(0, 0, 1, 0) }):Play()
    end
    if AutoSteal.PctLabel then AutoSteal.PctLabel.Text = "0%" end
end


-- ============================================================
-- AUTO STEAL V2 (FTX Auto Steal V3 logic)
-- 1) Hold callbacks for holdMin
-- 2) Park progress at ~75%
-- 3) Wait up to 2s for player to enter fire range, then trigger
-- 4) If timeout, briefly reset and stay on same target
-- Exclusive with V1.
-- ============================================================
local autoStealV2Connection = nil
local v2IsStealing = false
local v2VisualProgress = 0

function stopAutoStealV2()
    AutoSteal.EnabledV2 = false
    v2IsStealing = false
    v2VisualProgress = 0
    if autoStealV2Connection then
        pcall(function() autoStealV2Connection:Disconnect() end)
        autoStealV2Connection = nil
    end
    if AutoSteal.ProgressFill then
        pcall(function()
            AutoSteal.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
        end)
    end
    if AutoSteal.PctLabel then AutoSteal.PctLabel.Text = "0%" end
    if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "READY" end
end

function startAutoStealV2()
    if autoStealV2Connection then return end
    -- turn off V1
    if AutoSteal.Enabled then
        AutoSteal.Enabled = false
        pcall(stopAutoSteal)
        if setInstaGrab then pcall(setInstaGrab, false) end
    end
    AutoSteal.EnabledV2 = true
    v2VisualProgress = 0
    if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "V2 READY" end

    autoStealV2Connection = RunService.Heartbeat:Connect(function()
        if not AutoSteal.EnabledV2 or v2IsStealing then return end
        local prompt, podName = findNearestPrompt()
        if not prompt then return end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local spawn = prompt.Parent and prompt.Parent.Parent
        if not spawn then return end
        local dist = (hrp.Position - spawn.Position).Magnitude
        if dist > AutoSteal.Radius then return end

        v2IsStealing = true
        AutoSteal.IsStealing = true
        AutoSteal.Waiting = false
        if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "V2 HOLD" end

        task.spawn(function()
            -- build callbacks once
            if not AutoSteal.Data[prompt] then
                AutoSteal.Data[prompt] = { hold = {}, trigger = {}, ready = true }
                pcall(function()
                    if getconnections then
                        for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                            if c.Function then table.insert(AutoSteal.Data[prompt].hold, c.Function) end
                        end
                        for _, c in ipairs(getconnections(prompt.Triggered)) do
                            if c.Function then table.insert(AutoSteal.Data[prompt].trigger, c.Function) end
                        end
                    end
                end)
            end
            local data = AutoSteal.Data[prompt]
            if not data or not data.ready then
                v2IsStealing = false
                AutoSteal.IsStealing = false
                return
            end
            data.ready = false

            local holdMin = math.max(AutoSteal.HalfHoldMin or AutoSteal.Duration or 1.3, 0.4)
            local holdPercent = math.clamp(AutoSteal.V2HoldPercent or 0.75, 0.20, 0.75)
            local fireRange = AutoSteal.V2FireRange or AutoSteal.HalfFireRange or 10
            local primeRange = AutoSteal.Radius or 61
            local waitTimeout = AutoSteal.V2WaitTimeout or 2.0

            local function currentDist()
                local ch = LP.Character
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                if not root or not spawn or not spawn.Parent then return math.huge end
                return (root.Position - spawn.Position).Magnitude
            end

            local function setV2Progress(p)
                v2VisualProgress = math.clamp(p, 0, 1)
                if AutoSteal.ProgressFill then
                    AutoSteal.ProgressFill.Size = UDim2.new(v2VisualProgress, 0, 1, 0)
                end
                if AutoSteal.PctLabel then
                    AutoSteal.PctLabel.Text = math.floor(v2VisualProgress * 100) .. "%"
                end
            end

            -- Phase 1: fire hold callbacks and hold for holdMin
            for _, f in ipairs(data.hold) do
                task.spawn(function() pcall(f) end)
            end
            local holdStart = tick()
            local aborted = false
            while AutoSteal.EnabledV2 and (tick() - holdStart) < holdMin do
                if not prompt.Parent then aborted = true; break end
                if currentDist() > primeRange then aborted = true; break end
                local t = math.clamp((tick() - holdStart) / holdMin, 0, 1)
                setV2Progress(t * holdPercent)
                task.wait()
            end

            if aborted or not AutoSteal.EnabledV2 then
                data.ready = true
                v2IsStealing = false
                AutoSteal.IsStealing = false
                AutoSteal.Waiting = false
                setV2Progress(0)
                if AutoSteal.EnabledV2 and AutoSteal.StatusLabel then
                    AutoSteal.StatusLabel.Text = "V2 READY"
                end
                return
            end

            -- Phase 2: FTX V3 style — park at holdPercent, wait for close range, fire
            AutoSteal.Waiting = true
            if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "V2 WAIT" end
            local fired = false

            while AutoSteal.EnabledV2 and prompt.Parent do
                if currentDist() > primeRange then break end

                setV2Progress(holdPercent)
                local waitStart = tick()
                while AutoSteal.EnabledV2 and prompt.Parent and (tick() - waitStart) < waitTimeout do
                    local d = currentDist()
                    if d > primeRange then break end
                    if d <= fireRange then
                        pcall(function()
                            for _, f in ipairs(data.trigger) do
                                task.spawn(function() pcall(f) end)
                            end
                            local rs = game:GetService("ReplicatedStorage")
                            local remote = rs:FindFirstChild("StealAnimal")
                            if remote and podName then
                                pcall(function() remote:FireServer(podName) end)
                            end
                            if prompt and prompt.Fire then
                                pcall(function() prompt:Fire() end)
                            end
                        end)
                        fired = true
                        setV2Progress(1)
                        if AutoSteal.StatusLabel then AutoSteal.StatusLabel.Text = "V2 FIRED" end
                        break
                    end
                    task.wait()
                end

                if fired then break end
                -- timeout: briefly reset then re-park at holdPercent (FTX V3 behavior)
                setV2Progress(0)
                task.wait(0.05)
            end

            if fired then
                task.wait(0.15)
            end
            setV2Progress(0)
            data.ready = true
            v2IsStealing = false
            AutoSteal.IsStealing = false
            AutoSteal.Waiting = false
            if AutoSteal.EnabledV2 and AutoSteal.StatusLabel then
                AutoSteal.StatusLabel.Text = "V2 READY"
            end
            task.wait(0.08)
        end)
    end)
end


local DROP_ASCEND_DURATION=0.2; local DROP_ASCEND_SPEED=150
local POS={L1=Vector3.new(-476.48,-6.28,92.73),L2=Vector3.new(-483.12,-4.95,94.80),R1=Vector3.new(-476.16,-6.52,25.62),R2=Vector3.new(-483.04,-5.09,23.14)}
local Conns={autoSteal=nil,antiRag=nil,autoPlay=nil,anchor={},progress=nil,aimbot=nil,aimBypass=nil,antiCrash=nil}
local _anyKeyListening=false

local C_BG=Color3.fromRGB(7,7,7); local C_PANEL=Color3.fromRGB(14,14,14); local C_CARD=Color3.fromRGB(24,24,24)
local C_CARD_HOV=Color3.fromRGB(55,8,8); local C_BORDER=Color3.fromRGB(205,18,18); local C_BORDER2=Color3.fromRGB(120,10,10)
local C_TEXT=Color3.fromRGB(245,245,245); local C_TEXT_SUB=Color3.fromRGB(220,220,220); local C_TEXT_DIM=Color3.fromRGB(145,145,145)
local C_ACCENT=Color3.fromRGB(235,25,25); local C_HEADER=Color3.fromRGB(10,10,10)
local C_OFF_BG=Color3.fromRGB(18,18,18); local C_KB_BG=Color3.fromRGB(20,20,20); local C_INPUT_BG=Color3.fromRGB(16,16,16)
local C_TOGGLE_ON=Color3.fromRGB(220,18,18); local C_SIDEBAR=Color3.fromRGB(11,11,11); local C_TAB_ACT=Color3.fromRGB(190,15,15)
local C_TAB_IDL=Color3.fromRGB(22,22,22); local C_WHITE=Color3.fromRGB(255,255,255); local C_DIM=Color3.fromRGB(120,120,120)
local C_BTN_ON=Color3.fromRGB(215,18,18); local C_BTN_ON_TEXT=Color3.fromRGB(255,255,255)

local normalBox,carryBox,laggerBox,carryLaggerBox
local setSpeedToggleUI,setLaggerToggleUI,modeValLbl
local setAutoBat,setAutoSwingUI,setInstaGrab,setAutoStealV2,setInfJump,setAntiRag,setAntiDie,setFps
local setMedusaCounter,setAnimToggle,setUnwalkToggle,setHitbox
local setDarkModeUI,setRemoveAccUI,setDetachVisual
local setAutoPlayUI; local progressRadLbl,radiusBoxRef
local h,hrp
local startAutoPlay,stopAutoPlay; local setupMedusaCounter,stopMedusaCounter
local startAntiRagdoll,stopAntiRagdoll,startAntiDie,stopAntiDie; local applyFPSBoost
local animHeartbeatConn,savedAnimate,originalAnims

local setAutoTPDownUI
local setHardHitUI,setAntiLagUI,setUltraModeUI,setESPUI,setTracerUI,setNoCamUI
local setAimBypassUI
local _updateMobileScaleUI
local setInfJumpModeUI
local _mainFrame,_miniFrame,_comboFrame
local _mbBtnRefs={}
local _mbBtnSetters={}
local _mbBtnPositions={}


local _defBrightness=game:GetService("Lighting").Brightness; local _defClockTime=game:GetService("Lighting").ClockTime
local _defOutdoorAmb=game:GetService("Lighting").OutdoorAmbient; local _defExposure=game:GetService("Lighting").ExposureCompensation

function applyDarkMode()
	local L=game:GetService("Lighting"); local sky=L:FindFirstChild("slaxerDarkSky") or Instance.new("Sky")
	sky.Name="slaxerDarkSky"; sky.SkyboxBk="rbxassetid://159454299"; sky.SkyboxDn="rbxassetid://159454296"; sky.SkyboxFt="rbxassetid://159454293"; sky.SkyboxLf="rbxassetid://159454286"; sky.SkyboxRt="rbxassetid://159454289"; sky.SkyboxUp="rbxassetid://159454291"; sky.Parent=L
	L.Brightness=0; L.ClockTime=0; L.ExposureCompensation=-2; L.OutdoorAmbient=Color3.fromRGB(0,0,0)
end
function removeDarkMode()
	local L=game:GetService("Lighting"); local s=L:FindFirstChild("slaxerDarkSky"); if s then s:Destroy() end
	L.Brightness=_defBrightness; L.ClockTime=_defClockTime; L.ExposureCompensation=_defExposure; L.OutdoorAmbient=_defOutdoorAmb
end
local accConns={}
function removeAccsFromChar(char) if not char then return end; for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Accessory") or obj:IsA("Hat") then pcall(function() obj:Destroy() end) end end end
function startRemoveAccs()
	for _,p in ipairs(Players:GetPlayers()) do removeAccsFromChar(p.Character) end
	table.insert(accConns,Players.PlayerAdded:Connect(function(p) table.insert(accConns,p.CharacterAdded:Connect(function(char) task.wait(0.5); if State.removeAccEnabled then removeAccsFromChar(char) end end)) end))
	for _,p in ipairs(Players:GetPlayers()) do table.insert(accConns,p.CharacterAdded:Connect(function(char) task.wait(0.5); if State.removeAccEnabled then removeAccsFromChar(char) end end)) end
end
function stopRemoveAccs() for _,c in ipairs(accConns) do pcall(function() c:Disconnect() end) end; accConns={} end

local _hardHitRing=nil
function showHardHitRing()
	local char=LP.Character; if not char then return end; local hrp2=char:FindFirstChild("HumanoidRootPart"); if not hrp2 then return end
	if _hardHitRing and _hardHitRing.Parent then return end
	local cyl=Instance.new("CylinderHandleAdornment"); cyl.Name="SLAXERHardHitRing"; cyl.Adornee=hrp2; cyl.Color3=Color3.fromRGB(220,20,20); cyl.AlwaysOnTop=true; cyl.Transparency=0
	cyl.Radius=State.hardHitRadius; cyl.InnerRadius=State.hardHitRadius-0.3; cyl.Height=0.15; cyl.CFrame=CFrame.new(0,-3,0); cyl.Parent=hrp2; _hardHitRing=cyl
end
function hideHardHitRing() if _hardHitRing then pcall(function() _hardHitRing:Destroy() end); _hardHitRing=nil end end
local _hardHitConn=nil
function startHardHit()
	if _hardHitConn then return end
	_hardHitConn=RunService.Heartbeat:Connect(function()
		if not State.hardHitEnabled then return end; local char=LP.Character; if not char then return end; local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
		if not _hardHitRing or not _hardHitRing.Parent then showHardHitRing() end
		if _hardHitRing then _hardHitRing.Radius=State.hardHitRadius; _hardHitRing.InnerRadius=State.hardHitRadius-0.3 end
	end)
end
function stopHardHit() if _hardHitConn then _hardHitConn:Disconnect(); _hardHitConn=nil end; hideHardHitRing() end

local _antiLagDescConn=nil
function applyAntiLag(ultra)
	local L=game:GetService("Lighting"); L.GlobalShadows=false; L.FogEnd=1e10; L.Brightness=1; L.EnvironmentDiffuseScale=0; L.EnvironmentSpecularScale=0
	for _,e in pairs(L:GetC
