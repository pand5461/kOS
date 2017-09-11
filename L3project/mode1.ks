require("liborbital","etaNodes.ks").

clearscreen.

local ttr to time:seconds+etaAN()+19.066/360*orbit:period.
local a1 to (1.15*Mun:orbit:semimajoraxis + orbit:semimajoraxis)/2.
local Vpe to sqrt( body:mu*(2/orbit:semimajoraxis - 1/a1) ).
local deltav to Vpe - velocity:orbit:mag.
print "Transfer burn: " + round(velocity:orbit:mag) + " -> " + round(Vpe) + "m/s".
local nd to node(ttr, 0, 0, deltav).
add nd.
