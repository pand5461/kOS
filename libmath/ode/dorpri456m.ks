@lazyglobal off.
require("libmath", "linalg").

local dpc2 is 0.2.
local dpc3 is 0.3.
local dpc4 is 0.6.
local dpc5 is 2/3.

local dpa21 is 0.2.
local dpa31 is 0.075.
local dpa32 is 0.225.
local dpa41 is 0.3.
local dpa42 is -0.9.
local dpa43 is 1.2.
local dpa51 is 226/729.
local dpa52 is -25/27.
local dpa53 is 880/729.
local dpa54 is 55/729.
local dpa61 is -181/270.
local dpa62 is 2.5.
local dpa63 is -266/297.
local dpa64 is -91/27.
local dpa65 is 189/55.

local dpb11 is 19/216.
local dpb13 is 1000/2079.
local dpb14 is -125/216.
local dpb15 is 81/88.
local dpb16 is 5/56.

local dpb21 is 31/540.
local dpb23 is 190/297.
local dpb24 is -145/108.
local dpb25 is 351/220.
local dpb26 is 0.05.

local dprpow is -0.2.

// y0: a scalar or a vector or a list
// dydx: a function of two parameters, y and x
// x0, xmax, dx0: scalars
// tol: scalar, desired tolerance at each step
function dorpri456m {
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
    print "Unknown argument type for DORPRI: " + argtype.
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

    local k2 is dydx(axpy(dpa21 * dx, k1, y), x + dpc2 * dx).

    local k3 is axpby(dpa31, k1, dpa32, k2).
    set k3 to dydx(axpy(dx, k3, y), x + dpc3 * dx).

    local k4 is axpy(dpa41, k1,
                     axpby(dpa42, k2,
                           dpa43, k3)).
    set k4 to dydx(axpy(dx, k4, y), x + dpc4 * dx).

    local k5 is axpy(dpa51, k1,
                     axpy(dpa52, k2,
                          axpby(dpa53, k3,
                                dpa54, k4))).
    set k5 to dydx(axpy(dx, k5, y), x + dpc5 * dx).

    local k6 is axpy(dpa61, k1,
                     axpy(dpa62, k2,
                          axpy(dpa63, k3,
                               axpby(dpa64, k4,
                                     dpa65, k5)))).
    set k6 to dydx(axpy(dx, k6, y), x + dx).

    local k7 is axpy(dpb11, k1,
                     axpy(dpb13, k3,
                          axpy(dpb14, k4,
                               axpby(dpb15, k5,
                                     dpb16, k6)))).
    local dy5 is mul(dx, k7).
    local ynext is sum(y, dy5).
    set k7 to dydx(ynext, x + dx).

    local k8 is axpy(dpb21, k1,
                     axpy(dpb23, k3,
                          axpy(dpb24, k4,
                               axpby(dpb25, k5,
                                     dpb26, k6)))).
    local dy4 is mul(dx, k8).

    local diff is integ_error(dy5, dy4).
    if diff <= 1 {
      set y to ynext.
      set x to x + dx.
      set nsteps to nsteps + 1.
      set k1 to "None".
    } else {
      set nrej to nrej + 1.
    }
    local dxnext is 0.85 * dx * diff^dprpow.
    set dx to min(min(xmax - x, dxnext), dx*5).
    if dx <= 0 {set done to true.}
  }
  print "DORPRI successful steps: " + nsteps + "; rejected steps: " + nrej.
  return y.
}