function CapTWR {
  parameter maxTWR is 3.0.
  local g0 to Kerbin:mu/Kerbin:radius^2.
  lock throttle to min(1, ship:mass*g0*maxTWR / max( ship:availablethrust, 0.001 ) ).
}

function pidtlm {
  parameter pid.
  print "Error: " + round(pid:error,2) at (0,16).
  print "PTerm: " + round(pid:pterm,2) at (0,17).
  print "ITerm: " + round(pid:iterm,2) at (0,18).
  print "DTerm: " + round(pid:dterm,2) at (0,19).
  print "Output: " + round(pid:output,2) at (0,20).
}

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

function HDGctrl {
  parameter ti.
  parameter hdgpid.
  parameter GTstart.

  if alt:radar < GTstart return 90.
  local vh to vxcl(up:vector,velocity:orbit).
  local svh to vxcl(up:vector,velocity:surface).
  
  local xi to arcsin( max(-1, min( 1, cos(ti) / cos(latitude) ) ) ).
  if svh:mag > 50 and vh:y < 0 { set xi to 180 - xi. }

  local thdg to heading( xi, 0 ).
  local vside to vdot(vxcl(thdg:vector,vh),thdg:rightvector).
    
  local hdg to xi + hdgpid:update(time:seconds, vside).
    
  if hdgpid:pterm*hdgpid:iterm < 0 hdgpid:reset.
  
  local track to arctan2(vdot(vcrs(north:vector,vh:normalized), up:vector), vdot(north:vector,vh:normalized) ).
  
  print "Track: " + round(track) + "   " at (0,14).
  print "Wanted track: " + round(xi) + "   " at (20,14).
  print "Target heading: " + round(hdg) + "   " at (0,15).

  return hdg.
}

function hdgpid_init {
  parameter ti, Horb.
  
  local vorb to sqrt(body:mu/Horb).
  local vsurf to velocity:orbit:mag.
  
  local xi to arcsin( max(-1, min( 1, cos(ti) / cos(latitude) ) ) ).

  local azl to arcsin( (vorb*sin(xi) - vsurf) / sqrt( vsurf^2 + vorb^2 - 2*vsurf*vorb*sin(xi) ) ).
  
  print "Launch azimuth: " + round(azl).
  
  local Kp to 1/vorb.
  if cos(azl) <> 0 {
    set Kp to (xi - azl) / (vsurf*cos(xi)).
  }
  local Ki to Kp/25.
  return pidloop(Kp,Ki,0).
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
  parameter ti to 0.
  parameter GTv45 to 500.
  parameter GTendAP to 55000.
  parameter GTstart to 2*alt:radar.
  
  local maxTWR to 3.0.
  local hdgpid to hdgpid_init(ti, Horb).
  set hdgpid:setpoint to 0.

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

    lock steering to heading( hdgctrl(ti, hdgpid, GTstart),pitchctrl(GTStartSpd,GTstart,GTv45,Apo45,GTendAP) ).
    startnextstage().
    CapTWR(maxTWR).

    printtlm().
    pidtlm(hdgpid).
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
  print "We are in space. Deploying antenna.".
  wait 2.
  ship:partsnamed("ServiceBay.125")[0]:getmodule("ModuleAnimateGeneric"):doevent("Open").
  wait 2.
  ship:partsnamed("longAntenna")[0]:getmodule("ModuleRTAntenna"):doevent("activate").
}
