require("liborbital","circularize.ks").
require("libwarp","warpheight.ks").

function CapTWR {
  parameter maxTWR is 3.0.
  local g0 to 9.80665.
  lock throttle to min(1, ship:mass*g0*maxTWR / max(ship:availablethrust, 0.001) ).
}

function printtlm {
  local pitch to 90 - vang( up:vector, velocity:surface ).
  print "Apoapsis: " + round(apoapsis/1000, 2) + " km    " at (0,30).
  print "Periapsis: " + round(periapsis/1000, 2) + " km    " at (0,31).
  print " Altitude: " + round(altitude/1000, 2) + " km    " at (24,30).
  print " Pitch: " + round( pitch ) + " deg  " at (24,31).
}

function PitchCtrl {
  parameter vstart, h0, v45, Ap45, APstop is 60000.
  
  if alt:radar < h0 {return 90.}
  
  local vsm to velocity:surface:mag.
  local pitch to 0.
  if ( vsm < v45 ) {
    set pitch to 90 - arctan( (vsm - vstart)/(v45 - vstart) ).
  }
  else {
    set pitch to max(0, 45*(apoapsis - APstop) / (AP45 - APstop) ).
  }

  return pitch.
}
  
function startnextstage {
  until ship:availablethrust > 0 {
    if altitude<body:atm:height lock steering to srfprograde.
    wait 2.
    stage.
  }
}

function APkeep {
  parameter apw.
  local Kp to 200.
  if apoapsis > apw { lock throttle to 0. }
  else { lock throttle to max( 0.05, Kp*(apw - apoapsis)/apw ). }
  printtlm().
}

function gettoorbit {
  parameter Horb to body:atm:height + 10000.
  parameter GTv45 to 500.
  parameter GTstart to alt:radar*2.
  parameter GTendAP to 60000.
  
  local maxTWR to 3.0.
  lock throttle to 1.
  local initialpos to ship:facing.
  lock steering to initialpos.
  startnextstage().

  local vsm to velocity:surface:mag.
  local GTStartSpd to vsm.
  local Apo45 to apoapsis.

  until apoapsis >= Horb {
    set vsm to velocity:surface:mag.
    if vsm <= GTv45 { set Apo45 to apoapsis. }
    if alt:radar <= GTstart { set GTStartSpd to vsm. }

    lock steering to heading( 90,pitchctrl(GTStartSpd,GTstart,GTv45,Apo45,GTendAP) ).
    startnextstage().
    CapTWR(maxTWR).

    printtlm().
    wait 0.
  }
  
  lock throttle to 0.

  lock steering to prograde.
  set warp to 3.

  until altitude > body:atm:height { 
    APkeep(Horb).
    wait 0. 
  }
  set warp to 0.
  lock throttle to 0.
  print "We are in space. Deploying payload fairing. ".
  wait 5.
  stage.
  wait 5.
  
  warpheight(apoapsis - 10).
  circularize().
  
  print "We are in orbit: " + round(apoapsis/1000,2) + "x" + round(periapsis/1000,2) + " km. ".
  
  wait 5.
  
  local d to ship:partsnamed("HighGainAntenna5")[0]:getmodule("ModuleRTAntenna").
  d:doevent("activate").
  d:setfield("target","KSC Mission Control").
  
  print "Releasing payload.".
  lock steering to prograde.
  wait 5.
  stage.
}
