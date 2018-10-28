@lazyglobal off.
function vesselsize {
  // computes 4x maximal separation of vessel part from its CoM
  parameter obj.

  local vparts to obj:parts.
  local dmax to 0.
  for p in vparts {
    set dmax to max(dmax, (p:position - obj:position):sqrmagnitude).
  }

  return sqrt(dmax)*4+1.
}
