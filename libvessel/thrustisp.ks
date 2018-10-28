@lazyglobal off.
require("libmath", "mglobals").
function ThrustIsp {
  local el to 0.
  list engines in el.
  local vex to 1.
  local ff to 0.
  local tt to 0.
  for e in el {
    set ff to ff + e:availablethrust/max(e:visp,0.01).
    set tt to tt + e:availablethrust*vdot(facing:vector,e:facing:vector).
  }
  if tt<>0 set vex to g0*tt/ff.
  return list(tt, vex).
}

function ThrustIspAt {
  parameter P to 0.
  local el to 0.
  list engines in el.
  local vex to 1.
  local ff to 0.
  local tt to 0.
  for e in el {
    set ff to ff + e:availablethrustat(P)/max(e:ispat(P),0.01).
    set tt to tt + e:availablethrustat(P)*vdot(facing:vector,e:facing:vector).
  }
  if tt<>0 set vex to g0*tt/ff.
  return list(tt, vex).
}
