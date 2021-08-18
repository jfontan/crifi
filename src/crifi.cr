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
        break if @paths.size == 0

        p = @paths.pop
        dirs = process(p)
        dirs.each { |d| @paths.push(d) }
      end
    end

    def find_parallel
      work = Channel(String).new
      dirs = Channel(Array(String)).new

      4.times do
        spawn do
          while path = work.receive?
            break if !path
            d = process(path)
            dirs.send(d)
          end
        end
      end

      path = @path
      value = true
      active = 0
      loop do
        if value
          select
          when work.send(path)
            active += 1
            if @paths.size > 0
              path = @paths.pop
              value = true
            else
              value = false
            end
          when d = dirs.receive
            active -= 1
            d.each { |p| @paths.push(p) }
          end
        else
          break if active <= 0

          d = dirs.receive
          active -= 1
          d.each { |p| @paths.push(p) }

          if @paths.size > 0
            path = @paths.pop
            value = true
          end
        end
      end
      work.close
    end

    def process(path : String) : Array(String)
      begin
        dir = Crystal::System::Dir.open(path)
      rescue
        puts "Error: " + path
        return Array(String).new
      end

      dirs = Array(String).new
      files = String::Builder.new(4096)
      base = "#{path}/"
      if path == "/"
        base = "/"
      end

      while true
        begin
          e = Crystal::System::Dir.next_entry(dir, path)
        rescue
          puts "Error: " + path
        end

        break if !e
        next if e.name == "." || e.name == ".."

        fp = "#{base}#{e.name}"
        files << fp << "\n"

        next if !e.dir?
        dirs << fp
      end

      print files.to_s

      Crystal::System::Dir.close(dir, path)
      return dirs
    end
  end

  class DirReader
    def initialize(path : String)
      @dir = Crystal::System::Dir.open(path)
      @path = path
    end

    @[AlwaysInline]
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

f = Crifi::Find.new("/")
f.find_parallel
