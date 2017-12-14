function chFrame {
  parameter oldVec, oldSP, newSP to SolarPrimeVector.
  return vdot(oldVec, oldSP)*newSP + (oldVec:z * oldSP:x - oldVec:x * oldSP:z)*V(-newSP:z, 0, newSP:x) + V(0, oldVec:y, 0).
}

function toIRF {
// changes to inertial right-handed coordinate system where ix = SPV, iy = vcrs(SPV, V(0, 1, 0)), iz = V(0, 1, 0)
  parameter oldVec, SPV to SolarPrimeVector.
  return V( oldVec:x * SPV:x + oldVec:z * SPV:z, oldVec:z * SPV:x - oldVec:x * SPV:z, oldVec:y).
}

function fromIRF {
// changes from inertial right-handed coordinate system where ix = SPV, iy = vcrs(SPV, V(0, 1, 0)), iz = V(0, 1, 0)
  parameter irfVec, SPV to SolarPrimeVector.
  return V( irfVec:x * SPV:x - irfVec:y * SPV:z, irfVec:z, irfVec:x * SPV:z + irfVec:y * SPV:x ).
}
