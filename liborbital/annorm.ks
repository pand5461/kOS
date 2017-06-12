function ANNorm {
//returns direction with vector=AN vector, up=normal
  parameter lan, incl.
  local basedir to lookdirup(SolarPrimeVector, V(0,1,0)).
  set basedir to angleaxis(-lan, V(0,1,0))*basedir.
  set basedir to angleaxis(-incl, basedir:forevector)*basedir.
  return basedir.
}
