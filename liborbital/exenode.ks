require("libwarp","warpfor.ks").

function ThrustIsp {
  local g0 to Kerbin:mu/Kerbin:radius^2.
  list engines in el.
  local vex to 0.
  local ff to 0.
  local tt to 0.
  for e in el {
    set ff to ff + e:availablethrust*vdot(facing:vector,e:facing:vector)/(g0*max(e:isp,0.01)).
    set tt to tt + e:availablethrust.
  }
  if tt>0 set vex to tt/ff.
  return list(tt,vex).
}

function exenode {
  local nd to nextnode.
  local done to False.
  local once to True.
  local lock tm to round(missiontime).
  
  set ship:control:pilotmainthrottle to 0.
  print "T+" + tm + " Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).
  local maxa to 1.
  local TIsp to ThrustIsp().
  local tt to TIsp[0].
  local vex to TIsp[1].
  if tt = 0 { 
    print "ERROR: No active engines!".
    set ship:control:pilotmainthrottle to 0.
    return.
  }
  set dob to mass*vex/tt*(1 - constant:e^(-nd:deltav:mag/vex)).
  print "Burn duration: " + round(dob) + " s".
  warpfor(nd:eta-dob/2-60).
  sas off.
  rcs off.

  print "T+" + tm + " Turning ship to burn direction.".
  local np to lookdirup(nd:deltav,up:vector).
  lock steering to np.
  wait until vang( np:vector,facing:vector ) < 0.05 and ship:angularvel:mag < 0.05.
  warpfor(nd:eta-dob/2-7).
  print "T+" + tm + " Burn start " + round(dob/2) + " s before node.".
  set tset to 0.
  lock throttle to tset.

  lock steering to lookdirup(nd:deltav,up:vector).
  wait until nd:eta <= dob/2.
  local dv0 to nd:deltav.
  until done {
    set maxa to ship:availablethrust/mass.
    set tset to min(nd:deltav:mag/maxa, 1).
    if once and tset < 1 {
        print "T+" + tm + " Throttling down, remain dv " + round(nd:deltav:mag) + "m/s".
        set once to False.
    }
    if vdot(dv0, nd:deltav) < 0 {
        print "T+" + tm + " Burn aborted, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        lock throttle to 0.
        break.
    }
    if nd:deltav:mag < 0.1 {
        print "T+" + tm + " Finalizing, remain dv " + round(nd:deltav:mag,1) + "m/s".
        wait until vdot(dv0, nd:deltav) < 0.5.
        lock throttle to 0.
        print "T+" + tm + " End burn, remain dv " + round(nd:deltav:mag,1) + "m/s".
        set done to True.
    }
  }
  unlock steering.
  set ship:control:pilotmainthrottle to 0.
  print "T+" + tm + " Ap: " + round(apoapsis/1000,2) + " km, Pe: " + round(periapsis/1000,2) + " km".
  print "T+" + tm + " Remaining LF: " + round(stage:liquidfuel).
  wait 1.
  remove nd.
  unlock throttle.
}
