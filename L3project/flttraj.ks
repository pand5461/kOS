require("liborbital","etaNodes.ks").
{
  local nt to time:seconds + min(etaDN(), etaAN()).
  wait 0.
  local pn to positionat(ship, nt) - body:position.
  local vn to velocityat(ship,nt):orbit.
  local nrm to orbdir():upvector.
  local refvec to V(0, nrm:y, 0):normalized.
  local rad to vcrs(nrm, vn):normalized.
  local vh to vdot(vn, vcrs(pn:normalized, nrm)).
  local dv to vh*(vcrs(pn:normalized, refvec) - vcrs(pn:normalized,nrm)).
  local nd to node(nt, vdot(dv, rad), vdot(dv, nrm), vdot(dv, vn:normalized)).
  add nd.
}
