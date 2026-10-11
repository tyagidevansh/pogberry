let maxJsonNumber = num("1e308");

class Parser
{
  init(text)
  {
    this.text = text;
    this.pos = 0;
    this.failed = false;
  }

  fail()
  {
    this.failed = true;
    this.pos = len(this.text);
    return nil;
  }

  atEnd()
  {
    return this.pos >= len(this.text);
  }

  skipWs()
  {
    while (this.pos < len(this.text))
    {
      let ch = this.text[this.pos];
      if (ch == " " or ch == "\t" or ch == "\n" or ch == "\r") this.pos = this.pos + 1;
      else return nil;
    }
    return nil;
  }

  isDigit(ch)
  {
    return ch == "0" or ch == "1" or ch == "2" or ch == "3" or ch == "4" or ch == "5" or ch == "6" or ch == "7" or ch == "8" or ch == "9";
  }

  parseValue()
  {
    this.skipWs();
    if (this.atEnd()) return this.fail();
    let ch = this.text[this.pos];
    if (ch == "{") return this.parseObject();
    if (ch == "[") return this.parseArray();
    if (ch == "\"") return this.parseString();
    if (ch == "t" or ch == "f" or ch == "n") return this.parseLiteral();
    return this.parseNumber();
  }

  parseObject()
  {
    this.pos = this.pos + 1;
    let obj = {};
    this.skipWs();
    if (!this.atEnd() and this.text[this.pos] == "}")
    {
      this.pos = this.pos + 1;
      return obj;
    }
    while (!this.atEnd())
    {
      this.skipWs();
      if (this.atEnd() or this.text[this.pos] != "\"") return this.fail();
      let key = this.parseString();
      if (this.failed) return nil;
      this.skipWs();
      if (this.atEnd() or this.text[this.pos] != ":") return this.fail();
      this.pos = this.pos + 1;
      let value = this.parseValue();
      if (this.failed) return nil;
      obj[key] = value;
      this.skipWs();
      if (this.atEnd()) return this.fail();
      let ch = this.text[this.pos];
      if (ch == ",") this.pos = this.pos + 1;
      else if (ch == "}")
      {
        this.pos = this.pos + 1;
        return obj;
      }
      else return this.fail();
    }
    return this.fail();
  }

  parseArray()
  {
    this.pos = this.pos + 1;
    let items = [];
    this.skipWs();
    if (!this.atEnd() and this.text[this.pos] == "]")
    {
      this.pos = this.pos + 1;
      return items;
    }
    while (!this.atEnd())
    {
      let value = this.parseValue();
      if (this.failed) return nil;
      items.push(value);
      this.skipWs();
      if (this.atEnd()) return this.fail();
      let ch = this.text[this.pos];
      if (ch == ",") this.pos = this.pos + 1;
      else if (ch == "]")
      {
        this.pos = this.pos + 1;
        return items;
      }
      else return this.fail();
    }
    return this.fail();
  }

  parseString()
  {
    this.pos = this.pos + 1;
    let out = "";
    while (!this.atEnd())
    {
      let ch = this.text[this.pos];
      if (ch == "\"")
      {
        this.pos = this.pos + 1;
        return out;
      }
      if (ch == "\\")
      {
        this.pos = this.pos + 1;
        if (this.atEnd()) return this.fail();
        let esc = this.text[this.pos];
        if (esc == "\"") out = out + "\"";
        else if (esc == "\\") out = out + "\\";
        else if (esc == "/") out = out + "/";
        else if (esc == "n") out = out + "\n";
        else if (esc == "t") out = out + "\t";
        else if (esc == "r") out = out + "\r";
        else return this.fail();
        this.pos = this.pos + 1;
      }
      else
      {
        out = out + ch;
        this.pos = this.pos + 1;
      }
    }
    return this.fail();
  }

  parseLiteral()
  {
    if (this.text.substr(this.pos, 4) == "true")
    {
      this.pos = this.pos + 4;
      return true;
    }
    if (this.text.substr(this.pos, 5) == "false")
    {
      this.pos = this.pos + 5;
      return false;
    }
    if (this.text.substr(this.pos, 4) == "null")
    {
      this.pos = this.pos + 4;
      return nil;
    }
    return this.fail();
  }

  parseNumber()
  {
    let start = this.pos;
    if (!this.atEnd() and this.text[this.pos] == "-") this.pos = this.pos + 1;
    let digits = 0;
    while (!this.atEnd() and this.isDigit(this.text[this.pos]))
    {
      digits = digits + 1;
      this.pos = this.pos + 1;
    }
    if (digits == 0) return this.fail();
    if (!this.atEnd() and this.text[this.pos] == ".")
    {
      this.pos = this.pos + 1;
      let frac = 0;
      while (!this.atEnd() and this.isDigit(this.text[this.pos]))
      {
        frac = frac + 1;
        this.pos = this.pos + 1;
      }
      if (frac == 0) return this.fail();
    }
    if (!this.atEnd() and (this.text[this.pos] == "e" or this.text[this.pos] == "E"))
    {
      this.pos = this.pos + 1;
      if (!this.atEnd() and (this.text[this.pos] == "+" or this.text[this.pos] == "-")) this.pos = this.pos + 1;
      let exp = 0;
      while (!this.atEnd() and this.isDigit(this.text[this.pos]))
      {
        exp = exp + 1;
        this.pos = this.pos + 1;
      }
      if (exp == 0) return this.fail();
    }
    return num(this.text.substr(start, this.pos - start));
  }
}

export fun parse(text)
{
  let parser = Parser(text);
  let value = parser.parseValue();
  if (parser.failed) return nil;
  parser.skipWs();
  if (!parser.atEnd()) return nil;
  return value;
}

fun escapeString(text)
{
  let out = "\"";
  let i = 0;
  while (i < len(text))
  {
    let ch = text[i];
    if (ch == "\"") out = out + "\\\"";
    else if (ch == "\\") out = out + "\\\\";
    else if (ch == "\n") out = out + "\\n";
    else if (ch == "\t") out = out + "\\t";
    else if (ch == "\r") out = out + "\\r";
    else out = out + ch;
    i = i + 1;
  }
  return out + "\"";
}

fun stringifyOrNull(value)
{
  if (value == nil) return "null";
  return stringify(value);
}

fun encodeList(items)
{
  let out = "[";
  let i = 0;
  while (i < len(items))
  {
    if (i > 0) out = out + ",";
    let part = stringifyOrNull(items[i]);
    if (part == nil) return nil;
    out = out + part;
    i = i + 1;
  }
  return out + "]";
}

fun encodeMap(map)
{
  let out = "{";
  let first = true;
  let ks = map.keys();
  let i = 0;
  while (i < len(ks))
  {
    if (type(ks[i]) != "string") return nil;
    if (!first) out = out + ",";
    first = false;
    let part = stringifyOrNull(map[ks[i]]);
    if (part == nil) return nil;
    out = out + escapeString(ks[i]) + ":" + part;
    i = i + 1;
  }
  return out + "}";
}

export fun stringify(value)
{
  let kind = type(value);
  if (kind == "nil") return "null";
  if (kind == "bool")
  {
    if (value) return "true";
    return "false";
  }
  if (kind == "number") {
    if (value > maxJsonNumber or value < -maxJsonNumber) return nil;
    return str(value);
  }
  if (kind == "string") return escapeString(value);
  if (kind == "list") return encodeList(value);
  if (kind == "map") return encodeMap(value);
  return nil;
}
