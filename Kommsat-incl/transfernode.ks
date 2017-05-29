function transfernode {
  parameter newperiod is 3600.
  parameter ndeta is 30.
  
  local newsma to (newperiod/(2*constant:pi)*body:mu^0.5)^(2.0/3.0).
  local r0 to orbit:semimajoraxis.
  local v0 to velocity:orbit:mag.
  local a1 to (newsma+r0)/2.
  local Vpe to sqrt( body:mu*(2/r0 - 1/a1) ).
  set deltav to Vpe - v0.
  print "Transfer burn: " + round(v0) + " -> " + round(Vpe) + "m/s".
  set nd to node(time:seconds + ndeta, 0, 0, deltav).
  add nd.
}
