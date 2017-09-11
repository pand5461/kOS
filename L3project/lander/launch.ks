require("liborbital","circularize.ks").
require("liborbital","aponode.ks").
require("liborbital","exenode.ks").

function printtlm {
  local pitch to 90 - vang( up:vector, velocity:surface ).
  print "Apoapsis: " + round( apoapsis/1000, 2 ) + " km    " at (0,30).
  print "Periapsis: " + round( periapsis/1000, 2 ) + " km    " at (0,31).
  print " Altitude: " + round( altitude/1000, 2 ) + " km    " at (24,30).
  print " Pitch: " + round( pitch ) + " deg  " at (24,31).
}

function PitchCtrl {
  parameter vstart, h0, v45, AP45, APstop.
  
  if alt:radar < h0 {return 90.}
  
  local vsm to velocity:surface:mag.
  local pitch to 0.

  if vsm < v45 {
    set pitch to 90 - arctan( (vsm - vstart)/(v45 - vstart) ).
  }
  else {
    set pitch to max(0, 45*(apoapsis - APstop) / (AP45 - APstop) ).
  }
  return pitch.
}
  
function gettoorbit {
  parameter Horb to 15000.
  parameter GTstart to 2*alt:radar.
  parameter GTv1 to 80.
  parameter GTendAP to Horb - 1000.

  lock throttle to 1.
  lock steering to lookdirup(-body:position,facing:upvector).
  stage.
  wait 0.1.
  ship:partsnamed("liquidEngineMini")[0]:activate.

  local vsm to velocity:surface:mag.
  local GTStartSpd to vsm.
  local Apo2 to apoapsis.

  until apoapsis >= Horb {
    set vsm to velocity:surface:mag.
    local pitch to PitchCtrl(GTStartSpd,GTstart,GTv1,Apo2,GTendAP).
    if alt:radar <= GTstart { set GTStartSpd to vsm. }
    if vsm < GTv1 { 
      if apoapsis < GTendAP { set Apo2 to apoapsis. }
      else { set Apo2 to GTendAP*0.5. }
    }
    
    if alt:radar > GTstart lock steering to heading(270, pitch).
    printtlm().
    wait 0.
  }
  
  lock throttle to 0.

  aponode().
  exenode().
  circularize().
  deletepath("liborbital/circularize.ks").
}
