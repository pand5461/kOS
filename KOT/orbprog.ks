  if satmode = 1 {
    print "Aligning for optimal solar panel performance.".
    nextmode().
  }
  if satmode = 2 {
    if length(ship:crew())=0 nextmode().
    until length(ship:crew())=0 {
      hudtext("Waiting for crew EVA",1,2,18,YELLOW,True).
      wait 2.
    }
    nextmode().
  }
  if satmode = 3 {
    wait until length(ship:crew())>0.
    nextmode().
  }
  if satmode = 4 {
    require("libwarp","warpfor.ks").
    nextmode().
  }
  if satmode = 5 {
    wait 10.
    warpfor(orbit:period*2/3 - missiontime).
    nextmode().
  }
  if satmode = 6 {
    wait until vang(ship:facing:vector,retrograde:vector)<0.1.
    lock throttle to 1.
    nextmode().
  }
  if satmode = 7 {
    wait until ship:availablethrust=0.
    lock throttle to 0.
    wait 5.
    stage.
    nextmode().
  }  
  lock steering to lookdirup(-velocity:surface,Sun:position) + R(0,0,225).
  wait until alt:radar < 5000.
  stage.
  unlock steering.
  wait until ship:status = "LANDED" or ship:status = "SPLASHED".

  Hudtext(ship:status,20,2,18,YELLOW,True).
