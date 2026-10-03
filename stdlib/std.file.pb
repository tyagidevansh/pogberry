use "pb_file" as native;

export class File
{
  init(handle)
  {
    this.handle = handle;
  }

  read()
  {
    return native.read(this.handle);
  }

  write(text)
  {
    return native.write(this.handle, text);
  }

  close()
  {
    return native.close(this.handle);
  }
}

export fun open(path, mode)
{
  let handle = native.open(path, mode);
  if (handle == nil) return nil;
  return File(handle);
}

export fun readText(path)
{
  return native.readText(path);
}

export fun writeText(path, text)
{
  return native.writeText(path, text);
}

export fun appendText(path, text)
{
  return native.appendText(path, text);
}

export fun exists(path)
{
  return native.exists(path);
}

export fun delete(path)
{
  return native.delete(path);
}

export fun readBytes(path)
{
  return native.readBytes(path);
}

export fun writeBytes(path, bytes)
{
  return native.writeBytes(path, bytes);
}

export fun listFiles(dir)
{
  return native.listFiles(dir);
}

export fun makeDir(path)
{
  return native.makeDir(path);
}

export fun removeDir(path)
{
  return native.removeDir(path);
}
