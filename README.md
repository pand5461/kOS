# kOS
set of kOS utilities and complete mission profiles (with craft files)

## Utilities:
* __libinput__ - currently only has library loader
  * require.ks - load (require) and delete (unrequire) other libraries to the vessel storage

* __libmath__ - set of mathematical functions and solvers
  * mglobals.ks - globally defined mathematical constants and functions (sign() and clamp() functions, aliases for g0, Euler's e, pi, angle conversion constants)
  * hyp.ks - direct and inverse hyperbolic functions
  * frame.ks - functions to convert coordinates between reference frames
  * cse.ks - conic state extrapolation from arbitrary initial state
  * lambert.ks - Lambert solver
  * __zeros__ - solvers for equations of one variable
    * brent.ks - Brent-Dekker's algorithm (requires bracketing)
    * ridders.ks - Ridders' algorithm (requires bracketing)
    * steffensen.ks - Steffensen's algorithm (does not need bracketing)
  * __optimize__ - numerical optimization algorithms
    * mincore.ks - bracketing of minima of 1D functions and Brent's linear search algorithm
    * powell.ks - Powell's derivative-free minimization of functions of multiple variables

* __liborbital__ - library for orbital operations.
  * altNodes.ks - gives altitude (AltTA2), direction (UniPosTA2) and velocity (VelTA2) at given true anomaly, and true anomaly of ascending node (TAofAN2)
  * annorm.ks - calculate body-centric AN and normal vectors given orbital inclination and LAN
  * aponode.ks and perinode.ks - plan prograde maneuver nodes at apoapsis / periapsis to change the opposite apsis to a set value
  * circularize.ks - circularize orbit at ship's current position
  * dock.ks - dock to the target port of another vessel
  * etaNodes.ks - functions to calculate time to a given true anomaly, ascending node and descending node (only for elliptic orbits)
  * exenode.ks - execute maneuver node
  * orbdir.ks - calculate body-centric AN and normal vectors of ship's current orbit
  * trimperiod.ks - fine-tune orbital period burning prograde or retrograde
  
* __libvessel__ - functions to get vessel properties
  * thrustisp.ks - get projection of thrust onto current facing vector and effective exhaust velocity for all active engines
  * vesselsize.ks - estimate maximum size of the vessel (useful for safe docking)
  
* __libwarp__ - functions to control time warp
  * warpfor - warp for specified time (unlike kuniverse:timewarp:warpto() will not be interrupted by external events such as KAC alarms or whatnot)
  * warpheight - warp to the specified altitude ASL
  
## Missions:
* __KOT__ - 1-person spacecraft
  * __KOT-1__ - get to LKO and back
  * __KOT-D__ - equipped with a docking port, designed to dock to a target vessel

* __Dockee__ - docking target vessel for KOT-D

* __Kommsat__ - spacecraft for medium-altitude relay network. Designed to start from nonzero latitude and get to equatorial orbit
  * __Kommsat 2__ - same as Kommsat, designed to get into orbit 90 degrees apart from Kommsat 1

* __Mapsat__ - SCANSat probe designed for polar orbit

* __Moona__ - Munar robotic exploration project
  * __Moona 1__ - impactor probe
  * __Moona 2__ - orbiter probe
  * __Moona Pol__ - polar orbiter with SCANSat scanner
  * __Moona 6__ - lander (needs coordinates to land at)

* __L3project__ - Soviet-themed manned Munar landing
  * video: https://youtu.be/KP_vmEz1-34
  * parts from Home-Grown Rockets are highly customized, so no craft file, sorry
