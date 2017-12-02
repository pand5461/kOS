function require {
  parameter lib is "", fn is "".
  if not exists("1:/reqlex.json") {
    writejson(lexicon(), "1:/reqlex.json"). 
  }
  local reqlex to readjson("1:/reqlex.json").
  if lib = "" {
    if fn = "" {
      for l in reqlex:keys {
        for fname in reqlex[l] {
          print "1:/" + l + "/" + fname.
          runpath("1:/" + l + "/" + fname).
        }
      }
    }
    else {
      for l in reqlex:keys {
        for fname in reqlex[l] {
          if fname:contains(fn) runpath("1:/" + lib + "/" + fname).
        }
      }
    }
  }
  else {
    if not reqlex:haskey(lib) {
      reqlex:add(lib, list()).
    }
    local prefix to "1:/" + lib + "/".
    local fload to False.
    if not homeconnection:isconnected or homeconnection:delay > 2 {
      for fname in reqlex[lib] {
        if fname:contains(fn) {
          runpath(prefix + fname).
          set fload to True.
        }
      }
    }
    if (homeconnection:isconnected and homeconnection:delay <= 2) or not fload {
      cd("0:/" + lib).
      list files in fl.
      for f in fl {
        if f:name:contains(fn) {
          if not reqlex[lib]:contains(f:name) {
            reqlex[lib]:add(f:name).
          }
          copypath(f:name, prefix + f:name).
          writejson(reqlex, "1:/reqlex.json").
          runpath(prefix + f:name).
          set fload to True.
        }
      }
      cd("1:/").
    }
    if not fload {
      print "ERROR: Cannot load file".
      print 1/0.
    }
  }
}

function unrequire {
  parameter fn.
  local reqlex to readjson("1:/reqlex.json").
  for l in reqlex:keys {
    local it to reqlex[l]:iterator.
    until not it:next {
      print it:value.
      if it:value:startswith(fn) {
        deletepath("1:/" + l + "/" + it:value).
        print("Removing file " + l + "/" + it:value).
        reqlex[l]:remove(it:index).
        break.
      }
    }
    if reqlex[l]:empty() {
      reqlex:remove(l).
      break.
    }
  }
  writejson(reqlex, "1:/reqlex.json").
}
