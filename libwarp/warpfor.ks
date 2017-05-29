function warpfor {
  parameter dt.
  // warp    (0:1) (1:5) (2:10) (3:50) (4:100) (5:1000) (6:10000) (7:100000)
  set t1 to time:seconds+dt.
  if dt < 0 {
    print "WARNING: wait time " + round(dt) + " is in the past.".
  }
  local tw to kuniverse:timewarp.
  local oldwp to 0.
  local oldwarp to warp.
  until time:seconds >= t1 {
    local rt to t1-time:seconds.
    local wp to min(7,max(round(log10(min((rt*0.356)^2,rt*100))), 0)).
    if wp <> oldwp or warp <> wp {
        set warp to wp.
        wait 0.
        if wp <> oldwp or warp <> oldwarp {
            print "T+" + round(missiontime) + " Warp " + warp + "/" + wp + ", remaining wait " + round(rt) + "s".
        }
        set oldwp to wp.
        set oldwarp to warp.
    }
    if tw:mode <> "rails" and altitude > body:atm:height {
      tw:cancelwarp.
      wait until tw:issettled.
      set tw:mode to "rails".
    }
    wait 0.
  }
}
