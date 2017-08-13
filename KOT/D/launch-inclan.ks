require("liborbital","annorm.ks").
require("liborbital","aponode.ks").
require("liborbital","exenode.ks").

function HDGctrl {
  parameter ti, tlan, GTh0.
  parameter hdgpid.

  if alt:radar < GTh0 return 90.
  local vh to vxcl(up:vector,velocity:orbit).
  local svh to vxcl(up:vector,velocity:surface).

  local xi to arcsin( max(-1, min( 1, cos(ti) / cos(latitude) ) ) ).
  local ANNRM to ANNorm(tlan,ti).
  if vang(body:position, ANNRM:vector) < 90 set xi to 180 - xi.

  local thdg to heading( xi, 0 ).

  local distkm to vdot(ANNRM:upvector,body:position)/1000.

  local hdg to xi + hdgpid:update(time:seconds, distkm).

  if hdgpid:pterm*hdgpid:iterm < 0 or hdgpid:pterm*hdgpid:iterm > hdgpid:pterm^2 { 
    hdgpid:reset.
  }

  local track to arctan2(vdot(vcrs(north:vector,vh:normalized), up:vector), vdot(north:vector,vh:normalized) ).

  print "Track: " + round(track) + "   " at (0,14).
  print "Wanted track: " + round(xi) + "   " at (20,14).
  print "Target heading: " + round(hdg) + "   " at (0,15).

  return hdg.
}

function hdgpid_init {
  parameter leadtime.
  local Kd to 200.
  local Kp to Kd^2*4e-5.
  local Ki to Kp/(10*leadtime).
  return pidloop(Kp,Ki,Kd).
}

function pidtlm {
  parameter pid.
  print "Error: " + round(pid:error,2) + "    "at (0,16).
  print "PTerm: " + round(pid:pterm,2) + "    " at (0,17).
  print "ITerm: " + round(pid:iterm,2) + "    " at (0,18).
  print "DTerm: " + round(pid:dterm,2) + "    " at (0,19).
  print "Output: " + round(pid:output,2) + "    " at (0,20).
}

function printtlm {
  local pitch to 90 - vang( up:vector, velocity:surface ).
  print "Apoapsis: " + round( apoapsis/1000, 2 ) + " km    " at (0,30).
  print "Periapsis: " + round( periapsis/1000, 2 ) + " km    " at (0,31).
  print " Altitude: " + round( altitude/1000, 2 ) + " km    " at (24,30).
  print " Pitch: " + round( pitch ) + " deg  " at (24,31).
  print "Latitude: " + round(latitude) + "  " at (24,6).
  print "Inclination: " + round(orbit:inclination, 2) + "    " at (0,6).
  print "LAN: " + round(orbit:lan, 2) + "    " at (0,7).
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

function CapTWR {
  parameter maxTWR is 3.0.
  local g0 to 9.80665.
  lock throttle to min(1, ship:mass*g0*maxTWR / max( ship:availablethrust, 0.001 ) ).
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
    if altitude<body:atm:height and velocity:surface:sqrmagnitude > 4 lock steering to srfprograde.
    if altitude>body:atm:height lock steering to lookdirup(velocity:orbit, -body:position).
    wait 1.
    stage.
    if ship:availablethrust > 0 wait 1.
  }
}

function APkeep {
  parameter apw.
  local Kp to 200.
  if apoapsis > apw { lock throttle to 0. }
  else { lock throttle to max( 0.05, Kp*(apw - apoapsis)/apw ). }
  printtlm().
}

function nextLVmode {
  parameter newmode is LVmode+1.
  set LVmode to newmode.
  log "set LVmode to " + newmode + "." to "mode.ks".
}

function azlan {
  parameter xi.
  
  local Vvirt to heading(xi, 0):vector.
  local nvirt to vcrs(body:position, Vvirt).
  local ANvirt to vcrs(nvirt, V(0,1,0)).
  local vlan to arctan2( vdot( V(0,1,0), vcrs(ANvirt, solarprimevector) ), vdot(ANvirt, solarprimevector) ).
  if vlan<0 set vlan to vlan+360.
  return vlan.
}
  
function waitwindow {
  parameter ti, tlan, leadtime.
  local xi to arcsin( max(-1, min( 1, cos(ti) / cos(latitude) ) ) ).
  
  local LANvirt to azlan(xi).
  local landiff to tlan - LANvirt.
  until landiff > 0 { set landiff to landiff + 360. }.
  
  local xi2 to 180-xi.
  local LANvirt2 to azlan(xi2).
  local landiff2 to tlan - LANvirt2.
  until landiff2 > 0 { set landiff2 to landiff2 + 360. }.

  print round(tlan,2).
  print round(LANvirt,2).
  print round(LANvirt2,2).

  local dt to min(landiff, landiff2)/360 * body:rotationperiod - leadtime.
  if dt > 0 warpfor(dt).
  else warpfor(max(landiff, landiff2)/360 * body:rotationperiod - leadtime).
}

function LVprogram {
  parameter Horb.
  parameter ti to 0.
  parameter tlan to 0.
  parameter GTstart to 2*alt:radar.
  parameter GTendAP to 50000.
  parameter GTv45 to 500.
  
  local maxTWR to 3.0.
  local lt to 75.
  
  if LVmode = 0 {  
    waitwindow(ti,tlan,lt).
    nextlvmode().
  }
  
  clearscreen.
  print "Desired inclination: " + round(ti,2).
  print "Desired LAN: " + round(tlan,2).

  local hdgpid to hdgpid_init(lt).
  set hdgpid:setpoint to 0.
  
  if LVmode = 1 {
    lock throttle to 1.
    local initialpos to ship:facing.
    lock steering to initialpos.
    startnextstage().
    wait 0.
    nextlvmode().
  }
  if LVmode = 2 {
    local vsm to velocity:surface:mag.
    local GTStartSpd to vsm.
    local Apo45 to apoapsis.

    until apoapsis >= Horb {
      set vsm to velocity:surface:mag.
      if vsm <= GTv45 { set Apo45 to apoapsis. }
      if alt:radar <= GTstart { set GTStartSpd to vsm. }

      lock steering to heading( hdgctrl(ti, tlan, GTstart, hdgpid),pitchctrl(GTStartSpd,GTstart,GTv45,Apo45,GTendAP) ).
      startnextstage().
      CapTWR(maxTWR).

      printtlm().
      pidtlm(hdgpid).
      wait 0.
    }
    nextlvmode().
  }   
  if lvmode = 3 {
    lock throttle to 0.
    lock steering to prograde.
    set warp to 3.

    until altitude > body:atm:height { 
      APkeep(Horb).
      wait 0. 
    }
    nextlvmode().
  }
  if lvmode = 4 {
    set warp to 0.
    lock throttle to 0.
    clearscreen.
    print "We are in space. Ejecting nosecone. ".
    wait 2.
    stage.
    nextlvmode().
  }
  if lvmode = 5 {
    print "Deploying antenna.".
    wait 2.
    ship:partsnamed("ServiceBay.125")[0]:getmodule("ModuleAnimateGeneric"):doevent("Open").
    wait 2.
    ship:partsnamed("longAntenna")[0]:getmodule("ModuleRTAntenna"):doevent("activate").
    nextlvmode().
  }
  if lvmode = 6 {
    aponode(20000).
    nextlvmode().
  }
  if lvmode = 7 {
    exenode().
    nextlvmode().
  }
  if lvmode = 8 {
    print "Releasing payload.".
    lock steering to prograde.
    wait 5.
    stage.
  }
}
