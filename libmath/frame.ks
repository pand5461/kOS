@lazyglobal off.
function toIRF {
// changes to inertial right-handed coordinate system where ix = SPV, iy = vcrs(SPV, V(0, 1, 0)), iz = V(0, 1, 0)
  parameter oldVec, SPV to SolarPrimeVector.
  return V(vdot(oldVec, SPV), vdot(oldVec, V(-SPV:z, 0, SPV:x)), oldVec:y).
}

function fromIRF {
// changes from inertial right-handed coordinate system where ix = SPV, iy = vcrs(SPV, V(0, 1, 0)), iz = V(0, 1, 0)
  parameter irfVec, SPV to SolarPrimeVector.
  return V(vdot(irfVec, V(SPV:x, -SPV:z, 0)), irfVec:z, vdot(irfVec, V(SPV:z, SPV:x, 0))).
}
