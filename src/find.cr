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

    def find(jobs : Int = 0)
      nprocs = System.cpu_count
      jobs = nprocs - 1 if jobs == 0
      return find_sequential if jobs == 1 || nprocs < 4
      find_parallel(jobs)
    end

    def find_sequential : Array(String)
      files = Array(String).new
      @paths.push @path

      loop do
        break if @paths.size == 0

        p = @paths.pop
        r = process(p, @re)
        next if !r
        @paths.concat(r.dirs)
        files.concat(r.files) if @list && r.files
      end

      files
    end

    def find_parallel(jobs : Int = 0) : Array(String)
      work = Channel(String).new
      results = Channel(Result | Nil).new
      files = Array(String).new

      nprocs = System.cpu_count
      nprocs = jobs if jobs > 0

      jobs.times do
        spawn do
          while path = work.receive?
            break if !path
            r = process(path, @re)
            results.send(r)
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
      files
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
        if re.match(fp)
          show << fp << "\n" if show
          files << fp if @list
        end

        next if !e.dir?
        dirs << fp
      end

      print show.to_s if show

      Crystal::System::Dir.close(dir, path)
      return Result.new(dirs, files)
    end
  end
end
