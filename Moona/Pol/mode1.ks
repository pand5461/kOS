require("liborbital","orbdir.ks").

function dneta {
  local vecs to orbdir().
  local dnangle to arctan2( vdot(vcrs(vecs:vector,body:position), vecs:upvector), vdot(vecs:vector, body:position)).
  if dnangle < 0 { set dnangle to 360 + dnangle. }
  return dnangle / 360 * orbit:period.
}

clearscreen.

local ttr to time:seconds+dneta + 40.
local a1 to (Mun:orbit:semimajoraxis + orbit:semimajoraxis)/2.
local Vpe to sqrt( body:mu*(2/orbit:semimajoraxis - 1/a1) ).
local deltav to Vpe - velocity:orbit:mag - 2.
print "Transfer burn: " + round(velocity:orbit:mag) + " -> " + round(Vpe) + "m/s".
local nd to node(ttr, 0, 0, deltav).
add nd.
deletepath("orbdir.ks").
