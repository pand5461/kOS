@lazyglobal off.
require("libwarp","warpfor.ks").
require("libvessel","thrustisp.ks").
require("libmath","frame.ks").
require("libmath","cse.ks").
require("libmath/optimize","mincore.ks").

function PEG_init {
  parameter peg_state, obj_orbit, TI, flow_rate, vex.
  set peg_state["Vgo"] to GetStateFromOrbit(obj_orbit, peg_state["tnow"])[1] - peg_state["Vnow"].
  set peg_state["Vd"] to peg_state["Vnow"] + peg_state["Vgo"].
  set peg_state["Rd"] to peg_state["Rnow"].
  set peg_state["Rp"] to peg_state["Rnow"].
  set peg_state["Vmag"] to peg_state["Vgo"]:mag.
  set peg_state["tgo_pre"] to 1.
  set peg_state["omega_fctr"] to body:mu / peg_state["Rnow"]:sqrmagnitude^1.5.
  set peg_state["dRg"] to -peg_state["Rnow"] * peg_state["omega_fctr"].
  set peg_state["firstpass"] to True.
  set TI["F1"] to 1.
  set TI["F2"] to 1.
  set TI["F3"] to 1.
  local Vgo_converged to False.
  local niter to 0.
  until Vgo_converged {
    PEG_integ(peg_state, TI, flow_rate, vex).
    PEG_turnr(peg_state, TI).
    PEG_predictor(peg_state, TI).
    set Vgo_converged to (PEG_corrector(peg_state, obj_orbit) < 1e-4).
    set niter to niter + 1.
  }
  if homeconnection:isconnected {
    log "" to "0:/testing/peg_node_log.txt".
    open("0:/testing/peg_node_log.txt"):clear.
  }
  return niter.
}

function PEG_update {
  parameter peg_state.
  wait 0.
  local SPV to solarprimevector.
  local Rnow to -body:position.
  local Vnow to velocity:orbit.
  local dt to time:seconds - peg_state["tnow"].
  local cmass to mass.

  set Vnow to toIRF(Vnow, SPV).
  set Rnow to toIRF(Rnow, SPV).
  set peg_state["mass"] to cmass.
  set peg_state["tgo_pre"] to peg_state["tgo"].
  set peg_state["tnow"] to peg_state["tnow"] + dt.
  set peg_state["omega_fctr"] to body:mu / Rnow:sqrmagnitude^1.5.
  set peg_state["Vgo"] to peg_state["Vgo"] + peg_state["Vnow"] - Vnow - dt * peg_state["omega_fctr"] * Rnow .
  set peg_state["Vmag"] to peg_state["Vgo"]:mag.
  set peg_state["Vnow"] to Vnow.
  set peg_state["Rnow"] to Rnow.
  set peg_state["firstpass"] to True.
}

function PEG_integ {
  parameter peg_state, TI, flow_rate, vex.
  local tau to peg_state["mass"] / flow_rate.
  local Vgom to peg_state["Vmag"].
  local tgo to tau * (1 - M_E^(-Vgom / vex)).
  set peg_state["tgo"] to tgo.
  //print "Vgo: " + Vgom.
  if Vgom / vex > 0.02 {
    set TI["S"] to -Vgom * (tau - tgo) + vex * tgo.
    set TI["Q"] to TI["S"] * tau - 0.5 * vex * tgo * tgo.
  }
  else {
    set TI["S"] to 0.5 * Vgom * tgo.
    set TI["Q"] to TI["S"] * tgo / 3.
  }
  set TI["J"] to Vgom * tgo - TI["S"].
}

function PEG_turnr {
  parameter peg_state, TI.
  local phi_max to 0.5.
  local uniL to peg_state["Vgo"]/peg_state["Vmag"].
  set peg_state["uniL"] to uniL.
  local tgo to peg_state["tgo"].

  if tgo > 5 {
    local JoL to TI["J"] / peg_state["Vmag"].
    local omega_max to phi_max / JoL.
    set TI["Q"] to TI["F2"] * (TI["Q"] - TI["S"] * JoL).
    local dRg to (tgo / peg_state["tgo_pre"])^2 * peg_state["dRg"].
    local Rgo to peg_state["Rd"] - (peg_state["Rnow"] + peg_state["Vnow"] * tgo + dRg).
    set TI["S"] to TI["F3"] * TI["S"].
    set Rgo to Rgo + peg_state["iz"] * (TI["S"] - vdot(uniL, Rgo)) / vdot(peg_state["iz"], uniL).
    local dotL to (Rgo - TI["S"] * uniL) / TI["Q"].
    local omega to dotL:mag.
    local theta to omega * peg_state["tgo"] / 2.
    local delta to omega * JoL - theta.
    if omega > omega_max {
      set dotL to dotL / omega * tan(phi_max * M_RtD) / JoL.
      set theta to omega_max * peg_state["tgo"] / 2.
      set delta to omega_max * JoL - theta.
      set omega to 1e-6.
    }
    if omega < 1e-6 or omega > sqrt(peg_state["omega_fctr"]) {
      set omega to 1e-6.
    }
    local f1 to sin(theta * M_RtD) / theta.
    local cosd to cos(M_RtD * delta).
    set peg_state["F1"] to f1 * cosd.
    set peg_state["F2"] to cosd * 3 * (f1 - cos(M_RtD * theta)) / (theta * theta).
    set peg_state["F3"] to peg_state["F1"] * (1 - theta * delta / 3).
    set peg_state["dotL"] to dotL.
    set peg_state["omega"] to omega.
    set peg_state["Rgo"] to Rgo.
    set peg_state["tL"] to peg_state["tnow"] + tan(omega * JoL * M_RtD) / omega.
  }
  else {
    set peg_state["omega"] to 1e-8.
    set peg_state["dotL"] to V(0,0,0).
    set peg_state["Rgo"] to uniL * TI["S"].
  }
  print "Distance to go: " + peg_state["Rgo"]:mag at (0,16).
}

