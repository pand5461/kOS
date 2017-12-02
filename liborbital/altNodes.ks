require("liborbital","orbdir.ks").

function TAofAN2 {
  parameter ti, tlan, taop.
  local T_AN_NRM to lookdirup(SolarPrimeVector, V(0,1,0))*R(0,-tlan,-ti).
  local refNRM to T_AN_NRM:upvector.
  local T_PE_NRM to angleaxis(-taop, refNRM) * T_AN_NRM.
  local PEvec to T_PE_NRM:vector.
  local ANvec to orbdir(refNRM):vector.
  local taAN to arctan2( vdot(refNRM, vcrs(ANvec, PEvec)), vdot(ANvec, PEvec) ).
  until taAN >= 0 { set taAN to taAN + 360. }
  until taAN < 360 { set taAN to taAN - 360. }
  return taAN.
}

function AltTA2 {
  parameter tsma, tecc, ti, tlan, taop, tta.
  return tsma*(1 - tecc*tecc) / (1 + tecc * cos(tta)).
}

function UniPosTA2 {
  parameter tsma, tecc, ti, tlan, taop, tta.
  local T_AN_NRM to lookdirup(SolarPrimeVector, V(0,1,0))*R(0,-tlan,-ti).
  return (angleaxis(-taop-tta, T_AN_NRM:upvector)*T_AN_NRM):vector.
}

function VelTA2 {
  parameter tsma, tecc, ti, tlan, taop, tta.
  local int_e to -body:mu / (2*tsma).
  local refNRM to lookdirup(SolarPrimeVector, V(0,1,0))*R(0,-tlan,-ti):upvector.
  local AltAP to tsma * (1 + tecc).
  local AltTA to AltTA2(tsma, tecc, ti, tlan, taop, tta).
  local UniPos to UniPosTA2(tsma, tecc, ti, tlan, taop, tta).
  local SpdAP to sqrt( 2 * (body:mu / AltAP + int_e ) ).
  local SpdTA to sqrt( 2 * (body:mu / AltTA + int_e ) ).
  local int_l to AltAP * SpdAP.
  local Vtr to int_l / AltTA.
  local Vr to sqrt(SpdTA*SpdTA - Vtr*Vtr).
  if sin(tta) < 0 { set Vr to -Vr. }
  return Vr * UniPos + Vtr * vcrs(UniPos, refNRM).
}
