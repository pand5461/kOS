@lazyglobal off.
require("libmath/optimize","mincore").

function minimize_powell3 {
  // Powell's minimization, 3 dimensionals max
  parameter fn, x0, ndir to 3, rtol to 1e-8.

  if ndir > 3 {
    print "ERROR: POWELL3 called with more than 3 optimization variables".
    return 1 / 0.
  }

  local f0 to fn(x0).
  local df to 0.
  local ftol to 0.
  local search_vecs to list(V(1, 0, 0)).
  if ndir > 1 {
    search_vecs:add(V(0,1,0)).
  }
  if ndir > 2 {
    search_vecs:add(V(0,0,1)).
  }
  local xmin to x0.
  local first_iter to True.
  local stol to sqrt(rtol).

  print search_vecs.
  until 2 * df < ftol {
    local fcur to f0.
    local maxdf to 0.
    local imax to 0.
    local svec to search_vecs:iterator.
    until not svec:next() {
      local optfn to {
        parameter x.
        return fn(xmin + x * svec:value).
      }.
      local straddle to min_bracket(optfn, 0, 0, fcur).
      local minpoint to linesearch_brent(optfn, straddle, stol, 3).
      set xmin to minpoint["x"] * svec:value + xmin.
      local df1 to fcur - minpoint["f"].
      set fcur to minpoint["f"].
      if df1 > maxdf { set maxdf to df1. set imax to svec:index. }
    }
    set svec to xmin - x0.
    local xave to xmin + svec.
    local fe to fn(xave).
    local dfe to f0 - fe.

    // weird heuristics from Powell's method
    if dfe < 0 and 2 * (f0 - 2 * fcur + fe) * ((f0 - fcur) - maxdf)^2 < dfe * dfe * maxdf {
      local optfn to { parameter x. return fn(x * svec + xmin). }.
      local straddle to min_bracket(optfn, 0, 0, fcur).
      set d_last to linesearch_brent(optfn, straddle, stol, 3).
      set xmin to d_last["x"] * svec + xmin.
      set fcur to d_last["f"].
      search_vecs:remove(imax).
      search_vecs:add(svec).
    }
    if fe < fcur {
      set xmin to xave.
      set fcur to fe.
    }
    set df to f0 - fcur.
    set ftol to rtol * (1 + abs(f0) + abs(fcur)).
    //print svec.
    print xmin.
    print fcur.
    set x0 to xmin.
    set f0 to fcur.
  }

  return xmin.
}
