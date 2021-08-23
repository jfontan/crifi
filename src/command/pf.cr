require "option_parser"
require "../find"

pattern = ""
path = "."
jobs = 0

OptionParser.parse do |parser|
  parser.banner = "Usage: pf [options] [pattern] [path]"
  parser.on("-h", "--help", "Show help") do
    puts parser
    exit
  end
  parser.on("-j JOBS", "--jobs=JOBS", "The number of parallel threads") do |j|
    jobs = j.to_i
  end
end

pattern = ARGV[0] if ARGV.size > 0
path = ARGV[1] if ARGV.size > 1

f = ParallelFind::Find.new(path, pattern, list: false, print: true)
f.find(jobs)
