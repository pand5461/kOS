@lazyglobal off.
// a * x + y
function gen_axpy {
  parameter type.
  if type = "list" {
    return {
      parameter a, x, y.
      local z is x:copy().
      for i in range(x:length()) {
        set z[i] to a * x[i] + y[i].
      }
      return z.
    }.
  }
  else if type = "scalar" or type = "vector" {
    return {parameter a, x, y. return a * x + y.}.
  }
  else {
    print "Cannot generate AXPY for type " + type.
    return 1/0.
  }
}

// a * x + b * y
function gen_axpby {
  parameter type.
  if type = "list" {
    return {
      parameter a, x, b, y.
      local z is x:copy().
      for i in range(x:length()) {
        set z[i] to a * x[i] + b * y[i].
      }
      return z.
    }.
  }
  else if type = "scalar" or type = "vector" {
    return {parameter a, x, b, y. return a * x + b * y.}.
  }
  else {
    print "Cannot generate AXPBY for type " + type.
    return 1/0.
  }
}

function gen_sum {
  parameter type.
  if type = "list" {
    return {
      parameter x, y.
      local z is x:copy().
      for i in range(x:length()) {
        set z[i] to x[i] + y[i].
      }
      return z.
    }.
  }
  else if type = "scalar" or type = "vector" {
    return {parameter x, y. return x + y.}.
  }
  else {
    print "Cannot generate SUM for type " + type.
    return 1/0.
  }
}

function gen_mul {
  parameter type.
  if type = "list" {
    return {
      parameter a, x.
      local z is x:copy().
      for i in range(x:length()) {
        set z[i] to a * x[i].
      }
      return z.
    }.
  }
  else if type = "scalar" or type = "vector" {
    return {parameter a, x. return a * x.}.
  }
  else {
    print "Cannot generate MUL for type " + type.
    return 1/0.
  }
}

function gen_norm {
  parameter type, eltype is "None".
  if type = "scalar" {return abs@.}
  else if type = "vector" {
    return {parameter x. return x:mag.}.
  } else if type = "list" {
    local sqnorm is gen_sqnorm(eltype).
    return {
      parameter x.
      local sq is 0.
      for elt in x {set sq to sq + sqnorm(elt).}
      return sqrt(sq).
    }.
  } else {
    print "Cannot generate NORM for type " + type.
    return 1/0.
  }
}

function gen_sqnorm {
  parameter type.
  if type = "scalar" {
    return {parameter x. return x * x.}.
  } else if type = "vector" {
    return {parameter x. return x:sqrmagnitude.}.
  } else {
    print "Cannot generate SQNORM for type " + type.
    return 1/0.
  }
}