function PEG_predictor {
  parameter peg_state, TI.
  local tgo to peg_state["tgo"].
  local Vthrust to TI["F1"] * peg_state["Vgo"].
  local Rthrust to peg_state["Rgo"].
  if homeconnection:isconnected {
    log peg_state to "0:/testing/peg_node_log.txt".
  }

  if tgo > 5 {
    local Rc1 to peg_state["Rnow"] - (Rthrust + Vthrust * tgo / 3) / 10.
    local Vc1 to peg_state["Vnow"] + 1.2 * Rthrust / tgo - 0.1 * Vthrust.
    local rvgrav to CSER(Rc1, Vc1, tgo, body:mu, peg_state["xcse"], 1e-7).
    set peg_state["dRg"] to rvgrav[0] - Rc1 - Vc1 * tgo.
    set peg_state["dVg"] to rvgrav[1] - Vc1.
    set peg_state["xcse"] to rvgrav[2].
  }
  else {
    local gVec to -0.5 * (peg_state["Rnow"] * peg_state["omega_fctr"] +
                          body:mu * peg_state["Rp"] / peg_state["Rp"]:sqrmagnitude^1.5).
    set peg_state["dVg"] to gVec * tgo.
    set peg_state["dRg"] to gVec * tgo * tgo / 2.
  }
  set peg_state["Rp"] to peg_state["Rnow"] + peg_state["Vnow"] * tgo + Rthrust + peg_state["dRg"].
  set peg_state["Vp"] to peg_state["Vnow"] + peg_state["dVg"] + Vthrust.
}

function PEG_corrector {
  parameter peg_state, obj_orbit.
  local Rerr to peg_state["Rp"] - peg_state["Rd"].
  print "Position error: " + round(vdot(Rerr, peg_state["uniL"]), 3) + "         " at (0,9).
  local Verr to peg_state["Vp"] - peg_state["Vd"].
  local v2 to Verr:sqrmagnitude.
  print "Velocity error: " + round(sqrt(v2), 3) + "         " at (0,10).
  local tgo to peg_state["tgo"].
  set peg_state["Vgo"] to peg_state["Vgo"] - 0.5 * Verr.
  if v2 >= 1e-4 or peg_state["firstpass"] {
    local RVd to GetStateFromOrbit(obj_orbit, peg_state["tnow"] + peg_state["tgo"]).
    set peg_state["Rd"] to RVd[0].
    set peg_state["Vd"] to RVd[1].
    set peg_state["firstpass"] to False.
  }
  set peg_state["Vmag"] to peg_state["Vgo"]:mag.
  set peg_state["tgo_pre"] to tgo.
  return v2.
}

