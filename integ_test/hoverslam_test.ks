@lazyglobal off.
require("libmath/ode", "rk4").
require("libmath", "frame").
require("libmath", "mglobals").
require("libmath/zeros", "ridders").
require("libvessel", "thrustisp").

function gen_alt_stop {
  parameter thrust, vex, centerbody, offset.
  local mu is centerbody:mu.
  local omega is V(0, 0, -centerbody:angularvel:z).
  local maxflow is thrust / vex.
  local rbody is centerbody:radius.
  return {
    parameter pos0, vel0, m0, tlevel.
    local flow is tlevel * maxflow.
    local accfn is {
      parameter rvsrf, t.
      local rsrf is rvsrf[0].
      local vsrf is rvsrf[1].
      local grav is -mu * rsrf / rsrf:sqrmagnitude^1.5.
      local centrifugal is -vcrs(omega, vcrs(omega, rsrf)).
      local coriolis is -2 * vcrs(omega, vsrf).
      return list(vsrf, grav + centrifugal + coriolis - vsrf:normalized * tlevel * thrust / (m0 - flow * t)).
    }.
    local rv is list(pos0, vel0).
    local mnow is m0.
    local tnow is 0.
    until rv[1]:sqrmagnitude < 1e-2 {
      local rsrf is rv[0].
      local vsrf is rv[1].
      local gvec is -mu * rsrf / rsrf:sqrmagnitude^1.5.
      local t_est is mnow * (1 - M_E^(-vsrf:mag / vex)) / flow.
      local dv_est is (vsrf + t_est * gvec):mag.
      local mfin is mnow * M_E^(-dv_est / vex).
      set t_est to (mnow - mfin) / flow.
      local nrksteps is floor(t_est / 15) + 1.
      local dt is t_est / nrksteps.
      set rv to rk4(rv, tnow, accfn, dt, nrksteps).
      set mnow to mfin.
      set tnow to tnow + t_est.
    }
    local req is V(rv[0]:x, rv[0]:y, 0).
    local stop_lat is arctan(rv[0]:z / req:mag).
    local stop_lng is arctan2(req:y, req:x).
    return rv[0]:mag - (centerbody:geopositionlatlng(stop_lat, stop_lng):terrainheight + offset) - rbody.
  }.
}

function gen_hoverslam_thrustlevel {
  parameter centerbody, tmax, vex, offset.
  local stopalt is gen_alt_stop(tmax, vex, centerbody, offset).
  return {
    parameter pos0, vel0, m0, t_start is 0.1, t_max is 1.0.
    return solv_ridders(stopalt:bind(pos0, vel0, m0), t_start, t_max, 1e-4).
  }.
}

function ctrlpart_alt {
  local geo is ship:geoposition.
  local th is choose geo:terrainheight if body:hasocean else max(0, geo:terrainheight).
  return body:altitudeof(ship:controlpart:position) - th.
}

function hoverslam_thrust_simple {
  parameter h, vspeed.
  return (body:mu / body:position:sqrmagnitude + vspeed * vspeed / (2 * h)) * mass.
}

ag1 off.

wait until ag1.

set config:ipu to 2000.

until ship:availablethrust > 0 {
  wait 0.
  stage.
}

set steeringmanager:maxstoppingtime to 5.
lock steering to srfretrograde.

local tv is thrustisp().
local tmax is tv[0].
local vex is tv[1].

local shipbox is ship:bounds.
local bottom is shipbox:furthestcorner(-facing:vector).
local ctrloffset is vdot(ship:controlpart:position - bottom, facing:vector).
local hoverslam_thrustlevel is gen_hoverslam_thrustlevel(body, tmax, vex, ctrloffset).

local desired_thrustlevel is 0.97.

wait until verticalspeed < -10.

clearscreen.
local m0 is mass.

local hstl is 1.
local stopalt is gen_alt_stop(tmax, vex, body, ctrloffset).
local pos0 is ship:controlpart:position-body:position.
local vel0 is velocity:surface.
local xaxis is (latlng(0,0):position - body:position):normalized.

set pos0 to toIRF(pos0, xaxis).
set vel0 to toIRF(vel0, xaxis).

until stopalt(pos0, vel0, m0, hstl) < 0 {
  set hstl to hstl*0.9.
}

set hstl to hstl/0.95.

until hstl >= desired_thrustlevel {
  wait 0.
  set pos0 to ship:controlpart:position-body:position.
  set vel0 to velocity:surface.
  set xaxis to (latlng(0,0):position - body:position):normalized.

  set pos0 to toIRF(pos0, xaxis).
  set vel0 to toIRF(vel0, xaxis).

  set hstl to hoverslam_thrustlevel(pos0, vel0, m0, hstl*0.95, hstl*1.5).
  print "Needed thrustlevel: " + round(hstl, 4) + "     " at (0, 5).
}

lock throttle to hstl.

until verticalspeed > 0 or ctrlpart_alt() < 3 * ctrloffset {
  wait 0.
  set pos0 to ship:controlpart:position-body:position.
  set vel0 to velocity:surface.
  set m0 to ship:mass.
  set xaxis to (latlng(0,0):position - body:position):normalized.

  set pos0 to toIRF(pos0, xaxis).
  set vel0 to toIRF(vel0, xaxis).

  set hstl to hoverslam_thrustlevel(pos0, vel0, m0, hstl*0.9, hstl*1.1).
  print "Needed thrustlevel: " + round(hstl, 4) + "     " at (0, 5).
}

unlock steering.
lock steering to lookdirup(-velocity:surface - body:position:normalized, facing:upvector).

until verticalspeed > 0 {
  set hstl to hoverslam_thrust_simple(ctrlpart_alt(), verticalspeed) / (tmax * vdot(facing:vector, up:vector)).
  wait 0.
}

set hstl to 0.
unlock steering.
lock steering to lookdirup(-body:position:normalized, facing:upvector).

wait until ship:status = "landed".
wait 5.

print "Landing successful".

set ship:control:pilotmainthrottle to 0.
unlock throttle.
unlock steering.