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
  runfiles(list("exenode.ks","polorb.ks","perinode.ks","aponode.ks")).
  local hmun to 35000.
  if satmode = 0 {
    local Hb to 75000.
    require("Moona/Pol","wait.ks").
    waitwindow(Hb).
    deletepath("wait.ks").
    require("Moona/Pol","launch.ks").
    gettoorbit(Hb,750).
    startnextstage().
    deletepath("launch.ks").
    deletepath("warpheight.ks").
    panels on.
    wait 20.
    nextmode().
  }
  if satmode = 1 {
    require("Moona/Pol","mode1.ks").
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
    require("Moona/Pol","polorb.ks").
    polorb(60).
    deletepath("polorb.ks").
    nextmode().
  }
  if satmode = 6 {
    exenode().
    nextmode().
  }
  if satmode = 7 {
    require("liborbital","perinode.ks").
    require("liborbital","aponode.ks").
    perinode(hmun).
    nextmode().
  }
  if satmode = 8 {
    exenode().
    nextmode().
  }
  if satmode = 9 {
    if abs(periapsis - hmun) < abs(apoapsis - hmun) perinode().
    else aponode().
    nextmode().
  }
  if satmode = 10 {
    exenode().
    nextmode().
  }
  until false AlignToSun().
}

local satmode to 0.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).
satprogram().
