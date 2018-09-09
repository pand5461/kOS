@lazyglobal off.
// Brent's algorithm for finding zeros of functions
// Coded after Press W.H. et al., Numerical Recipes, 3rd ed.

function solv_brent {
  parameter fn, x0, x1, rtol to 0.0, verbose to False.

  local MAXITER to 150.
  set rtol to max(rtol, 2^(-53)).

  local xpre to x0. // previous best approx
  local xcur to x1. // current best approx
  local xopp to xcur. // x with opposite sign to xcur
  local fpre to fn(x0). // correspondng function values
  local fcur to fn(x1).
  local fopp to fcur.
  local dxpre to 0. // increment on previous iteration
  local dxcur to 0. // increment on current iteration
  local dxtry to 0. // trial increment
  local dxbin to 0. // would-be increment for binary search
  local dxmax to 1.
  local delta to rtol. // tolerable absolute uncertainty
  local rco to 1. // ratio fcur / fopp
  local rcp to 1. // ratio fcur / fpre
  local rpo to 1. // ratio fpre / fopp
  local interptype to "". // interpolation type (verbose only)

  local function rearrange {
    set xopp to xpre.
    set fopp to fpre.
    set dxpre to xcur - xpre.
    set dxcur to dxpre.
  }

  local function change_best_approximant {
    set fpre to fcur.
    set fcur to fopp.
    set fopp to fpre.

    set xpre to xcur.
    set xcur to xopp.
    set xopp to xpre.
  }

  local function interpolate {
    set rcp to fcur / fpre.
    if (xpre = xopp) {lininterp().}
    else {iquadinterp().}
  }

  local function lininterp {
    set interptype to " secant ".
    set dxtry to 2 * dxbin * rcp / (rcp - 1).
  }

  local function iquadinterp {
    set interptype to " inverse quadratic ".
    set rpo to fpre / fopp.
    set rco to fcur / fopp.
    local dxnum to rcp * (2 * dxbin * rpo * (rpo - rco) - (xcur - xpre) * (rco - 1)).
    local dxden to (rpo - 1) * (rco - 1) * (rcp - 1).
    set dxtry to -dxnum / dxden.
  }

  local function acceptinterp {
    if verbose {print "Using" + interptype + "interpolation".}
    set dxpre to dxcur.
    set dxcur to dxtry.
  }

  local function usebisect {
    if verbose {print "Using bisection".}
    set dxcur to dxbin.
    set dxpre to dxbin.
  }

  local iter to 1.

  if fpre * fcur > 0 {
    print "ERROR in SOLV_BRENT: root not bracketed between endpoints".
    return 1 / 0.
  }

  if fpre = 0 {return xpre.}
  if fcur = 0 {return xcur.}

  until iter > MAXITER {
    if verbose {print "Iteration #" + iter.}
    set iter to iter + 1.

    if (fopp * fcur > 0) { rearrange(). }

    if abs(fopp) < abs(fcur) { change_best_approximant(). }

    set delta to rtol * (1 + abs(xcur)) * 0.5.
    set dxbin to (xopp - xcur) / 2.
    set dxmax to min(3 * abs(dxbin) - delta, abs(dxpre)).

    if verbose {print "x = " + xcur +"; est_err = " + 2 * abs(dxbin).}
    if ((fcur = 0) or (abs(dxbin) < delta)) {
      if verbose {print "SOLV_BRENT converged in " + iter + " iterations".}
      return xcur.}

    if ((abs(dxpre) >= delta) and (abs(fcur) < abs(fpre))) {
      interpolate().
      if (2 * abs(dxtry) < dxmax) and (dxtry * dxbin > 0) {
        acceptinterp().
      }
      else {
        usebisect().
      }
    }
    else {
      usebisect().
    }

    set xpre to xcur.
    set fpre to fcur.

    if abs(dxcur) < delta {
      if dxcur < 0 {set dxcur to -delta.}
      else {set dxcur to delta.}
    }
    set xcur to xcur + dxcur.
    set fcur to fn(xcur).
  }

  print "WARNING: SOLV_BRENT exceeded maximum number of iterations.".
  return xcur.
}
