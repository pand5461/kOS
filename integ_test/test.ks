@lazyglobal off.
require("libmath/ode", "verlet").
require("libmath/ode", "rk4").
require("libmath/ode", "dorpri.ks").
require("libmath/ode", "dorpri456m.ks").
require("libmath/ode", "km4.ks").
require("libmath/ode", "ode43.ks").
require("libmath", "frame").

core:doevent("open terminal").

function reactive_acc_r {
  parameter thrust, vex, m0, r, t.
  local mflow is thrust / vex.
  return -thrust / (m0 - t * mflow).
}

function reactive_acc_rv {
  parameter thrust, vex, m0, rv, t.
  local mflow is thrust / vex.
  return list(rv[1], -thrust / (m0 - t * mflow)).
}

function grav_acc_r {
  parameter centerbody.
  return {
    parameter r, t.
    return -centerbody:mu * r:sqrmagnitude^(-1.5) * r.
  }.
}

function grav_acc_rv {
  parameter centerbody.
  return {
    parameter rv, t.
    local r is rv[0].
    return list(rv[1], -centerbody:mu * r:sqrmagnitude^(-1.5) * r).
  }.
}

local spos0 is 0.
local svel0 is 500.
local srv0 is list(spos0, svel0).

local thrust is 50.
local vex is 3500.
local mfin is 1.
local m0 is mfin * constant:e^(svel0 / vex).
local maxtime is (m0 - mfin)/(thrust / vex).

local t_fwd is 15800. //Gilly:orbit:period.
set config:ipu to 1000.
wait 0.
local t_fin is time:seconds + t_fwd.
local spv is solarprimevector.
local init_r is Gilly:position - Gilly:body:position.
local init_v is Gilly:orbit:velocity:orbit.
local fin_r is positionat(Gilly, t_fin) - Gilly:body:position.
local fin_v is velocityat(Gilly, t_fin):orbit.

set init_r to toIRF(init_r, spv).
set init_v to toIRF(init_v, spv).
set fin_r to toIRF(fin_r, spv).
set fin_v to toIRF(fin_v, spv).


local init_rv is list(init_r, init_v).

local gravity_verlet is grav_acc_r(Gilly:body).
local gravity_rk is grav_acc_rv(Gilly:body).

set config:ipu to 200.

local nsteps_verlet is 50.
local nsteps_rk4 is 8.

clearscreen.
print "Verlet integration".
wait 0.
local t0 is time:seconds.
print verlet(init_r, init_v, 0, gravity_verlet, t_fwd / nsteps_verlet, nsteps_verlet).
print "Time: " + (time:seconds - t0).

print "RK4 integration".
wait 0.
set t0 to time:seconds.
print rk4(init_rv, 0, gravity_rk, t_fwd / nsteps_rk4, nsteps_rk4).
print "Time: " + (time:seconds - t0).

print "Adaptive step integration".
wait 0.
set t0 to time:seconds.
print dorpri(init_rv, 0, t_fwd, gravity_rk, t_fwd/2, 1e-1, 1e-7).
print "Time: " + (time:seconds - t0).

print "Reference".
// print svel0 * m0 / (thrust / vex) - vex * maxtime.
// print 0.
print fin_r.
print fin_v.