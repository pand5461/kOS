//	Conic State Extrapolation
// Formulas follow H.D. Curtis, Orbital Mechanics for Engineering Students, Chapter 3.7

// Stumpff S and C functions
function SnC {
  parameter z.
  local az to abs(z).
  if az < 1e-4 {
    return lexicon("S", (1 - z * ( 0.05 - z / 840) ) / 6, "C", 0.5 - z * ( 1 - z / 30) / 24).
  }
  else {
    local saz to sqrt(az).
    if z > 0 {
      local x to saz * constant:radtodeg.
      return lexicon("S", (saz - sin(x)) / (saz * az), "C", (1 - cos(x)) / az).
    }
    else {
      local x to constant:e^saz.
      return lexicon("S", (0.5 * (x - 1 / x) - saz) / (saz * az), "C", (0.5 * (x + 1 / x) - 1) / az).
    }
  }
}

// Conic State Extrapolation Routine
function CSER {
  parameter r0v0, dt, mu to body:mu, x0 to 0, tol to 5e-12.
  local rscale to r0v0[0]:mag.
  local vscale to sqrt(mu / rscale).
  local r0s to r0v0[0] / rscale.
  local v0s to r0v0[1] / vscale.
  local dts to dt * vscale / rscale.
  local v2s to r0v0[1]:sqrmagnitude * rscale / mu.
  local alpha to 2 - v2s.
  local armd1 to v2s - 1.
  local rvr0s to vdot(r0v0[0], r0v0[1]) / sqrt(mu * rscale).
  
  local x to x0.
  if x0 = 0 { set x to dts * abs(alpha). }
  local ratio to 1.
  local x2 to x * x.
  local z to alpha * x2.
  local SCz to SnC(z).
  local x2Cz to x2 * SCz["C"].
  local f to 0.
  local df to 0.
  
  until abs(ratio) < tol {
    set f to x + rvr0s * x2Cz + armd1 * x * x2 * SCz["S"] - dts.
    set df to x * rvr0s * (1 - z * SCz["S"]) + armd1 * x2Cz + 1.
    set ratio to f / df.
    set x to x - ratio.
    set x2 to x * x.
    set z to alpha * x2.
    set SCz to SnC(z).
    set x2Cz to x2 * SCz["C"].
  }

  local Lf to 1 - x2Cz.
  local Lg to dts - x2 * x * SCz["S"].
  
  local r1 to Lf * r0s + Lg * v0s.
  local ir1 to 1 / r1:mag.
  local Lfdot to ir1 * x * (z * SCz["S"] - 1).
  local Lgdot to 1 - x2Cz * ir1.

  local v1 to Lfdot * r0s + Lgdot * v0s.
  
  return list(r1 * rscale, v1 * vscale, x).
}
