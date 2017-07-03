function polorb {
  parameter dtnode is 150.
  local nodet is time:seconds + dtnode.

  local vatnode is velocityat(ship,nodet):orbit.
  local upnode is (positionat(ship,nodet)-body:position):normalized.
  local northax is vxcl(upnode,V(0,1,0)):normalized.

  local prg is vatnode:normalized.
  local nrm is vcrs(prg,upnode):normalized.
  local rad is vcrs(nrm,prg).

  local vnorth is vdot(northax, vatnode).
  local vh is vxcl(upnode,vatnode).
  local vv is vatnode - vh.
  local vhmag is vh:mag.
  local newv is velocity:orbit.
  if vnorth > 0 { set newv to vv + vhmag*northax. }
  else { set newv to vv - vhmag*northax. }

  print vang(newv,vv).
  print vang(vatnode,vv).
  local dv is newv - vatnode.
  local dvprg is vdot(dv,prg).
  local dvrad is vdot(dv,rad).
  local dvnrm is vdot(dv,nrm).

  local nd is node(nodet,dvrad,dvnrm,dvprg).
  add nd.
}
