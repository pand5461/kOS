set volume(1):name to "landerCPU".
set core:part:tag to "landerCPU".
function require {
  parameter lib, fn is "".
  local prefix to "1:/" + lib + "/".
  if fn = "" {
    if not exists(lib) {
      cd("0:/" + lib).
      list files in fl.
      for f in fl { copypath(f:name, prefix + f:name). }
    }
    cd("1:/" + lib).
    list files in fl.
    for f in fl { runpath(f:name). }
    cd("1:/").
  }
  else {
    set lfn to prefix + fn.
    if not exists(lfn) {
      set fn to "0:/" + lib + "/" + fn.
      copypath(fn, lfn).
    }
    runpath(lfn).
  }
}
require("L3/lander","program.ks").
