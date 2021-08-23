require "./spec_helper"
require "file_utils"

describe ParallelFind do
  it "setup" do
    Generator.generate(10, 10, 10, 10, 1)
  end

  it "finds all files" do
    t = Generator.path
    f = ParallelFind::Find.new(t, "", print: false)
    files = f.find_parallel
    files.sort!
    files.should eq(Generator.files)
  end

  it "finds pattern" do
    t = Generator.path
    f = ParallelFind::Find.new(t, "f0", print: false)
    files = f.find_parallel
    files.sort!
    expected = Generator.files.select { |n| /f0/.match(n) }
    files.should eq(expected)
  end

  it "cleanup" do
    Generator.clean
  end
end
