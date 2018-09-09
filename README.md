# kOS
set of kOS utilities and complete mission profiles (with craft files)

Utilities:
* libinput - currently only has library loader
  * require.ks - load (require) and delete (unrequire) other libraries to the vessel storage

* libmath - set of mathematical functions and solvers
  * math.ks - useful mathematical functions (direct and inverse hyperbolic functions, sign, short aliases for Euler e, pi, degtorad and radtodeg)
  * frame.ks - functions to convert coordinates between reference frames
  * cse.ks - conic state extrapolation from arbitrary initial state
  * brent.ks - Brent-Dekker's root-finding algorithm
  * lambert.ks - Lambert solver

* liborbital - library for orbital operations.
  * altNodes - gives altitude (AltTA2), direction (UniPosTA2) and velocity (VelTA2) at given true anomaly, and true anomaly of ascending node (TAofAN2)
  * annorm.ks - calculate body-centric AN and normal vectors given orbital inclination and LAN
  * aponode.ks and perinode.ks - plan prograde maneuver nodes at apoapsis / periapsis to change the opposite apsis to a set value
  * circularize.ks - circularize orbit at ship's current position
  * dock.ks - dock to the target port of another vessel
  * etaNodes.ks - functions to calculate time to a given true anomaly, ascending node and descending node (only for elliptic orbits)
  * exenode.ks - execute maneuver node
  * orbdir.ks - calculate body-centric AN and normal vectors of ship's current orbit
  * trimperiod.ks - fine-tune orbital period burning prograde or retrograde
  
* libvessel - functions to get vessel properties
  * thrustisp.ks - get projection of thrust onto current facing vector and effective exhaust velocity for all active engines
  * vesselsize.ks - estimate maximum size of the vessel (useful for safe docking)
  
* libwarp - functions to control time warp
  * warpfor - warp for specified time (unlike kuniverse:timewarp:warpto() will not be interrupted by external events such as KAC alarms or whatnot)
  * warpheight - warp to the specified altitude ASL
  
Missions:
* KOT - 1-person spacecraft
  * KOT-1 - get to LKO and back
  * KOT-D - equipped with a docking port, designed to dock to a target vessel

* Dockee - docking target vessel

* Kommsat - spacecraft for medium-altitude relay network. Designed to start from nonzero latitude and get to equatorial orbit
  * Kommsat 2 - same as Kommsat, designed to get into orbit 90 degrees apart from Kommsat 1

* Mapsat - SCANSat probe designed for polar orbit

* Moona - Munar robotic exploration project
  * Moona 1 - impactor probe
  * Moona 2 - orbiter probe
  * Moona Pol - polar orbiter with SCANSat scanner
  * Moona 6 - lander (needs coordinates to land at)

* L3project - Soviet-themed manned Munar landing
  * video: https://youtu.be/KP_vmEz1-34
  * parts from Home-Grown Rockets are highly customized, so no craft file, sorry
