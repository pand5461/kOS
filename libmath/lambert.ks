@lazyglobal off.
require("libmath", "mglobals").
require("libmath", "hyp").
require("libmath/zeros", "ridders").

// The following function assumes that coordinate system is right-handed
// and the normal to the base plane is the Z axis (V(0,0,1)).
// To convert from the standard kOS frame, either swap :y and :z components
// or use toIRF() function from libmath

function lambert {
 // Following: Gooding, A procedure for the solution of Lambert's orbital boundary-value problem, Celestial Mechanics and Astronomy 48 (1990), 145-165
 // Lancaster and Blanchard, A unified form of Lambert's theorem, NASA Technical Note D-5368
 // PRG = if the transfer is prograde relative to the base plane
  parameter r0, r1, dt, mu, prg to 1, tol to 1e-15, utol to 5*tol.

  local smu to sqrt(mu).
  local atol to 0.
  local alphavec to (prg * vcrs(r0, r1)):normalized.
  local alpha to alphavec:z.

  local psi to vang(r0, r1).
  if alpha < 0 {
    set psi to 360 - psi.
  }
  print psi.

  local r0m to r0:mag.
  local r1m to r1:mag.
  local unir0 to r0 / r0m.
  local unir1 to r1 / r1m.
  local c to (r1 - r0):mag.
  local m to r0m + r1m + c.
  local n to m - 2 * c.

  local tau to 8 * dt * smu / m^1.5.
  local ssign to sign(sin(psi)).
  local s to ssign * sqrt(n / m).
  local s2 to n / m.
  local qs3 to 4 * s2 * s.
  local s2fm1 to 2 * c / m. // 1 - s^2

  local tau_p to (4 - qs3) / 3.

  local ttype to 0. // ellipse
  if abs(tau - tau_p) < tol { set ttype to 1. } // parabola
  if tau < tau_p { set ttype to 2. } // hyperbola

  local tau_me to 2 * (arccos(s) * m_dtr + s * sqrt(s2fm1)).

  local get_d to {
    parameter f, g.
    return (90 - arctan(g / f)) * m_dtr.
  }.

  local get_y to {
    parameter U.
    return sqrt(U).
  }.

  if ttype = 2 {
    set get_d to {
      parameter f, g.
      return ln(f + g).
    }.
    set get_y to {
      parameter U.
      return sqrt(-U).
    }.
  }

 local function tof {
    parameter x.
    local U to 1 - x * x.
    if abs(U) < utol {
      return 0.
    }
    local y to get_y(U).
    local z to sqrt(s2 * x * x + s2fm1).
    local f to y * (z - s * x).
    local g to x * z + s * U.
    return 2 * (s * z + get_d(f, g) / y - x) / U - tau.
  }

  local x0 to 1.
  local x1 to 1.

  if ttype <> 1 {
    if tau < tau_me {
      set x0 to tau_me * (tau_me / tau - 1).
    }
    else {
      set x0 to sqrt((tau - tau_me) / (tau + 0.5 * tau_me)).
    }
  }

  local tof0 to tof(x0).
  if ttype = 0 {
    if tof0 < 0 {
      set x1 to (x0 - 1) / 2.
      local tof1 to tof(x1).
      until tof1 >= 0 {
        set tof0 to tof1.
        set x0 to x1.
        set x1 to (x0 - 1) / 2.
        set tof1 to tof(x1).
      }
    }
  }
  else if ttype = 2 {
    if tof0 > 0 {
      set x1 to x0 * 2.
      local tof1 to tof(x1).
      until tof1 <= 0 {
        set tof0 to tof1.
        set x0 to x1.
        set x1 to 2 * x1.
        set tof1 to tof(x1).
      }
    }
  }

  local x to solv_ridders(tof@, x0, x1, tol).
  local z to sqrt(s2 * x * x + s2fm1).
  local gamma to 0.5 * smu * sqrt(m).
  local rho to 0.
  local ss to 0.
  if c > 0 {
    set rho to (r0m - r1m) / c.
    set ss to 2 * sqrt(r0m * r1m) / c * sin(0.5 * psi).
  }
  local rszpx to rho * (s * z + x).
  local szmx to s * z - x.

  local vr0 to gamma * (szmx - rszpx) / r0m.
  local vr1 to -gamma * (szmx + rszpx) / r1m.

  local vt to gamma * ss * (z + s * x).

  return lexicon("v0", vr0 * unir0 - vt / r0m * vcrs(alphavec, unir0), "v1", vr1 * unir1 - vt / r1m * vcrs(alphavec, unir1)).
}
