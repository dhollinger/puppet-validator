class PuppetValidator

  # rspec defines a crapton of global information and doesn't clean up well
  # between runs. This means that there are global objects that leak and chew
  # up memory. To counter that, we fork a process to run the spec test.
  #
  # This also allows us to load different versions of Puppet so users can select
  # the version they want to validate against.
  def self.run_in_process
    raise "Please define a block to run in a new process." unless block_given?

    reader, writer = IO.pipe
    output = nil

    if fork
      writer.close
      output = reader.read
      reader.close
      Process.wait
    else
      reader.close
      writer.write(yield)
      writer.close
      # if we fire any at_exit hooks, Sinatra has a kitten
      exit!
    end

    output
  end

end