require("libvessel","vesselsize.ks").

function bnd {
  parameter val, minval, maxval.
  return min(maxval, max(minval, val)).
}

function tgtmove {
  parameter tgtport, dr, vmax.

  local vtgt to ship:velocity:orbit - tgtport:ship:velocity:orbit.
  local v0 to vmax*dr:normalized.
  local dv to v0-vtgt.
  local fc to ship:facing.
  local tf to bnd(vdot(dv, fc:vector),-1,1).
  local ts to bnd(vdot(dv, fc:starvector),-1,1).
  local tt to bnd(vdot(dv, fc:topvector),-1,1).
  set ship:control:translation to V(ts,tt,tf).
}

function ControlBackup {
  if not exists("controlrestore.ks")
  log "for p in ship:parts if p:uid = " + char(34) + ship:controlpart:uid + char(34) + " p:controlfrom." to "controlrestore.ks".
}

function dockto {
  parameter tgtport.

  print tgtport.
  rcs on.  
  controlbackup().

  if (not ship:dockingports:contains(ship:controlpart)) or (ship:controlpart:nodetype <> tgtport:nodetype)  {
    for myport in ship:dockingports {
      if myport:nodetype = tgtport:nodetype {
        myport:controlfrom.
        break.
      }
    }
  }

  local eln to ship:elements:length.
  local safedst to vesselsize(tgtport:ship)+vesselsize(ship).
  local safedst0 to safedst.
  print "Safety bubble radius: " + round(safedst).

  local lock vtgt to ship:velocity:orbit - tgtport:ship:velocity:orbit.

  local f0 to ship:facing.
  lock steering to f0.
  
  local lock tgtpos to tgtport:nodeposition:normalized*(safedst+1).
  local lock dr to tgtport:nodeposition - ship:controlpart:position - tgtpos.
  until tgtport:nodeposition:mag > safedst {
    tgtmove(tgtport, dr, 3).
    wait 0.
  }
  set ship:control:translation to V(0,0,0).
  unlock steering. wait 0.2.
  
  lock steering to lookdirup(-tgtport:facing:vector, tgtport:facing:upvector).
  until vtgt:sqrmagnitude < 0.04 {
    local fc to ship:facing.
    set ship:control:fore to bnd(vdot(-vtgt, fc:vector),-1,1).
    set ship:control:starboard to bnd(vdot(-vtgt, fc:starvector),-1,1).
    set ship:control:top to bnd(vdot(-vtgt, fc:topvector),-1,1).
    print ship:control:translation + "                " at (0,10).
    wait 0.
  }
  set ship:control:translation to V(0,0,0).
  
  local lock tgtpos to (vxcl(tgtport:facing:vector,tgtport:nodeposition):normalized-tgtport:facing:vector)*safedst.
  local lock vsafe to min(5,max(0.15,(tgtport:nodeposition - ship:controlpart:position):mag/safedst0)).
  if vdot(tgtport:nodeposition, facing:vector) < safedst - 1 {
    until dr:sqrmagnitude < 1 {
      tgtmove(tgtport,dr,vsafe).
      print "Safe docking speed: " + round(vsafe,2) at (0,20).
      wait 0.
    }
  }

  local lock tgtpos to -safedst*tgtport:facing:vector.
  print "Getting in front of target port".
  until dr:mag < vsafe {
    tgtmove(tgtport,dr,vsafe).
    wait 0.
  }
  
  unlock tgtpos.
  print "Performing final docking approach".
  until (tgtport:nodeposition - ship:controlpart:position):mag < tgtport:acquirerange*1.25 or ship:elements:length > eln {
    set safedst to safedst*0.75.
    set tgtpos to -safedst*tgtport:facing:vector.
    until dr:mag < tgtport:acquirerange*0.5 {
      set tgtpos to -safedst*tgtport:facing:vector.
      tgtmove(tgtport,dr,max(vsafe,0.1)).
      wait 0.
    }
  }
  
  set ship:control:translation to V(0,0,0).
  rcs off.
  unlock steering.
  wait 0.
  runpath("controlrestore.ks").
  wait until ship:elements:length > eln.
  wait 0.2.
}
