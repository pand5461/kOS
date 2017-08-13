require("liborbital","circularize.ks").

function runfiles {
  parameter fl.
  for f in fl if exists(f) runpath(f).
}

function AlignToSun {
  lock steering to lookdirup(V(0,1,0),Sun:position)+R(0,0,90).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
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

function satprogram {
  runfiles(list("exenode.ks","aponode.ks")).
   
  local ti to 0.
  local tlan to 0.
  if hastarget {
    set ti to target:orbit:inclination.
    set tlan to target:orbit:lan.
  }
  
  print "Starting program in mode " + satmode.
  if satmode = 0 {
    require("KOT/D","launch-inclan.ks").
    local Hsat to 75000.
    LVprogram(Hsat,ti,tlan,2*alt:radar,57500,575).
    deletepath("launch-inclan.ks").
    nextmode().
  }
  if satmode = 1 {
    startnextstage().
    wait 1.
    circularize().
    nextmode().
  }
  if satmode = 2 {
    clearscreen.
    print "Desired inclination: " + round(ti,2) at (0,1).
    print "Reached inclination: " + round(orbit:inclination,2) at (0,2).
    print "Desired LAN: " + round(tlan,2) at (30,1).
    print "Reached LAN: " + round(orbit:lan,2) at (30,2).
    nextmode().
  }
  if satmode = 3 {
    AlignToSun().
    wait until hastarget.
    transferto(target).
    nextmode().
  }
  if satmode = 4 {
    exenode().
    nextmode().
  }
  if satmode = 5 {
    aponode().
    nextmode().
  }
  if satmode = 6 {
    exenode().
    nextmode(9).
  }
  if satmode = 7 {
    print "Manual control on".
    unlock steering.
    unlock throttle.
    wait until not gear.
    print "Manual control off".
    nextmode(9).
  }
  if satmode = 8 {
    AlignToSun().
    wait until altitude-body:atm:height < 100.
    kuniverse:timewarp:cancelwarp..
    wait until kuniverse:timewarp:issettled.
    stage.
    wait 2.
    lock steering to srfretrograde.
    wait until altitude < 45000.
    unlock steering.
    wait until altitude < 6000 and velocity:surface:mag < 250.
    stage.
    wait until status="landed" or status="splashed".
    return.
  }
  print "Aligning for optimal solar panel performance".
  AlignToSun().
  wait until false.
}

local satmode to 0.
local LVmode to 0.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).

when satmode <> 7 and gear then {
  nextmode(7).
  reboot.
}

when satmode <> 8 and brakes then {
  nextmode(8).
  reboot.
}

satprogram().
