require("liborbital","orbdir.ks").

function etaToTA {
  parameter ta, orbit_in to ship:orbit.
  
  local tanow to orbit_in:trueanomaly.
  local ecc to orbit_in:eccentricity.
  local ef to sqrt( (1-ecc) / (1+ecc) ).
  local eanow to 2*arctan( ef * tan(tanow / 2) ).
  local eanew to 2*arctan( ef * tan(ta / 2) ).
  
  local dt to sqrt( orbit_in:semimajoraxis^3 / orbit_in:body:mu ) * ((eanew - eanow)*constant:degtorad - ecc * (sin(eanew) - sin(eanow))).
  until dt > 0 { set dt to dt + orbit_in:period. }
  return dt.
}

function etaAN {
  parameter refNRM to V(0,1,0).
  
  local AN_NRM to orbdir(refNRM).
  local ANvec to AN_NRM:vector.
  local taAN to arctan2( vdot(AN_NRM:upvector, vcrs(body:position, ANvec)), -vdot(body:position, ANvec) ) + orbit:trueanomaly.
  return etaToTA(taAN).
}

function etaDN {
  parameter refNRM to V(0,1,0).
  
  local DN_NRM to orbdir(refNRM).
  local DNvec to -DN_NRM:vector.
  local taDN to arctan2( vdot(DN_NRM:upvector, vcrs(body:position, DNvec)), -vdot(body:position, DNvec) ) + orbit:trueanomaly.
  return etaToTA(taDN).
}
