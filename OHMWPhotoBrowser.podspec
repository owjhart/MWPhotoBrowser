Pod::Spec.new do |s|

  s.name = 'OHMWPhotoBrowser'
  s.version = '3.0.0'
  s.license = 'MIT'
  s.summary = 'A fork of MWPhotoBrowser. A simple iOS photo and video browser with optional captions for iOS 13+.'
  s.description = <<-DESCRIPTION
                  MWPhotoBrowser can display one or more images or videos by providing either UIImage
                  objects, web images/videos or local files.
                  The photo browser handles the downloading and caching of photos from the web seamlessly.
                  Photos can be zoomed and panned, and optional (customisable) captions can be displayed.
                  DESCRIPTION
  s.screenshots = [
    'https://raw.github.com/mwaterfall/MWPhotoBrowser/master/Screenshots/MWPhotoBrowser1.png',
    'https://raw.github.com/mwaterfall/MWPhotoBrowser/master/Screenshots/MWPhotoBrowser2.png',
    'https://raw.github.com/mwaterfall/MWPhotoBrowser/master/Screenshots/MWPhotoBrowser3.png',
    'https://raw.github.com/mwaterfall/MWPhotoBrowser/master/Screenshots/MWPhotoBrowser4.png',
    'https://raw.github.com/mwaterfall/MWPhotoBrowser/master/Screenshots/MWPhotoBrowser5.png',
    'https://raw.github.com/mwaterfall/MWPhotoBrowser/master/Screenshots/MWPhotoBrowser6.png'
  ]

  s.homepage = 'https://github.com/owjhart/MWPhotoBrowser'
  s.author = { 'owjhart' => 'owenjhart@gmail.com' }

  s.source = {
    :git => 'https://github.com/owjhart/MWPhotoBrowser.git',
    :tag => '2.1.1'
  }
  s.platform = :ios, '13.0'
  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'MWPhotoBrowser' => ['Pod/Assets/*.png']
  }
  s.requires_arc = true

  s.frameworks = 'ImageIO', 'QuartzCore', 'AVKit'
  s.weak_frameworks = 'Photos'

  s.dependency 'MBProgressHUD', '~> 1.1'
  s.dependency 'DACircularProgress', '~> 2.3'
  s.dependency 'SDWebImage', '~> 5.2'

end
