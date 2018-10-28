@lazyglobal off.

global g0 to 9.80665.
global M_PI to constant:pi.
global M_E to constant:e.
global M_RTD to constant:radtodeg.
global M_DTR to constant:degtorad.
global M_GOLD to (1 + sqrt(5)) / 2.

function sign {
  parameter x.
  if x > 0 { return 1. }
  if x < 0 { return -1. }
  return 0.
}

function clamp {
  parameter x, b1, b2.
  local xmin to min(b1, b2).
  local xmax to max(b1, b2).

  if x < xmin { return xmin. }
  if x > xmax { return xmax. }
  return x.
}
