function waitwindow {
  parameter Horb.
  
  local lngdiff to ship:longitude + 270 - Mun:longitude.
  
  local a1 to (1.15*Mun:orbit:semimajoraxis + Horb + body:radius)/2.
  local ecc to (1.15*Mun:orbit:semimajoraxis - Horb - body:radius)/(2*a1).
  local tamun to arccos( (((1 - ecc^2)*a1/Mun:orbit:semimajoraxis) - 1) / ecc ).
  local ef to sqrt( (1-ecc) / (1+ecc) ).
  local eanew to 2*arctan( ef * tan(tamun / 2) ).
  local t12 to sqrt(a1^3/body:mu) * (eanew*constant:degtorad - ecc * sin(eanew)).
  
  local phitrans to 180*(2*t12/Mun:orbit:period - 1).
  local omegaeff to 360*(1/body:rotationperiod - 1/Mun:orbit:period).
  local etatrans to (phitrans - lngdiff)/omegaeff - constant:pi*1.5*sqrt((body:radius + Horb)^3/body:mu) + 800.
  until etatrans > 0 set etatrans to etatrans + 360/omegaeff.

  wait until kuniverse:timewarp:issettled.
  set kuniverse:timewarp:mode to "rails".
  warpfor(etatrans).
}
