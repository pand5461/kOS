@lazyglobal off.
require("libmath", "linalg").

local dpc2 is 0.2.
local dpc3 is 0.3.
local dpc4 is 0.8.
local dpc5 is 8/9.

local dpa21 is 0.2.
local dpa31 is 0.075.
local dpa32 is 0.225.
local dpa41 is 44/45.
local dpa42 is -56/15.
local dpa43 is 32/9.
local dpa51 is 19372/6561.
local dpa52 is -25360/2187.
local dpa53 is 64448/6561.
local dpa54 is -212/729.
local dpa61 is 9017/3168.
local dpa62 is -355/33.
local dpa63 is 46732/5247.
local dpa64 is 49/176.
local dpa65 is -5103/18656.

local dpb11 is 35/384.
local dpb13 is 500/1113.
local dpb14 is 125/192.
local dpb15 is -2187/6784.
local dpb16 is 11/84.

// 4th order coeffs are from Shampine's modification
// (Mathematics of Computation V.46, no. 173 (1986), P. 135-150)
local dpb21 is 1951/21600.
local dpb23 is 22642/50085.
local dpb24 is 451/720.
local dpb25 is -12231/42400.
local dpb26 is 649/6300.
local dpb27 is 1/60.

// original DP547M coefficients
// local dpb21 is 5179/57600.
// local dpb23 is 7571/16695.
// local dpb24 is 393/640.
// local dpb25 is -92097/339200.
// local dpb26 is 187/2100.
// local dpb27 is 1/40.

local dprpow is -0.2.

// y0: a scalar or a vector or a list
// dydx: a function of two parameters, y and x
// x0, xmax, dx0: scalars
// tol: scalar, desired tolerance at each step
function dorpri {
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
                               axpy(dpb25, k5,
                                    axpby(dpb26, k6,
                                          dpb27, k7))))).
    local dy4 is mul(dx, k8).

    local diff is integ_error(dy5, dy4).
    if diff <= 1 {
      set y to ynext.
      set x to x + dx.
      set nsteps to nsteps + 1.
      set k1 to k7.
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