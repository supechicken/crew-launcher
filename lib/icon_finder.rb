module IconFinder
  def self.find(iconName) # find an icon from ${XDG_ICON_DIRS}
    if iconName[0] == '/'
      iconPath, iconMime = iconName, MimeType[ File.extname(iconName) ]
    else
      svgIcon = Dir["/usr/local/share/icons/*/scalable/apps/#{iconName}.svg"]
      iconPath, iconMime = svgIcon[0], MimeType['.svg'] if svgIcon.any?

      pngIcon = Dir["/usr/local/share/icons/*/*x*/apps/#{iconName}.png"].sort_by {|path| path[/\/(\d+)x\d+\//, 1] }
      iconPath, iconMime = pngIcon[-1], MimeType['.png'] if pngIcon.any? or pngIcon[-1][/\/(\d+)x\d+\//, 1].to_i < 144

      return nil
    end

    # remove duplicate slash in path
    iconPath.squeeze!('/')

    if iconPath
      Verbose.puts "Icon found: #{iconPath}"
      return iconPath, iconMime
    end
  end
end
