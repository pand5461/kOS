global m_pi to constant:pi.
global m_e to constant:e.
global m_rtd to constant:radtodeg.
global m_dtr to constant:degtorad.

function sinh {
  parameter x.
  return 0.5 * (m_e^x - m_e^(-x)).
}

function cosh {
  parameter x.
  return 0.5 * (m_e^x + m_e^(-x)).
}

function tanh {
  parameter x.
  local y to m_e^(2*x)
  return (y - 1) / (y + 1).
}

function sign {
  parameter x.
  if x > 0 { return 1. }
  if x < 0 { return -1. }
  return 0.
}

function bnd {
  parameter x, b1, b2.
  local xmin to min(b1, b2).
  local xmax to max(b1, b2).
  
  if x < xmin { return xmin. }
  if x > xmax { return xmax. }
  return x.
}

function arsinh {
  parameter x.
  return ln(x + sqrt(x * x + 1)).
}

function arcosh {
  parameter x.
  return ln(x + sqrt(x * x - 1)).
}

function artanh {
  parameter x.
  return 0.5 * ln((1 + x) / (1 - x)).
}
