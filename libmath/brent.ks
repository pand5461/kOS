@lazyglobal off.
// Brent's algorithm for finding zeros of functions
// Coded after Press W.H. et al., Numerical Recipes, 3rd ed.

function solv_brent {
  parameter fn, x0, x1, rtol to 1e-12, verbose to False.

  local MAXITER to 150.

  local xpre to x0.
  local xcur to x1.
  local xblk to xcur.
  local fpre to fn(x0).
  local fcur to fn(x1).
  local fblk to fcur.
  local spre to 0.
  local scur to 0.
  local sbis to 0.
  local delta to rtol.
  local rcb to 0.
  local rcp to 0.
  local rpb to 0.
  local p to 1.
  local q to 1.
  local interptype to "".

  local function lininterp {
    set interptype to " secant ".
    set p to 2 * sbis * rcp.
    set q to 1 - rcp.
  }

  local function iquadinterp {
    set interptype to " inverse quadratic ".
    set rpb to fpre / fblk.
    set rcb to fcur / fblk.
    set p to rcp * (2 * sbis * rpb * (rpb - rcb) - (xcur - xpre) * (rcb - 1)).
    set q to (rpb - 1) * (rcb - 1) * (rcp - 1).
  }

  local function acceptinterp {
    if verbose {print "Using" + interptype + "interpolation".}
    set spre to scur.
    set scur to p / q.
  }

  local function usebisect {
    if verbose {print "Using bisection".}
    set scur to sbis.
    set spre to sbis.
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

    if (fblk * fcur > 0) {
      set xblk to xpre.
      set fblk to fpre.
      set spre to xcur - xpre.
      set scur to spre.
    }

    if abs(fblk) < abs(fcur) {
      set fpre to fcur.
      set xpre to xcur.

      set fcur to fblk.
      set xcur to xblk.

      set fblk to fpre.
      set xblk to xpre.
    }

    set delta to rtol * (1 + abs(xcur)) * 0.5.
    set sbis to (xblk - xcur) / 2.

    if verbose {print "x = " + xcur +"; est_err = " + 2 * abs(sbis).}
    if ((fcur = 0) or (abs(sbis) < delta)) {
      if verbose {print "SOLV_BRENT converged in " + iter + " iterations".}
      return xcur.}

    if ((abs(spre) >= delta) and (abs(fcur) < abs(fpre))) {
      set rcp to fcur / fpre.
      if (xpre = xblk) {lininterp().}
      else {iquadinterp().}

      if (p > 0) {set q to -q.}
      set p to abs(p).

      if 2 * p < min(3 * sbis * q - abs(delta * q), abs(spre * q)) {
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

    if abs(scur) < delta {
      if scur < 0 {set scur to -delta.}
      else {set scur to delta.}
    }
    set xcur to xcur + scur.
    set fcur to fn(xcur).
  }

  print "WARNING: SOLV_BRENT exceeded maximum number of iterations.".
  return xcur.
}

