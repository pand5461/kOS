require("libwarp","warpfor.ks").
require("libvessel","thrustisp.ks").

function exenode {
  local nd to nextnode.
  local done to False.
  local once to True.
  local lock tm to round(missiontime).
  
  set ship:control:pilotmainthrottle to 0.
  print "T+" + tm + " Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).
  local TIsp to ThrustIsp().
  local tt to TIsp[0].
  local vex to TIsp[1].
  if tt = 0 {
    print "ERROR: No active engines!".
    set ship:control:pilotmainthrottle to 0.
    return.
  }
  local maxa to tt/mass.
  local dob to vex / maxa * (1 - constant:e^(-nd:deltav:mag/vex)).
  print "Burn duration: " + round(dob) + " s".
  local dob2 to vex/maxa - vex*dob/nd:deltav:mag.
  warpfor(nd:eta-dob2-60).
  sas off.
  rcs off.

  print "T+" + tm + " Turning ship to burn direction.".
  lock steering to lookdirup(nd:deltav*(tt/abs(tt)),-body:position).
  wait until vang( nd:deltav*(tt/abs(tt)),facing:vector ) < 0.05 and ship:angularvel:mag < 0.05.
  warpfor(nd:eta-dob2-10).
  print "T+" + tm + " Burn start " + round(dob2) + " s before node.".
  local tset to 0.
  lock throttle to tset.

  local dv0 to nd:deltav.
  wait until nd:eta <= dob2.
  until done {
    set tset to min(nd:deltav:mag*mass/abs(tt), 1).
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
  print "T+" + tm + " Remaining LF: " + round(stage:liquidfuel,1).
  wait 1.
  remove nd.
  unlock tm.
  unlock throttle.
}
