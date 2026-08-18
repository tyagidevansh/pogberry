let nativeAbs = abs;
let nativeFloor = floor;
let nativeSqrt = sqrt;

export let pi = 3.141592653589793;
export let e = 2.718281828459045;

export fun abs(value)
{
  return nativeAbs(value);
}

export fun floor(value)
{
  return nativeFloor(value);
}

export fun sqrt(value)
{
  return nativeSqrt(value);
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
