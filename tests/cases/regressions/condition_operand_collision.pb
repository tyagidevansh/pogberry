class Holder {
  init() {
    this.flag = true;
  }

  check() {
    let c0 = "c0";
    let c1 = "c1";
    let c2 = "c2";
    let c3 = "c3";
    let c4 = "c4";
    let c5 = "c5";
    let c6 = "c6";
    let c7 = "c7";
    let c8 = "c8";
    let c9 = "c9";
    let c10 = "c10";
    let c11 = "c11";
    let c12 = "c12";
    let c13 = "c13";
    let c14 = "c14";
    let c15 = "c15";
    let c16 = "c16";
    let c17 = "c17";

    if (this.flag) {
      print("flag passed");
    }
  }
}

let h = Holder();
h.check();

// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|flag passed
// END EXPECTED OUTPUT

