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
