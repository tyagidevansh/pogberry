use "pb.math" as native;

export let pi = 3.141592653589793;
export let e = 2.718281828459045;

export fun abs(value)
{
  if (value == 0)
    return 0;
  if (value < 0)
    return -value;
  return value;
}

export fun floor(value)
{
  return native.floor(value);
}

export fun sqrt(value)
{
  return native.sqrt(value);
}

export fun min(left, right)
{
  if (left < right)
    return left;
  return right;
}

export fun max(left, right)
{
  if (left > right)
    return left;
  return right;
}

export fun clamp(value, minimum, maximum)
{
  if (value < minimum)
    return minimum;
  if (value > maximum)
    return maximum;
  return value;
}

export fun ceil(value)
{
  return native.ceil(value);
}

export fun round(value)
{
  return native.round(value);
}

export fun sin(value)
{
  return native.sin(value);
}

export fun cos(value)
{
  return native.cos(value);
}

export fun tan(value)
{
  return native.tan(value);
}

export fun asin(value)
{
  return native.asin(value);
}

export fun acos(value)
{
  return native.acos(value);
}

export fun atan(value)
{
  return native.atan(value);
}

export fun atan2(y, x)
{
  return native.atan2(y, x);
}

export fun pow(base, exp)
{
  return native.pow(base, exp);
}

export fun lerp(start, end, amount)
{
  return start + (end - start) * amount;
}

export fun dist(x1, y1, x2, y2)
{
  let dx = x2 - x1;
  let dy = y2 - y1;
  return native.sqrt(dx * dx + dy * dy);
}

export fun deg2rad(degrees)
{
  return degrees * (pi / 180.0);
}

export fun rad2deg(radians)
{
  return radians * (180.0 / pi);
}

