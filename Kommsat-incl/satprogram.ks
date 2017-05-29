function AlignToSun {
  lock steering to lookdirup(north:vector,Sun:position) + R(0,0,90).
}

function aneta {
  local vecs to orbdir().
  local anangle to arctan2( vdot(vcrs(body:position, vecs:vector), vecs:upvector), -vdot(vecs:vector, body:position)).
  if anangle < 0 { set anangle to 360 + anangle. }
  return anangle / 360 * orbit:period.
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

function satprogram {
  if satmode = 0 {
    require("Kommsat-incl","launch.ks").
    gettoorbit().
    deletepath("launch.ks").
    startnextstage().
    circularize().
    deletepath("circularize.ks").
    wait 20.
    nextmode().
  }
  if satmode = 1 {
    print "Aligning for optimal solar panel performance.".
    waitconnect().
    nextmode().
  }
  if satmode = 2 {
    require("liborbital","orbdir.ks").
    require("Kommsat-incl","transfernode.ks").
    require("liborbital","exenode.ks").
    transfernode(7200, aneta).
    deletepath("transfernode.ks").
    deletepath("orbdir.ks").
    nextmode().
  }
  if satmode = 3 {
    exenode().
    nextmode().
  }
  if satmode = 4 {
    waitconnect().
    require("","crcfltdn.ks").
    deletepath("crcfltdn.ks").
    nextmode().
  }
  if satmode = 5 {
    exenode().
    nextmode().
  }
  if satmode = 6 {
    waitconnect().
    require("liborbital","circularize.ks").
    circularize().
    require("liborbital","trimperiod.ks").
    TrimPeriod(7200).
    nextmode().
  }
  if satmode = 7 {
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
