@lazyglobal off.
require("libmath", "linalg").

// coefficients from [Sofroniou & Spaletta, Mathematical and Computer Modeling 40 (2004), 1157]
// doi:10.1016/j.mcm.2005.01.010

local c2 is 0.4.
local c3 is 0.6.

local a21 is 0.4.
local a31 is -0.15.
local a32 is 0.75.
local a41 is 19/44.
local a42 is -15/44.
local a43 is 10/11.

local b11 is 11/72.
local b12 is 25/72.
local b13 is 25/72.
local b14 is 11/72.

local b21 is 1251515/8970912.
local b22 is 3710105/8970912.
local b23 is 2519695/8970912.
local b24 is 61105/8970912.
local b25 is 119041/747576.

local rpow is -0.25.

// y0: a scalar or a vector or a list
// dydx: a function of two parameters, y and x
// x0, xmax, dx0: scalars
// tol: scalar, desired tolerance at each step
function ode43 {
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
      return norm(z2 - z1) / (atol + rtol * max(norm(z1), norm(z2))).
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
      return sqrt(errorsum / n).
    }.
  } else {
    print "Unknown argument type for ODE43: " + argtype.
    return 1/0.
  }
  local y is y0.
  local x is x0.
  local dx is min(xmax - x0, dx0).
  local done is false.
  local nsteps is 0.
  local nrej is 0.
  local k1 is "None".
  until done {
    if k1 = "None" {set k1 to dydx(y, x).}

    local k2 is dydx(axpy(a21 * dx, k1, y), x + c2 * dx).

    local k3 is axpby(a31, k1, a32, k2).
    set k3 to dydx(axpy(dx, k3, y), x + c3 * dx).

    local k4 is axpy(a41, k1,
                     axpby(a42, k2,
                           a43, k3)).
    set k4 to dydx(axpy(dx, k4, y), x + dx).

    local k5 is axpy(b11, k1,
                     axpy(b12, k2,
                          axpby(b13, k3,
                                b14, k4))).
    local dy4 is mul(dx, k5).
    local ynext is sum(y, dy4).
    set k5 to dydx(ynext, x + dx).

    local k6 is axpy(b21, k1,
                     axpy(b22, k2,
                          axpy(b23, k3,
                               axpby(b24, k4,
                                     b25, k5)))).
    local dy3 is mul(dx, k6).

    local diff is integ_error(dy3, dy4).
    if diff <= 1 {
      set y to ynext.
      set x to x + dx.
      set nsteps to nsteps + 1.
      set k1 to k5.
    } else {
      set nrej to nrej + 1.
    }
    local dxnext is 0.85 * dx * diff^rpow.
    set dx to min(min(xmax - x, dxnext), dx*5).
    if dx <= 0 {set done to true.}
  }
  print "ODE43 successful steps: " + nsteps + "; rejected steps: " + nrej.
  return y.
}