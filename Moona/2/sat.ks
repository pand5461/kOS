require("libwarp","warpfor.ks").

function runfiles {
  parameter fl.
  for f in fl if exists(f) runpath(f).
}

function AlignToSun {
  lock steering to lookdirup(north:vector,Sun:position).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
}

function frt {
  local tnode to time:seconds + 600.
  local nd to node(tnode,0,0,0).
  add nd.
  local lock returnpatch to nd:orbit:nextpatch:nextpatch.
  until returnpatch:periapsis > 15000 and returnpatch:periapsis < 35000 {
    until returnpatch:periapsis > 15000 set nd:prograde to nd:prograde - 0.02.
    until returnpatch:periapsis < 35000 set nd:prograde to nd:prograde + 0.02.
  }
  print "Free return trajectory computed".
}

function satprogram {
  runfiles(list("exenode.ks","warpfor.ks","warpheight.ks")).
  if satmode = 0 {
    local rh to alt:radar.
    local Hb to 75000.
    require("Moona/2","wait.ks").
    waitwindow(Hb).
    deletepath("wait.ks").
    require("Moona/2","launch.ks").
    gettoorbit(Hb,650,rh*2).
    startnextstage().
    deletepath("launch.ks").
    deletepath("warpheight.ks").
    panels on.
    wait 20.
    nextmode().
  }
  if satmode = 1 {
    require("Moona/2","mode1.ks").
    nextmode().
  }
  if satmode = 2 {
    deletepath("mode1.ks").
    require("liborbital","exenode.ks").
    exenode().
    nextmode().
  }
  if satmode = 3 {
    frt().
    nextmode().
  }
  if satmode = 4 {
    exenode().
    deletepath("exenode.ks").
    require("libwarp","warpheight.ks").
    nextmode().
  }
  if satmode = 5 {
    if body:name = "Kerbin" warpfor(eta:transition).
    nextmode().
  }
  if satmode = 6 {
    wait until body:name = "Mun".
    wait 5.
    for part in ship:parts {
      for m in part:modules {
        if m="ModuleScienceExperiment" or m="dmmodulescienceanimate" {
          for e in part:getmodule(m):allactionnames {
            if e:contains("Log") part:getmodule(m):doaction(e,True).
          }
        }
      }
    }
    wait 30.
    nextmode().
  }
  if satmode = 7 {
    if body:name = "Mun" warpfor(eta:transition).
    wait until body:name = "Kerbin".
    nextmode().
  }
  if satmode = 8 {
    if periapsis > 30000 {
      lock steering to retrograde.
      wait until vang(facing:vector,-velocity:orbit) < 1.
      lock throttle to 1.
      wait until periapsis < 30000.
      lock throttle to 0.
    }
    nextmode().
  }
  if satmode = 9 {
    wait 5.
    warpheight(2*body:atm:height).
    nextmode().
  }
  if satmode = 10 {
    for part in ship:parts {
      for m in part:modules {
        if m="ModuleScienceExperiment" or m="dmmodulescienceanimate" {
          for e in part:getmodule(m):alleventnames {
            if e:contains("Toggle Magnetometer") part:getmodule(m):doevent(e).
          }
        }
      }
    }
    wait 5.
    stage.
    ship:partsnamed("longAntenna")[0]:getmodule("ModuleRTAntenna"):doevent("deactivate").
    ship:partsnamed("ServiceBay.125")[0]:getmodule("ModuleAnimateGeneric"):doevent("Close").
    nextmode().
  }
  if satmode = 11 {
    lock steering to srfretrograde.
    warpheight(periapsis + 500).
    set warp to 3.
    wait until alt:radar < 5000 and velocity:surface:mag < 250.
    set warp to 0.
    wait 1.
    stage.
    wait 1.
    chutes on.
    unlock steering.
    wait until status="landed" or status="splashed".
    return 0.
  }
  until false AlignToSun().
}

local satmode to 0.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).
satprogram().
