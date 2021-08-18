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
      if File.symlink?(path)
        return Array(String).new
      end
      dirs = Array(String).new
      files = Array(String).new
      base = Path.new(path)

      Dir.each(path) do |f|
        if f == "." || f == ".."
          next
        end

        fp = base.join(f).to_s
        files << fp

        begin
          info = File.info(fp)
        rescue
          puts "Error: " + fp
          next
        end

        if info.directory?
          dirs << fp
        end
      end

      puts files.join("\n")

      return dirs
    rescue
      puts "Error: " + path
      return Array(String).new
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

r = Crifi::DirReader.new(".")
r.each { |e| puts e.name, e.dir? }
r.close
