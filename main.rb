#!/usr/bin/env ruby
# - * - coding: UTF-8 - * -

require 'fileutils'
require 'socket'
require 'uri'
require 'json'
require_relative 'lib/const'
require_relative 'lib/color'
require_relative 'lib/desktop_file'
require_relative 'lib/function'
require_relative 'lib/http_server'
require_relative 'lib/icon_finder'

FileUtils.mkdir_p [ "#{TMPDIR}/cmdlog/", CONFIGDIR ]
Process.setproctitle 'Chromebrew Launcher'

def getPID
  if File.exist?("#{TMPDIR}/daemon.pid")
    return File.read("#{TMPDIR}/daemon.pid").to_i
  else
    return 0
  end
end

def stopExistingDaemon
  # kill existing server daemon
  begin
    daemon_pid = getPID
    if daemon_pid > 0
      Process.kill(15, daemon_pid)
      FileUtils.rm_f "#{TMPDIR}/daemon.pid"
      puts "crew-launcher server daemon with PID #{daemon_pid} stopped.".lightred
    end
  rescue Errno::ESRCH
  end
end

def CreateProfile(entryFile)
  # convert given path to absolute path
  entryFile = File.expand_path(entryFile)

  abort "crew-launcher: No such file or directory -- '#{entryFile}'".lightred unless File.exist?(entryFile)

  # convert parsed hash into json format
  desktop = DesktopFile.parse(entryFile)

  _, iconType = IconFinder.find(desktop['Desktop Entry']['Icon'])
  return {
    background_color: 'black',
    theme_color: 'black',
    name: desktop['Desktop Entry']['Name'],
    short_name: desktop['Desktop Entry']['GenericName'],
    description: desktop['Desktop Entry']['Comment'],
    start_url: "/exec?entry=#{entryFile}&action=main",
    display: 'standalone',
    icons: [{ src: "/icon?entry=#{entryFile}", type: iconType }],
    shortcuts:
      desktop.select {|k, v| k =~ /^Desktop Action/ } .map do |k, v|
        actionTag = k[/^Desktop Action (.+)$/, 1]
        url = "/exec?entry=#{entryFile}&action=#{actionTag}"
        { name: v['Name'], url: url }
      end
  }
end

def InstallPWA (entryFile)
  manifest = CreateProfile(entryFile)
  # open a new tab in Chrome OS using dbus
  system 'dbus-send',
         '--system',
         '--type=method_call',
         '--print-reply',
         '--dest=org.chromium.UrlHandlerService',
         '/org/chromium/UrlHandlerService',
         'org.chromium.UrlHandlerServiceInterface.OpenUrl',
         "string:http://localhost:#{PORT}/installer.html?entry=#{entryFile}"

  HTTPServer.start do |sock, uri, method|
    filename = File.basename(uri.path)
    iconPath, iconType = IconFinder.find(desktop['Desktop Entry']['Icon'])

    case filename
    when 'manifest.webmanifest'
      sock.print HTTPHeader(200, 'application/manifest+json')
      sock.write JSON.parse(manifest)
    when 'appicon'
      sock.print HTTPHeader(200, iconType)
      sock.write File.binread(iconPath)
    when 'stop'
      sock.print HTTPHeader(200)
      return
    else
      # search requested file in `pwa/` directory
      if File.file?("#{APPDIR}/pwa/#{filename}")
        sock.print HTTPHeader(200, MimeType[ File.extname(filename) ])
        sock.write File.read("#{APPDIR}/pwa/#{filename}")
      else
        sock.print HTTPHeader(404)
      end
    end
  end
end

def StartWebDaemon
  def LaunchApp(entryFile, actionTag)
    unless File.exist?(entryFile)
      error "#{entryFile}: No such file or directory"
      retuen false
    end

    if actionTag == 'main'
      group = 'Desktop Entry'
    else
      group = "Desktop Action #{actionTag}"
    end
    
    entry = DesktopFile.parse(entryFile)
    execCmd = entry[group]['Exec'].gsub(/%[^%]/, '')

    log = "#{TMPDIR}/cmdlog/#{uuid}.log"
    spawn(execCmd, {[:out, :err] => File.open(log, 'w')})

    puts <<~EOT, nil
      Profile: #{file}
      CmdLine: #{execCmd}
      Output: #{log}
    EOT
  end

  # turn into a background process
  Process.daemon(true, true)

  puts "crew-launcher server daemon with PID #{Process.pid} started.".lightgreen

  # redirect output to log
  log = File.open("#{TMPDIR}/daemon.log", 'w')
  log.sync = true
  STDOUT.reopen(log)
  STDERR.reopen(log)

  File.write("#{TMPDIR}/daemon.pid", Process.pid)

  HTTPServer.start do |sock, uri, method|
    action = File.basename(uri)
    params = URI.decode_www_form(uri.query.to_s).to_h
    entryFile = params['entry']
    actionTag = params['action']

    unless File.exist?(entryFile)
      sock.print HTTPHeader(404)
      next
    end

    case action
    when 'run'
      LaunchApp(entryFile, actionTag)
      sock.print HTTPHeader(200, 'text/html')
      sock.write File.read("#{APPDIR}/pwa/app.html")
    when 'stop'
      sock.print HTTPHeader(200)
      sock.print 'crew-launcher server terminated: User interrupt.'
      exit 0
    end
  end
end

case ARGV[0]
when 'add', 'new'
  stopExistingDaemon()
  InstallPWA(ARGV[1])
  StartWebDaemon()
when 'start', 'start-server'
  stopExistingDaemon()
  StartWebDaemon()
when 'stat', 'status'
  daemon_pid = getPID
  if daemon_pid > 0
    puts "crew-launcher server daemon with PID #{daemon_pid} is running.".lightgreen
  else
    puts "crew-launcher server daemon is not running.".lightred
  end
when 'stop', 'stop-server'
  stopExistingDaemon()
when 'remove'
  uuid = getUUID(ARGV[1])
  if uuid
    File.delete("#{CONFIGDIR}/#{uuid}.json")
    puts "Profile #{CONFIGDIR}/#{uuid}.json removed!".lightgreen
  else
    error "Error: Cannot find a profile for #{ARGV[1]} :/"
  end
when 'help', 'h', nil
  puts HELP
else
  print <<~EOT.lightred
    crew-launcher: invalid option '#{ARGV[0]}'
    Run `crew-launcher help` for more information.
  EOT
end
