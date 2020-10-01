module SystemHelpers
  require "open3"

  protected

  def shell(*args)
    stdin, stdouterr, thr = Open3.popen2e(*args)
    out = stdouterr.read
    stdin.close
    stdouterr.close
    [thr.value.success?, out]
  end

  def shell_stream(*args)
    Open3.popen2e(*args) do |stdin, stdouterr, thr|
      stdouterr.each do |line|
        $stdout.puts line
      end
      stdin.close
      stdouterr.close
      thr.value.success?
    end
  end
end