function exenode_peg {
  clearscreen.
  local nd1 to nextnode.
  local obj_orbit to nd1:orbit.
  local TIsp to ThrustIsp().
  local tt to TIsp[0].
  local vex to TIsp[1].
  if tt = 0 {
    print "ERROR: No active engines!".
    set ship:control:pilotmainthrottle to 0.
    return.
  }
  local flow_rate to tt / vex.
  local m0 to mass.
  local ndv to nd1:deltav:mag.
  local tau to m0 / flow_rate.
  local dob to tau * (1 - M_E^(-ndv / vex)).
  local JoL to tau - vex * dob / ndv.
  wait 0.
  local cur_orbit to ship:orbit.
  local iz to toIRF(nd1:deltav):normalized.

  local function get_position_error {
    parameter dt.
    local utstart to obj_orbit:epoch - dt.
    local RVnow to GetStateFromOrbit(cur_orbit, utstart).
    local peg_state to lex("Rnow", RVnow[0], "Vnow", RVnow[1], "tnow", utstart, "mass", m0, "xcse", False, "omega", 1e-6, "iz", iz).
    local TI to lex().
    PEG_init(peg_state, obj_orbit, TI, flow_rate, vex).
    return (peg_state["Rp"] - peg_state["Rd"]):sqrmagnitude.
  }

  local dt to linesearch_brent(get_position_error@, lex("xlo", JoL, "xhi", m0 * ndv / (2 * tt)), max(0.02 / JoL, 1e-3), 3)["x"].
  local utstart to nd1:orbit:epoch - dt.
  wait 0.
  local SPV to solarprimevector.
  local Rb to body:position.
  local Rnow to positionat(ship, utstart) - Rb.
  local Vnow to velocityat(ship, utstart):orbit.

  local peg_state to lex("Rnow", toIRF(Rnow, SPV), "Vnow", toIRF(Vnow, SPV), "tnow", utstart, "mass", mass, "xcse", False, "omega", 1e-6, "iz", iz).
  local TI to lex().
  local maxiter to PEG_init(peg_state, obj_orbit, TI, flow_rate, vex).
  local peg_steer to lex("L", peg_state["uniL"], "dL", peg_state["dotL"], "tL", peg_state["tL"]).
  local done to False.
  local once to True.
  local lock tm to round(missiontime).

  set ship:control:pilotmainthrottle to 0.

  warpfor(utstart - time:seconds - 60 - dob / 30).
  sas off.
  rcs off.

  print "T+" + tm + " Turning ship to burn direction.".
  local lock steer_vector to fromIRF(peg_steer["L"] + peg_steer["dL"] * (time:seconds - peg_steer["tL"])).
  lock steering to lookdirup(steer_vector, -body:position).
  wait until (vang(steer_vector, facing:vector) < 0.05 and
             ship:angularvel:mag < max(0.05, 1.5 * peg_state["omega"])) or
             utstart - time:seconds < 10.
  warpfor(utstart - time:seconds - 10).
  print "T+" + tm + " Burn start " + round(obj_orbit:epoch - utstart, 2) + " s before node.".
  local tset to 0.
  lock throttle to tset.
  wait until time:seconds >= utstart.
  set tset to clamp(peg_state["Vmag"] * m0 / tt, 0, 1).
  until done {
    local PEG_conv to False.
    local niter to 0.
    PEG_update(peg_state).
    until PEG_conv or niter > maxiter {
      set niter to niter + 1.
      PEG_integ(peg_state, TI, flow_rate, vex).
      PEG_turnr(peg_state, TI).
      PEG_predictor(peg_state, TI).
      set PEG_conv to (PEG_corrector(peg_state, obj_orbit) < 1e-4).
    }
    set maxiter to clamp(niter, 1, maxiter).
    set tset to clamp(1.5 * peg_state["Vmag"] * mass / tt, 0.02, 1).
    if PEG_conv {
      print "PEG converged in " + niter + " iterations" at (0,15).
      set peg_steer["L"] to peg_state["uniL"].
      set peg_steer["dL"] to peg_state["dotL"].
      set peg_steer["tL"] to peg_state["tL"].
    }
    if vdot(iz, peg_state["Vgo"]) < 0 {
      print "T+" + tm + " Burn aborted, remain dv " + round(peg_state["Vgo"]:mag,1) + "m/s, vdot: " + round(vdot(iz, peg_state["Vgo"]),1).
      lock throttle to 0.
      break.
    }
    if tset < 1 {
      wait 0.
      local Rb to body:position.
      unlock steer_vector.
      local steer_vector to velocityat(ship, time:seconds + tset / 1.5):orbit - (velocity:orbit + tset / 1.5 * body:mu * Rb / Rb:sqrmagnitude^1.5).
      lock steering to lookdirup(steer_vector, -body:position).
      local ndsma to nd1:orbit:semimajoraxis.
      local s0 to sign((orbit:semimajoraxis - ndsma)).
      local s1 to s0.
      set iz to fromIRF(iz).
      until s0 <> s1 or vdot(steer_vector, iz) < 0 {
        wait 0.
        local dtr to steer_vector:mag * mass / tt.
        set Rb to body:position.
        set steer_vector to velocityat(ship, time:seconds + dtr):orbit - (velocity:orbit + dtr * body:mu * Rb / Rb:sqrmagnitude^1.5).
        set tset to clamp(1.5 * dtr, 0.02, 1).
        set s1 to sign(orbit:semimajoraxis - ndsma).
      }
      lock throttle to 0.
      print "T+" + tm + " Burn finished, remain dv " + round(steer_vector:mag, 2) + "m/s".
      set done to True.
    }
  }
  print "Total dv spent: " + round(vex * ln(m0 / mass), 1) + "m/s".
  print "T+" + tm + " Ap: " + round(apoapsis/1000,2) + " km, Pe: " + round(periapsis/1000,2) + " km".
  print "T+" + tm + " Remaining LF: " + round(stage:liquidfuel, 1).
  unlock all.
  set ship:control:pilotmainthrottle to 0.
  wait 1.
}
