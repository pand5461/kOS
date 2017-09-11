function TrimPeriod {
  parameter WantedPeriod.
  parameter epsilon is 5e-8.
  
  local dt to  WantedPeriod - orbit:period.
  lock steering to velocity:orbit*dt.
  list engines in elist.
  local thrustlim to list().
  // set thrustlimit to max 0.05 m/s^2 acceleration
  from { local i to 0. } until i=elist:length step { set i to i+1. } do {
    thrustlim:add(elist[i]:thrustlimit).
    set elist[i]:thrustlimit to 5*ship:mass/ship:maxthrust.
  }
  wait until vang(facing:vector,velocity:orbit*dt) < 1.
  until abs( (orbit:period - WantedPeriod) / WantedPeriod ) < epsilon {
    lock throttle to min( max( abs( orbit:period - WantedPeriod ), 0.05 ), 1 ).
    wait 0.
  }
  lock throttle to 0.
  // restore thrustlimits
  from { local i to 0. } until i=elist:length step { set i to i+1. } do {
    set elist[i]:thrustlimit to thrustlim[i].
  }
  print "Target period: " + round(WantedPeriod,1) + "s, Delta: " + (orbit:period - WantedPeriod) + " s ".
  set ship:control:pilotmainthrottle to 0.
  unlock throttle.
}
