function require {
  parameter lib is "", fn is "".
  local wd to path().
  if exists("1:/reqlex.json") = false {
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
    if reqlex:haskey(lib) = false {
      reqlex:add(lib, list()).
    }
    local prefix to "1:/" + lib + "/".
    local fhere to False.
    if (homeconnection:isconnected = false) or homeconnection:delay > 2 {
      for fname in reqlex[lib] {
        if fname:contains(fn) {
          set fhere to exists(prefix + fname).
        }
      }
    }
    if (homeconnection:isconnected and homeconnection:delay <= 2) or fhere = false {
      cd("0:/" + lib).
      list files in fl.
      for f in fl {
        if f:name:contains(fn) {
          if reqlex[lib]:contains(f:name) = false {
            reqlex[lib]:add(f:name).
          }
          copypath(f:name, prefix + f:name).
          writejson(reqlex, "1:/reqlex.json").
          set fhere to exists(prefix + f:name).
        }
      }
      cd(wd).
    }    
    if fhere = false {
      print "ERROR: Cannot load file".
      print 1/0.
    }
    for fname in reqlex[lib] {
      if fname:contains(fn) { runpath(prefix + fname). }
    }
  }
}

function unrequire {
  parameter fn.
  local reqlex to readjson("1:/reqlex.json").
  for l in reqlex:keys {
    local it to reqlex[l]:iterator.
    until it:next = false {
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
