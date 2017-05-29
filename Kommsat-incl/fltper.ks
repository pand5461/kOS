function fltper {
  parameter newperiod.
  local atodn to orbit:argumentofperiapsis.
  local Ra to apoapsis + body:radius.
  local Va to sqrt( body:mu * (2/Ra - 1/orbit:semimajoraxis) ).
  local tm to time:seconds + eta:apoapsis - sin(atodn)*Ra/Va.
  if tm < time:seconds set tm to time:seconds + eta:apoapsis.
  local a1 to (newperiod/(2*constant:pi)*body:mu^0.5)^(2.0/3.0).
  local v1 to sqrt(body:mu*(2/Ra-1/a1)).
  local Vc to sqrt(body:mu/Ra).
  local i to orbit:inclination.
  local dVy to Vc*sin(i).
  local dVx to Vc*cos(i)-Va.
  local sqdV to dvx^2+dvy^2. 
  local alpha to (sqrt((Va*dVx)^2+sqdV*(v1^2-Va^2))-Va*dVx)/sqdV.
  if alpha>0.99 set alpha to 1.
  local nd to node(tm,0,alpha*dVy,alpha*dVx).
  add nd.
}
