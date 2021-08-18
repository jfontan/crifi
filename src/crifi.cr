# TODO: Write documentation for `Crifi`
module Crifi
  VERSION = "0.1.0"

  class Find
    def initialize(path : String)
      @path = path
      @paths = Array(String).new
    end

    def find
      @paths.push @path

      while true
        if @paths.size == 0
          break
        end

        p = @paths.pop
        dirs = process(p)
        dirs.each { |d| @paths.push(d) }
      end
    end

    def process(path : String) : Array(String)
      begin
        dir = DirReader.new(path)
      rescue
        puts "Error: " + path
        return Array(String).new
      end

      dirs = Array(String).new
      files = Array(String).new
      base = Path.new(path)

      dir.each do |e|
        if e.name == "." || e.name == ".."
          next
        end

        fp = base.join(e.name).to_s
        files << fp

        if e.dir? == nil || e.dir? == false
          next
        end

        dirs << fp
      rescue
        if fp
          puts "Error: " + fp
        end
      end

      puts files.join("\n")

      dir.close
      return dirs
    end
  end

  class DirReader
    def initialize(path : String)
      @dir = Crystal::System::Dir.open(path)
      @path = path
    end

    def each(&block)
      while true
        ent = Crystal::System::Dir.next_entry(@dir, @path)
        break if !ent
        yield ent
      end
    end

    def close
      Crystal::System::Dir.close(@dir, @path)
    end
  end
end

f = Crifi::Find.new("/home/jfontan")
f.find
