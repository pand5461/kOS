function orbdir {
//returns direction with vector=AN vector, up=normal
  local normvec to vcrs(body:position-orbit:position,velocity:orbit).
  local anvec to vcrs(normvec,V(0,1,0)).
  return lookdirup(anvec,normvec).
}
