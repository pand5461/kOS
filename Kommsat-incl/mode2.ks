require("liborbital","orbdir.ks").

function aneta {
  local vecs to orbdir().
  local anangle to arctan2( vdot(vcrs(body:position, vecs:vector), vecs:upvector), -vdot(vecs:vector, body:position)).
  if anangle < 0 { set anangle to 360 + anangle. }
  return anangle / 360 * orbit:period.
}

clearscreen.
set target to vessel("Kommsat III").
local trsma to (orbit:semimajoraxis+target:orbit:semimajoraxis)/2.
local trperiod to 2*constant:pi*(trsma^3/body:mu)^0.5.
print "Transfer orbit period: " + round(trperiod) at (0,15).
local maxphase to 360*(1-trperiod/target:orbit:period).
print "Max phase gain: " + round(maxphase) at (0,16).
local ttr to time:seconds+aneta.
local apphase to phase(positionat(target,ttr+trperiod/2)-body:position,body:position-positionat(ship,ttr)).
until apphase>90 and apphase-90<=maxphase {
  set ttr to ttr+orbit:period.
  set apphase to phase(positionat(target,ttr+trperiod/2)-body:position,body:position-positionat(ship,ttr)).
}
print "Phase to target at AP: "+round(apphase).
local Vpe to sqrt( body:mu*(2/orbit:semimajoraxis - 1/trsma) ).
local deltav to Vpe - velocity:orbit:mag.
print "Transfer burn: " + round(velocity:orbit:mag) + " -> " + round(Vpe) + "m/s".
local nd to node(ttr, 0, 0, deltav).
add nd.
deletepath("orbdir.ks").
