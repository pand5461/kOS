@lazyglobal off.

function require {
  parameter lib is "", fn is "".
  local wd to path().
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
    local fhere to False.
    if (not homeconnection:isconnected) or homeconnection:delay > 2 {
      for fname in reqlex[lib] {
        if fname:contains(fn) {
          set fhere to exists(prefix + fname).
        }
      }
    }
    if (homeconnection:isconnected and homeconnection:delay <= 2) or not fhere {
      cd("0:/" + lib).
      local fl to 0.
      list files in fl.
      for f in fl {
        if f:name:contains(fn) and f:name:endswith(".ks") {
          local cname to f:name:replace(".ks", ".ksm").
          if not reqlex[lib]:contains(cname) {
            reqlex[lib]:add(cname).
          }
          compile f:name to (prefix + cname).
          writejson(reqlex, "1:/reqlex.json").
          set fhere to exists(prefix + cname).
        }
      }
      cd(wd).
    }
    if fhere = false {
      print "ERROR: Cannot load file".
      print 1/0.
    }
    for fname in reqlex[lib] {
      if fname:contains(fn) {
        print "Loading " + prefix + fname.
        runpath(prefix + fname).
      }
    }
  }
  print "Required files loaded".
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
