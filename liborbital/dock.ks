require("libvessel","vesselsize.ks").

function bnd {
  parameter val, minval, maxval.
  return min(maxval, max(minval, val)).
}

function tgtmove {
  parameter tgtport, pos, vmax to 3.
  
  local rcsacc to 0.
  list parts in pl.
  for p in pl
    for i in range(0,p:modules:length) {
      local m to p:getmodulebyindex(i).
      if m:name = ("ModuleRCSFX") and m:getfield("rcs")
          set rcsacc to rcsacc+m:getfield("thrust limiter")*0.01.
    }

  set rcsacc to rcsacc/ship:mass.
  print "RCS acceleration: " + round(rcsacc,2) at (0,35).
  set vmax to min(3,vmax).
  local safespeed to min(vmax, sqrt(rcsacc*(tgtport:nodeposition-ship:controlpart:position):mag)).

  local vtgt to ship:velocity:orbit - tgtport:ship:velocity:orbit.
  local v0 to safespeed*(tgtport:nodeposition - ship:controlpart:position - pos):normalized.
  local dv to v0-vtgt.
  local fc to ship:facing.
  set ship:control:fore to bnd(vdot(dv, fc:vector),-1,1).
  set ship:control:starboard to bnd(vdot(dv, fc:starvector),-1,1).
  set ship:control:top to bnd(vdot(dv, fc:topvector),-1,1).
}

function dockto {
  parameter tgtport.
  
  local icp to ship:controlpart.

  if ship:controlpart:title <> tgtport:title {
    local myport to ship:partsnamed(tgtport:name)[0].
    myport:controlfrom.
  }
  
  local safedst to vesselsize(tgtport:ship)+vesselsize(ship).
  
  local lock vtgt to ship:velocity:orbit - tgtport:ship:velocity:orbit.
  
  rcs on.
  local f0 to ship:facing.
  lock steering to f0.
  until tgtport:nodeposition:mag > safedst {
    tgtmove(tgtport, tgtport:nodeposition:normalized*(safedst+1)).
    wait 0.
  }
  set ship:control:translation to V(0,0,0).
  
  lock steering to lookdirup(-tgtport:facing:vector, tgtport:facing:upvector).
  until vtgt:sqrmagnitude < 0.04 {
    local fc to ship:facing.
    set ship:control:fore to bnd(vdot(-vtgt, fc:vector),-1,1).
    set ship:control:starboard to bnd(vdot(-vtgt, fc:starvector),-1,1).
    set ship:control:top to bnd(vdot(-vtgt, fc:topvector),-1,1).
    wait 0.
  }
  set ship:control:translation to V(0,0,0).
  
  print "Safety bubble radius: " + round(safedst).
  local lock newpos to (vxcl(tgtport:facing:vector,tgtport:nodeposition):normalized-tgtport:facing:vector)*safedst.
  local lock dsq to (tgtport:nodeposition - ship:controlpart:position - newpos):sqrmagnitude.
  until dsq < 1 {
    tgtmove(tgtport,newpos, max((tgtport:nodeposition - ship:controlpart:position):mag*0.02,0.5)).
    wait 0.
  }
  
  local lock newpos to -safedst*tgtport:facing:vector.
  print "Getting in front of target port".
  until dsq < 0.25 {
    tgtmove(tgtport,newpos,(tgtport:nodeposition - ship:controlpart:position):mag*0.02).
    wait 0.
  }
  
  local lock newpos to -0.5*tgtport:facing:vector.
  print "Performing final docking approach".
  until dsq < 0.01 or ship:elements:length > 1 {
    tgtmove(tgtport,newpos,0.2).
    wait 0.
  }
  
  rcs off.
  icp:controlfrom.
}
