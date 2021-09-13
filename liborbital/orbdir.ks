function orbdir {
// Returns direction with vector = AN vector, up = normal
// Parameters:
// * refNRM - normal to the orbit wrt which the the AN is taken.
//   Default: V(0,1,0) - equatorial prograde orbit
  parameter refNRM is V(0,1,0). 
  local normvec is vcrs(body:position-orbit:position,velocity:orbit).
  local anvec is vcrs(normvec, refNRM).
  return lookdirup(anvec, normvec).
}
