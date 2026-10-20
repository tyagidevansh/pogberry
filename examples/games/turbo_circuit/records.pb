// TURBO CIRCUIT: OVERDRIVE — Lap Records & High Score Persistence
use "pb_file" as file;

export class RecordManager {
  init(filepath) {
    this.path = filepath;
    // Default best lap times in seconds for each F1 track
    this.records = [88.50, 54.20, 102.50, 78.40];
    this.load();
  }

  load() {
    if (!file.exists(this.path)) {
      this.save();
      return;
    }
    let text = file.readText(this.path);
    if (text == nil or text == "") return;

    let lines = text.split("\n");
    for (let i = 0; i < len(lines); i += 1) {
      let line = lines[i];
      if (line != "" and i < len(this.records)) {
        let val = num(line);
        if (val > 0.0) {
          this.records[i] = val;
        }
      }
    }
  }

  save() {
    let out = "";
    for (let i = 0; i < len(this.records); i += 1) {
      out = out + str(this.records[i]) + "\n";
    }
    file.writeText(this.path, out);
  }

  getRecord(trackId) {
    if (trackId >= 0 and trackId < len(this.records)) {
      return this.records[trackId];
    }
    return 99.99;
  }

  submitLapTime(trackId, time) {
    if (time <= 0.0) return false;
    if (trackId >= 0 and trackId < len(this.records)) {
      if (time < this.records[trackId]) {
        this.records[trackId] = time;
        this.save();
        return true; // New record!
      }
    }
    return false;
  }
}

