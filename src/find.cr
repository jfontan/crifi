require "nested_scheduler"

module ParallelFind
  VERSION = "0.1.0"

  struct Result
    property dirs, files

    def initialize(@dirs : Array(String), @files : Array(String))
    end
  end

  class Find
    def initialize(
      path : String,
      search : String,
      list : Bool = true,
      print : Bool = false
    )
      @path = path
      @paths = Array(String).new
      @re = Regex.new(search)
      @list = list
      @print = print
    end

    def find
      @paths.push @path

      loop do
        break if @paths.size == 0

        p = @paths.pop
        dirs = process(p, @re)
        dirs.each { |d| @paths.push(d) }
      end
    end

    def find_parallel : Array(String)
      work = Channel(String).new
      results = Channel(Result | Nil).new
      files = Array(String).new

      nprocs = System.cpu_count

      NestedScheduler::ThreadPool.nursery(thread_count: nprocs.to_i32) do |pool|
        (nprocs - 1).times do
          pool.spawn do
            while path = work.receive?
              break if !path
              r = process(path, @re)
              results.send(r)
            end
          end
        end

        pool.spawn do
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
              when r = results.receive
                active -= 1
                if r
                  @paths.concat(r.dirs) if r.dirs
                  files.concat(r.files) if r.files
                end
              end
            else
              break if active <= 0

              r = results.receive
              active -= 1
              if r
                @paths.concat(r.dirs) if r.dirs
                files.concat(r.files) if r.files
              end

              if @paths.size > 0
                path = @paths.pop
                value = true
              end
            end
          end
          work.close
        end
        files
      end
    end

    def process(path : String, re : Regex) : Result | Nil
      begin
        dir = Crystal::System::Dir.open(path)
      rescue
        puts "Error: " + path
        return nil
      end

      dirs = Array(String).new
      files = Array(String).new
      show = String::Builder.new(4096) if @print
      base = "#{path}/"
      if path == "/"
        base = "/"
      end

      loop do
        begin
          e = Crystal::System::Dir.next_entry(dir, path)
        rescue
          puts "Error: " + path
        end

        break if !e
        next if e.name == "." || e.name == ".."

        fp = "#{base}#{e.name}"
        show << fp << "\n" if re.match(fp) if show
        files << fp if @list

        next if !e.dir?
        dirs << fp
      end

      print show.to_s if show

      Crystal::System::Dir.close(dir, path)
      return Result.new(dirs, files)
    end
  end
end
