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
end
