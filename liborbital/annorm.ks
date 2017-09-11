function ANNorm {
//returns direction with vector=AN vector, up=normal
  parameter lan, incl, SPV to SolarPrimeVector.
  return lookdirup(SPV, V(0,1,0))*R(0,-lan,-incl).
}
