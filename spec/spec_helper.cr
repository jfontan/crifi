require "spec"
require "../src/find"

module Generator
  extend self
  @@path : String = ""
  @@files : Array(String) = Array(String).new

  def generate(
    dirs : Int,
    hidden_dirs : Int,
    files : Int,
    hidden_files : Int,
    depth : Int
  )
    f = File.tempfile("find")
    @@path = f.path
    f.delete
    Dir.mkdir_p(@@path)
    @@files = mkfiles(@@path, dirs, hidden_dirs, files, hidden_files, depth)
    @@files.sort!
  end

  def clean
    FileUtils.rm_rf(@@path) if @@path != ""
    @@path = ""
    @@files = Array(String).new
  end

  def path
    @@path
  end

  def files
    @@files
  end

  private def mkfiles(
    path : String,
    dirs : Int,
    hidden_dirs : Int,
    files : Int,
    hidden_files : Int,
    depth : Int
  ) : Array(String)
    list = Array(String).new
    return list if depth == 0

    (0..dirs).each do |n|
      n = File.join(path, "d#{n}")
      list << n
      FileUtils.mkdir_p(n)
      f = mkfiles(n, dirs, hidden_dirs, files, hidden_files, depth - 1)
      list.concat(f)
    end

    (0..hidden_dirs).each do |n|
      n = File.join(path, ".d#{n}")
      list << n
      FileUtils.mkdir_p(n)
      f = mkfiles(n, dirs, hidden_dirs, files, hidden_files, depth - 1)
      list.concat(f)
    end

    (0..files).each do |n|
      n = File.join(path, "f#{n}")
      list << n
      FileUtils.touch(n)
    end

    (0..hidden_files).each do |n|
      n = File.join(path, ".f#{n}")
      list << n
      FileUtils.touch(n)
    end

    list
  end
end
