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
  parameter aoalim to 2.5.
  parameter aoalh to 15000.
  
  if alt:radar < h0 {return 90.}
  
  local vsm to velocity:surface:mag.
  local pitch to 0.

  if vsm < v45 {
    set pitch to 90 - arctan( (vsm - vstart)/(v45 - vstart) ).
  }
  else {
    set pitch to max(0, 45*(apoapsis - APstop) / (AP45 - APstop) ).
  }
  
  local vpitch to 90-vang(up:vector, velocity:surface).
  if altitude > aoalh set aoalim to aoalim*constant:e^(2*(altitude/aoalh-1)).
  if pitch > vpitch + aoalim {set pitch to vpitch + aoalim.}
  if pitch < vpitch - aoalim {set pitch to vpitch - aoalim.}

  return pitch.
}
  
function startnextstage {
  local allengactive to 
  {
    list engines in el.
    for e in el
      if e:flameout return False.
    return True.
  }.
  until ship:availablethrust > 0 and allengactive() {
    list engines in el.
    for e in el if e:ignition set e:thrustlimit to 100.
    if altitude<body:atm:height and velocity:surface:sqrmagnitude > 4 lock steering to srfprograde.
    if altitude>body:atm:height lock steering to lookdirup(velocity:orbit, -body:position).
    wait 0.5.
    stage.
    if ship:availablethrust > 0 wait 0.5. 
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
  parameter Horb.
  parameter GTstart to 50.
  parameter GTv1 to 550.
  parameter GTendAP to 60000.

  lock throttle to 1.
  lock steering to heading(90,90).
  stage.

  local vsm to velocity:surface:mag.
  local GTStartSpd to vsm.
  local Apo2 to apoapsis.
  local tlesjett to time:seconds.
  local lesjett to False.
  local pitch to 90.

  until apoapsis >= Horb {
    if stage:number = 10 and not lesjett { set tlesjett to time:seconds + 3. set lesjett to True. }
    if not lesjett { set tlesjett to time:seconds + 1. }
    if time:seconds > tlesjett { toggle AG1. }
    set vsm to velocity:surface:mag.
    if stage:number > 10 {
      set pitch to PitchCtrl(GTStartSpd,GTstart,GTv1,Apo2,GTendAP).
    }
    else {
      set pitch to 0.4*(90 - vang(velocity:orbit, -body:position)).
      local fpitch to 90 - vang(facing:vector, -body:position).
      if pitch > fpitch + 1.5 {set pitch to fpitch + 1.5.}
      if pitch < fpitch - 1.5 {set pitch to fpitch - 1.5.}
    }
    if alt:radar <= GTstart { set GTStartSpd to vsm. }
    if vsm < GTv1 { set Apo2 to apoapsis. }
    
    local tisp to thrustisp().
    if stage:number < 11 or (stage:liquidfuel + stage:oxidizer)*0.005*tisp[1]/max(1, tisp[0]) > 5 {
      lock steering to heading(90, pitch).
    }
    else { lock steering to srfprograde. }
    print "Pitch (prog): " + round(pitch) at (0,32).
    printtlm().
    startnextstage().
    wait 0.
  }
  
  lock throttle to 0.

  lock steering to prograde.
  set warp to 3.
  until altitude > body:atm:height { 
    APkeep(Horb).
    startnextstage().
    wait 0. 
  }
  lock throttle to 0.
  set warp to 0.
  print "We are in space. Deploying fairing. ".
  wait 2.
  stage.
  wait 1.
  stage.
  wait 1.
  
  aponode().
  exenode().
  circularize().
  wait 3.
  panels on.
}
