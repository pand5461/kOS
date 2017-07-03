require("libwarp","warpfor.ks").

function AlignToSun {
  lock steering to lookdirup(Sun:position,north:vector).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
}

function waitwindow {
  parameter Horb.
  
  local lngdiff to ship:longitude + 90 - Mun:longitude.
  
  local a1 to (Mun:apoapsis + Horb)/2 + body:radius.
  local t12 to constant:pi*sqrt(a1^3/body:mu).
  
  local phitrans to 180*(2*t12/Mun:orbit:period - 1).
  local omegaeff to 360*(1/body:rotationperiod - 1/Mun:orbit:period).
  local etatrans to (phitrans - lngdiff)/omegaeff - constant:pi/2*sqrt((body:radius + Horb)^3/body:mu) - 120.
  if etatrans < 0 set etatrans to etatrans + 360/omegaeff.

  wait until kuniverse:timewarp:issettled.
  set kuniverse:timewarp:mode to "rails".
  warpfor(etatrans).
}

function satprogram {
  if satmode = 0 {
    local Hb to 75000.
    waitwindow(Hb).
    require("Moona/1","launch.ks").
    gettoorbit(Hb,600).
    startnextstage().
    deletepath("launch.ks").
    deletepath("warpheight.ks").
    panels on.
    wait 20.
    nextmode().
  }
  if satmode = 1 {
    require("Moona/1","mode1.ks").
    nextmode().
  }
  if satmode = 2 {
    deletepath("mode1.ks").
    require("liborbital","exenode.ks").
    exenode().
    nextmode().
  }
  if satmode = 3 {
    set dish to ship:partsnamed("HighGainAntenna5")[0].
    set d to dish:getmodule("ModuleRTAntenna").
    d:doevent("activate").
    d:setfield("target", Kerbin).
    nextmode().
  }
  until false AlignToSun().
}

local satmode to 0.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).
satprogram().
