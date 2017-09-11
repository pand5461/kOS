function bnd {
  parameter val, minval, maxval.
  return min(maxval, max(minval, val)).
}

function warpfor {
  parameter dt.
  // warp    (0:1) (1:5) (2:10) (3:50) (4:100) (5:1000) (6:10000) (7:100000)
  set t1 to time:seconds+dt.
  if dt < 0 {
    print "WARNING: wait time " + round(dt) + " is in the past.".
    return.
  }
  local tw to kuniverse:timewarp.
  local wp to tw:warp.
  local oldwp to wp.
  local rt to t1 - time:seconds.
  until rt <= 0 {
    set wp to bnd(round(log10(min((rt*0.356)^2,rt*50))),0,7).
    if wp <> oldwp or wp <> tw:warp {
      if not tw:issettled wait tw:ratelist[min(oldwp,wp)]*0.1.
      set wp to bnd(wp, oldwp-1, oldwp+1).
      set tw:warp to wp.
      if wp <> oldwp print "Warp " + tw:ratelist[wp] + "x; remaining time " + round(rt) + "/" + round(dt).
      set oldwp to wp.
    }
    if tw:mode <> "rails" and (altitude > body:atm:height or status = "prelaunch") {
      tw:cancelwarp.
      wait until tw:issettled.
      set tw:mode to "rails".
      wait 0.
    }
    wait 0.
    set rt to t1 - time:seconds.
  }
  tw:cancelwarp.
}
