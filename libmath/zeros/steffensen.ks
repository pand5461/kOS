@lazyglobal off.
// Steffensen's root-finding algorithm

function solv_steffensen {
  parameter fn, x0, rtol to 1e-12, verbose to False.

  local MAXITER to 100.

  local delta to (1 + abs(x0)) * rtol / 2.
  local dx to delta * 2.
  local xans to x0.
  local fcur to 0.
  local fnext to 0.
  local iter to 1.

  until iter > MAXITER {
    set fcur to fn(xans).
    if (fcur = 0) {
      if verbose {print "Solution converged in " + iter + " iterations".}
      return xans.
    }

    set dx to fcur.
    local dxm to max(1, abs(xans)) * 0.01.
    if abs(dx) > dxm {
      if dx < 0 { set dx to -dxm. }
      else { set dx to dxm. }
    }

    set fnext to fn(xans + dx).
    if (fnext = 0) {
      if verbose {print "Solution converged in " + iter + " iterations".}
      return xans + dx.
    }

    if (fnext - fcur) <> 0 {
      set dx to -fcur * dx / (fnext - fcur).
    }
    else { set dx to dxm. }
    until abs(dx) < max(abs(xans), 1) { set dx to dx / 2. }
    set xans to xans + dx.
    set delta to (1 + abs(xans)) * rtol / 2.
    if verbose {
      print "Iteration #" + iter.
      print "x = " + xans + "; est_err = " + abs(dx).
    }
    if abs(dx) < delta {
      if verbose {print "Solution converged in " + iter + " iterations".}
      return xans.
    }
    set iter to iter + 1.
  }

  print "WARNING: exceeded MAXITER in SOLV_STEFFENSEN".
  return xans.
}
