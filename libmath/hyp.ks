@lazyglobal off.
require("libmath", "mglobals").

function sinh {
  parameter x.
  local y to M_E^x.
  return 0.5 * (y - 1 / y).
}

function cosh {
  parameter x.
  local y to M_E^x.
  return 0.5 * (y + 1 / y).
}

function tanh {
  parameter x.
  local y to m_e^(2*x).
  return (y - 1) / (y + 1).
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
