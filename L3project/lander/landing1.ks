require("libwarp","warpfor.ks").

function GeoDist {
  parameter geocoord.
  parameter normvec to V(0,1,0).
  return abs( vdot(geocoord:altitudeposition(0), normvec:normalized) ).
}

function OrbAngTo {
  parameter pos.
  local nvec to vcrs( body:position, velocity:orbit ):normalized.
  local proj to vxcl(nvec, pos - body:position).
  local angl to arctan2( vdot(nvec, vcrs(body:position, proj)), -vdot(body:position, proj) ).
  if angl < 0 set angl to 360 + angl.
  
  return angl.
}

function WaitOrient {
  parameter tgtcoord.
  parameter maxangle to arcsin(50/velocity:orbit:mag).

  if abs(tgtcoord:lat) > orbit:inclination + maxangle or abs(tgtcoord:lat) > 180 - orbit:inclination + maxangle {return 1/0.}
  local corrlng to tgtcoord:lng + OrbAngTo(tgtcoord:position)*orbit:period/body:rotationperiod.
  local corrtgt to latlng(tgtcoord:lat, corrlng).
  local nvec to vcrs( body:position, velocity:orbit ).
  until GeoDist(corrtgt, nvec) < body:radius * sin(maxangle) and OrbAngTo(corrtgt:position) > 90 {
    set warp to 4.
    wait 10.
    set corrlng to tgtcoord:lng + OrbAngTo(tgtcoord:position)*orbit:period/body:rotationperiod.
    set corrtgt to latlng(tgtcoord:lat, corrlng).
    set nvec to vcrs( body:position, velocity:orbit ).
    print "Angle to target projection: " + round(OrbAngTo(tgtcoord:position)) + "   " at (0,9).
  }
  set warp to 0.
}

function RotateOrbit {
  parameter tgtcoord.
  parameter newpe to -5000.
  
  local corrlng to tgtcoord:lng + 90*orbit:period/body:rotationperiod.
  local corrtgt to latlng(tgtcoord:lat, corrlng).

  warpfor((OrbAngTo(corrtgt:position) - 90)/360*orbit:period).

  local newvdir to heading(corrtgt:heading, 0):vector.

  local newsma to body:radius + (newpe + altitude)*0.5.
  local newvmag to sqrt( body:mu * (2/body:position:mag - 1/newsma) ).
  local newv to newvmag*newvdir.
  local deltav to newv - velocity:orbit.
  
  lock steering to lookdirup(deltav, up:vector).
  wait until vang(facing:vector, deltav) < 1.
  lock throttle to max(0.05, GeoDist(corrtgt, vcrs(body:position, velocity:orbit))/500).
  wait until periapsis < newpe or availablethrust=0.
  lock throttle to 0.
  unlock steering.
}

function waitdownrange {
// assumed acceleration: maxah from 0 to ftfrac*th, change to 0 during last th
  parameter tgtcoord.
  parameter maxahfrac to 0.95.
  parameter ftfrac to min(4,availablethrust*body:radius^2/(mass*body:mu)).
  
  local maxah to maxahfrac*availablethrust/mass.
  local hland to tgtcoord:terrainheight.
  local lock vh to vxcl(up:vector,velocity:orbit - tgtcoord:altitudevelocity(hland):orbit):mag.
  local th to vh/(maxah*(ftfrac + 0.5)).
  
  lock steering to lookdirup(srfretrograde:vector,up:vector).
  until false {
    wait 0.
    set th to vh/(maxah*(ftfrac + 0.5)).
    local stopdist to maxah*th^2*0.5*(1/3 + ftfrac * (1+ftfrac) ).
    local tgtdist to (body:radius + (altitude - hland)/3)*vang(up:vector,tgtcoord:position - body:position)*constant:degtorad.
    if tgtdist < stopdist break.
    set kuniverse:timewarp:rate to (tgtdist - stopdist)/(vh*10).
  }
  return th.
}

