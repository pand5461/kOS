require("libwarp","warpfor.ks").

function waitwindow {
  parameter Horb.
  
  local lngdiff to ship:longitude + 90 - Mun:longitude.
  
  local a1 to (Mun:apoapsis + Horb)/2 + body:radius.
  local t12 to constant:pi*sqrt(a1^3/body:mu).
  
  local phitrans to 180*(2*t12/Mun:orbit:period - 1).
  local omegaeff to 360*(1/body:rotationperiod - 1/Mun:orbit:period).
  local etatrans to (phitrans - lngdiff)/omegaeff - constant:pi/2*sqrt((body:radius + Horb)^3/body:mu) - 600.
  if etatrans < 0 set etatrans to etatrans + 360/omegaeff.

  wait until kuniverse:timewarp:issettled.
  set kuniverse:timewarp:mode to "rails".
  warpfor(etatrans).
}
