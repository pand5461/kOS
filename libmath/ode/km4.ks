@lazyglobal off.
require("libmath", "linalg").

// Kutta-Merson process
// following [R.H. Merson, "An operational method for the study of integration processes", Proc. Symp. Data Processing, (1957) pp. 110–125]

local c2 is 1/3.
local c3 is 1/3.
local c4 is 0.5.

local a21 is 1/3.
local a31 is 1/6.
local a32 is 1/6.
local a41 is 0.125.
local a43 is 0.375.

local b11 is 0.5.
local b13 is -1.5.
local b14 is 2.

local b21 is 1/6.
local b24 is 2/3.
local b25 is 1/6.

local rpow is -0.25.

// y0: a scalar or a vector or a list
// dydx: a function of two parameters, y and x
// x0, xmax, dx0: scalars
// tol: scalar, desired tolerance at each step
function km4 {
  parameter y0, x0, xmax, dydx, dx0, atol is 0, rtol is 1e-6.

  local argtype is y0:typename.
  local eltype is choose y0[0]:typename() if argtype = "list" else argtype.
  local axpy is gen_axpy(argtype).
  local axpby is gen_axpby(argtype).
  local mul is gen_mul(argtype).
  local sum is gen_sum(argtype).
  local sqnorm is gen_sqnorm(eltype).
  local norm is gen_norm(eltype).
  local integ_error is 0.
  if argtype = "scalar" or argtype = "vector" {
    set integ_error to {
      parameter z1, z2.
      return 0.2 * norm(z2 - z1) / (atol + rtol * max(norm(z1), norm(z2))).
    }.
  } else if argtype = "list" {
    local n is y0:length.
    set integ_error to {
      parameter z1, z2.
      local errorsum is 0.
      for idx in range(n) {
        local sc is (atol + rtol * max(norm(z1[idx]), norm(z2[idx]))).
        set errorsum to errorsum + sqnorm(z2[idx] - z1[idx]) / (sc * sc).
      }
      return 0.2 * sqrt(errorsum / n).
    }.
  } else {
    print "Unknown argument type for KM4: " + argtype.
    return 1/0.
  }
  local y is y0.
  local x is x0.
  local dx is min(xmax - x0, dx0).
  local done is false.
  local nsteps is 0.
  local nrej is 0.
  until done {
    local k1 is dydx(y, x).

    local k2 is dydx(axpy(a21 * dx, k1, y), x + c2 * dx).

    local k3 is dydx(axpy(a31 * dx, sum(k1, k2), y), x + c3 * dx).

    local k4 is axpby(a41, k1,
                      a43, k3).
    set k4 to dydx(axpy(dx, k4, y), x + c4 * dx).

    local k5 is axpy(b11, k1,
                     axpby(b13, k3,
                           b14, k4)).
    local dy1 is mul(dx, k5).
    set k5 to dydx(sum(dy1, y), x + dx).

    local k6 is axpy(b21, k1,
                     axpby(b24, k4,
                           b25, k5)).
    local dy2 is mul(dx, k6).

    local diff is integ_error(dy1, dy2).
    if diff <= 1 {
      set y to sum(axpby(1.2, dy2, -0.2, dy1), y).
      set x to x + dx.
      set nsteps to nsteps + 1.
    } else {
      set nrej to nrej + 1.
    }
    local dxnext is 0.9 * dx * diff^rpow.
    set dx to min(min(xmax - x, dxnext), dx*5).
    if dx <= 0 {set done to true.}
  }
  print "KM4 successful steps: " + nsteps + "; rejected steps: " + nrej.
  return y.
}