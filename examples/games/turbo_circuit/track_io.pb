// TURBO CIRCUIT: OVERDRIVE — Track Serialization & Persistence Engine
use "pb_file" as file;
use "constants" as const;
use "f1_data" as f1;
use "std.math" as math;

fun isDigit(ch) {
  let digits = "0123456789";
  return digits.find(ch) >= 0;
}

fun isIdentChar(ch) {
  let valid = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
  return valid.find(ch) >= 0;
}

export class JsonParser {
  init(src) {
    this.src = src;
    this.pos = 0;
    this.len = len(src);
  }

  skipWhitespace() {
    while (this.pos < this.len) {
      let ch = this.src.substr(this.pos, 1);
      if (ch == " " or ch == "\t" or ch == "\n" or ch == "\r") {
        this.pos = this.pos + 1;
      } else {
        break;
      }
    }
  }

  peek() {
    this.skipWhitespace();
    if (this.pos >= this.len) return "";
    return this.src.substr(this.pos, 1);
  }

  parseString() {
    this.pos = this.pos + 1;
    let start = this.pos;
    while (this.pos < this.len) {
      let ch = this.src.substr(this.pos, 1);
      if (ch == "\"") {
        let res = this.src.substr(start, this.pos - start);
        this.pos = this.pos + 1;
        return res;
      }
      this.pos = this.pos + 1;
    }
    return "";
  }

  parseNumber() {
    let start = this.pos;
    while (this.pos < this.len) {
      let ch = this.src.substr(this.pos, 1);
      if (isDigit(ch) or ch == "-" or ch == "." or ch == "e" or ch == "E" or ch == "+") {
        this.pos = this.pos + 1;
      } else {
        break;
      }
    }
    return num(this.src.substr(start, this.pos - start));
  }

  parseArray() {
    this.pos = this.pos + 1;
    let arr = [];
    this.skipWhitespace();
    if (this.peek() == "]") {
      this.pos = this.pos + 1;
      return arr;
    }
    while (this.pos < this.len) {
      let val = this.parseValue();
      arr.push(val);
      this.skipWhitespace();
      let ch = this.peek();
      if (ch == ",") {
        this.pos = this.pos + 1;
      } else if (ch == "]") {
        this.pos = this.pos + 1;
        break;
      }
    }
    return arr;
  }

  parseObject() {
    this.pos = this.pos + 1;
    let obj = {};
    this.skipWhitespace();
    if (this.peek() == "}") {
      this.pos = this.pos + 1;
      return obj;
    }
    while (this.pos < this.len) {
      this.skipWhitespace();
      let key = this.parseString();
      this.skipWhitespace();
      if (this.peek() == ":") this.pos = this.pos + 1;
      let val = this.parseValue();
      obj[key] = val;
      this.skipWhitespace();
      let ch = this.peek();
      if (ch == ",") {
        this.pos = this.pos + 1;
      } else if (ch == "}") {
        this.pos = this.pos + 1;
        break;
      }
    }
    return obj;
  }

  parseValue() {
    this.skipWhitespace();
    let ch = this.peek();
    if (ch == "\"") return this.parseString();
    if (ch == "[") return this.parseArray();
    if (ch == "{") return this.parseObject();
    if (ch == "t" or ch == "f") {
      if (this.src.substr(this.pos, 4) == "true") { this.pos = this.pos + 4; return true; }
      if (this.src.substr(this.pos, 5) == "false") { this.pos = this.pos + 5; return false; }
    }
    if (ch == "n") {
      if (this.src.substr(this.pos, 4) == "null") { this.pos = this.pos + 4; return nil; }
    }
    return this.parseNumber();
  }
}

export fun parseJson(src) {
  if (src == nil or src == "") return nil;
  let p = JsonParser(src);
  return p.parseValue();
}

export fun stringifyJson(val) {
  let t = type(val);
  if (t == "nil") return "null";
  if (t == "bool") {
    if (val) return "true";
    return "false";
  }
  if (t == "number") return str(val);
  if (t == "string") return "\"" + val + "\"";
  if (t == "list") {
    let s = "[";
    for (let i = 0; i < len(val); i += 1) {
      if (i > 0) s = s + ", ";
      s = s + stringifyJson(val[i]);
    }
    return s + "]";
  }
  if (t == "map") {
    let s = "{";
    let ks = val.keys();
    for (let i = 0; i < len(ks); i += 1) {
      if (i > 0) s = s + ", ";
      let k = ks[i];
      s = s + "\"" + str(k) + "\": " + stringifyJson(val[k]);
    }
    return s + "}";
  }
  return "null";
}

export fun getCustomTracksDir() {
  return "custom_tracks";
}

export fun ensureCustomTracksDir() {
  let dir = getCustomTracksDir();
  if (!file.exists(dir)) {
    file.makeDir(dir);
  }
}

export fun copyColor(col) {
  if (col == nil) return [255, 255, 255];
  return [col[0], col[1], col[2]];
}

