module DesktopFile
  def self.parse(path) # parse .desktop file into hash
    fileIO = File.open(entryFile, 'r')
    parsedEntry = Hash.new

    while ( line = fileIO.gets(chomp: true) )
      case line[0]
      when '#', "\n"
        next
      when '['
        currentGroup = line[/^\[(.+)\]$/, 1]
        parsedEntry[currentGroup] = Hash.new
      else
        k, v = line.split('=', 2)
        parsedEntry[currentGroup][k] = v
      end
    end

    return parsedEntry
  end
end
