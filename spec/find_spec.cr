require "./spec_helper"

describe ParallelFind do
  # TODO: Write tests

  it "works" do
    true.should eq(true)
  end

  it "finds" do
    f = ParallelFind::Find.new(".", "")
    f.find_parallel
  end
end
