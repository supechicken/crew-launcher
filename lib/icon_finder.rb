def magick_installed?
  return system('command -v convert', out: '/dev/null')
end

def getImgSize (icon, width_only: false)
  # img_size: return size of the icon
  format = (width_only)? '%w' : '%wx%h'
  return `identify -format '#{format}' #{icon}`.chomp
end

def convert_img (imgFile, convertedSize = '512x512') # convert icon to .png format
  imgName = File.basename(imgFile, '.*')
  outImg = "#{ICONDIR}/#{imgName}.png"

  system 'convert', '-resize', convertedSize, imgFile, outImg, exception: true
  return outImg, convertedSize, 'image/png'
end

module IconFinder
  def self.find(pkgName, iconName) # find an icon from paths in package's filelist
    matchedIcon = Dir[*IconSearchGlob.map {|path| path % pkgName}].sort_by do |icon|
                    # priority: '.svg' > '.png' > '.xpm' > Chromebrew Icon
                    case File.extname(icon)
                    when '.svg'
                      3
                    when '.png'
                      pngSize = getImgSize(icon, w_only: true).to_i
                      # assign priority based on the image size
                      "2.#{pngSize.rjust(4, '0')}".to_f
                    when '.xpm'
                      0
                    end
                  end[-1]

    # convert the XPM file to PNG as XPM is not supported by chrome
    # if the icon size is smaller than 144x144px, resize it to meets the minimum requirement of PWA icons
    iconPath, iconSize, iconMime = if matchIcon and matchIcon !~ /\.svg$/ and \
                                        (
                                          getImgSize(matchedIcon, w_only: true).to_i >= 144 or \
                                          matchedIcon =~ /\.xpm$/
                                        )
                                     convert_img(matchedIcon)
                                   elsif matchIcon
                                     [ matchedIcon, getImgSize(matchedIcon), MimeType[ File.extname(matchedIcon) ] ]
                                   else
                                     error 'Unable to find an icon :/'
                                     [ CREWICON, '546x546', 'image/png' ]
                                   end

    # remove duplicate slash in path
    iconPath.squeeze!('/')

    Verbose.puts "Icon found: #{iconPath}" unless iconPath == CREWICON
    return iconPath, iconSize, iconMime
  end
end