function GetVA {
// acceleration changes from a0 to a1 at tau, then to a2 at ts
  parameter hland, v0, geff.
  parameter ts, Isp.

  local dh to altitude - hland.
  
  local g1 to body:mu/(body:radius + hland + dh/3)^2.
  local dv to sqrt(velocity:surface:sqrmagnitude + 2*g1*dh ) + g1*ts/3.
  local a2 to availablethrust/mass - body:mu/(body:radius + hland)^2.
  
  local a0 to -geff.
  local tau to ( ts*(a2*ts - 2*v0) - 6*dh ) / ( 2*v0 + (a0 + a2)*ts ).
  local a1 to ( tau*(a2 - a0) - 2*v0 ) / ts - a2.
  
  print "ts = " + round(ts) + " ; tau = " + round(tau) + " ; a0 = " + round(a0,2) + " ; a1 = " + round(a1,2) + " ; a2 = " + round(a2,2) at (0,11).
  return list(a1, a2, tau).
}

function Descent {
  parameter tgtcoord.
  parameter th, shipheight, Isp.
  parameter ftfrac to min(4,availablethrust*body:radius^2/(mass*body:mu)).
  
  local tburn to th*(1+ftfrac).
  local tend to time:seconds + tburn.
  local hland to tgtcoord:terrainheight + shipheight.
  
  local vv0 to verticalspeed.
  local vh to vxcl(up:vector,velocity:orbit - tgtcoord:altitudevelocity(hland):orbit).
  local ah0 to vh:mag/(th * (ftfrac + 0.5)).

  local hpid to pidloop(0.04, 0, 0.4).
  local vpid to pidloop(0.04, 0, 0.4).
  set hpid:setpoint to 0.
  set vpid:setpoint to 0.
  set hpid:minoutput to -ah0/2.
  set hpid:maxoutput to ah0/2.
  set vpid:minoutput to -body:mu/(body:radius^2*2).

  local av to 0.
  local expdr to ah0*th^2*0.5*(1/3 + ftfrac * (1+ftfrac) ).
  local expalt to altitude.
  
  local alt0 to expalt.
  local tleft to tburn.
  
  local dcenter to body:position:mag.
  local geff to (body:mu/dcenter - vxcl(up:vector,velocity:orbit):sqrmagnitude)/dcenter.
  
  local a1a2tau to getva(hland, vv0, geff, tleft, Isp).
  local a0 to -geff.
  local a1 to a1a2tau[0].
  local a2 to a1a2tau[1].
  local tau to a1a2tau[2].
  
  until tleft <= 0 {
    local hdir to vxcl(up:vector,tgtcoord:position):normalized.
    set vh to vxcl(up:vector,velocity:orbit - tgtcoord:altitudevelocity(hland):orbit).
    set dcenter to body:position:mag.
    set geff to (body:mu/dcenter - vxcl(up:vector,velocity:orbit):sqrmagnitude)/dcenter.
    local maxa to ship:availablethrust / mass.
    
    set tleft to tend - time:seconds.
    local td to tburn - tleft.
    if td < tau set av to a0 + (a1 - a0)*td/tau.
    else set av to a2 + (a1 - a2)*tleft/(tburn - tau).
    local ah to ah0 * min(1, tleft/th).
    
    // expected downrange and altitude
    if tleft > th set expdr to ah0*th^2/6 + ah0 * th/2*(tleft - th) + ah0*(tleft - th)^2/2.
    else set expdr to ah0*tleft^3/(6*th).
    
    if td < tau set expalt to alt0 + vv0*td + a0*td^2 / 2 + (a1 - a0)*td^3/(6*tau).
    else set expalt to hland + a2*tleft^2 / 2 + (a1 - a2)*tleft^3/(6*(tburn - tau)).

    // real values
    local hasl to altitude.
    local dr to (body:radius + (hasl - hland)/3)*vang(up:vector, tgtcoord:position - body:position)*constant:degtorad.
    
    // side velocity component
    local latvel to vxcl(hdir, vh).
    if vdot(hdir, vh) < 0 {
      set dr to -dr.
      set latvel to V(0,0,0).
      set hdir to -hdir.
    }
    local alatvec to -latvel*5/max(tleft,1).
    local ahvec to -hdir*(ah + hpid:update(time:seconds, dr - expdr)).
    local avvec to up:vector*(av + geff + vpid:update(time:seconds, hasl - expalt)).

    print "Hacc: " + round(ahvec:mag,2) + "  Vacc: " + round(avvec:mag,2) + "  Lacc: " + round(alatvec:mag,2) + "     " at (0,13).
    print "Downrange current / predicted: " + round(dr/1000, 2) + " / " + round(expdr/1000, 2) + "      " at (0,14).
    print "Altitude current / predicted: " + round(hasl/1000, 2) + " / " + round(expalt/1000, 2) + "      " at (0,15).
    
    print "HPID output: " + round(hpid:output, 2) + "     " at (0,16).
    set avec to ahvec + avvec + alatvec.
    
    local dup to -body:position.
    if dr <= 0 or vang(facing:vector, up:vector) <= 1 set dup to facing:upvector.
    lock steering to lookdirup(avec,dup).
    lock throttle to avec:mag/maxa.
    if avec:mag/maxa > 1.005 { print " WARNING: not enough TWR" at (25,33). }
    else print "                        " at (25,33).
    if alt:radar < 2*shipheight and verticalspeed > -2 break.
    if velocity:surface:mag < 100 {
      until stage:number = 1 {
        list engines in el.
        for e in el if e:ignition e:shutdown.
        wait 0.2.
        stage.
        wait 0.2.
      }
      gear on.
    }
    wait 0.
  }
}

