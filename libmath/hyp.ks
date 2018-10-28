@lazyglobal off.
require("libmath", "mglobals").

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
