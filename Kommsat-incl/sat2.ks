function AlignToSun {
  lock steering to lookdirup(north:vector,Sun:position).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
}

function waitconnect {
  wait 15.
  set warp to 3.
  wait until addons:rt:haskscconnection(ship).
  set warp to 0.
}

function phase {
  parameter pos1, pos2.
  local p to arctan2( vcrs(pos1,pos2):y,vdot(pos1,pos2) ).
  if p<0 set p to 360+p.
  return p.
}

function satprogram {
  if satmode = 0 {
    require("Kommsat-incl","launch2.ks").
    startnextstage().
    deletepath("launch2.ks").
    panels on.
    wait 20.
    nextmode().
  }
  if satmode = 1 {
    print "Aligning for optimal solar panel performance.".
    waitconnect().
    nextmode().
  }
  if satmode = 2 {
    require("Kommsat-incl","mode2.ks").
    nextmode().
  }
  if satmode = 3 {
    deletepath("mode2.ks").
    exenode().
    nextmode().
  }
  if satmode = 4 {
    clearscreen.
    waitconnect().
    require("Kommsat-incl","fltper.ks").
    local dphi to phase(positionat(target,time:seconds+eta:apoapsis)-body:position,positionat(ship,time:seconds+eta:apoapsis)-body:position)-90.
    print "Phasing angle: "+round(dphi).
    fltper(target:orbit:period*(1-dphi/360)).
    nextmode().
  }
  if satmode = 5 {
    exenode().
    nextmode().
  }
  if satmode = 6 {
    fltper(target:orbit:period).
    deletepath("fltper.ks").
    nextmode().
  }
  if satmode = 7 {
    exenode().
    nextmode().
  }  
  if satmode = 8 {
    waitconnect().
    require("liborbital","circularize.ks").
    circularize().
    require("liborbital","trimperiod.ks").
    TrimPeriod(target:orbit:period).
    nextmode().
  }
  if satmode = 9 {
    set dish to ship:partsnamed("HighGainAntenna5")[0].
    set d to dish:getmodule("ModuleRTAntenna").
    d:doevent("activate").
    d:setfield("target", Mun).
    print "Satellite deployed to operational orbit.".
    nextmode().
  }  
  until false AlignToSun().
}

local satmode to 0.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).
satprogram().
