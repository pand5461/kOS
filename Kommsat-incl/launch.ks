require("liborbital","circularize.ks").

function VertAscent {
  lock steering to heading(90,90).
}

function CapTWR {
  parameter maxTWR is 3.0.
  local g0 to Kerbin:mu/Kerbin:radius^2.
  lock throttle to min(1, ship:mass*g0*maxTWR / max( ship:availablethrust, 0.001 ) ).
}

function printtlm {
  local pitch to 90 - vang( up:vector, velocity:surface ).
  print "Apoapsis: " + round( apoapsis/1000, 2 ) + " km    " at (0,30).
  print "Periapsis: " + round( periapsis/1000, 2 ) + " km    " at (0,31).
  print " Altitude: " + round( altitude/1000, 2 ) + " km    " at (24,30).
  print " Pitch: " + round( pitch ) + " deg  " at (24,31).
}

function GravityTurn {
  parameter vstart.
  parameter AP45 is apoapsis.
  parameter APstop is 60000.
  parameter v45 is 500.
  
  local vsm to velocity:surface:mag.
  local pitch to 0.
  if ( vsm < v45 ) {
    set pitch to 90 - arctan( (vsm - vstart)/(v45 - vstart) ).
  }
  else {
    set pitch to max(0, 45*(apoapsis - APstop) / (AP45 - APstop) ).
  }
  lock steering to heading( 90, pitch ).
  printtlm().
}
  
function startnextstage {
  until ship:availablethrust > 0 {
    if altitude<body:atm:height lock steering to srfprograde.
    wait 0.5.
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
  parameter GTstart to 800.
  parameter GTendAP to 55000.
  
  local maxTWR to 3.0.
  lock throttle to 1.
  local initialpos to ship:facing.
  lock steering to initialpos.
  startnextstage().

  until alt:radar > GTstart {
    VertAscent().
    startnextstage().
    CapTWR(maxTWR).
    wait 0.01.
  }
  
  local GTStartSpd to velocity:surface:mag.
  local Apo45 to apoapsis.
  local lock pitch to 90 - vang( up:vector, velocity:surface ).

  until apoapsis >= Horb {
    if pitch >= 45 { set Apo45 to apoapsis. } 
    GravityTurn(GTStartSpd,Apo45,GTendAP).
    startnextstage().
    CapTWR(maxTWR).
    wait 0.01.
  }
  
  lock throttle to 0.

  lock steering to prograde.
  until altitude > body:atm:height { 
    APkeep(Horb).
    wait 0.01. 
  }
  lock throttle to 0.
  print "We are in space. Deploying payload fairing. ".
  wait 5.
  stage.
  
  wait until altitude > apoapsis - 20.
  circularize().

  print "We are in orbit: " + round(apoapsis/1000,2) + "x" + round(periapsis/1000,2) + " km. ".
  wait 5.
  
  print "Deploying omni antennae.".
  set alist to ship:partsnamed("longAntenna").
  for an in alist {
    set d to an:getmodule("ModuleRTAntenna").
    d:doevent("activate").
  }
  
  print "Releasing payload.".
  lock steering to prograde.
  wait 5.
  stage.
}
gettoorbit(80000,100).
