@lazyglobal off.
require("libmath", "mglobals").

function min_bracket {
  parameter fn, x0, dx0 to 1.
  // search in direction from x0 to x0 + dx0
  // by default, in positive direction

  local MAXITER to 100.
  local TINY to 1e-20.
  local MAGLIMIT to 10. // how far a parabolic extrapolation step can be, compared to the default

  local f0 to fn(x0).
  if dx0 > 0 {
    local xlo to x0.
    local xmid to x0 + dx0.
    local xhi to xmid + m_gold * (xmid - xlo).
    local xopt to x0.
    local flo to f0.
    local fhi to fn(xhi).
    local fmid to fn(xmid).
    local fopt to f0.
    local iter to 0.
    local dfh to 0.
    local dfl to 0.
    local dxh to 0.
    local dxl to 0.
    local alpha to 0.
    until False {
      set dxl to xmid - xlo.
      set dxh to xhi - xmid.

      set dfl to (fmid - flo) / dxl.
      set dfh to (fhi - fmid) / dxh.
      if (dfl < 0) and (dfh > 0) {
        return list(xlo, xhi).
      }
      set alpha to (dfh - dfl) / (dxl + dxh).

      if alpha > TINY {
        // get the minimum of the parabolic fit thru xlo, xmid and xhi
        set xopt to (xlo + xhi + (flo - fhi) / (alpha * (dxl + dxh))) * 0.5.
        local dxo to xopt - xhi.
        if sign(xopt - xlo) <> sign(dxo) {
          set fopt to fn(xopt).
          if (xopt < xmid) and (fopt <= flo) and (fopt <= fmid) {
            return list(xlo, xmid).
          }
          if (xopt > xmid) and (fopt <= fmid) and (fopt <= fhi) {
            return list(xmid, xhi).
          }
          if (fopt <= flo) and (fopt <= fhi) {
            return list(xlo, xhi).
          }
          set xopt to xhi + M_GOLD * dxh.
          set fopt to fn(xopt).
        }
        else if sign(dxo) <> sign(dxo - MAGLIMIT * dxh) {
          set fopt to fn(xopt).
          if fopt <= fhi {
            local newxopt to xopt + M_GOLD * (xopt - xhi).
            set xmid to xhi.
            set xhi to xopt.
            set xopt to newxopt.
            set fmid to fhi.
            set fhi to fopt.
            set fopt to fn(xopt).
          }
        }
        else {
          set xopt to xhi + M_GOLD * dxh.
          set fopt to fn(xopt).
        }
      }
      else {
        set xopt to xhi + M_GOLD * dxh.
        set fopt to fn(xopt).
      }

      set xlo to xmid.
      set xmid to xhi.
      set xhi to xopt.

      set flo to fmid.
      set fmid to fhi.
      set fhi to fopt.
      print xlo + " " + flo.
      print xmid + " " + fmid.
      print xhi + " " + fhi.
      print "---".
    }
  }
  else if dx0 < 0 {
    local alt_fn to {parameter x. return fn(-x).}.
    local nstraddle to min_bracket(alt_fn, -x0, -dx0).
    return list(-nstraddle[0], -nstraddle[1]).
  }
  else {
    local dir to 0.
    local x1 to x0.
    until dir <> 0 {
      set x1 to x1 + 0.02 * (1 + abs(x1)).
      set dir to fn(x1) - f0.
    }
    if dir < 0 return min_bracket(fn, x0, x1 - x0).
    else return min_bracket(fn, x1, x0 - x1).
  }
}

function linesearch_brent {
  parameter fn, xlo, xhi, rtol to 1e-8.

  local CGOLD to 1 - 1 / M_GOLD.
  local MAXITER to 40.
  local TINY to 1e-20.
  if (xlo > xhi) {
    local tmp to xlo.
    set xlo to xhi.
    set xhi to tmp.
  }

  local dx to xhi - xlo.
  local xmid to xlo + dx / 2.
  local atol to 0.
  local atol2 to 0.
  local xbest to xlo.
  local xsecb to xhi.
  local xspre to xhi.
  local flo to fn(xlo).
  local fhi to fn(xhi).
  local fbest to flo.
  local fsecb to fhi.
  local fspre to fhi.
  if fhi < flo {
    set fbest to fhi.
    set fsecb to flo.
    set fspre to flo.

    set xbest to xhi.
    set xsecb to xlo.
    set xspre to xlo.
  }
  local fcur to fbest.
  local xcur to xbest.
  local dxpre to 0.
  local dxcur to 0.

  local dxl to 0.
  local dxh to 0.
  local dfl to 0.
  local dfh to 0.
  local alpha to 0.
  local niter to 1.

  local function use_goldsection {
    if xbest < xmid { set xcur to xhi - CGOLD * dx. }
    else { set xcur to xlo + CGOLD * dx. }
  }

  until abs(xmid - xbest) < atol2 {
    if abs(dxpre) > atol {
      set dxl to xbest - xsecb.
      set dxh to xspre - xbest.

      set dfl to (fbest - fsecb) / dxl.
      set dfh to (fspre - fbest) / dxh.
      if dxl + dxh <> 0 {
        set alpha to (dfh - dfl) / (dxl + dxh).
      }
      else set alpha to 0.

      if alpha > TINY {
      // get the minimum of the parabolic fit thru xlo, xmid and xhi
        //print "Parabolic fit used".
        set xcur to (xsecb + xspre + (fsecb - fspre) / (alpha * (dxl + dxh))) * 0.5.
      }
      if alpha <= TINY or xcur < xlo or xcur > xhi {
        use_goldsection().
      }
    }
    else {
      use_goldsection().
    }
    set dxpre to dxcur.
    set dxcur to xcur - xbest.
    if abs(dxcur) < atol {
      if dxcur >= 0 set dxcur to atol.
      else set dxcur to -atol.
      set xcur to xbest + dxcur.
    }
    if (xcur - xlo < atol) {
      set xcur to xlo + atol.
    }
    if (xhi - xcur < atol) {
      set xcur to xhi - atol.
    }
    set fcur to fn(xcur).

    if fcur <= fbest {
      if xcur >= xbest { set xlo to xbest. }
      else { set xhi to xbest. }
      set xspre to xsecb.
      set fspre to fsecb.
      set xsecb to xbest.
      set fsecb to fbest.
      set xbest to xcur.
      set fbest to fcur.
    }
    else {
      //print "no improvement".
      //print xlo + " " + xhi + " " + xcur.
      if xcur < xbest { set xlo to xcur. }
      else { set xhi to xcur. }
      if (fcur <= fsecb) or (xsecb = xbest) {
        set xspre to xsecb.
        set fspre to fsecb.
        set xsecb to xcur.
        set fsecb to fcur.
      }
      else if (fcur <= fspre) or (xspre = xbest) or (xspre = xsecb) {
        set xspre to xcur.
        set fspre to fcur.
      }
    }
    //print "Iteration " + niter + ". Current best: " + xbest.
    //print xlo + "  " + xhi.
    set dx to xhi - xlo.
    set xmid to xlo + dx / 2.
    set atol to rtol * (1 + abs(xmid)).
    set atol2 to 2 * atol - dx / 2.
    set niter to niter + 1.
    if niter > MAXITER {
      print "WARNING: exceeded MAXITER in LINSEARCH".
      break.
    }
  }
  print fbest.
  return xbest.
}
