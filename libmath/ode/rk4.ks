@lazyglobal off.
require("libmath", "linalg").

// y0: a scalar or a vector or a list
// dydx: a function of two parameters, y and x
// x0, dx: scalars
// nsteps: integer
function rk4 {
  parameter y0, x0, dydx, dx, nsteps.

  local argtype is y0:typename.
  local eltype is choose y0[0]:typename() if argtype = "list" else argtype.
  local axpy is gen_axpy(argtype).
  local sum is gen_sum(argtype).

  local y is y0.
  local x is x0.
  local halfdx is 0.5 * dx.
  local sixthdx is dx/6.
  for s in range(1, nsteps+1) {
    local k1 is dydx(y, x).
    set x to x0 + (s - 0.5) * dx.
    local k2 is dydx(axpy(halfdx, k1, y), x).
    local k3 is dydx(axpy(halfdx, k2, y), x).
    set x to x0 + s * dx.
    local k4 is dydx(axpy(dx, k3, y), x).
    local dy is axpy(2, sum(k2, k3), sum(k1, k4)).
    set y to axpy(sixthdx, dy, y).
  }
  return y.
}