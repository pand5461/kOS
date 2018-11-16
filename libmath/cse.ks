@lazyglobal off.
require("libmath", "mglobals").
require("libmath/zeros", "ridders.ks").
//	Conic State Extrapolation
// Formulas follow H.D. Curtis, Orbital Mechanics for Engineering Students, Chapter 3.7

// Stumpff S and C functions
function SnC_ell {
  parameter z.
  if z < 1e-4 {
    return lex("S", (1 - z * ( 0.05 - z / 840) ) / 6, "C", 0.5 - z * ( 1 - z / 30) / 24).
  }
  local saz to sqrt(z).
  local x to saz * m_rtd.
  return lex("S", (saz - sin(x)) / (saz * z), "C", (1 - cos(x)) / z).
}

function SnC_hyp {
  parameter z.
  if z > 1e-4 {
    return lex("S", (1 - z * ( 0.05 - z / 840) ) / 6, "C", 0.5 - z * ( 1 - z / 30) / 24).
  }
  local saz to sqrt(-z).
  local x to m_e^saz.
  local sh to 0.5 * (x - 1 / x).
  return lex("S", (saz - sh) / (saz * z), "C", (1 - sh - 1 / x) / z).
}

// Conic State Extrapolation Routine
function CSER {
  parameter r0, v0, dt, mu to body:mu, x0 to False, tol to 1e-12.
  if dt = 0 {
    return list(r0, v0, 0).
  }
  local rscale to r0:mag.
  local vscale to sqrt(mu / rscale).
  local r0s to r0 / rscale.
  local v0s to v0 / vscale.
  local dts to dt * vscale / rscale.
  local v2s to v0:sqrmagnitude * rscale / mu.
  local alpha to 2 - v2s.
  local armd1 to v2s - 1.
  local rvr0s to vdot(r0, v0) / sqrt(mu * rscale).

  local period to 2 * M_PI / abs(alpha)^1.5.
  if alpha > 0 {
    until dts > 0 {
      set dts to dts + period.
    }
    until dts <= period {
      set dts to dts - period.
    }
  }


  local SnC to SnC_ell@.
  if alpha < 0 {
    set SnC to SnC_hyp@.
  }.

  local anomaly_eq to {
    parameter x.

    local x2 to x * x.
    local SCz to SnC(alpha * x2).
    return x2 * (rvr0s * SCz["C"] + x * armd1 * SCz["S"]) + x - dts.
  }.

  local x to dts * alpha.

  if (not x0) {
    if alpha > 0 {
      set x0 to x.
    }
    else {
      local s to sign(dts).
      local r to sqrt(-1 / alpha).
      set x0 to s * r * ln(-2 * dts * alpha / (rvr0s + s * r * (1 - alpha))).
    }
  }

  local f0 to anomaly_eq(x0).
  local x1 to 0.
  local f1 to -dts.

  if alpha > 0 { // elliptic orbit
    local ecc to sqrt(1 - alpha * (v2s - rvr0s * rvr0s)).
    local dx to max(2.01 * ecc / sqrt(alpha), tol * abs(x)).
    if f0 < 0 {
      set x1 to min(1.01 * period * alpha, x + dx).
      set f1 to anomaly_eq(x1).
    }
    else if x > dx {
      set x1 to x - dx.
      set f1 to anomaly_eq(x1).
    }
  }
  else { // hyperbolic orbit
    local dx to -x0.
    until sign(f1) * sign(f0) < 0 {
      set dx to dx * 2.
      set x0 to x1.
      set f0 to f1.
      set x1 to x1 + dx.
      set f1 to anomaly_eq(x1).
    }
  }

  if f0 * f1 > 0 {
    print x0.
    print x.
    print x1.
    print f0.
    print f1.
  }
  set x to solv_ridders(anomaly_eq, x0, x1, tol, f0, f1).
  local x2 to x * x.
  local z to alpha * x2.
  local SCz to SnC(z).
  local x2Cz to x2 * SCz["C"].

  local r1 to (1 - x2Cz) * r0s + (dts - x2 * x * SCz["S"]) * v0s.
  local ir1 to 1 / r1:mag.
  local Lfdot to ir1 * x * (z * SCz["S"] - 1).
  local Lgdot to 1 - x2Cz * ir1.

  local v1 to Lfdot * r0s + Lgdot * v0s.

  return list(r1 * rscale, v1 * vscale, x).
}

function GetStateFromOrbit {
  parameter torb, utime, x to False.

  local mu to torb:body:mu.
  local sma to abs(torb:semimajoraxis).
  local mm to sqrt(mu / sma^3).
  local mna to torb:meananomalyatepoch.
  local dts to (utime - torb:epoch) * mm + mna * M_DtR.
  local ecc to torb:eccentricity.
  if ecc < 1 {
    local period to 2 * M_PI.
    until dts <= period set dts to dts - period.
    until dts >= 0 set dts to dts + period.
  }

  local PeNRM to R(0, 0, torb:lan) * R(torb:inclination, 0, torb:argumentofperiapsis).

  local r0s to PeNRM:rightvector * abs(1 - ecc).
  local v0s to PeNRM:upvector * sqrt((1 + ecc) / abs(1 - ecc)).
  local vscale to sqrt(mu / sma).

  local r1v1s to CSER(r0s, v0s, dts, 1, x).
  return list(r1v1s[0] * sma, r1v1s[1] * vscale, r1v1s[2]).
}
