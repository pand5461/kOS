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
    until (ship:altitude > h) <> flag {
      local rt to abs(ship:altitude - h)/max(0.01,abs(verticalspeed)).
      set wp to min(7,max(round(log10(min((rt*0.356)^2,rt*100))), 0)).
      if warp <> wp set warp to wp.
      if tw:mode <> "rails" and altitude > body:atm:height {
        tw:cancelwarp().
        wait until tw:issettled.
        set tw:mode to "rails".
      }
      wait 0.
    }
  }
}
