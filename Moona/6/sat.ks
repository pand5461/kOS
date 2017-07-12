function runfiles {
  parameter fl.
  for f in fl if exists(f) runpath(f).
}

function AlignToSun {
  lock steering to lookdirup(Sun:position,Kerbin:position).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
}

function satprogram {
  runfiles(list("warpfor.ks","exenode.ks","perinode.ks","aponode.ks","landing1.ks")).
  local hmun to 25500.
  if satmode = 0 {
    local Hb to 75000.
    require("Moona/5","wait.ks").
    waitwindow(Hb).
    deletepath("wait.ks").
    require("Moona/5","launch.ks").
    gettoorbit(Hb,650,55000).
    startnextstage().
    deletepath("launch.ks").
    deletepath("warpheight.ks").
    panels on.
    wait 20.
    nextmode().
  }
  if satmode = 1 {
    require("Moona/5","mode1.ks").
    nextmode().
  }
  if satmode = 2 {
    deletepath("mode1.ks").
    require("liborbital","exenode.ks").
    exenode().
    nextmode().
  }
  if satmode = 3 {
    ship:partsnamed("HighGainAntenna5")[0]:getmodule("ModuleRTAntenna"):setfield("target",Kerbin).
    nextmode().
  }
  if satmode = 4 {
    if body:name = "Kerbin" warpfor(eta:transition-60).
    wait until body:name = "Mun".
    nextmode().
  }
  if satmode = 5 {
    require("liborbital","perinode.ks").
    require("liborbital","aponode.ks").
    require("Moona/5","landing1.ks").
    perinode(hmun).
    nextmode().
  }
  if satmode = 6 {
    exenode().
    nextmode().
  }
  if satmode = 7 {
    if abs(periapsis - hmun) < abs(apoapsis - hmun) perinode().
    else aponode().
    nextmode().
  }
  if satmode = 8 {
    exenode().
    nextmode().
  }
  if satmode = 9 {
    deletepath("exenode.ks").
    deletepath("aponode.ks").
    deletepath("perinode.ks").
    
    local Isp to 315.
    local tmax to 0.9.

    if lmode = 0 nextlmode().
    landing(landsite, 0.85, 4.0, Isp).
    nextmode().
  }
  unlock steering.
  sas on.
  return.
}

local satmode to 0.
local lmode to 0.
if exists("lmode.ks") runpath("lmode.ks").
if exists("mode.ks") runpath("mode.ks").
else nextmode(0).
satprogram().
