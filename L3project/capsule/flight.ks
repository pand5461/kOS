require("libwarp","").
require("liborbital","orbdir.ks").
require("liborbital","dock.ks").

function runfiles {
  parameter fl.
  for f in fl if exists(f) runpath(f).
}

function AlignToSun {
  lock steering to lookdirup(V(0,1,0), Sun:position) + R(0,0,90).
}

function nextmode {
  parameter newmode is satmode+1.
  set satmode to newmode.
  deletepath("mode.ks").
  log "set satmode to " + newmode + "." to "mode.ks".
  AlignToSun().
}

function satprogram {
  runfiles(list("libwarp/warpfor.ks","libwarp/warpheight.ks","liborbital/exenode.ks","liborbital/perinode.ks","liborbital/circularize.ks","liborbital/orbdir.ks","liborbital/dock.ks")).

  print "Starting program in mode " + satmode.
  local aomni to ship:partsnamed("SurfAntenna")[0]:getmodule("ModuleRTAntenna").
  local adish to ship:partstagged("OMAntenna")[0]:getmodule("ModuleRTAntenna").
  if satmode = 0 {
    local Hsat to 75000.
    runpath("0:/L3/wait.ks").
    waitwindow(Hsat).
    require("L3","launch.ks").
    gettoorbit(Hsat).
    deletepath("L3/launch.ks").
    nextmode().
  }
  aligntosun().
  if satmode = 1 {
    require("L3","mode1.ks").
    nextmode().
  }
  if satmode = 2 {
    deletepath("L3/mode1.ks").
    require("liborbital","exenode.ks").
    exenode().
    nextmode().
  }
  if satmode = 3 {
    adish:doevent("activate").
    adish:setfield("target", Kerbin).
    nextmode().
  }
  if satmode = 4 {
    require("L3","flttraj.ks").
    deletepath("L3/flttraj.ks").
    nextmode().
  }
  if satmode = 5 {
    wait min(nextnode:eta, 10).
    require("liborbital","perinode.ks").
    exenode().
    aomni:doevent("deactivate").
    nextmode().
  }
  if satmode = 6 {
    if body:name = "Kerbin" warpfor(eta:transition).
    wait until body:name = "Mun".
    nextmode().
  }
  if satmode = 7 {
    wait 1.
    add node(time:seconds + 120, 0.01, 0, 0).
    wait 0.1.
    local dpedv to (nextnode:orbit:periapsis - orbit:periapsis)*100.
    until abs(nextnode:orbit:periapsis - 25000) < 30 {
      local oldpe to nextnode:orbit:periapsis.
      local dv to (25000 - oldPe)/dpedv.
      set nextnode:radialout to nextnode:radialout + dv.
      set dpedv to (nextnode:orbit:periapsis - oldPe)/dv.
    }
    nextmode().
  }
  if satmode = 8 {
    exenode().
    nextmode().
  }
  if satmode = 9 {
    perinode().
    nextmode().
  }
  if satmode = 10 {
    if hasnode exenode().
    circularize().
    nextmode().
  }
  if satmode = 11 {
    wait until vang(steering:vector, facing:vector) < 1 and ship:angularvel:mag < 0.1.
    processor("landerCPU"):connection:sendmessage("release").
    wait until ship:partsnamed("landerCabinSmall"):length = 0.
    set ship:name to "7K-LOK".
    nextmode().
  }
  if satmode = 12 {
    aomni:doevent("activate").
    wait 2.
    rcs on.
    wait 1.
    set ship:control:fore to 1.
    wait 2.
    set ship:control:translation to V(0,0,0).
    rcs off.
    nextmode().
  }
  if satmode = 13 {
    wait 5.
    dockto(vessel("MunKraft1"):partstagged("landerPort")[0]).
    nextmode().
  }
  if satmode = 14 {
    ladders on.
    local lcan to ship:partsnamed("landerCabinSmall")[0].
    local landerocc to false.
    until landerocc {
      hudtext("Waiting for crew transfer to lander",1,2,18,YELLOW,True).
      wait 2.
      for knaut in ship:crew if knaut:part = lcan set landerocc to true.
    }
    ladders off.
    wait 1.
    nextmode().
  }
  if satmode = 15 {
    ship:dockingports[0]:undock.
    wait 0.5.
    if ship:dockingports:length > 1 { ship:dockingports[1]:undock. }
    wait 0.5.
    if ship:availablethrust = 0 { stage. }
    nextmode().
  }
  if satmode = 16 {
    wait 1.
    rcs on.
    wait 1.
    set ship:control:fore to -1.
    wait 1.
    set ship:control:translation to V(0,0,0).
    rcs off.
    nextmode().
  }
  if satmode = 17 {
    local mesq to ship:messages.
    wait until not mesq:empty.
    local chk to mesq:pop:content.
    if chk = "Rendezvous" nextmode().
  }
  if satmode = 18 {
    dockto(vessel("MunKraft1"):partstagged("landerPort")[0]).
    nextmode().
  }
  if satmode = 19 {
    ladders on.
    if aomni:hasevent("deactivate") aomni:doevent("deactivate").
    local rpod to ship:partsnamedpattern("Soy")[0].
    local rpodcrew to 0.
    until rpodcrew = 2 {
      set rpodcrew to 0.
      hudtext("Waiting for crew return to pod",1,2,18,YELLOW,True).
      for knaut in ship:crew if knaut:part = rpod set rpodcrew to rpodcrew+1.
      wait 2.
    }
    nextmode().
  }
  if satmode = 20 {
    ladders off.
    ship:dockingports[0]:undock.
    wait 0.5.
    if ship:dockingports:length > 1 { ship:dockingports[1]:undock. }
    wait 0.5.
    if ship:availablethrust = 0 { stage. }
    nextmode().
  }
  if satmode = 21 {
    brakes off.
    wait 0.2.
    until brakes {
      hudtext("Activate Brakes group when you're ready for return",1,2,18,YELLOW,True).
      wait 2.
    }
    nextmode().
  }
  if satmode = 22 {
    add node(time:seconds + 60, 0, 0, 300).
    wait 0.1.
    until abs(nextnode:orbit:nextpatch:periapsis - 33000) < 3000 {
      set nextnode:eta to nextnode:eta + 0.5.
    }
    nextmode().
  }
  if satmode = 23 {
    exenode().
    brakes off.
    nextmode().
  }
  if satmode = 24 {
    wait 10.
    if body:name = "Mun" warpfor(eta:transition).
    wait until body:name = "Kerbin".
    adish:doevent("deactivate").
    aomni:doevent("activate").
    nextmode().
  }
  if satmode = 25 {
    wait 2.
    warpheight(body:atm:height + 10000).
    nextmode().
  }
  if satmode = 26 {
    until ship:partstitledpattern("Onion"):length = 0 {
      stage.
      wait 0.5.
    }
    nextmode().
  }
  if satmode = 27 {
    wait 1.
    lock steering to lookdirup(-velocity:surface,body:position).
    warpheight(55000).
    unlock steering.
    warpheight(periapsis + 500).
    set warp to 3.
    wait until alt:radar < 7500 and velocity:surface:mag < 250.
    set warp to 0.
    wait 1.
    stage. //parachutes
    wait until velocity:surface:mag < 20.
    stage. //heatshield
    unlock steering.
    wait until alt:radar < 5.
    stage. //soft landing motors
    wait until status="landed" or status="splashed".
    return 0.
  }
  AlignToSun().
  wait until false.
}

local satmode to 0.
if exists("mode.ks") { runpath("mode.ks"). }
else nextmode(0).

wait 2.

satprogram().
