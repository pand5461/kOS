function vesselsize {
  parameter v.

  local vparts to v:parts.
  local vcenter to V(0,0,0).

  for p in vparts { set vcenter to vcenter+v:position. }
  set vcenter to vcenter/vparts:length.
  
  set dmax to 0.
  for p in vparts {
    set dmax to max(dmax, (p:position - vcenter):sqrmagnitude).
  }
  
  return sqrt(dmax)*4+1.
}