export fun exportOfficialTrack(id) {
  let spec = const.getTrackSpec(id);
  let nodes = f1.getF1Nodes(id);
  let copiedNodes = [];
  for (let i = 0; i < len(nodes); i += 1) {
    copiedNodes.push([nodes[i][0], nodes[i][1]]);
  }

  let elevations = [];
  let tunnels = [];

  if (id == 0) {
    // Suzuka elevations
    elevations.push({ "s": 0.0, "y": 6.0 });
    elevations.push({ "s": 1500.0, "y": 9.5 });
    elevations.push({ "s": 3710.0, "y": 1.0 }); // Underpass
    elevations.push({ "s": 5000.0, "y": 7.5 });
    elevations.push({ "s": 7460.0, "y": 14.5 }); // Bridge overpass
    elevations.push({ "s": 9500.0, "y": 6.0 });
  } else if (id == 1) {
    // Spa elevations
    elevations.push({ "s": 0.0, "y": 12.0 });
    elevations.push({ "s": 800.0, "y": 4.0 });  // Foot of Eau Rouge
    elevations.push({ "s": 1400.0, "y": 28.0 }); // Raidillon crest
    elevations.push({ "s": 3800.0, "y": 24.0 }); // Les Combes
    elevations.push({ "s": 6200.0, "y": 10.0 }); // Pouhon
    elevations.push({ "s": 11500.0, "y": 14.0 }); // Blanchimont
  } else if (id == 2) {
    // Monza elevations
    elevations.push({ "s": 0.0, "y": 4.0 });
    elevations.push({ "s": 2800.0, "y": 5.5 });  // Curva Grande
    elevations.push({ "s": 5500.0, "y": 3.0 });  // Lesmo
    elevations.push({ "s": 8500.0, "y": 4.5 });  // Ascari
    elevations.push({ "s": 10500.0, "y": 4.0 }); // Parabolica
  } else {
    // Monaco elevations
    elevations.push({ "s": 0.0, "y": 0.5 });
    elevations.push({ "s": 480.0, "y": 0.5 });
    elevations.push({ "s": 1350.0, "y": 7.5 }); // Beau Rivage top
    elevations.push({ "s": 1740.0, "y": 7.5 }); // Casino crest
    elevations.push({ "s": 2650.0, "y": 1.0 }); // Hairpin descent
    elevations.push({ "s": 2720.0, "y": 0.8 }); // Portier entry
    elevations.push({ "s": 5200.0, "y": 0.8 }); // Quayside
    elevations.push({ "s": 5500.0, "y": 0.5 });
    tunnels.push({ "startS": 2720.0, "endS": 3570.0, "name": "The Tunnel" });
  }

  let def = {
    "version": 1,
    "id": "official_" + str(id),
    "baseTrackId": id,
    "name": spec["name"],
    "subtitle": spec["subtitle"],
    "difficulty": spec["difficulty"],
    "laps": spec["laps"],
    "length": spec["length"],
    "roadWidth": spec["roadWidth"],
    "curbWidth": spec["curbWidth"],
    "runoffWidth": spec["runoffWidth"],
    "skyColor": copyColor(spec["skyColor"]),
    "skyTop": copyColor(spec["skyTop"]),
    "skyBottom": copyColor(spec["skyBottom"]),
    "railColorA": copyColor(spec["railColorA"]),
    "railColorB": copyColor(spec["railColorB"]),
    "roadR": spec["roadR"],
    "roadG": spec["roadG"],
    "roadB": spec["roadB"],
    "curbR": spec["curbR"],
    "curbG": spec["curbG"],
    "curbB": spec["curbB"],
    "groundColor": copyColor(spec["groundColor"]),
    "nodes": copiedNodes,
    "elevations": elevations,
    "tunnels": tunnels
  };
  return def;
}

export fun saveTrackFile(filename, trackDef) {
  ensureCustomTracksDir();
  let path = getCustomTracksDir() + "/" + filename;
  let json = stringifyJson(trackDef);
  file.writeText(path, json);
}

export fun loadTrackFile(filename) {
  let path = getCustomTracksDir() + "/" + filename;
  if (!file.exists(path)) return nil;
  let text = file.readText(path);
  if (text == nil or text == "") return nil;
  return parseJson(text);
}

export fun deleteTrackFile(filename) {
  let path = getCustomTracksDir() + "/" + filename;
  if (file.exists(path)) {
    file.delete(path);
  }
}

export fun listCustomTracks() {
  ensureCustomTracksDir();
  let dir = getCustomTracksDir();
  let entries = file.listFiles(dir);
  if (entries == nil) return [];
  let tracks = [];
  for (let i = 0; i < len(entries); i += 1) {
    let name = entries[i];
    let endIdx = len(name) - 5;
    if (endIdx > 0 and name.substr(endIdx, 5) == ".json") {
      let def = loadTrackFile(name);
      if (def != nil and def["nodes"] != nil and len(def["nodes"]) >= 3) {
        tracks.push({
          "filename": name,
          "trackDef": def
        });
      }
    }
  }
  return tracks;
}

export fun cleanIdentifier(strVal) {
  let out = "";
  for (let i = 0; i < len(strVal); i += 1) {
    let ch = strVal.substr(i, 1);
    if (isIdentChar(ch)) {
      out = out + ch;
    } else if (ch == " " or ch == "-") {
      out = out + "_";
    }
  }
  if (out == "") out = "custom_track";
  return out;
}

export fun forkTrack(trackId, customName) {
  let baseDef = nil;
  if (type(trackId) == "number" and trackId >= 0 and trackId < 4) {
    baseDef = exportOfficialTrack(trackId);
  } else if (type(trackId) == "number" and trackId >= 4) {
    let orig = f1.getCustomTrack(trackId);
    if (orig != nil) {
      let json = stringifyJson(orig);
      baseDef = parseJson(json);
    }
  }

  if (baseDef == nil) return nil;

  let cleanName = cleanIdentifier(customName);
  let filename = cleanName + ".json";

  baseDef["id"] = cleanName;
  baseDef["name"] = customName;
  baseDef["subtitle"] = "Custom Circuit // User Edition";

  saveTrackFile(filename, baseDef);
  return {
    "filename": filename,
    "trackDef": baseDef
  };
}
