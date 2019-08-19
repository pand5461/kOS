@lazyglobal off.

// r0, v0: scalars or vectors
// accfn: a function of two parameters, r and t
// t0, dt: scalars
// nsteps: integer
function verlet {
  parameter r0, v0, t0, accfn, dt, nsteps.
  local pos is r0.
  local vel is v0.
  local t is t0.
  local halfdt is 0.5 * dt.
  local acc is accfn(pos, t).
  for k in range(1, nsteps+1) {
    set vel to vel + acc * halfdt.
    set pos to pos + vel * dt.
    set t to t0 + k * dt.
    set acc to accfn(pos, t).
    set vel to vel + acc * halfdt.
  }
  return list(pos, vel).
}