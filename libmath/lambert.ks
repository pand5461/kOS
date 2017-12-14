require("libmath", "math.ks").

function lambert2 {
 // Following: Gooding, A procedure for the solution of Lambert's orbital boundary-value problem, Celestial Mechanics and Astronomy 48 (1990), 145-165
 // Der, The superior Lambert algorithm
  parameter r0, r1, dt, mu, prg to 1, tol to 5e-7, utol to 5*tol.
  
  local smu to sqrt(mu).
  local alpha to prg * vcrs(r1, r0):y.
  
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
  local uniC to (r1 - r0) / c.
  local m to r0m + r1m + c.
  local n to m - 2 * c.
  local ism to 1 / sqrt(m).
  local isn to 1 / sqrt(n).
  
  local  tau to 4 * dt * smu / m^1.5.
  local ssign to sign(sin(psi)).
  local s to ssign * sqrt(n / m).
  local s2 to n / m.
  local ds3 to 2 * s2 * s.
  local s2fm1 to 2 * c / m. // 1 - s^2
  

  local tau_p to (2 - ds3) / 3.

  local ttype to 0. // ellipse
  if abs(tau - tau_p) < utol { set ttype to 1. } // parabola
  if tau < tau_p { set ttype to 2. } // hyperbola
  
  local x to ttype.
  local z to 0.

  local tau_me to arccos(s) * m_dtr + s * sqrt(s2fm1).

  local converged to false.
  local order to 2.
  local nmax to 10.
  local f0 to 0.
  local f1 to 1.
  local f2 to 1.
  
  until converged {
    if ttype <> 1 {
      if tau < tau_me {
        set x to tau_me * (tau_me / tau - 1).
      }
      else {
        set x to sqrt((tau - tau_me) / (tau + 0.5 * tau_me)).
      }
    }
    local U to 1 - x * x.
    set z to sqrt(s2 * x * x + s2fm1).
    local niter to 0.
    local ratio to 1.
  
    until abs(ratio) < tol or niter > nmax {
      local y to sqrt(abs(U)).
      local f to y * (z - s * x).
      local g to x * z + s * U.
      local d to 0.
      if U > utol {
        set d to (90 - arctan(g / f)) * m_dtr.
      }
      else if U < -utol {
        set d to ln(f + g).
      }
      if abs(U) > utol {
        set f0 to (s * z + d / y - x) / U.
        set f1 to (x * (3 * f0 + ds3 / z) - 2) / U.
        set f2 to (5 * x * f1 + 3 * f0 - ds3 * s2fm1 / z^3) / U.
      }
      else {
        set f0 to tau_p.
      }

      local diff to f0 - tau.
      local rooted to (order - 1) * ((order - 1) * f1 * f1 - order * diff * f2).
      if rooted > 0 {
        set ratio to order * diff / (f1 * (sqrt(rooted) / abs(f1) + 1)).
      }
      else {
        set ratio to diff / f1.
      }
      print diff / tau + "  " + x.
      set x to x - ratio.
      set U to 1 - x * x.
      set z to sqrt(s2 * x * x + s2fm1).
      set niter to niter + 1.
    }
    if abs(ratio) < tol set converged to true.
    set order to order + 1.
  }
  
  local v to ssign * z * isn.
  local w to x * ism.
  local vcvec to smu * (v + w) * uniC.
  local vr to smu * (v - w).

  return lexicon("v0", vcvec + vr * unir0, "v1", vcvec - vr * unir1).
}
