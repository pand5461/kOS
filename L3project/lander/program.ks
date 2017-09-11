require("liborbital","exenode.ks").

function AlignToSun {
  if status = "landed" lock steering to lookdirup(-body:position, facing:upvector).
  else lock steering to lookdirup(Sun:position, -body:position).
}

function runfiles {
  parameter fl.
  for f in fl if exists(f) runpath(f).
}

function nextmode {
  parameter newmode is mode+1.
  set mode to newmode.
  deletepath("mode.ks").
  log "set mode to " + newmode + "." to "mode.ks".
  if mode > 4 and mode < 19 and ship:elements:length = 1 aligntosun().
}

function OrbAngTo {
  parameter pos.
  local nvec to vcrs( body:position, velocity:orbit ):normalized.
  local proj to vxcl(nvec, pos - body:position).
  local angl to arctan2( vdot(nvec, vcrs(body:position, proj)), -vdot(body:position, proj) ).
  if angl < 0 set angl to 360 + angl.
  
  return angl.
}

function transferto {
  parameter tgt.
  parameter phitotgt is 0.
  
  local newsma to tgt:orbit:semimajoraxis.
  local r0 to orbit:semimajoraxis.
  local v0 to velocity:orbit:mag.
  
  local a1 to (newsma + r0)/2.
  local Vpe to sqrt( body:mu*(2/r0 - 1/a1) ).
  local deltav to Vpe - v0.
  
  local t12 to constant:pi*(a1^3/body:mu)^0.5.
  local tomega to 360/tgt:orbit:period.
  local phitrans to phitotgt - tomega*t12 + 180.
  until phitrans>=0 set phitrans to phitrans + 360.
  
  local phinow to orbangto(tgt:position).

  local omegaeff to 360/orbit:period - tomega.
  local etatrans to (phinow - phitrans) / omegaeff.
  if etatrans < (deltav*mass/ship:availablethrust + 5) { set etatrans to etatrans + 360/abs(omegaeff). }
  
  print "Current phase angle: " + round(phinow) + "; ".
  print "Needed phase angle: " + round(phitrans) + "; ".
  print "Transfer burn: " + round(v0) + " -> " + round(Vpe) + "m/s".
  set nd to node(time:seconds + etatrans, 0, 0, deltav).
  add nd.
}

function landprogram {
  runfiles(list("L3/lander/landing1.ks","liborbital/exenode.ks","liborbital/aponode.ks","liborbital/circularize.ks")).
  local dprt to ship:partstagged("landerPort")[0].
  if mode = 0 {
    require("L3/lander","landing1.ks").
    wait until not core:messages:empty.
    local msg to core:messages:pop().
    wait 0.2.
    nextmode().
  }
  if mode = 1 {
    dprt:getmodule("ModuleDockingNode"):doevent("decouple node").
    wait 0.1.
    lock steering to "kill".
    wait 0.2.
    nextmode().
  }
  if mode = 2 {
    wait 1.
    set ship:name to "MunKraft1".
    ship:partsnamed("RTShortAntenna1")[0]:getmodule("ModuleRTAntenna"):doevent("activate").
    for res in ship:partsnamed("landerCabinSmall")[0]:resources { set res:enabled to true. }
    nextmode().
  }
  local mship to vessel("7K-LOK").
  if mode = 3 {
    lock steering to lookdirup(mship:position, Sun:position).
    wait until dprt:state <> "Ready".
    unlock steering.
    nextmode().
  }
  if mode = 4 {  
    wait until ship:elements:length = 1 and ship:crew:length = 1.
    nextmode().
  }
  if mode = 5 {
    wait 10.
    list engines in el.
    for e in el if e:ignition set e:thrustlimit to 100*2.5*mass*body:mu/(body:radius^2*ship:maxthrust).
    nextmode().
  }
  if mode = 6 {
    landing(latlng(2.3934, 81.703), 0.85, 8, 320).
    deletepath("L3/lander/landing1.ks").
    nextmode().
  }
  if mode = 7 {
    lock steering to lookdirup(-body:position, facing:upvector).
    local amdl to ship:partstagged("landerAntenna")[0]:getmodule("ModuleRTAntenna").
    amdl:doevent("activate").
    amdl:setfield("target", Kerbin).
    nextmode().
  }
  lock steering to lookdirup(-body:position, facing:upvector).
  if mode = 8 {
    ship:partsnamed("liquidEngineMini")[0]:shutdown.
    set ship:partsnamed("liquidEngineMini")[0]:thrustlimit to 30.
    until ship:crew:length < ship:crewcapacity {
      hudtext("Waiting for crew EVA",1,2,18,YELLOW,True).
      wait 2.
    }
    nextmode().
  }
  if mode = 9 {
    wait until ship:crew:length = ship:crewcapacity.
    nextmode().
  }
  if mode = 10 {
    brakes off.
    wait 0.5.
    until brakes {
      hudtext("Activate Brakes group when you're ready for takeoff",1,2,18,YELLOW,True).
      wait 2.
    }
    nextmode().
  }
  if mode = 11 {
    require("L3/lander","launch.ks").
    local lngdiff to mship:longitude - ship:longitude + 4.
    until lngdiff > 0 {
      set lngdiff to 360 + lngdiff.
    }
    local omegaeff to 360/mship:orbit:period + 360/body:rotationperiod.
    warpfor(lngdiff / omegaeff).
    brakes off.
    gettoorbit().
    nextmode().
  }
  deletepath("L3/lander/launch.ks").
  if mode = 12 {
    require("L3","flttraj.ks").
    deletepath("L3/flttraj.ks").
    nextmode().
  }
  if mode = 13 {
    exenode().
    nextmode().
  }
  if mode = 14 {
    transferto(mship).
    nextmode().
  }
  if mode = 15 {
    exenode().
    nextmode().
  }
  if mode = 16 {
    aponode().
    nextmode().
  }
  if mode = 17 {
    exenode().
    nextmode().
  }
  if mode = 18 {
    local conn to mship:connection.
    conn:sendmessage("Rendezvous").
    nextmode().
  }
  if mode = 19 {
    rcs on.
    lights on.
    lock steering to lookdirup(mship:position, Sun:position).
    wait until dprt:state <> "Ready".
    unlock steering.
    rcs off.
    nextmode().
  }
  wait until ship:elements:length = 1 and ship:crew:empty.
  rcs on.
  set ship:control:fore to -1.
  wait 2.
  set ship:control:translation to V(0,0,0).
  lock steering to retrograde.
  wait 10.
  set ship:control:fore to 1.
  lock throttle to 1.
  wait until false.
}

local mode to 0.
local lmode to 1.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).

landprogram().
