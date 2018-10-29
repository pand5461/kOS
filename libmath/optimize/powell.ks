@lazyglobal off.
require("libmath/optimize","mincore").

function minimize_powell {
  parameter fn, x0, rtol to 1e-8.

  function saxpy {
    //returns a * x + y (a is scalar)
    parameter a, x, y.
    local ix to x:iterator.
    local iy to y:iterator.
    local s to list().
    until not ix:next() {
      iy:next.
      s:add(a * ix:value + iy:value).
    }
    return s.
  }

  function zeros {
    parameter n.
    local ans to list().
    local i to 1.
    until i > n { ans:add(0). set i to i + 1. }
    return ans.
  }

  function close {
    parameter x, y, rtol.
    local ix to x:iterator.
    local iy to y:iterator.
    until not ix:next {
      iy:next.
      if abs(ix:value - iy:value) > rtol * (1 + abs(iy:value)) return False.
    }
    return True.
  }

  local f0 to fn(x0).
  local df to 0.
  local ftol to 0.
  local search_vecs to list().
  local iter to x0:iterator.
  local ndir to x0:length.
  local xmin to x0.
  local xnorm to 0.
  local first_iter to True.
  local atol to rtol * xnorm.
  local d_last to 1.

  until not iter:next() {
    local vec to zeros(ndir).
    set vec[iter:index] to 1.
    search_vecs:add(vec).
  }

  print search_vecs.
  until 2 * abs(df) < ftol {
    local fcur to f0.
    local maxdf to 0.
    local imax to 0.
    local svec to search_vecs:iterator.
    print svec:index.
    until not svec:next() {
      local optfn to {
        parameter x.
        local arg to saxpy(x, svec:value, xmin).
        return fn(arg).
      }.
      local straddle to min_bracket(optfn, 0, 0).
      set xmin to saxpy(linesearch_brent(optfn, straddle[0], straddle[1], rtol), svec:value, xmin).
      local f1 to fn(xmin).
      local df1 to abs(f1 - fcur).
      set fcur to f1.
      if abs(df1) > maxdf { set maxdf to abs(df1). set imax to svec:index. }
    }
    set svec to saxpy(-1, x0, xmin).
    local xave to saxpy (1, xmin, svec).
    local fe to fn(xave).

    local snorm to 0.
    set xnorm to 0.
    local isv to svec:iterator.
    local ix to xmin:iterator.
    until not isv:next {
      ix:next.
      set snorm to snorm + isv:value * isv:value.
      set xnorm to xnorm + ix:value * ix:value.
    }
    set snorm to sqrt(snorm).
    set d_last to snorm.
    set xnorm to sqrt(xnorm).
    set atol to rtol * (1 + xnorm).
    // weird heuristics from Powell's method
    if fe < f0 and 2 * (f0 - 2 * fcur + fe) * ((f0 - fcur) - maxdf)^2 < (f0 - fe)^2 * maxdf {
      local optfn to { parameter x. return fn(saxpy(x, svec, xmin)). }.
      local straddle to min_bracket(optfn, 0, 0).
      set d_last to linesearch_brent(optfn, straddle[0], straddle[1], rtol).
      set xmin to saxpy(d_last, svec, xmin).
      set fcur to fn(xmin).
      set d_last to d_last * snorm.
      search_vecs:remove(imax).
      search_vecs:add(svec).
    }
    set df to fcur - f0.
    set ftol to rtol * (1 + (abs(f0) + abs(fcur)) / 2).
    print svec.
    print xmin.
    print fcur.
    set x0 to xmin.
    set f0 to fcur.
  }

  return xmin.
}