function VertDescent {
  parameter shipheight.
  parameter endspeed to 1.5.
  
  unlock steering.
  wait 0.
  local av to ship:verticalspeed^2 * 0.5 / max(alt:radar - shipheight, 0.1).

  until status = "Landed" {
    local vh to vxcl(up:vector, velocity:surface).
    set vh to vh / max(1, vh:mag).
    lock steering to lookdirup(up:vector - 0.2*min(1, groundspeed)*vh, facing:upvector).
    if verticalspeed < -abs(endspeed) {
      set av to ship:verticalspeed^2 * 0.5 / max(alt:radar - shipheight, 0.1).
    }
    else set av to -0.1.
    local dcenter to body:position:mag.
    local geff to (body:mu/dcenter - vxcl(up:vector,velocity:orbit):sqrmagnitude)/dcenter.
    lock throttle to mass * (av + geff) / (availablethrust * vdot(facing:vector, up:vector)).
    wait 0.
  }
  lock throttle to 0.
}

function nextlmode {
  parameter newmode is lmode+1.
  set lmode to newmode.
  deletepath("lmode.ks").
  log "set lmode to " + newmode + "." to "lmode.ks".
}

function landing {
  parameter landsite.
  parameter ahmaxfrac, shipheight, Isp.
  
  local stoptime to 0.

  if lmode = 1 {
    waitorient(landsite, 5).
    nextlmode().
  }

  if lmode = 2 {
    rotateorbit(landsite).
    wait 1.
    nextlmode().
  }

  if lmode = 3 {
    set tmax to min(ahmaxfrac, 3*mass*body:mu/(body:radius^2*availablethrust)).
    set stoptime to waitdownrange(landsite, tmax).
    nextlmode().
  }

  if lmode = 4 {
    clearscreen.
    Descent(landsite, stoptime, shipheight, Isp).
    nextlmode().
  }

  if lmode = 5 {
    VertDescent(shipheight).
    lock steering to lookdirup(up:vector, facing:upvector).
    wait 5.
    nextlmode().
  }
  set ship:control:pilotmainthrottle to 0.
  unlock throttle.
  unlock steering.
  wait 0.
  lock steering to "kill".
  wait 10.
}
