function bnd {
  parameter val, minval, maxval.
  return min(maxval, max(minval, val)).
}

function warpheight {
  parameter h.
  local wp to 0.
 
  if (h < periapsis) {
    print "ERROR: target altitude is lower than periapsis.".
  }
  else if (apoapsis > 0) and (h > apoapsis) {
    print "ERROR: target altitude is higher than apoapsis.".
  }
  else {
    local tw to kuniverse:timewarp.
    local flag to ship:altitude > h.
    local wp to tw:warp.
    local oldwp to wp.
    local rt to 0.
    until (ship:altitude > h) <> flag {
      set rt to abs(ship:altitude - h)/max(0.01,abs(verticalspeed)).
      set oldwp to tw:warp.
      set wp to bnd(round(log10(min((rt*0.356)^2,rt*100))),0,6).
      if wp <> oldwp {
        if not tw:issettled wait tw:ratelist[min(oldwp,wp)]*0.1.
        set wp to bnd(wp, oldwp-1, oldwp+1).
        set tw:warp to wp.
      }
      if tw:mode <> "rails" and altitude > body:atm:height {
        tw:cancelwarp().
        wait until tw:issettled.
        set tw:mode to "rails".
      }
      wait 0.
    }
  }
}
