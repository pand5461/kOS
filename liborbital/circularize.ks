function circularize {
  local a0 is 2.                  // aoa limit
  local kt is 2.                  // gain factor
  local hz is 10.                 // controller rate

  local st is facing.
  local th is 0.
  lock steering to st.
  lock throttle to th.

  until false {
    local sc is sqrt(body:mu/(body:radius+altitude)). //circular speed
    local hv is vxcl(up:vector,velocity:orbit):normalized. //horizontal velocity
    local ev to hv*sc-velocity:orbit.
    if ev:mag < 0.05 break.
    local ad is 1-vang(facing:vector,ev)/a0.
    set st to lookdirup(ev,facing:topvector).
    set th to min(ad*kt*ev:mag*mass/max(1,maxthrust),1).
    if ship:availablethrust = 0 { set th to max(th,0.05). }
    wait 1/hz.
  }
  set th to 0.
  wait 1.
  unlock steering.
  set ship:control:pilotmainthrottle to 0.
  unlock throttle.
}
