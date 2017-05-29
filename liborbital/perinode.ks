function aponode {
  parameter newapsis is periapsis.

  print "T+" + round(missiontime) + " Maneuver at Pe. Changing orbit around ". + body:name + ":".
  print round(periapsis/1000,1) + "x" + round(apoapsis/1000,1) + " km -> " + round( min(apoapsis,newapsis)/1000,1) + "x" + round( max(apoapsis,newapsis)/1000,1) + " km ".

  local a0 to orbit:semimajoraxis.     
  local Rp to body:radius + periapsis.  
  local Vp to sqrt( body:mu * (2/Rp - 1/a0) ).

  local a1 to (newapsis + periapsis)/2 + body:radius. // target orbit SMA
  local v1 to sqrt( body:mu * (2/Rp - 1/a1) ).
  set deltav to v1 - Vp.
  
  print "Burn at Pe: " + round(Vp) + " -> " + round(v1) + "m/s".
  set nd to node(time:seconds + eta:periapsis, 0, 0, deltav).
  add nd.
  print "T+" + round(missiontime) + " Node created.".
}
