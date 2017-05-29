function AlignToSun {
  lock steering to lookdirup(-velocity:orbit,Sun:position) + R(0,0,225).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
}

function length {
  parameter lst.
  local n to 0.
  for i in lst set n to n+1.
  return n.
}
  
function satprogram {
  if satmode = 0 {
    require("KOT","launch.ks").
    gettoorbit(80000,100).
    deletepath("launch.ks").
    startnextstage().
    deletepath("circularize.ks").
    wait 20.
    nextmode().
  }
  require("KOT","orbprog.ks").
}

local satmode to 0.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).
satprogram().
