module IconFinder
  def self.find(pkgName, iconName) # find an icon from ${XDG_ICON_DIRS}
    if icoName[0] == '/'
      iconPath, iconMime = iconName, MimeType[ File.extname(iconName) ]
    else
      svgIco = Dir["/usr/local/share/icons/*/scalable/apps/#{iconName}.svg"]
      iconPath, iconMime = svgIco[0], MimeType['.svg'] if svgIco.any?

      pngIco = Dir["/usr/local/share/icons/*/*x*/apps/#{iconName}.png"].sort_by {|path| path[/\/(\d+)x\d+\//, 1] }
      iconPath, iconMime = pngIco[-1], MimeType['.png'] if pngIco.any? or pngIco[-1][/\/(\d+)x\d+\//, 1].to_i < 144

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
