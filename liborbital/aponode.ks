function aponode {
  parameter newapsis is apoapsis.

  print "T+" + round(missiontime) + " Maneuver at Ap. Changing orbit around " + body:name + ":".
  print round(periapsis/1000,1) + "x" + round(apoapsis/1000,1) + " km -> " + round( min(apoapsis,newapsis)/1000,1) + "x" + round( max(apoapsis,newapsis)/1000,1) + " km ".

  local a0 to orbit:semimajoraxis.
  local Ra to body:radius + apoapsis.
  local Va to sqrt( body:mu * (2/Ra - 1/a0) ).

  local a1 to (newapsis + apoapsis)/2 + body:radius. // target orbit SMA
  local v1 to sqrt( body:mu * (2/Ra - 1/a1) ).
  set deltav to v1 - Va.
  
  print "Burn at Ap: " + round(Va) + " -> " + round(v1) + "m/s".
  local nd to node(time:seconds + eta:apoapsis, 0, 0, deltav).
  add nd.
  print "T+" + round(missiontime) + " Node created.".
}
