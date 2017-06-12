require("liborbital","circularize.ks").

function AlignToSun {
  lock steering to lookdirup(-Sun:position,Kerbin:position).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
}

function satprogram {
  local ti to 51.6.
  local tlan to 12.
  
  clearscreen.
  print "Desired inclination: " + round(ti,2).
  print "Desired LAN: " + round(tlan,2).
  if satmode = 0 {
    require("Mapsat-K","launch-inclan.ks").
    local Hsat to 80000.
    LVprogram(Hsat,ti,tlan,80,57500,575).
    nextmode().
  }
  if satmode = 1 {
    startnextstage().
    panels on.
    wait 5.
    circularize().
    nextmode().
  }

  clearscreen.
  print "Desired inclination: " + round(ti,2) at (0,1).
  print "Reached inclination: " + round(orbit:inclination,2) at (0,2).
  print "Desired LAN: " + round(tlan,2) at (30,1).
  print "Reached LAN: " + round(orbit:lan,2) at (30,2).
  until false AlignToSun().
}

local satmode to 0.
local Hsat to altitude.
local LVmode to 0.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).

satprogram().
