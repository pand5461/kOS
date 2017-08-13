function AlignToSun {
  lock steering to lookdirup(V(0,1,0),Sun:position).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
}

function waitconnect {
  if not addons:rt:haskscconnection(ship) {
    set warp to 0.
    wait 10.
    set warp to 3.
    wait until addons:rt:haskscconnection(ship).
    set warp to 0.
  }
}

function satprogram {
  if satmode = 0 {
    require("Dockee","launch-incl.ks").
    gettoorbit(Hsat,21.5,550,55000).
    deletepath("launch-incl.ks").
    wait 5.
    nextmode().
  }
  if satmode = 1 {
    print "Aligning for optimal solar panel performance.".
    waitconnect().
    nextmode().
  }
  if satmode = 2 {
    require("liborbital","aponode.ks").
    aponode(Hsat).
    deletepath("aponode.ks").
    nextmode().
  }
  if satmode = 3 {
    require("liborbital","exenode.ks").
    exenode().
    nextmode().
  }  
  if satmode = 4 {
    require("liborbital","circularize.ks").
    circularize().
    deletepath("circularize.ks").
    nextmode().
  }
  AlignToSun().
  wait until ship:elements:length>1.
  unlock steering.
  wait until ship:elements:length=1.
  reboot.
}

local satmode to 0.
local Hsat to 90000.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).
satprogram().
