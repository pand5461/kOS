require("liborbital","orbdir.ks").

function dneta {
  local vecs to orbdir().
  local dnangle to arctan2( vdot(vcrs(vecs:vector,body:position), vecs:upvector), vdot(vecs:vector, body:position)).
  if dnangle < 0 { set dnangle to 360 + dnangle. }
  return dnangle / 360 * orbit:period.
}

clearscreen.

local ttr to time:seconds+dneta + 10.
local a1 to (Mun:orbit:semimajoraxis + orbit:semimajoraxis)/2.
local Vpe to sqrt( body:mu*(2/orbit:semimajoraxis - 1/a1) ).
local deltav to Vpe - velocity:orbit:mag - 2.
print "Transfer burn: " + round(velocity:orbit:mag) + " -> " + round(Vpe) + "m/s".
local nd to node(ttr, 0, 0, deltav).
add nd.
local pe0 to nd:orbit:nextpatch:periapsis.
set nd:prograde to nd:prograde + 0.001.
local pe1 to nd:orbit:nextpatch:periapsis.
local dpedv to (pe1 - pe0)/0.001.
until pe1 > 50000 {
  set pe0 to pe1.
  local dv to 0.1*(50000 - pe0)/dpedv.
  set nd:prograde to nd:prograde + dv.
  set pe1 to nd:orbit:nextpatch:periapsis.
  set dpedv to (pe1-pe0)/dv.
}
deletepath("orbdir.ks").
