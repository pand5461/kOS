@lazyglobal off.
// Ridders' algorithm for finding zeros of functions
// Ridders (1979), IEEE Transactions on Circuits and Systems, 26(11), 979-980
// DOI: 10.1109/TCS.1979.1084580

function solv_ridders {
  parameter fn, x0, x1, rtol to 0.0, verbose to False.

  local MAXITER to 50.
  set rtol to max(rtol, 2^(-53)).

  local xlo to x0.
  local xhi to x1.
  local xmid to 0.
  local flo to fn(x0).
  local fhi to fn(x1).
  local fmid to 0.
  local iter to 1.
  local delta to rtol * (1 + min(abs(x0), abs(x1))) * 0.5.
  local denom to 0.
  local xans to x0.

  if flo * fhi > 0 {
    print "ERROR in SOLV_RIDDERS: root not bracketed between endpoints".
    return 1 / 0.
  }

  if flo = 0 {return xlo.}
  if fhi = 0 {return xhi.}

  until iter > MAXITER {
    set xmid to (xlo + xhi) / 2.
    set delta to rtol * (1 + abs(xmid)) / 2.
    set fmid to fn(xmid).
    local r1 to fmid / flo.
    local r2 to fhi / flo.
    set denom to sqrt(r1 * r1 - r2).

    local dx to (xhi - xlo) * 0.5 * r1 / denom.
    if abs(dx) < delta {
      if dx > 0 {set dx to delta.}
      else {set dx to -delta.}
    }
    set xans to xmid + dx.

   if verbose {
      print iter + ". x = " + xans + "; est_err = " + abs(xhi - xlo) / 2.
    }

    if (abs(xhi - xlo) < 2 * delta) {return xans.}
    local fans to fn(xans).
    if fans = 0 { return fans. }
    if fans * fmid < 0 {
      set xlo to xmid.
      set xhi to xans.
      set flo to fmid.
      set fhi to fans.
    }
    else if fans * flo < 0 {
      set xhi to xans.
      set fhi to fans.
    }
    else {
      set xlo to xans.
      set flo to fans.
    }
    set iter to iter + 1.
  }
  print "WARNING: exceeded MAXITER in SOLV_RIDDERS".
  return xans.
}
